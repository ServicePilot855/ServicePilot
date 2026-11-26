import { parseArgs } from 'node:util';

const { values } = parseArgs({
  options: { project: { type: 'string' }, apply: { type: 'boolean' }, declined: { type: 'boolean' }, help: { type: 'boolean' } },
});
if (values.help) {
  console.log('node tool/backfill_booking_inbox.mjs --project PROJECT_ID [--declined] [--apply]');
  console.log('Dry run by default. Use the local emulator or supply FIRESTORE_ACCESS_TOKEN for the named project.');
  console.log('Use --declined for declined history. The default processes pending requests.');
  process.exit(0);
}
const project = values.project;
if (!project || !/^[a-z][a-z0-9-]+$/.test(project)) throw new Error('Specify a valid --project.');

const local = process.env.FIRESTORE_EMULATOR_HOST;
if (local && !/^(127\.0\.0\.1|localhost):\d+$/.test(local)) {
  throw new Error('FIRESTORE_EMULATOR_HOST must be a loopback address.');
}
const token = local ? 'owner' : process.env.FIRESTORE_ACCESS_TOKEN;
if (!token) throw new Error('Set FIRESTORE_ACCESS_TOKEN for the specified project.');
const documentRoot = `projects/${project}/databases/(default)/documents`;
const api = local ? `http://${local}` : 'https://firestore.googleapis.com';
const endpoint = `${api}/v1/${documentRoot}`;
const status = values.declined ? 'declined' : 'pending';
const collection = values.declined ? 'declinedBookingRequests' : 'incomingBookingRequests';

async function request(url, body) {
  const response = await fetch(url, {
    method: body ? 'POST' : 'GET',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    ...(body && { body: JSON.stringify(body) }),
    signal: AbortSignal.timeout(30_000),
  });
  if (!response.ok) throw new Error(`Firestore request failed with HTTP ${response.status}.`);
  return response.json();
}

const rows = await request(`${endpoint}:runQuery`, {
  structuredQuery: {
    from: [{ collectionId: 'bookings' }],
    where: { fieldFilter: { field: { fieldPath: 'status' }, op: 'EQUAL', value: { stringValue: status } } },
    select: { fields: ['providerId', 'serviceType', 'categoryName', 'description', 'notes', 'appointmentDate']
      .map(fieldPath => ({ fieldPath })) },
  },
});
const empty = { stringValue: '' };
let processed = 0;
for (const { document } of rows) {
  if (!document) continue;
  const data = document.fields;
  const providerId = data.providerId?.stringValue;
  if (!providerId || providerId.includes('/')) throw new Error('A booking has an invalid provider ID.');
  const id = document.name.split('/').at(-1);
  const name = `${documentRoot}/providers/${providerId}/${collection}/${id}`;
  if (values.apply) {
    await request(`${endpoint}:commit`, { writes: [
      { verify: document.name, currentDocument: { updateTime: document.updateTime } },
      { update: { name, fields: {
        serviceTitle: data.serviceType ?? data.categoryName ?? empty,
        description: data.description ?? data.notes ?? empty,
        appointmentDate: data.appointmentDate ?? { nullValue: null },
      } } },
    ] });
  }
  processed++;
}
console.log(`${processed} ${status} booking(s) ${values.apply ? 'processed' : 'found (dry run)'}.`);
