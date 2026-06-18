const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { Pool } = require('pg');
const { PrismaPg } = require('@prisma/adapter-pg');
const { PrismaClient } = require('@prisma/client');

const databaseUrl = (process.env.DATABASE_URL || '').trim();
const useDatabaseSsl = /render\.com/i.test(databaseUrl);
const prismaPool = new Pool({
  connectionString: databaseUrl,
  ssl: useDatabaseSsl ? { rejectUnauthorized: false } : undefined,
});
const prismaAdapter = new PrismaPg(prismaPool);
const app = express();
const prisma = new PrismaClient({ adapter: prismaAdapter });
const PORT = Number.parseInt(process.env.PORT || '3000', 10);
const backendApiToken = (process.env.BACKEND_API_TOKEN || '').trim();
const requireAuthForWrites =
  (process.env.REQUIRE_AUTH_FOR_WRITES ||
    (process.env.NODE_ENV === 'production' ? '1' : '0')) === '1';
const allowedOrigins = (process.env.CORS_ALLOWED_ORIGINS || '')
  .split(',')
  .map(origin => origin.trim())
  .filter(Boolean);
const stripeWebhookSecret = (process.env.STRIPE_WEBHOOK_SECRET || '').trim();
const stripeWebhookToleranceSec = Number.parseInt(
  process.env.STRIPE_WEBHOOK_TOLERANCE_SEC || '300',
  10,
);
const allowClientProviderEvents =
  (process.env.ALLOW_CLIENT_PROVIDER_EVENTS ||
    (process.env.NODE_ENV === 'production' ? '0' : '1')) === '1';

const writeRateWindowMs = Number.parseInt(
  process.env.WRITE_RATE_LIMIT_WINDOW_MS || `${15 * 60 * 1000}`,
  10,
);
const writeRateMax = Number.parseInt(
  process.env.WRITE_RATE_LIMIT_MAX || '120',
  10,
);
const writeRateBuckets = new Map();
const DEMO_USER_ID = 'host_demo_001';
const DEMO_FAMILY_ID = 'demo-family-001';

const WRITE_METHODS = new Set(['POST', 'PUT', 'PATCH', 'DELETE']);

function isWriteRequest(req) {
  return WRITE_METHODS.has(req.method);
}

function getClientIp(req) {
  const xff = req.headers['x-forwarded-for'];
  if (typeof xff === 'string' && xff.trim()) {
    return xff.split(',')[0].trim();
  }
  return req.ip || req.socket?.remoteAddress || 'unknown';
}

function parseStripeSignatureHeader(headerValue) {
  if (!headerValue || typeof headerValue !== 'string') {
    return { timestamp: null, signatures: [] };
  }

  let timestamp = null;
  const signatures = [];

  for (const part of headerValue.split(',')) {
    const [key, value] = part.split('=');
    if (!key || !value) continue;
    const trimmedKey = key.trim();
    const trimmedValue = value.trim();

    if (trimmedKey === 't') {
      const parsed = Number.parseInt(trimmedValue, 10);
      if (Number.isFinite(parsed)) {
        timestamp = parsed;
      }
    }

    if (trimmedKey === 'v1' && trimmedValue) {
      signatures.push(trimmedValue);
    }
  }

  return { timestamp, signatures };
}

function verifyStripeWebhookSignature({ rawBody, signatureHeader, secret, toleranceSec }) {
  const { timestamp, signatures } = parseStripeSignatureHeader(signatureHeader);
  if (!timestamp || signatures.length === 0 || !secret) {
    return false;
  }

  const nowSec = Math.floor(Date.now() / 1000);
  if (Math.abs(nowSec - timestamp) > toleranceSec) {
    return false;
  }

  const payloadToSign = `${timestamp}.${rawBody}`;
  const expected = crypto
    .createHmac('sha256', secret)
    .update(payloadToSign, 'utf8')
    .digest('hex');

  const expectedBuffer = Buffer.from(expected, 'hex');
  for (const candidate of signatures) {
    try {
      const candidateBuffer = Buffer.from(candidate, 'hex');
      if (
        candidateBuffer.length === expectedBuffer.length &&
        crypto.timingSafeEqual(candidateBuffer, expectedBuffer)
      ) {
        return true;
      }
    } catch (_) {
      // Ignore malformed signature fragments.
    }
  }

  return false;
}

// Middleware
app.use((req, res, next) => {
  // Baseline hardening headers for API traffic.
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('Referrer-Policy', 'no-referrer');
  res.setHeader('Permissions-Policy', 'geolocation=(), microphone=(), camera=()');
  next();
});

app.use(
  cors({
    origin(origin, callback) {
      if (!origin) {
        callback(null, true);
        return;
      }

      if (allowedOrigins.length === 0) {
        callback(null, true);
        return;
      }

      if (allowedOrigins.includes(origin)) {
        callback(null, true);
        return;
      }

      callback(new Error('Origin not allowed by CORS'));
    },
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    maxAge: 600,
  }),
);

app.post('/payments/stripe/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  if (!stripeWebhookSecret) {
    return res.status(503).json({ error: 'STRIPE_WEBHOOK_SECRET fehlt' });
  }

  const signatureHeader = req.headers['stripe-signature'];
  const rawBody = Buffer.isBuffer(req.body) ? req.body.toString('utf8') : '';
  const isValid = verifyStripeWebhookSignature({
    rawBody,
    signatureHeader,
    secret: stripeWebhookSecret,
    toleranceSec: stripeWebhookToleranceSec,
  });

  if (!isValid) {
    return res.status(400).json({ error: 'Ungueltige Stripe-Signatur' });
  }

  let event;
  try {
    event = JSON.parse(rawBody);
  } catch (_) {
    return res.status(400).json({ error: 'Ungueltiges Stripe-Webhook-JSON' });
  }

  const eventType = (event?.type || '').toString();
  const obj = event?.data?.object || {};
  let targetStatus = null;

  if (eventType === 'payment_intent.succeeded') {
    targetStatus = 'completed';
  } else if (eventType === 'payment_intent.payment_failed') {
    targetStatus = 'failed';
  } else if (eventType === 'charge.refunded') {
    targetStatus = 'refunded';
  }

  if (!targetStatus) {
    return res.json({ received: true, ignored: true, reason: 'event_not_mapped' });
  }

  const providerTransactionRef =
    (obj?.payment_intent || obj?.id || '').toString().trim();

  if (!providerTransactionRef) {
    return res.status(400).json({ error: 'Stripe event ohne payment reference' });
  }

  const result = await applyProviderTransactionStatusUpdate({
    provider: 'stripe',
    providerTransactionRef,
    targetStatus,
    verified: true,
  });

  if (!result.ok) {
    if (result.code === 'not_found') {
      return res.status(202).json({
        received: true,
        pending: true,
        reason: 'transaction_not_found',
      });
    }
    return res.status(result.httpStatus).json({ error: result.error });
  }

  return res.json({
    received: true,
    transactionId: result.item.id,
    status: result.item.status,
  });
});

app.use(express.json({ limit: '1mb' }));

app.use((req, res, next) => {
  if (!isWriteRequest(req)) {
    next();
    return;
  }

  const now = Date.now();
  const key = `${getClientIp(req)}:${req.method}`;
  const bucket = writeRateBuckets.get(key);

  if (!bucket || now - bucket.start > writeRateWindowMs) {
    writeRateBuckets.set(key, { start: now, count: 1 });
    next();
    return;
  }

  bucket.count += 1;
  if (bucket.count > writeRateMax) {
    res.status(429).json({ error: 'Zu viele Anfragen. Bitte später erneut versuchen.' });
    return;
  }

  next();
});

app.use((req, res, next) => {
  if (!isWriteRequest(req)) {
    next();
    return;
  }

  if (!requireAuthForWrites) {
    next();
    return;
  }

  if (!backendApiToken) {
    res.status(503).json({ error: 'Server-Konfiguration unvollständig (BACKEND_API_TOKEN fehlt).' });
    return;
  }

  const authHeader = req.headers.authorization || '';
  const expected = `Bearer ${backendApiToken}`;
  if (authHeader !== expected) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }

  next();
});

// Providers-Daten aus JSON laden
const providersPath = path.join(__dirname, 'providers.json');
const weeklyImpulseSchemaPath = path.join(
  __dirname,
  'weekly_impulse_schema_year3.json',
);

function getProviders() {
  try {
    const data = fs.readFileSync(providersPath, 'utf8');
    return JSON.parse(data).providers;
  } catch (error) {
    console.error('Fehler beim Lesen der Providers:', error);
    return [];
  }
}

function saveProviders(providers) {
  try {
    fs.writeFileSync(providersPath, JSON.stringify({ providers }, null, 2));
    return true;
  } catch (error) {
    console.error('Fehler beim Speichern der Providers:', error);
    return false;
  }
}

