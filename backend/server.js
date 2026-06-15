const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = Number.parseInt(process.env.PORT || '3000', 10);
const backendApiToken = (process.env.BACKEND_API_TOKEN || '').trim();
const requireAuthForWrites =
  (process.env.REQUIRE_AUTH_FOR_WRITES ||
    (process.env.NODE_ENV === 'production' ? '1' : '0')) === '1';
const allowedOrigins = (process.env.CORS_ALLOWED_ORIGINS || '')
  .split(',')
  .map(origin => origin.trim())
  .filter(Boolean);

const writeRateWindowMs = Number.parseInt(
  process.env.WRITE_RATE_LIMIT_WINDOW_MS || `${15 * 60 * 1000}`,
  10,
);
const writeRateMax = Number.parseInt(
  process.env.WRITE_RATE_LIMIT_MAX || '120',
  10,
);
const writeRateBuckets = new Map();

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

// Routes

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

// 8. Todos
app.get('/todos', (req, res) => {
  res.json({ items: todos });
});

app.post('/todos', (req, res) => {
  const item = {
    id: generateId('todo'),
    familyId: req.body.familyId || 'demo-family-001',
    title: req.body.title || '',
    completed: Boolean(req.body.completed),
    assigneeName: req.body.assigneeName || 'Familie',
    category: req.body.category || 'Allgemein',
    createdAt: new Date().toISOString(),
  };
  todos.unshift(item);
  res.status(201).json({ item });
});

app.put('/todos/:id', (req, res) => {
  const index = todos.findIndex(item => item.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ error: 'Todo nicht gefunden' });
  }

  todos[index] = {
    ...todos[index],
    completed: Boolean(req.body.completed),
    updatedAt: new Date().toISOString(),
  };
  res.json({ item: todos[index] });
});

app.delete('/todos/:id', (req, res) => {
  const index = todos.findIndex(item => item.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ error: 'Todo nicht gefunden' });
  }
  todos.splice(index, 1);
  res.status(204).send();
});

// 9. Shopping
app.get('/shopping', (req, res) => {
  res.json({ items: shoppingItems });
});

app.post('/shopping', (req, res) => {
  const item = {
    id: generateId('shop'),
    familyId: req.body.familyId || 'demo-family-001',
    name: req.body.name || '',
    checked: Boolean(req.body.checked),
    category: req.body.category || 'Allgemein',
    createdAt: new Date().toISOString(),
  };
  shoppingItems.unshift(item);
  res.status(201).json({ item });
});

app.put('/shopping/:id', (req, res) => {
  const index = shoppingItems.findIndex(item => item.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ error: 'Shopping-Item nicht gefunden' });
  }

  shoppingItems[index] = {
    ...shoppingItems[index],
    checked: Boolean(req.body.checked),
    updatedAt: new Date().toISOString(),
  };
  res.json({ item: shoppingItems[index] });
});

app.delete('/shopping/:id', (req, res) => {
  const index = shoppingItems.findIndex(item => item.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ error: 'Shopping-Item nicht gefunden' });
  }
  shoppingItems.splice(index, 1);
  res.status(204).send();
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
  res.status(201).json({
    item: {
      provider: 'stripe',
      eventId: body.eventId || null,
      hosterId: body.hosterId || null,
      amount: Number(body.amount || 0),
      clientSecret: `pi_mock_${Date.now()}`,
      status: 'requires_payment_method',
    },
  });
});

app.post('/payments/paypal/initiate', (req, res) => {
  const body = req.body || {};
  res.status(201).json({
    item: {
      provider: 'paypal',
      eventId: body.eventId || null,
      hosterId: body.hosterId || null,
      amount: Number(body.amount || 0),
      approvalUrl: `https://paypal.com/mock/approve/${Date.now()}`,
      token: `mock_token_${Date.now()}`,
      status: 'approval_pending',
    },
  });
});

app.post('/payments/confirm', (req, res) => {
  const body = req.body || {};
  const transaction = {
    id: generateId('txn'),
    eventId: body.eventId || '',
    hosterId: body.hosterId || 'host_demo_001',
    amount: Number(body.amount || 0),
    status: body.status || 'completed',
    paymentMethod: body.paymentMethod || 'stripe',
    stripePaymentIntentId: body.stripePaymentIntentId || null,
    createdAt: new Date().toISOString(),
    completedAt: new Date().toISOString(),
  };

  paymentTransactions.unshift(transaction);

  const eventIndex = events.findIndex(event => event.id === transaction.eventId);
  if (eventIndex !== -1) {
    events[eventIndex] = {
      ...events[eventIndex],
      paymentDate: transaction.completedAt,
    };
  }

  res.status(201).json({ item: transaction });
});

app.get('/payments/transactions', (req, res) => {
  let items = [...paymentTransactions];
  if (req.query.hosterId) {
    items = items.filter(item => item.hosterId === req.query.hosterId);
  }
  res.json({ items });
});

app.get('/payments/transactions/:id', (req, res) => {
  const item = paymentTransactions.find(transaction => transaction.id === req.params.id);
  if (!item) {
    return res.status(404).json({ error: 'Transaktion nicht gefunden' });
  }
  res.json({ item });
});

app.get('/payments/host/:hosterId', (req, res) => {
  const items = paymentTransactions.filter(
    transaction => transaction.hosterId === req.params.hosterId,
  );
  res.json({ items });
});

app.post('/payments/transactions/:id/refund', (req, res) => {
  const index = paymentTransactions.findIndex(item => item.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ error: 'Transaktion nicht gefunden' });
  }

  paymentTransactions[index] = {
    ...paymentTransactions[index],
    status: 'refunded',
    refundedAt: new Date().toISOString(),
  };

  res.json({ item: paymentTransactions[index] });
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
