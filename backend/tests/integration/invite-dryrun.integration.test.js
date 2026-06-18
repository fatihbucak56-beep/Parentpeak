const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { spawn } = require('node:child_process');

const BACKEND_DIR = path.resolve(__dirname, '..', '..');
const SERVER_PATH = path.join(BACKEND_DIR, 'server.js');
const ENV_PATH = path.join(BACKEND_DIR, '.env');

function parseDotEnvFile(filePath) {
  if (!fs.existsSync(filePath)) return {};
  const raw = fs.readFileSync(filePath, 'utf8');
  const out = {};

  for (const line of raw.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;

    const eqIdx = trimmed.indexOf('=');
    if (eqIdx <= 0) continue;

    const key = trimmed.slice(0, eqIdx).trim();
    let value = trimmed.slice(eqIdx + 1).trim();

    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }

    out[key] = value;
  }

  return out;
}

async function waitForHealth(baseUrl, timeoutMs = 15000) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    try {
      const response = await fetch(`${baseUrl}/health`);
      if (response.ok) return;
    } catch (_) {
      // Keep polling until timeout.
    }
    await new Promise(resolve => setTimeout(resolve, 150));
  }
  throw new Error(`Server health check timed out for ${baseUrl}`);
}

function startServer(port, extraEnv = {}) {
  const envFromFile = parseDotEnvFile(ENV_PATH);
  const child = spawn(process.execPath, [SERVER_PATH], {
    cwd: BACKEND_DIR,
    env: {
      ...process.env,
      ...envFromFile,
      REQUIRE_AUTH_FOR_WRITES: '0',
      PORT: String(port),
      ...extraEnv,
    },
    stdio: ['ignore', 'pipe', 'pipe'],
  });

  let logs = '';
  const collect = chunk => {
    logs += chunk.toString();
    if (logs.length > 20000) {
      logs = logs.slice(-20000);
    }
  };

  child.stdout.on('data', collect);
  child.stderr.on('data', collect);

  return {
    child,
    getLogs: () => logs,
    baseUrl: `http://127.0.0.1:${port}`,
  };
}

async function stopServer(child, timeoutMs = 7000) {
  if (!child || child.killed) return;

  child.kill('SIGTERM');
  const exited = await new Promise(resolve => {
    const timer = setTimeout(() => resolve(false), timeoutMs);
    child.once('exit', () => {
      clearTimeout(timer);
      resolve(true);
    });
  });

  if (!exited) {
    child.kill('SIGKILL');
    await new Promise(resolve => child.once('exit', () => resolve()));
  }
}