function getWeeklyImpulseSchema() {
  try {
    const data = fs.readFileSync(weeklyImpulseSchemaPath, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    console.error('Fehler beim Lesen des Weekly-Impulse-Schemas:', error);
    return null;
  }
}

// In-memory stores for app endpoints
const todos = [
  {
    id: 'todo-1',
    familyId: 'demo-family-001',
    title: 'Hausaufgaben machen',
    completed: false,
    assigneeName: 'Leon',
    category: 'Schule',
  },
  {
    id: 'todo-2',
    familyId: 'demo-family-001',
    title: 'Arzttermin buchen',
    completed: false,
    assigneeName: 'Mama',
    category: 'Gesundheit',
  },
];

const shoppingItems = [
  {
    id: 'shop-1',
    familyId: 'demo-family-001',
    name: 'Milch',
    checked: false,
    category: 'Lebensmittel',
  },
  {
    id: 'shop-2',
    familyId: 'demo-family-001',
    name: 'Windeln',
    checked: true,
    category: 'Baby',
  },
];

const calendarEvents = [
  {
    id: 'cal-1',
    familyId: 'demo-family-001',
    title: 'Elternabend',
    startsAt: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000).toISOString(),
    location: 'Kita Sonnenschein',
  },
];

const photoAlbums = [
  {
    id: 'album-1',
    familyId: 'demo-family-001',
    title: 'Familienausflug',
    photoCount: 12,
    createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
  },
  {
    id: 'album-2',
    familyId: 'demo-family-001',
    title: 'Geburtstag Leon',
    photoCount: 24,
    createdAt: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000).toISOString(),
  },
];

const parentProfiles = [
  {
    id: 'p1',
    name: 'Miriam',
    age: 34,
    city: 'Berlin',
    bio: 'Ich suche Eltern für gemeinsame Wochenendaktivitäten und ehrlichen Austausch.',
    interests: ['Spielplatz', 'Outdoor', 'Familienzeit', 'Bildung'],
    languages: ['Deutsch', 'Englisch'],
    valuesFocus: ['Gewaltfrei', 'Empathie', 'Inklusion'],
    childAges: ['3-5', '6-9'],
    familyForm: 'Kernfamilie',
    verificationLevel: 'recommended',
  },
  {
    id: 'p2',
    name: 'Sibel',
    age: 37,
    city: 'Köln',
    bio: 'Alleinerziehend, offen für neue Freundschaften mit Eltern in ähnlicher Situation.',
    interests: ['Gesundheit', 'Bildung', 'Kreativ'],
    languages: ['Deutsch', 'Türkisch'],
    valuesFocus: ['Respekt', 'Offenheit', 'Empathie'],
    childAges: ['6-9', '10-13'],
    familyForm: 'Alleinerziehend',
    verificationLevel: 'checked',
  },
];

const parentMatchingActions = [];

const familyContacts = [
  {
    userId: 'host_001',
    displayName: 'Mia Schneider',
    city: 'Berlin',
    childrenSummary: 'Kind: 4 Jahre',
  },
  {
    userId: 'host_002',
    displayName: 'Lena Yilmaz',
    city: 'Berlin',
    childrenSummary: 'Kinder: 7 und 10 Jahre',
  },
  {
    userId: 'host_003',
    displayName: 'Noah Weber',
    city: 'Berlin',
    childrenSummary: 'Kind: 2 Jahre',
  },
];

const familyRequests = [
  {
    id: 'req_1',
    fromUserId: 'host_003',
    toUserId: 'host_demo_001',
    fromDisplayName: 'Noah Weber',
    sentAt: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
    status: 'pending',
  },
];

const events = [
  {
    id: 'event-1',
    hosterId: 'host_001',
    title: 'Spielplatz Treffen',
    description: 'Treffen für Kinder zum gemeinsamen Spielen auf dem Spielplatz',
    category: 'socialGathering',
    ageGroups: ['toddler', 'preschool'],
    location: 'Zentralpark, Berlin',
    latitude: 52.52,
    longitude: 13.405,
    eventDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString(),
    createdAt: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
    paymentDate: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
    maxParticipants: 15,
    currentParticipants: 5,
    photoUrl: '',
    status: 'active',
    visibility: 'publicNearby',
    shareRadiusKm: 25,
    invitedUserIds: [],
    inviteCodeExpiresAt: null,
  },
  {
    id: 'event-2',
    hosterId: 'host_002',
    title: 'Kinderturnen im Park',
    description: 'Altersgerechtes Turntraining für kleine Sportler',
    category: 'sports',
    ageGroups: ['elementary'],
    location: 'Sportplatz Mitte, Berlin',
    latitude: 52.53,
    longitude: 13.415,
    eventDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000).toISOString(),
    createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
    paymentDate: new Date(Date.now() - 60 * 60 * 1000).toISOString(),
    maxParticipants: 20,
    currentParticipants: 12,
    photoUrl: '',
    status: 'active',
    visibility: 'publicNearby',
    shareRadiusKm: 25,
    invitedUserIds: [],
    inviteCodeExpiresAt: null,
  },
];

const eventInvitations = [];
const eventParticipations = [];
const eventInviteCodes = {};
const eventInviteExpiresAt = {};
const paymentTransactions = [];
const eventChatMessages = {};
const eventChatReports = [];
const userEntitlements = new Map();

function generateInviteCode(eventId) {
  const suffix = (eventId || '').slice(-4).toUpperCase() || '0000';
  return `PP-${suffix}`;
}

function isInviteExpired(eventId) {
  const expiresAt = eventInviteExpiresAt[eventId];
  if (!expiresAt) return false;
  return new Date() > new Date(expiresAt);
}

function canViewerSeeEvent(event, viewerUserId) {
  if (!event || event.status !== 'active') return false;
  if (event.hosterId === viewerUserId) return true;

  if (event.visibility === 'privateOnly') return false;

  if (event.visibility === 'familyCircle') {
    const keyA = [event.hosterId, viewerUserId].sort().join('::');
    return keyA === 'host_001::host_demo_001' || keyA === 'host_002::host_demo_001';
  }

  if (event.visibility === 'inviteOnly') {
    return eventInvitations.some(
      invitation =>
        invitation.eventId === event.id &&
        invitation.invitedUserId === viewerUserId &&
        invitation.status === 'accepted',
    );
  }

  return true;
}

function generateId(prefix) {
  return `${prefix}-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
}

async function ensureDemoFamilyContext(familyId) {
  const targetFamilyId = (familyId || DEMO_FAMILY_ID).toString().trim() || DEMO_FAMILY_ID;

  await prisma.user.upsert({
    where: { id: DEMO_USER_ID },
    update: {},
    create: {
      id: DEMO_USER_ID,
      email: 'demo-host-001@parentpeak.local',
      passwordHash: 'demo',
      passwordSalt: 'demo',
      firstName: 'Demo',
      lastName: 'Host',
    },
  });

  await prisma.family.upsert({
    where: { id: targetFamilyId },
    update: {},
    create: {
      id: targetFamilyId,
      name: targetFamilyId === DEMO_FAMILY_ID ? 'Demo Familie' : `Familie ${targetFamilyId}`,
      createdById: DEMO_USER_ID,
      memberUsers: {
        connect: [{ id: DEMO_USER_ID }],
      },
    },
  });

  return targetFamilyId;
}

function parseTodoDescription(description) {
  if (!description || typeof description !== 'string') {
    return { assigneeName: 'Familie', category: 'Allgemein' };
  }

  try {
    const parsed = JSON.parse(description);
    return {
      assigneeName: (parsed.assigneeName || 'Familie').toString(),
      category: (parsed.category || 'Allgemein').toString(),
    };
  } catch (_) {
    return { assigneeName: 'Familie', category: 'Allgemein' };
  }
}

function buildTodoDescription(meta) {
  return JSON.stringify({
    assigneeName: (meta.assigneeName || 'Familie').toString(),
    category: (meta.category || 'Allgemein').toString(),
  });
}

function mapTodoRecordToApiItem(record) {
  const meta = parseTodoDescription(record.description);
  return {
    id: record.id,
    familyId: record.familyId,
    title: record.title,
    completed: Boolean(record.done),
    assigneeName: meta.assigneeName,
    category: meta.category,
    createdAt: record.createdAt,
    updatedAt: record.completedAt || null,
  };
}

function mapShoppingRecordToApiItem(record) {
  return {
    id: record.id,
    familyId: record.familyId,
    name: record.name,
    checked: Boolean(record.bought),
    category: 'Allgemein',
    createdAt: record.createdAt,
    updatedAt: record.boughtAt || null,
  };
}

function buildLocalEmail(identifier) {
  const safeIdentifier = (identifier || 'user')
    .toString()
    .toLowerCase()
    .replace(/[^a-z0-9._-]/g, '_');
  return `${safeIdentifier}@parentpeak.local`;
}

async function ensureBackendUser(userId, displayName) {
  const trimmedUserId = (userId || DEMO_USER_ID).toString().trim() || DEMO_USER_ID;
  const [firstName, ...restName] = (displayName || trimmedUserId).toString().split(' ');

  await prisma.user.upsert({
    where: { id: trimmedUserId },
    update: {},
    create: {
      id: trimmedUserId,
      email: buildLocalEmail(trimmedUserId),
      passwordHash: 'demo',
      passwordSalt: 'demo',
      firstName: firstName || 'Demo',
      lastName: restName.join(' ') || 'User',
    },
  });

  return trimmedUserId;
}

async function ensurePaymentContext(eventId, hosterId) {
  const trimmedEventId = (eventId || '').toString().trim();
  const trimmedHosterId = await ensureBackendUser(hosterId || DEMO_USER_ID, hosterId || 'Demo Host');
  const sourceEvent = events.find(item => item.id === trimmedEventId);

  await prisma.event.upsert({
    where: { id: trimmedEventId },
    update: {},
    create: {
      id: trimmedEventId,
      hosterId: trimmedHosterId,
      title: sourceEvent?.title || `Event ${trimmedEventId}`,
      description: sourceEvent?.description || 'Automatisch fuer Payment-Persistenz angelegt',
      startDate: sourceEvent?.eventDate ? new Date(sourceEvent.eventDate) : new Date(),
      location: sourceEvent?.location || '',
      status: sourceEvent?.status === 'active' ? 'upcoming' : (sourceEvent?.status || 'upcoming'),
      eventType: sourceEvent?.category || 'generic',
      maxParticipants: Number.isFinite(Number(sourceEvent?.maxParticipants))
        ? Number(sourceEvent.maxParticipants)
        : null,
    },
  });

  return { eventId: trimmedEventId, hosterId: trimmedHosterId };
}

function normalizeStoredPaymentStatus(value) {
  if (value === 'succeeded') return 'completed';
  return normalizePaymentStatus(value) || 'pending';
}

function getPaymentAuditDetails(record) {
  if (!record?.auditDetails || typeof record.auditDetails !== 'object') {
    return {};
  }
  return record.auditDetails;
}

function mapPaymentRecordToApiItem(record) {
  const audit = getPaymentAuditDetails(record);
  const status = normalizeStoredPaymentStatus(record.status);
  return {
    id: record.id,
    mode: audit.mode || 'prisma',
    eventId: record.eventId,
    hosterId: audit.hosterId || record.userId,
    amount: Number(record.amount),
    status,
    paymentMethod: audit.paymentMethod || 'stripe',
    providerTransactionRef: audit.providerTransactionRef || record.stripePaymentIntentId || null,
    providerVerified: Boolean(record.verifiedAt) || audit.providerVerified === true,
    stripePaymentIntentId: record.stripePaymentIntentId || null,
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
    completedAt: audit.completedAt || (status === 'completed' ? (record.verifiedAt || record.updatedAt) : null),
    failedAt: audit.failedAt || null,
    refundedAt: record.refundedAt || audit.refundedAt || null,
  };
}

function asIsoDate(value) {
  if (!value) return null;
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return null;
  return parsed.toISOString();
}

function parsePositiveNumber(value) {
  const amount = Number(value);
  if (!Number.isFinite(amount) || amount <= 0) return null;
  return amount;
}

function normalizePaymentStatus(value) {
  const raw = (value || '').toString().trim().toLowerCase();
  if (!raw) return 'completed';
  const allowed = new Set(['initiated', 'pending', 'completed', 'failed', 'refunded']);
  if (!allowed.has(raw)) return null;
  return raw;
}

function canTransitionPaymentStatus(fromStatus, toStatus) {
  if (fromStatus === toStatus) return true;
  const transitions = {
    initiated: new Set(['pending', 'completed', 'failed']),
    pending: new Set(['completed', 'failed', 'refunded']),
    completed: new Set(['refunded']),
    failed: new Set([]),
    refunded: new Set([]),
  };
  return transitions[fromStatus]?.has(toStatus) === true;
}

async function updateEventPaymentDateIfCompleted(transaction) {
  if (!transaction || transaction.status !== 'completed') {
    return;
  }
  const eventIndex = events.findIndex(event => event.id === transaction.eventId);
  if (eventIndex !== -1) {
    events[eventIndex] = {
      ...events[eventIndex],
      paymentDate: transaction.completedAt || new Date().toISOString(),
    };
  }

  try {
    await prisma.event.update({
      where: { id: transaction.eventId },
      data: {
        updatedAt: new Date(),
      },
    });
  } catch (_) {
    // Ignore DB event update failures here; payment persistence remains primary.
  }
}

async function applyTransactionStatusUpdateByIndex(index, targetStatus) {
  const current = paymentTransactions[index];
  if (!canTransitionPaymentStatus(current.status, targetStatus)) {
    return {
      ok: false,
      code: 'invalid_transition',
      httpStatus: 409,
      error: `Statuswechsel ${current.status} -> ${targetStatus} nicht erlaubt`,
    };
  }

  const nowIso = new Date().toISOString();
  const updated = {
    ...current,
    status: targetStatus,
    updatedAt: nowIso,
    completedAt: targetStatus === 'completed' ? (current.completedAt || nowIso) : current.completedAt,
    failedAt: targetStatus === 'failed' ? nowIso : current.failedAt,
    refundedAt: targetStatus === 'refunded' ? nowIso : current.refundedAt,
  };

  paymentTransactions[index] = updated;
  await updateEventPaymentDateIfCompleted(updated);
  return { ok: true, item: updated };
}

async function applyTransactionStatusUpdateByRecord(record, targetStatus) {
  const currentStatus = normalizeStoredPaymentStatus(record.status);
  if (!canTransitionPaymentStatus(currentStatus, targetStatus)) {
    return {
      ok: false,
      code: 'invalid_transition',
      httpStatus: 409,
      error: `Statuswechsel ${currentStatus} -> ${targetStatus} nicht erlaubt`,
    };
  }

  const audit = getPaymentAuditDetails(record);
  const nowIso = new Date().toISOString();
  const nextAudit = {
    ...audit,
    completedAt: targetStatus === 'completed' ? (audit.completedAt || nowIso) : audit.completedAt || null,
    failedAt: targetStatus === 'failed' ? nowIso : audit.failedAt || null,
    refundedAt: targetStatus === 'refunded' ? nowIso : audit.refundedAt || null,
  };

  const updated = await prisma.paymentTransaction.update({
    where: { id: record.id },
    data: {
      status: targetStatus,
      refundedAt: targetStatus === 'refunded' ? new Date(nowIso) : record.refundedAt,
      auditDetails: nextAudit,
    },
  });

  const mapped = mapPaymentRecordToApiItem(updated);
  await updateEventPaymentDateIfCompleted(mapped);
  return { ok: true, item: mapped };
}

async function applyProviderTransactionStatusUpdate({
  provider,
  providerTransactionRef,
  targetStatus,
  verified,
  transactionId,
}) {
  if (!provider || !providerTransactionRef) {
    return {
      ok: false,
      code: 'invalid_payload',
      httpStatus: 400,
      error: 'provider und providerTransactionRef sind erforderlich',
    };
  }

  if ((targetStatus === 'completed' || targetStatus === 'refunded') && !verified) {
    return {
      ok: false,
      code: 'verification_required',
      httpStatus: 409,
      error: `${targetStatus} nur mit verified=true erlaubt`,
    };
  }

  try {
    let record = null;

    if (transactionId) {
      record = await prisma.paymentTransaction.findUnique({ where: { id: transactionId } });
    }

    if (!record && provider === 'stripe' && providerTransactionRef) {
      record = await prisma.paymentTransaction.findFirst({
        where: { stripePaymentIntentId: providerTransactionRef },
      });
    }

    if (!record && providerTransactionRef) {
      record = await prisma.paymentTransaction.findFirst({
        where: { idempotencyKey: `${provider}:${providerTransactionRef}` },
      });
    }

    if (!record) {
      return {
        ok: false,
        code: 'not_found',
        httpStatus: 404,
        error: 'Transaktion nicht gefunden',
      };
    }

    const statusUpdate = await applyTransactionStatusUpdateByRecord(record, targetStatus);
    if (!statusUpdate.ok) {
      return statusUpdate;
    }

    const currentRecord = await prisma.paymentTransaction.findUnique({ where: { id: record.id } });
    const currentAudit = getPaymentAuditDetails(currentRecord);
    const nowIso = new Date().toISOString();
    const enhanced = await prisma.paymentTransaction.update({
      where: { id: record.id },
      data: {
        verifiedAt: verified ? new Date(nowIso) : currentRecord.verifiedAt,
        verifiedByType: verified ? 'webhook' : currentRecord.verifiedByType,
        auditDetails: {
          ...currentAudit,
          providerVerified: currentAudit.providerVerified === true || verified,
          providerEventStatus: targetStatus,
          providerEventReceivedAt: nowIso,
          providerTransactionRef: currentAudit.providerTransactionRef || providerTransactionRef,
          paymentMethod: currentAudit.paymentMethod || provider,
        },
      },
    });

    return { ok: true, item: mapPaymentRecordToApiItem(enhanced) };
  } catch (error) {
    console.error('Prisma payment provider update fallback:', error?.message || error);
  }

  const index = paymentTransactions.findIndex(item => {
    if (transactionId && item.id === transactionId) {
      return true;
    }
    return (
      item.paymentMethod === provider &&
      (item.providerTransactionRef || '') === providerTransactionRef
    );
  });

  if (index === -1) {
    return {
      ok: false,
      code: 'not_found',
      httpStatus: 404,
      error: 'Transaktion nicht gefunden',
    };
  }

  const statusUpdate = await applyTransactionStatusUpdateByIndex(index, targetStatus);
  if (!statusUpdate.ok) {
    return statusUpdate;
  }

  const nowIso = new Date().toISOString();
  const enhanced = {
    ...statusUpdate.item,
    providerVerified: paymentTransactions[index].providerVerified || verified,
    providerEventStatus: targetStatus,
    providerEventReceivedAt: nowIso,
  };
  paymentTransactions[index] = enhanced;

  return { ok: true, item: enhanced };
}

function ensureEntitlement(userId, options = {}) {
  const existing = userEntitlements.get(userId);
  const nowIso = new Date().toISOString();
  const registeredAtHint = asIsoDate(options.registeredAt);
  const isPremiumHint = options.isPremium === true;

  if (!existing) {
    const created = {
      userId,
      registeredAt: registeredAtHint || nowIso,
      isPremium: isPremiumHint,
      updatedAt: nowIso,
    };
    userEntitlements.set(userId, created);
    return created;
  }

  if (registeredAtHint) {
    existing.registeredAt = existing.registeredAt && existing.registeredAt < registeredAtHint
      ? existing.registeredAt
      : registeredAtHint;
  }

  if (isPremiumHint) {
    existing.isPremium = true;
  }

  existing.updatedAt = nowIso;
  userEntitlements.set(userId, existing);
  return existing;
}

function buildEntitlementStatus(record) {
  const trialDays = 14;
  const now = new Date();
  const registeredAt = new Date(record.registeredAt);
  const trialEndsAt = new Date(registeredAt.getTime() + trialDays * 24 * 60 * 60 * 1000);
  const trialMillisRemaining = trialEndsAt.getTime() - now.getTime();
  const trialDaysRemaining = Math.max(0, Math.ceil(trialMillisRemaining / (24 * 60 * 60 * 1000)));
  const trialActive = trialMillisRemaining > 0;
  const hasFullAccess = Boolean(record.isPremium) || trialActive;

  return {
    userId: record.userId,
    isPremium: Boolean(record.isPremium),
    trialActive,
    trialDaysRemaining,
    trialEndsAt: trialEndsAt.toISOString(),
    hasFullAccess,
    source: 'server',
    updatedAt: new Date().toISOString(),
  };
}

function removeMatching(list, predicate) {
  if (!Array.isArray(list) || list.length === 0) return 0;
  const originalLength = list.length;
  for (let i = list.length - 1; i >= 0; i -= 1) {
    if (predicate(list[i])) {
      list.splice(i, 1);
    }
  }
  return originalLength - list.length;
}

function deleteAccountDataByUserId(userId) {
  let removed = 0;

  if (userEntitlements.delete(userId)) {
    removed += 1;
  }

  removed += removeMatching(familyContacts, item => item.userId === userId);
  removed += removeMatching(
    familyRequests,
    item => item.fromUserId === userId || item.toUserId === userId,
  );

  const removedEventIds = [];
  removed += removeMatching(events, item => {
    const shouldRemove = item.hosterId === userId;
    if (shouldRemove && item.id) {
      removedEventIds.push(item.id);
      delete eventInviteCodes[item.id];
      delete eventInviteExpiresAt[item.id];
      delete eventChatMessages[item.id];
    }
    return shouldRemove;
  });

  removed += removeMatching(
    eventInvitations,
    item =>
      item.invitedUserId === userId ||
      item.hostUserId === userId ||
      removedEventIds.includes(item.eventId),
  );

  removed += removeMatching(
    eventParticipations,
    item => item.userId === userId || removedEventIds.includes(item.eventId),
  );

  removed += removeMatching(
    paymentTransactions,
    item => item.userId === userId || item.hostUserId === userId,
  );

  removed += removeMatching(eventChatReports, item => item.userId === userId);

  for (const [eventId, messages] of Object.entries(eventChatMessages)) {
    if (!Array.isArray(messages)) continue;
    const before = messages.length;
    for (let i = messages.length - 1; i >= 0; i -= 1) {
      if (messages[i]?.userId === userId) {
        messages.splice(i, 1);
      }
    }
    removed += before - messages.length;
    if (messages.length === 0) {
      delete eventChatMessages[eventId];
    }
  }

  removed += removeMatching(parentMatchingActions, item => item.userId === userId);

  return removed;
}

// Routes

app.post('/account/delete-data', (req, res) => {
  const userId = (req.body.userId || '').toString().trim();
  if (!userId) {
    return res.status(400).json({ error: 'userId ist erforderlich' });
  }

  const removedEntries = deleteAccountDataByUserId(userId);
  return res.json({ ok: true, userId, removedEntries });
});

app.get('/entitlements/:userId/status', (req, res) => {
  const userId = (req.params.userId || '').toString().trim();
  if (!userId) {
    return res.status(400).json({ error: 'userId ist erforderlich' });
  }

  const hintPremium = `${req.query.isPremium || ''}`.toLowerCase() === 'true';
  const record = ensureEntitlement(userId, {
    registeredAt: req.query.registeredAt,
    isPremium: hintPremium,
  });
  const item = buildEntitlementStatus(record);
  return res.json({ item });
});

app.post('/entitlements/:userId/activate-premium', (req, res) => {
  const userId = (req.params.userId || '').toString().trim();
  if (!userId) {
    return res.status(400).json({ error: 'userId ist erforderlich' });
  }

  const record = ensureEntitlement(userId, {
    registeredAt: req.body.registeredAt,
    isPremium: true,
  });
  record.isPremium = true;
  record.updatedAt = new Date().toISOString();
  userEntitlements.set(userId, record);

  return res.status(201).json({ item: buildEntitlementStatus(record) });
});

// 0. Weekly Impulse abrufen
app.get('/api/weekly-impulse', (req, res) => {
  const schema = getWeeklyImpulseSchema();

  if (!schema) {
    return res.status(500).json({ error: 'Weekly Impulse Schema fehlt' });
  }

  const today = new Date().toISOString().slice(0, 10);

  const impulse = {
    id: `imp_${schema.id}_gfk_w1`,
    title: 'Warum-Fragen gelassen begleiten',
    content_body:
      `${schema.parent_lens}\n\n` +
      `Fokus diese Woche: ${schema.pedagogical_focus}.\n\n` +
      `Drei alltagsnahe Impulse:\n` +
      `- ${schema.parent_tips[0]}\n` +
      `- ${schema.parent_tips[1]}\n` +
      `- ${schema.parent_tips[2]}\n\n` +
      `${schema.reassurance}`,
    practical_tip:
      'Heute bei der naechsten Warum-Frage: erst Gefuehl spiegeln, dann in einem Satz antworten und die Grenze freundlich benennen.',
    audio_script:
      `Hallo und schoen, dass du da bist. ${schema.parent_lens} ` +
      'Bleib bei kurzen Antworten, klaren Grenzen und liebevoller Praesenz. ' +
      'Du gibst deinem Kind damit Sicherheit und Orientierung. Du machst das gut.',
    category: 'gfk',
    publish_date: today,
  };

  res.json(impulse);
});

// 1. Alle Anbieter abrufen
app.get('/api/providers', (req, res) => {
  const providers = getProviders();
  res.json(providers);
});

// 2. Anbieter nach Kategorie filtern
app.get('/api/providers/category/:category', (req, res) => {
  const { category } = req.params;
  const providers = getProviders();
  const filtered = providers.filter(p => p.category === category || p.subcategory === category);
  res.json(filtered);
});

// 3. Anbieter nach ID abrufen
app.get('/api/providers/:id', (req, res) => {
  const { id } = req.params;
  const providers = getProviders();
  const provider = providers.find(p => p.id === id);
  
  if (!provider) {
    return res.status(404).json({ error: 'Anbieter nicht gefunden' });
  }
  
  res.json(provider);
});

// 4. Suche nach Name
app.get('/api/search', (req, res) => {
  const { q } = req.query;
  
  if (!q) {
    return res.status(400).json({ error: 'Suchtext erforderlich' });
  }
  
  const providers = getProviders();
  const filtered = providers.filter(p => 
    p.name.toLowerCase().includes(q.toLowerCase()) ||
    p.category.toLowerCase().includes(q.toLowerCase()) ||
    p.description.toLowerCase().includes(q.toLowerCase())
  );
  
  res.json(filtered);
});

// 5. Alle Kategorien abrufen
app.get('/api/categories', (req, res) => {
  const providers = getProviders();
  const categories = [...new Set(providers.map(p => p.category))];
  res.json(categories);
});

// 6. Neue Bewertung hinzufügen (Mock - speichert nicht wirklich)
app.post('/api/providers/:id/review', (req, res) => {
  const { id } = req.params;
  const { rating, comment, parentName } = req.body;
  
  if (!rating || rating < 1 || rating > 5) {
    return res.status(400).json({ error: 'Bewertung muss zwischen 1 und 5 liegen' });
  }
  
  const providers = getProviders();
  const provider = providers.find(p => p.id === id);
  
  if (!provider) {
    return res.status(404).json({ error: 'Anbieter nicht gefunden' });
  }
  
  // Mock: Aktualisiere Rating
  provider.reviews += 1;
  provider.rating = ((provider.rating * (provider.reviews - 1)) + rating) / provider.reviews;
  
  saveProviders(providers);
  
  res.json({
    message: 'Bewertung hinzugefügt',
    provider: provider
  });
});

// 7. Filter nach Kriterien
app.post('/api/providers/filter', (req, res) => {
  const { categories, maxPrice, minRating } = req.body;
  
  let providers = getProviders();
  
  if (categories && categories.length > 0) {
    providers = providers.filter(p => categories.includes(p.category));
  }
  
  if (maxPrice) {
    providers = providers.filter(p => p.price <= maxPrice);
  }
  
  if (minRating) {
    providers = providers.filter(p => p.rating >= minRating);
  }
  
  res.json(providers);
});

// 8. Todos (Prisma-first with in-memory fallback)
app.get('/todos', async (req, res) => {
  try {
    const familyId = (req.query.familyId || '').toString().trim();
    const items = await prisma.todo.findMany({
      where: familyId ? { familyId } : undefined,
      orderBy: { createdAt: 'desc' },
    });
    return res.json({ items: items.map(mapTodoRecordToApiItem) });
  } catch (error) {
    console.error('GET /todos fallback (in-memory):', error?.message || error);
    return res.json({ items: todos });
  }
});

app.post('/todos', async (req, res) => {
  try {
    const familyId = await ensureDemoFamilyContext(req.body.familyId || DEMO_FAMILY_ID);
    const completed = Boolean(req.body.completed);
    const item = await prisma.todo.create({
      data: {
        familyId,
        title: (req.body.title || '').toString(),
        description: buildTodoDescription({
          assigneeName: req.body.assigneeName || 'Familie',
          category: req.body.category || 'Allgemein',
        }),
        done: completed,
        completedAt: completed ? new Date() : null,
      },
    });
    return res.status(201).json({ item: mapTodoRecordToApiItem(item) });
  } catch (error) {
    console.error('POST /todos fallback (in-memory):', error?.message || error);
    const item = {
      id: generateId('todo'),
      familyId: req.body.familyId || DEMO_FAMILY_ID,
      title: req.body.title || '',
      completed: Boolean(req.body.completed),
      assigneeName: req.body.assigneeName || 'Familie',
      category: req.body.category || 'Allgemein',
      createdAt: new Date().toISOString(),
    };
    todos.unshift(item);
    return res.status(201).json({ item });
  }
});

app.put('/todos/:id', async (req, res) => {
  try {
    const existing = await prisma.todo.findUnique({ where: { id: req.params.id } });
    if (!existing) {
      return res.status(404).json({ error: 'Todo nicht gefunden' });
    }

    const currentMeta = parseTodoDescription(existing.description);
    const completed = Boolean(req.body.completed);
    const item = await prisma.todo.update({
      where: { id: req.params.id },
      data: {
        done: completed,
        completedAt: completed ? (existing.completedAt || new Date()) : null,
        description: buildTodoDescription({
          assigneeName: req.body.assigneeName || currentMeta.assigneeName,
          category: req.body.category || currentMeta.category,
        }),
      },
    });
    return res.json({ item: mapTodoRecordToApiItem(item) });
  } catch (error) {
    console.error('PUT /todos fallback (in-memory):', error?.message || error);
    const index = todos.findIndex(item => item.id === req.params.id);
    if (index === -1) {
      return res.status(404).json({ error: 'Todo nicht gefunden' });
    }
    todos[index] = {
      ...todos[index],
      completed: Boolean(req.body.completed),
      updatedAt: new Date().toISOString(),
    };
    return res.json({ item: todos[index] });
  }
});

app.delete('/todos/:id', async (req, res) => {
  try {
    await prisma.todo.delete({ where: { id: req.params.id } });
    return res.status(204).send();
  } catch (error) {
    if (error?.code === 'P2025') {
      return res.status(404).json({ error: 'Todo nicht gefunden' });
    }

    console.error('DELETE /todos fallback (in-memory):', error?.message || error);
    const index = todos.findIndex(item => item.id === req.params.id);
    if (index === -1) {
      return res.status(404).json({ error: 'Todo nicht gefunden' });
    }
    todos.splice(index, 1);
    return res.status(204).send();
  }
});

// 9. Shopping (Prisma-first with in-memory fallback)
app.get('/shopping', async (req, res) => {
  try {
    const familyId = (req.query.familyId || '').toString().trim();
    const items = await prisma.shoppingItem.findMany({
      where: familyId ? { familyId } : undefined,
      orderBy: { createdAt: 'desc' },
    });
    return res.json({ items: items.map(mapShoppingRecordToApiItem) });
  } catch (error) {
    console.error('GET /shopping fallback (in-memory):', error?.message || error);
    return res.json({ items: shoppingItems });
  }
});

app.post('/shopping', async (req, res) => {
  try {
    const familyId = await ensureDemoFamilyContext(req.body.familyId || DEMO_FAMILY_ID);
    const checked = Boolean(req.body.checked);
    const item = await prisma.shoppingItem.create({
      data: {
        familyId,
        name: (req.body.name || '').toString(),
        quantity: 1,
        bought: checked,
        boughtAt: checked ? new Date() : null,
      },
    });
    return res.status(201).json({ item: mapShoppingRecordToApiItem(item) });
  } catch (error) {
    console.error('POST /shopping fallback (in-memory):', error?.message || error);
    const item = {
      id: generateId('shop'),
      familyId: req.body.familyId || DEMO_FAMILY_ID,
      name: req.body.name || '',
      checked: Boolean(req.body.checked),
      category: req.body.category || 'Allgemein',
      createdAt: new Date().toISOString(),
    };
    shoppingItems.unshift(item);
    return res.status(201).json({ item });
  }
});

app.put('/shopping/:id', async (req, res) => {
  try {
    const checked = Boolean(req.body.checked);
    const item = await prisma.shoppingItem.update({
      where: { id: req.params.id },
      data: {
        bought: checked,
        boughtAt: checked ? new Date() : null,
      },
    });
    return res.json({ item: mapShoppingRecordToApiItem(item) });
  } catch (error) {
    if (error?.code === 'P2025') {
      return res.status(404).json({ error: 'Shopping-Item nicht gefunden' });
    }

    console.error('PUT /shopping fallback (in-memory):', error?.message || error);
    const index = shoppingItems.findIndex(item => item.id === req.params.id);
    if (index === -1) {
      return res.status(404).json({ error: 'Shopping-Item nicht gefunden' });
    }

    shoppingItems[index] = {
      ...shoppingItems[index],
      checked: Boolean(req.body.checked),
      updatedAt: new Date().toISOString(),
    };
    return res.json({ item: shoppingItems[index] });
  }
});

app.delete('/shopping/:id', async (req, res) => {
  try {
    await prisma.shoppingItem.delete({ where: { id: req.params.id } });
    return res.status(204).send();
  } catch (error) {
    if (error?.code === 'P2025') {
      return res.status(404).json({ error: 'Shopping-Item nicht gefunden' });
    }

    console.error('DELETE /shopping fallback (in-memory):', error?.message || error);
    const index = shoppingItems.findIndex(item => item.id === req.params.id);
    if (index === -1) {
      return res.status(404).json({ error: 'Shopping-Item nicht gefunden' });
    }
    shoppingItems.splice(index, 1);
    return res.status(204).send();
  }
});

// 10. Calendar events
app.get('/calendar/events', (req, res) => {
  res.json({ items: calendarEvents });
});

app.post('/calendar/events', (req, res) => {
  const event = {
    id: generateId('cal'),
    familyId: req.body.familyId || 'demo-family-001',
    title: req.body.title || 'Neuer Termin',
    startsAt: req.body.startsAt || new Date().toISOString(),
    location: req.body.location || '',
    createdAt: new Date().toISOString(),
  };
  calendarEvents.unshift(event);
  res.status(201).json({ item: event });
});

// 11. Photos
app.get('/photos', (req, res) => {
  res.json({ items: photoAlbums });
});

app.post('/photos', (req, res) => {
  const album = {
    id: generateId('album'),
    familyId: req.body.familyId || 'demo-family-001',
    title: req.body.title || 'Neues Album',
    photoCount: Number(req.body.photoCount || 0),
    createdAt: req.body.createdAt || new Date().toISOString(),
  };
  photoAlbums.unshift(album);
  res.status(201).json({ item: album });
});

// 12. Parent matching
app.get('/parent-matching/profiles', (req, res) => {
  res.json({ profiles: parentProfiles });
});

app.post('/parent-matching/actions', (req, res) => {
  const action = {
    id: generateId('match-action'),
    familyId: req.body.familyId || 'demo-family-001',
    profileId: req.body.profileId || '',
    action: req.body.action || 'unknown',
    createdAt: req.body.createdAt || new Date().toISOString(),
  };
  parentMatchingActions.unshift(action);
  res.status(201).json({ item: action });
});

// 13. Family circle
app.get('/family/contacts', (req, res) => {
  const userId = req.query.userId;
  if (!userId) {
    return res.json({ contacts: familyContacts });
  }

  const filtered = familyContacts.filter(c => c.userId !== userId);
  res.json({ contacts: filtered });
});

app.get('/family/requests', (req, res) => {
  const userId = req.query.userId;
  const requests = userId
    ? familyRequests.filter(r => r.toUserId === userId)
    : familyRequests;
  res.json({ requests });
});

app.put('/family/requests/:id', (req, res) => {
  const index = familyRequests.findIndex(item => item.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ error: 'Anfrage nicht gefunden' });
  }

  const status = req.body.status;
  if (!['pending', 'accepted', 'declined'].includes(status)) {
    return res.status(400).json({ error: 'Ungültiger Status' });
  }

  familyRequests[index] = {
    ...familyRequests[index],
    status,
    updatedAt: new Date().toISOString(),
  };
  res.json({ item: familyRequests[index] });
});

// 14. Events
app.get('/events', (req, res) => {
  let items = [...events];
  if (req.query.status) {
    items = items.filter(event => event.status === req.query.status);
  }
  if (req.query.hostUserId) {
    items = items.filter(event => event.hosterId === req.query.hostUserId);
  }
  res.json({ items });
});

app.get('/events/discover', (req, res) => {
  const viewerUserId = (req.query.viewerUserId || 'guest_user').toString();
  let items = events.filter(event => canViewerSeeEvent(event, viewerUserId));

  if (req.query.ageGroups) {
    const requested = req.query.ageGroups
      .toString()
      .split(',')
      .map(value => value.trim())
      .filter(Boolean);
    if (requested.length > 0) {
      items = items.filter(event =>
        (event.ageGroups || []).some(group => requested.includes(group)),
      );
    }
  }

  res.json({ items });
});

app.get('/events/item/:id', (req, res) => {
  const item = events.find(event => event.id === req.params.id);
  if (!item) {
    return res.status(404).json({ error: 'Event nicht gefunden' });
  }
  const inviteCode = eventInviteCodes[item.id] || null;
  const inviteCodeExpiresAt = eventInviteExpiresAt[item.id] || item.inviteCodeExpiresAt || null;
  res.json({ item: { ...item, inviteCode, inviteCodeExpiresAt } });
});

app.post('/events', (req, res) => {
  const body = req.body || {};
  const item = {
    id: body.id || generateId('event'),
    hosterId: body.hosterId || 'host_demo_001',
    title: body.title || 'Neues Event',
    description: body.description || '',
    category: body.category || 'other',
    ageGroups: Array.isArray(body.ageGroups) ? body.ageGroups : [],
    location: body.location || '',
    latitude: Number(body.latitude || 0),
    longitude: Number(body.longitude || 0),
    eventDate: body.eventDate || new Date().toISOString(),
    createdAt: body.createdAt || new Date().toISOString(),
    paymentDate: body.paymentDate || null,
    maxParticipants: Number(body.maxParticipants || 20),
    currentParticipants: Number(body.currentParticipants || 0),
    photoUrl: body.photoUrl || '',
    status: body.status || 'active',
    price: body.price ?? null,
    visibility: body.visibility || 'publicNearby',
    shareRadiusKm: Number(body.shareRadiusKm || 25),
    invitedUserIds: Array.isArray(body.invitedUserIds) ? body.invitedUserIds : [],
    inviteCodeExpiresAt: body.inviteCodeExpiresAt || null,
  };

  events.push(item);

  if (item.visibility === 'inviteOnly') {
    const code = generateInviteCode(item.id);
    eventInviteCodes[item.id] = code;
    eventInviteExpiresAt[item.id] =
      item.inviteCodeExpiresAt || new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString();

    for (const invitedUserId of item.invitedUserIds) {
      eventInvitations.push({
        id: `inv_${item.id}_${invitedUserId}`,
        eventId: item.id,
        hostUserId: item.hosterId,
        invitedUserId,
        createdAt: new Date().toISOString(),
        status: 'pending',
      });
    }
  }

  res.status(201).json({
    item: {
      ...item,
      inviteCode: eventInviteCodes[item.id] || null,
      inviteCodeExpiresAt: eventInviteExpiresAt[item.id] || item.inviteCodeExpiresAt,
    },
  });
});

app.delete('/events/item/:id', (req, res) => {
  const index = events.findIndex(event => event.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ error: 'Event nicht gefunden' });
  }

  const [removed] = events.splice(index, 1);
  delete eventInviteCodes[removed.id];
  delete eventInviteExpiresAt[removed.id];

  for (let i = eventInvitations.length - 1; i >= 0; i -= 1) {
    if (eventInvitations[i].eventId === removed.id) {
      eventInvitations.splice(i, 1);
    }
  }

  res.status(204).send();
});

// 15. Event invitations
app.get('/events/invitations', (req, res) => {
  let items = [...eventInvitations];
  if (req.query.userId) {
    items = items.filter(invitation => invitation.invitedUserId === req.query.userId);
  }
  if (req.query.eventId) {
    items = items.filter(invitation => invitation.eventId === req.query.eventId);
  }
  if (req.query.status) {
    items = items.filter(invitation => invitation.status === req.query.status);
  }
  res.json({ items });
});

app.put('/events/invitations/:id/respond', (req, res) => {
  const index = eventInvitations.findIndex(item => item.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ error: 'Einladung nicht gefunden' });
  }

  const accept = Boolean(req.body.accept);
  const nextStatus = accept ? 'accepted' : 'declined';
  eventInvitations[index] = {
    ...eventInvitations[index],
    status: nextStatus,
    updatedAt: new Date().toISOString(),
  };

  res.json({ item: eventInvitations[index] });
});

app.post('/events/invitations/join', (req, res) => {
  const codeInput = (req.body.code || '').toString().trim().toUpperCase();
  const userId = (req.body.userId || '').toString().trim();

  if (!codeInput || !userId) {
    return res.status(400).json({ error: 'Code und UserId sind erforderlich' });
  }

  const eventId = Object.keys(eventInviteCodes).find(
    id => (eventInviteCodes[id] || '').toUpperCase() === codeInput,
  );

  if (!eventId || isInviteExpired(eventId)) {
    return res.status(404).json({ error: 'Code ungültig oder abgelaufen' });
  }

  const event = events.find(item => item.id === eventId);
  if (!event) {
    return res.status(404).json({ error: 'Event nicht gefunden' });
  }

  let invitation = eventInvitations.find(
    item => item.eventId === eventId && item.invitedUserId === userId,
  );

  if (!invitation) {
    invitation = {
      id: `inv_${eventId}_${userId}`,
      eventId,
      hostUserId: event.hosterId,
      invitedUserId: userId,
      createdAt: new Date().toISOString(),
      status: 'accepted',
    };
    eventInvitations.push(invitation);
  } else {
    invitation.status = 'accepted';
    invitation.updatedAt = new Date().toISOString();
  }

  res.status(201).json({ item: invitation });
});

app.get('/events/hosted-invite-only', (req, res) => {
  const hostUserId = (req.query.hostUserId || '').toString();
  const items = events.filter(
    event =>
      event.visibility === 'inviteOnly' &&
      event.status === 'active' &&
      (!hostUserId || event.hosterId === hostUserId),
  );
  res.json({ items });
});

app.get('/events/:id/invitations/accepted', (req, res) => {
  const items = eventInvitations.filter(
    item => item.eventId === req.params.id && item.status === 'accepted',
  );
  res.json({ items });
});

// 16. Event participations (host dashboard)
app.get('/events/participations', (req, res) => {
  let items = [...eventParticipations];
  if (req.query.userId) {
    items = items.filter(item => item.userId === req.query.userId);
  }
  if (req.query.eventId) {
    items = items.filter(item => item.eventId === req.query.eventId);
  }
  res.json({ items });
});

app.get('/events/participations/pending', (req, res) => {
  const hostUserId = (req.query.hostUserId || '').toString();
  const hostEventIds = events
    .filter(event => !hostUserId || event.hosterId === hostUserId)
    .map(event => event.id);

  const items = eventParticipations.filter(
    item => hostEventIds.includes(item.eventId) && item.status === 'pending',
  );

  res.json({ items });
});

app.post('/events/participations', (req, res) => {
  const eventId = (req.body.eventId || '').toString();
  const userId = (req.body.userId || '').toString();

  if (!eventId || !userId) {
    return res.status(400).json({ error: 'eventId und userId sind erforderlich' });
  }

  const event = events.find(item => item.id === eventId);
  if (!event) {
    return res.status(404).json({ error: 'Event nicht gefunden' });
  }

  const existing = eventParticipations.find(
    item => item.eventId === eventId && item.userId === userId && item.status !== 'cancelled',
  );
  if (existing) {
    return res.status(200).json({ item: existing });
  }

  const item = {
    id: generateId('participation'),
    eventId,
    userId,
    requestedAt: new Date().toISOString(),
    approvedAt: null,
    declinedAt: null,
    cancelledAt: null,
    status: 'pending',
  };

  eventParticipations.unshift(item);
  res.status(201).json({ item });
});

app.put('/events/participations/:id/respond', (req, res) => {
  const index = eventParticipations.findIndex(item => item.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ error: 'Teilnahme nicht gefunden' });
  }

  const accept = Boolean(req.body.accept);
  const current = eventParticipations[index];
  const eventIndex = events.findIndex(event => event.id === current.eventId);

  const nextItem = {
    ...current,
    status: accept ? 'approved' : 'declined',
    approvedAt: accept ? new Date().toISOString() : null,
    declinedAt: accept ? null : new Date().toISOString(),
  };

  eventParticipations[index] = nextItem;

  if (accept && eventIndex !== -1) {
    events[eventIndex] = {
      ...events[eventIndex],
      currentParticipants: Number(events[eventIndex].currentParticipants || 0) + 1,
    };
  }

  res.json({ item: nextItem });
});

app.get('/events/:id/participations/approved', (req, res) => {
  const items = eventParticipations.filter(
    item => item.eventId === req.params.id && item.status === 'approved',
  );
  res.json({ items });
});

// 17. Event chat
app.get('/events/:id/chat/messages', (req, res) => {
  const items = eventChatMessages[req.params.id] || [];
  res.json({ items });
});

app.post('/events/:id/chat/messages', (req, res) => {
  const eventId = req.params.id;
  const event = events.find(item => item.id === eventId);
  if (!event) {
    return res.status(404).json({ error: 'Event nicht gefunden' });
  }

  const item = {
    id: generateId('msg'),
    eventId,
    userId: req.body.userId || '',
    userName: req.body.userName || 'Unbekannt',
    userAvatarUrl: req.body.userAvatarUrl || '',
    content: req.body.content || '',
    timestamp: new Date().toISOString(),
    isHost: Boolean(req.body.isHost),
  };

  if (!eventChatMessages[eventId]) {
    eventChatMessages[eventId] = [];
  }
  eventChatMessages[eventId].push(item);
  res.status(201).json({ item });
});

app.delete('/events/:eventId/chat/messages/:messageId', (req, res) => {
  const items = eventChatMessages[req.params.eventId] || [];
  const before = items.length;
  eventChatMessages[req.params.eventId] = items.filter(
    item => item.id !== req.params.messageId,
  );
  if (before === eventChatMessages[req.params.eventId].length) {
    return res.status(404).json({ error: 'Nachricht nicht gefunden' });
  }
  res.status(204).send();
});

app.post('/events/:id/chat/reports', (req, res) => {
  const item = {
    id: generateId('report'),
    eventId: req.params.id,
    reportedMessageId: req.body.reportedMessageId || '',
    reporterId: req.body.reporterId || '',
    reason: req.body.reason || 'other',
    description: req.body.description || null,
    reportedAt: new Date().toISOString(),
  };
  eventChatReports.unshift(item);
  res.status(201).json({ item });
});

app.get('/events/:id/chat/reports', (req, res) => {
  const items = eventChatReports.filter(item => item.eventId === req.params.id);
  res.json({ items });
});

app.get('/events/:id/chat/access', (req, res) => {
  const event = events.find(item => item.id === req.params.id);
  if (!event) {
    return res.status(404).json({ error: 'Event nicht gefunden' });
  }

  const userId = (req.query.userId || '').toString();
  const hosterId = (req.query.hosterId || event.hosterId || '').toString();

  const approvedParticipation = eventParticipations.some(
    item =>
      item.eventId === event.id &&
      item.userId === userId &&
      item.status === 'approved',
  );
  const acceptedInvite = eventInvitations.some(
    item =>
      item.eventId === event.id &&
      item.invitedUserId === userId &&
      item.status === 'accepted',
  );

  const hasAccess = userId === hosterId || approvedParticipation || acceptedInvite;
  res.json({ hasAccess });
});

// 18. Payments
app.post('/payments/stripe/initiate', (req, res) => {
  const body = req.body || {};
  const amount = parsePositiveNumber(body.amount);
  const eventId = (body.eventId || '').toString();
  const hosterId = (body.hosterId || '').toString();

  if (!eventId || !hosterId || amount == null) {
    return res.status(400).json({
      error: 'eventId, hosterId und amount > 0 sind erforderlich',
    });
  }

  res.status(201).json({
    item: {
      provider: 'stripe',
      mode: 'mock_backend',
      eventId,
      hosterId,
      amount,
      clientSecret: `pi_mock_${Date.now()}`,
      status: 'requires_payment_method',
    },
  });
});

app.post('/payments/paypal/initiate', (req, res) => {
  const body = req.body || {};
  const amount = parsePositiveNumber(body.amount);
  const eventId = (body.eventId || '').toString();
  const hosterId = (body.hosterId || '').toString();

  if (!eventId || !hosterId || amount == null) {
    return res.status(400).json({
      error: 'eventId, hosterId und amount > 0 sind erforderlich',
    });
  }

  res.status(201).json({
    item: {
      provider: 'paypal',
      mode: 'mock_backend',
      eventId,
      hosterId,
      amount,
      approvalUrl: `https://paypal.com/mock/approve/${Date.now()}`,
      token: `mock_token_${Date.now()}`,
      status: 'approval_pending',
    },
  });
});