async function postJson(baseUrl, route, body) {
  const response = await fetch(`${baseUrl}${route}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const payload = await response.json();
  return { response, payload };
}

async function getJson(baseUrl, route) {
  const response = await fetch(`${baseUrl}${route}`);
  const payload = await response.json();
  return { response, payload };
}

async function deletePath(baseUrl, route) {
  const response = await fetch(`${baseUrl}${route}`, {
    method: 'DELETE',
  });

  let payload = null;
  const contentType = response.headers.get('content-type') || '';
  if (contentType.includes('application/json')) {
    payload = await response.json();
  }

  return { response, payload };
}

test('invite code persists in DB across restart and delete-data dryRun is non-destructive', async () => {
  const suffix = `${Date.now()}-${Math.random().toString(16).slice(2, 8)}`;
  const inviteHostUser = `it_invite_host_${suffix}`;
  const inviteJoinUser = `it_invite_join_${suffix}`;
  const dryRunUser = `it_dryrun_${suffix}`;

  let serverA;
  let serverB;

  try {
    serverA = startServer(3025);
    await waitForHealth(serverA.baseUrl);

    const createInviteEvent = await postJson(serverA.baseUrl, '/events', {
      hosterId: inviteHostUser,
      title: `IT Invite Event ${suffix}`,
      visibility: 'inviteOnly',
      eventDate: '2026-07-02T10:00:00.000Z',
      invitedUserIds: [inviteJoinUser],
    });

    assert.equal(createInviteEvent.response.status, 201);
    assert.ok(createInviteEvent.payload?.item?.id);
    assert.ok(createInviteEvent.payload?.item?.inviteCode);

    const inviteCode = createInviteEvent.payload.item.inviteCode;

    const createDryRunEvent = await postJson(serverA.baseUrl, '/events', {
      hosterId: dryRunUser,
      title: `IT DryRun Event ${suffix}`,
      eventDate: '2026-07-03T10:00:00.000Z',
    });

    assert.equal(createDryRunEvent.response.status, 201);
    const dryRunEventId = createDryRunEvent.payload?.item?.id;
    assert.ok(dryRunEventId);

    const dryRunDelete = await postJson(
      serverA.baseUrl,
      '/account/delete-data?dryRun=true',
      { userId: dryRunUser },
    );
    assert.equal(dryRunDelete.response.status, 200);
    assert.equal(dryRunDelete.payload?.dryRun, true);

    const listAfterDryRun = await getJson(serverA.baseUrl, `/events?hostUserId=${dryRunUser}`);
    assert.equal(listAfterDryRun.response.status, 200);
    assert.ok(Array.isArray(listAfterDryRun.payload?.items));
    assert.ok(listAfterDryRun.payload.items.some(item => item.id === dryRunEventId));

    await stopServer(serverA.child);

    serverB = startServer(3026);
    await waitForHealth(serverB.baseUrl);

    const joinByCode = await postJson(serverB.baseUrl, '/events/invitations/join', {
      code: inviteCode,
      userId: inviteJoinUser,
    });

    assert.equal(joinByCode.response.status, 201);
    assert.equal(joinByCode.payload?.item?.status, 'accepted');

    const realDelete = await postJson(serverB.baseUrl, '/account/delete-data', {
      userId: dryRunUser,
    });
    assert.equal(realDelete.response.status, 200);
    assert.equal(realDelete.payload?.dryRun, false);

    const listAfterRealDelete = await getJson(serverB.baseUrl, `/events?hostUserId=${dryRunUser}`);
    assert.equal(listAfterRealDelete.response.status, 200);
    assert.ok(Array.isArray(listAfterRealDelete.payload?.items));
    assert.equal(listAfterRealDelete.payload.items.length, 0);

    // Best-effort cleanup of created test users.
    await postJson(serverB.baseUrl, '/account/delete-data', { userId: inviteHostUser });
    await postJson(serverB.baseUrl, '/account/delete-data', { userId: inviteJoinUser });
  } catch (error) {
    const extraLogs = [
      serverA ? `serverA logs:\n${serverA.getLogs()}` : '',
      serverB ? `serverB logs:\n${serverB.getLogs()}` : '',
    ]
      .filter(Boolean)
      .join('\n\n');

    throw new Error(`${error.message}\n\n${extraLogs}`);
  } finally {
    await stopServer(serverA?.child);
    await stopServer(serverB?.child);
  }
});

test('invite join rejects expired or invalid codes and dryRun delete requires userId', async () => {
  const suffix = `${Date.now()}-${Math.random().toString(16).slice(2, 8)}`;
  const inviteHostUser = `it_invite_negative_host_${suffix}`;
  const inviteJoinUser = `it_invite_negative_join_${suffix}`;

  let server;

  try {
    server = startServer(3027);
    await waitForHealth(server.baseUrl);

    const createExpiredInviteEvent = await postJson(server.baseUrl, '/events', {
      hosterId: inviteHostUser,
      title: `IT Expired Invite Event ${suffix}`,
      visibility: 'inviteOnly',
      eventDate: '2026-07-04T10:00:00.000Z',
      inviteCodeExpiresAt: '2001-01-01T00:00:00.000Z',
      invitedUserIds: [inviteJoinUser],
    });

    assert.equal(createExpiredInviteEvent.response.status, 201);
    const expiredInviteCode = createExpiredInviteEvent.payload?.item?.inviteCode;
    assert.ok(expiredInviteCode);

    const joinExpiredCode = await postJson(server.baseUrl, '/events/invitations/join', {
      code: expiredInviteCode,
      userId: inviteJoinUser,
    });
    assert.equal(joinExpiredCode.response.status, 404);
    assert.match(joinExpiredCode.payload?.error || '', /ungültig|abgelaufen/i);

    const joinInvalidCode = await postJson(server.baseUrl, '/events/invitations/join', {
      code: 'PP-INVALID-CODE',
      userId: inviteJoinUser,
    });
    assert.equal(joinInvalidCode.response.status, 404);
    assert.match(joinInvalidCode.payload?.error || '', /ungültig|abgelaufen/i);

    const dryRunWithoutUser = await postJson(server.baseUrl, '/account/delete-data?dryRun=true', {});
    assert.equal(dryRunWithoutUser.response.status, 400);
    assert.match(dryRunWithoutUser.payload?.error || '', /userId/i);

    // Best-effort cleanup of created test users.
    await postJson(server.baseUrl, '/account/delete-data', { userId: inviteHostUser });
    await postJson(server.baseUrl, '/account/delete-data', { userId: inviteJoinUser });
  } catch (error) {
    const extraLogs = server ? `server logs:\n${server.getLogs()}` : '';
    throw new Error(`${error.message}\n\n${extraLogs}`);
  } finally {
    await stopServer(server?.child);
  }
});

test('discover enforces public, familyCircle, privateOnly and inviteOnly visibility', async () => {
  const suffix = `${Date.now()}-${Math.random().toString(16).slice(2, 8)}`;
  const viewerUserId = 'host_demo_001';
  const publicHostUser = `it_discover_public_host_${suffix}`;
  const privateHostUser = `it_discover_private_host_${suffix}`;
  const inviteHostUser = `it_discover_invite_host_${suffix}`;

  let server;
  const createdEventIds = [];

  try {
    server = startServer(3028);
    await waitForHealth(server.baseUrl);

    const publicEvent = await postJson(server.baseUrl, '/events', {
      hosterId: publicHostUser,
      title: `IT Discover Public ${suffix}`,
      visibility: 'publicNearby',
      eventDate: '2026-07-05T10:00:00.000Z',
    });
    assert.equal(publicEvent.response.status, 201);
    const publicEventId = publicEvent.payload?.item?.id;
    createdEventIds.push(publicEventId);

    const familyEvent = await postJson(server.baseUrl, '/events', {
      hosterId: 'host_001',
      title: `IT Discover Family ${suffix}`,
      visibility: 'familyCircle',
      eventDate: '2026-07-05T11:00:00.000Z',
    });
    assert.equal(familyEvent.response.status, 201);
    const familyEventId = familyEvent.payload?.item?.id;
    createdEventIds.push(familyEventId);

    const privateEvent = await postJson(server.baseUrl, '/events', {
      hosterId: privateHostUser,
      title: `IT Discover Private ${suffix}`,
      visibility: 'privateOnly',
      eventDate: '2026-07-05T12:00:00.000Z',
    });
    assert.equal(privateEvent.response.status, 201);
    const privateEventId = privateEvent.payload?.item?.id;
    createdEventIds.push(privateEventId);

    const inviteOnlyEvent = await postJson(server.baseUrl, '/events', {
      hosterId: inviteHostUser,
      title: `IT Discover Invite ${suffix}`,
      visibility: 'inviteOnly',
      eventDate: '2026-07-05T13:00:00.000Z',
      invitedUserIds: [viewerUserId],
    });
    assert.equal(inviteOnlyEvent.response.status, 201);
    const inviteOnlyEventId = inviteOnlyEvent.payload?.item?.id;
    const inviteCode = inviteOnlyEvent.payload?.item?.inviteCode;
    createdEventIds.push(inviteOnlyEventId);
    assert.ok(inviteCode);

    const discoverBeforeJoin = await getJson(
      server.baseUrl,
      `/events/discover?viewerUserId=${viewerUserId}`,
    );
    assert.equal(discoverBeforeJoin.response.status, 200);
    const beforeJoinIds = new Set((discoverBeforeJoin.payload?.items || []).map(item => item.id));

    assert.ok(beforeJoinIds.has(publicEventId));
    assert.ok(beforeJoinIds.has(familyEventId));
    assert.ok(!beforeJoinIds.has(privateEventId));
    assert.ok(!beforeJoinIds.has(inviteOnlyEventId));

    const joinInvite = await postJson(server.baseUrl, '/events/invitations/join', {
      code: inviteCode,
      userId: viewerUserId,
    });
    assert.equal(joinInvite.response.status, 201);

    const discoverAfterJoin = await getJson(
      server.baseUrl,
      `/events/discover?viewerUserId=${viewerUserId}`,
    );
    assert.equal(discoverAfterJoin.response.status, 200);
    const afterJoinIds = new Set((discoverAfterJoin.payload?.items || []).map(item => item.id));

    assert.ok(afterJoinIds.has(publicEventId));
    assert.ok(afterJoinIds.has(familyEventId));
    assert.ok(!afterJoinIds.has(privateEventId));
    assert.ok(afterJoinIds.has(inviteOnlyEventId));

    const discoverForPrivateHost = await getJson(
      server.baseUrl,
      `/events/discover?viewerUserId=${privateHostUser}`,
    );
    assert.equal(discoverForPrivateHost.response.status, 200);
    const privateHostIds = new Set((discoverForPrivateHost.payload?.items || []).map(item => item.id));
    assert.ok(privateHostIds.has(privateEventId));
  } catch (error) {
    const extraLogs = server ? `server logs:\n${server.getLogs()}` : '';
    throw new Error(`${error.message}\n\n${extraLogs}`);
  } finally {
    if (server) {
      for (const eventId of createdEventIds) {
        if (!eventId) continue;
        try {
          await deletePath(server.baseUrl, `/events/item/${eventId}`);
        } catch (_) {
          // Ignore cleanup errors in tests.
        }
      }

      await postJson(server.baseUrl, '/account/delete-data', { userId: publicHostUser });
      await postJson(server.baseUrl, '/account/delete-data', { userId: privateHostUser });
      await postJson(server.baseUrl, '/account/delete-data', { userId: inviteHostUser });
    }

    await stopServer(server?.child);
  }
});