app.post('/payments/confirm', async (req, res) => {
  const body = req.body || {};
  const amount = parsePositiveNumber(body.amount);
  const eventId = (body.eventId || '').toString();
  const hosterId = (body.hosterId || '').toString();
  const paymentMethod = (body.paymentMethod || 'stripe').toString();
  const allowedMethods = new Set(['stripe', 'paypal', 'apple_iap', 'google_play']);
  const normalizedStatus = normalizePaymentStatus(body.status || 'pending');
  const providerVerified = body.providerVerified === true;
  const providerTransactionRef = (body.providerTransactionRef || '').toString().trim();

  if (!eventId || !hosterId || amount == null) {
    return res.status(400).json({
      error: 'eventId, hosterId und amount > 0 sind erforderlich',
    });
  }

  if (!allowedMethods.has(paymentMethod)) {
    return res.status(400).json({ error: 'Unbekannte paymentMethod' });
  }

  if (normalizedStatus == null) {
    return res.status(400).json({ error: 'Ungueltiger payment status' });
  }

  if (normalizedStatus === 'completed' && !providerVerified) {
    return res.status(409).json({
      error: 'completed ist nur mit verifiziertem Provider-Event erlaubt',
    });
  }

  if ((paymentMethod === 'stripe' || paymentMethod === 'paypal') && !providerTransactionRef) {
    return res.status(400).json({
      error: 'providerTransactionRef ist fuer Stripe/PayPal erforderlich',
    });
  }

  const nowIso = new Date().toISOString();

  try {
    const context = await ensurePaymentContext(eventId, hosterId);
    const stripePaymentIntentId = paymentMethod === 'stripe'
      ? ((body.stripePaymentIntentId || providerTransactionRef || `pi_mock_${Date.now()}`).toString())
      : `alt_${paymentMethod}_${Date.now()}_${Math.floor(Math.random() * 1000)}`;

    const created = await prisma.paymentTransaction.create({
      data: {
        eventId: context.eventId,
        userId: context.hosterId,
        amount,
        currency: (body.currency || 'EUR').toString(),
        stripePaymentIntentId,
        idempotencyKey: (body.idempotencyKey || `${paymentMethod}:${providerTransactionRef || stripePaymentIntentId}`).toString(),
        status: normalizedStatus,
        verifiedAt: providerVerified ? new Date(nowIso) : null,
        verifiedByType: providerVerified ? 'api' : null,
        auditDetails: {
          mode: 'mock_backend',
          hosterId: context.hosterId,
          paymentMethod,
          providerTransactionRef: providerTransactionRef || null,
          providerVerified,
          completedAt: normalizedStatus === 'completed' ? nowIso : null,
          failedAt: normalizedStatus === 'failed' ? nowIso : null,
        },
      },
    });

    const item = mapPaymentRecordToApiItem(created);
    await updateEventPaymentDateIfCompleted(item);
    return res.status(201).json({ item });
  } catch (error) {
    console.error('POST /payments/confirm fallback (in-memory):', error?.message || error);
    const transaction = {
      id: generateId('txn'),
      mode: 'mock_backend',
      eventId,
      hosterId,
      amount,
      status: normalizedStatus,
      paymentMethod,
      providerTransactionRef: providerTransactionRef || null,
      providerVerified,
      stripePaymentIntentId: body.stripePaymentIntentId || null,
      createdAt: nowIso,
      completedAt: normalizedStatus === 'completed' ? nowIso : null,
    };

    paymentTransactions.unshift(transaction);
    await updateEventPaymentDateIfCompleted(transaction);
    return res.status(201).json({ item: transaction });
  }
});

app.post('/payments/provider-events', async (req, res) => {
  if (!allowClientProviderEvents) {
    return res.status(403).json({
      error: 'Client Provider-Events sind deaktiviert',
    });
  }

  const body = req.body || {};
  const targetStatus = normalizePaymentStatus(body.status);
  const provider = (body.provider || '').toString().trim().toLowerCase();
  const providerTransactionRef = (body.providerTransactionRef || '').toString().trim();
  const transactionId = (body.transactionId || '').toString().trim();
  const verified = body.verified === true;

  if (targetStatus == null) {
    return res.status(400).json({ error: 'Ungueltiger payment status' });
  }

  const result = await applyProviderTransactionStatusUpdate({
    provider,
    providerTransactionRef,
    targetStatus,
    verified,
    transactionId,
  });

  if (!result.ok) {
    return res.status(result.httpStatus).json({ error: result.error });
  }

  return res.json({ item: result.item });
});

app.get('/payments/transactions', async (req, res) => {
  try {
    const hosterId = (req.query.hosterId || '').toString().trim();
    const items = await prisma.paymentTransaction.findMany({
      where: hosterId
        ? {
            OR: [
              { userId: hosterId },
              { auditDetails: { path: ['hosterId'], equals: hosterId } },
            ],
          }
        : undefined,
      orderBy: { createdAt: 'desc' },
    });
    return res.json({ items: items.map(mapPaymentRecordToApiItem) });
  } catch (error) {
    console.error('GET /payments/transactions fallback (in-memory):', error?.message || error);
    let items = [...paymentTransactions];
    if (req.query.hosterId) {
      items = items.filter(item => item.hosterId === req.query.hosterId);
    }
    return res.json({ items });
  }
});

app.get('/payments/transactions/:id', async (req, res) => {
  try {
    const item = await prisma.paymentTransaction.findUnique({ where: { id: req.params.id } });
    if (!item) {
      return res.status(404).json({ error: 'Transaktion nicht gefunden' });
    }
    return res.json({ item: mapPaymentRecordToApiItem(item) });
  } catch (error) {
    console.error('GET /payments/transactions/:id fallback (in-memory):', error?.message || error);
    const item = paymentTransactions.find(transaction => transaction.id === req.params.id);
    if (!item) {
      return res.status(404).json({ error: 'Transaktion nicht gefunden' });
    }
    return res.json({ item });
  }
});

app.get('/payments/host/:hosterId', async (req, res) => {
  try {
    const hosterId = (req.params.hosterId || '').toString().trim();
    const items = await prisma.paymentTransaction.findMany({
      where: {
        OR: [
          { userId: hosterId },
          { auditDetails: { path: ['hosterId'], equals: hosterId } },
        ],
      },
      orderBy: { createdAt: 'desc' },
    });
    return res.json({ items: items.map(mapPaymentRecordToApiItem) });
  } catch (error) {
    console.error('GET /payments/host/:hosterId fallback (in-memory):', error?.message || error);
    const items = paymentTransactions.filter(
      transaction => transaction.hosterId === req.params.hosterId,
    );
    return res.json({ items });
  }
});

app.post('/payments/transactions/:id/refund', async (req, res) => {
  try {
    const current = await prisma.paymentTransaction.findUnique({ where: { id: req.params.id } });
    if (!current) {
      return res.status(404).json({ error: 'Transaktion nicht gefunden' });
    }

    const mapped = mapPaymentRecordToApiItem(current);
    if (mapped.status !== 'completed') {
      return res.status(409).json({
        error: 'Rueckerstattung nur fuer completed-Transaktionen erlaubt',
      });
    }

    const updated = await prisma.paymentTransaction.update({
      where: { id: req.params.id },
      data: {
        status: 'refunded',
        refundedAt: new Date(),
        auditDetails: {
          ...getPaymentAuditDetails(current),
          refundedAt: new Date().toISOString(),
        },
      },
    });
    return res.json({ item: mapPaymentRecordToApiItem(updated) });
  } catch (error) {
    console.error('POST /payments/transactions/:id/refund fallback (in-memory):', error?.message || error);
    const index = paymentTransactions.findIndex(item => item.id === req.params.id);
    if (index === -1) {
      return res.status(404).json({ error: 'Transaktion nicht gefunden' });
    }

    if (paymentTransactions[index].status !== 'completed') {
      return res.status(409).json({
        error: 'Rueckerstattung nur fuer completed-Transaktionen erlaubt',
      });
    }

    paymentTransactions[index] = {
      ...paymentTransactions[index],
      status: 'refunded',
      refundedAt: new Date().toISOString(),
    };

    return res.json({ item: paymentTransactions[index] });
  }
});

app.post('/payments/transactions/:id/status', async (req, res) => {
  const targetStatus = normalizePaymentStatus(req.body.status);
  if (targetStatus == null) {
    return res.status(400).json({ error: 'Ungueltiger Zielstatus' });
  }

  try {
    const current = await prisma.paymentTransaction.findUnique({ where: { id: req.params.id } });
    if (!current) {
      return res.status(404).json({ error: 'Transaktion nicht gefunden' });
    }

    const result = await applyTransactionStatusUpdateByRecord(current, targetStatus);
    if (!result.ok) {
      return res.status(result.httpStatus).json({ error: result.error });
    }

    return res.json({ item: result.item });
  } catch (error) {
    console.error('POST /payments/transactions/:id/status fallback (in-memory):', error?.message || error);
    const index = paymentTransactions.findIndex(item => item.id === req.params.id);
    if (index === -1) {
      return res.status(404).json({ error: 'Transaktion nicht gefunden' });
    }

    const current = paymentTransactions[index];
    if (!canTransitionPaymentStatus(current.status, targetStatus)) {
      return res.status(409).json({
        error: `Statuswechsel ${current.status} -> ${targetStatus} nicht erlaubt`,
      });
    }

    const nowIso = new Date().toISOString();
    const updated = {
      ...current,
      status: targetStatus,
      updatedAt: nowIso,
      completedAt: targetStatus === 'completed' ? (current.completedAt || nowIso) : current.completedAt,
      failedAt: targetStatus === 'failed' ? nowIso : current.failedAt,
      refundedAt: targetStatus === 'refunded' ? nowIso : current.refundedAt,
    };

    paymentTransactions[index] = updated;
    return res.json({ item: updated });
  }
});

// Health Check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', message: 'Parentpeak Backend läuft!' });
});

// Server starten
app.listen(PORT, '0.0.0.0', () => {
  if (allowedOrigins.length > 0) {
    console.log(`🌐 CORS allowlist aktiv (${allowedOrigins.length} Origin(s))`);
  } else {
    console.log('🌐 CORS allowlist nicht gesetzt, alle Origins erlaubt');
  }
  if (requireAuthForWrites) {
    console.log('🔐 Write-Auth aktiv (Bearer Token erforderlich)');
  } else {
    console.log('🔓 Write-Auth deaktiviert (REQUIRE_AUTH_FOR_WRITES=0)');
  }
  console.log(`✅ Parentpeak Backend läuft auf http://localhost:${PORT}`);
  console.log(`📍 API verfügbar unter http://localhost:${PORT}/api`);
});
