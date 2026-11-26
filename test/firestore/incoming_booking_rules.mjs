import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';

const project = 'demo-servicepilot';
const { FIREBASE_AUTH_EMULATOR_HOST: auth, FIRESTORE_EMULATOR_HOST: firestore } = process.env;
for (const host of [auth, firestore]) assert.match(host ?? '', /^(127\.0\.0\.1|localhost):\d+$/);
const storage = process.env.FIREBASE_STORAGE_EMULATOR_HOST;
if (storage) assert.match(storage, /^(127\.0\.0\.1|localhost):\d+$/);

const prefix = `projects/${project}/databases/(default)/documents`;
const documents = `http://${firestore}/v1/${prefix}`;

async function request(url, { method = 'GET', token, body, status = 200 } = {}) {
  const response = await fetch(url, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token && { Authorization: `Bearer ${token}` }),
    },
    ...(body && { body: JSON.stringify(body) }),
  });
  const data = await response.json();
  assert.equal(response.status, status, `${method} ${url}: ${JSON.stringify(data)}`);
  return data;
}

function fields(data) {
  return Object.fromEntries(Object.entries(data).map(([key, value]) => [key, { stringValue: value }]));
}

async function account(role, { status = 'active', companyId } = {}) {
  const { localId: id, idToken: token } = await request(
    `http://${auth}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-key`,
    {
      method: 'POST',
      body: { email: `${crypto.randomUUID()}@example.test`, password: crypto.randomUUID(), returnSecureToken: true },
    },
  );
  await request(`${documents}/users/${id}`, {
    method: 'PATCH', token: 'owner',
    body: { fields: fields({ id, role, status,
      ...(role === 'company' && { companyId: companyId ?? id }),
      ...(role === 'company_technician' && { companyId }),
    }) },
  });
  return { id, token };
}

const [customer, independent, company, outsider, suspended] = await Promise.all([
  account('homeowner'), account('independent_provider'), account('company'),
  account('independent_provider'), account('company', { status: 'suspended' }),
]);
const companyTechnician = await account('company_technician', { companyId: company.id });

const collection = id => `providers/${id}/incomingBookingRequests`;
const update = (path, values) => ({ update: { name: `${prefix}/${path}`, fields: values } });
const commit = (token, writes, status = 200) => request(`${documents}:commit`, {
  method: 'POST', token, body: { writes }, status,
});

const job = fields({ serviceTitle: 'Sink repair', description: 'The sink leaks below the trap.' });
job.appointmentDate = { timestampValue: '2026-12-01T03:00:00Z' };

function bookingFor(providerId, id) {
  return {
    ...fields({ id, providerId, customerId: customer.id, status: 'pending',
      serviceType: 'Sink repair', description: 'The sink leaks below the trap.',
      customerPhone: '012345678', address: 'Private street address' }),
    appointmentDate: job.appointmentDate,
    location: { geoPointValue: { latitude: 11.5, longitude: 104.9 } },
    photos: { arrayValue: { values: [{ stringValue: 'https://example.test/private.jpg' }] } },
  };
}

for (const provider of [independent, company, suspended]) {
  const id = crypto.randomUUID();
  const booking = `bookings/${id}`;
  const preview = `${collection(provider.id)}/${id}`;
  const data = bookingFor(provider.id, id);

  await commit(customer.token, [update(booking, data)], 403);
  await commit(customer.token, [
    update(booking, { ...data, ...fields({ technicianId: outsider.id }) }),
    update(preview, job),
  ], 403);
  await commit(customer.token, [update(booking, data), update(preview, { ...job, address: data.address })], 403);
  await commit(customer.token, [update(booking, data), update(preview, { ...job, description: data.address })], 403);
  await commit(customer.token, [update(booking, data), update(`${collection(outsider.id)}/${id}`, job)], 403);
  await commit(customer.token, [update(booking, data), update(preview, job)]);
  await commit(customer.token, [update(booking, { ...data, ...fields({ technicianId: outsider.id }) })], 403);

  const ownStatus = provider === suspended ? 403 : 200;
  const list = await request(`${documents}/${collection(provider.id)}`, { token: provider.token, status: ownStatus });
  if (ownStatus === 200) {
    assert.deepEqual(list.documents.map(doc => doc.fields), [job]);
    assert.deepEqual((await request(`${documents}/${preview}`, { token: provider.token })).fields, job);
  }
  for (const token of [outsider.token, companyTechnician.token, customer.token, undefined]) {
    await request(`${documents}/${preview}`, { token, status: 403 });
    await request(`${documents}/${collection(provider.id)}`, { token, status: 403 });
  }
  for (const token of [provider.token, outsider.token, companyTechnician.token]) {
    await request(`${documents}/${booking}`, { token, status: 403 });
  }
  assert.deepEqual((await request(`${documents}/${booking}`, { token: customer.token })).fields, data);

  const removePreview = { delete: `${prefix}/${preview}` };
  const cancelled = update(booking, { ...data, status: { stringValue: 'cancelled' } });
  await commit(customer.token, [removePreview], 403);
  await commit(customer.token, [cancelled], 403);
  await commit(customer.token, [cancelled, removePreview]);
  await request(`${documents}/${preview}`, { token: provider.token, status: ownStatus === 200 ? 404 : 403 });
  await request(`${documents}/${booking}`, { token: provider.token, status: 403 });
}

const id = crypto.randomUUID();
const booking = `bookings/${id}`;
const preview = `${collection(company.id)}/${id}`;
// A legacy booking can acquire the same limited view without changing the original.
const original = bookingFor(company.id, id);
await commit('owner', [update(booking, original)]);
const backfill = (...args) => execFileSync(process.execPath, [
  'tool/backfill_booking_inbox.mjs', '--project', project, ...args,
], { encoding: 'utf8' });
assert.match(backfill(), /1 pending booking\(s\) found \(dry run\)/);
await request(`${documents}/${preview}`, { token: company.token, status: 404 });
assert.match(backfill('--apply'), /1 pending booking\(s\) processed/);
assert.match(backfill('--apply'), /1 pending booking\(s\) processed/);
assert.deepEqual((await request(`${documents}/${booking}`, { token: customer.token })).fields, original);
assert.deepEqual((await request(`${documents}/${preview}`, { token: company.token })).fields, job);

const photos = `http://${storage}/v0/b/${project}.appspot.com/o`;
const photo = encodeURIComponent(`bookings/${customer.id}/${id}/sink.jpg`);
const photoData = new Uint8Array([255, 216, 255, 217]);
async function readPhoto(token, allowed) {
  const response = await fetch(`${photos}/${photo}?alt=media`, {
    headers: { Authorization: `Firebase ${token}` },
  });
  assert.equal(response.status, allowed ? 200 : 403);
  if (allowed) assert.deepEqual(new Uint8Array(await response.arrayBuffer()), photoData);
}
if (storage) {
  const upload = await fetch(`${photos}?name=${photo}`, {
    method: 'POST',
    headers: { Authorization: `Firebase ${customer.token}`, 'Content-Type': 'image/jpeg' },
    body: photoData,
  });
  assert.equal(upload.status, 200, await upload.text());
  await readPhoto(customer.token, true);
  for (const actor of [company, companyTechnician, outsider]) await readPhoto(actor.token, false);
}

const confirmWrite = (confirmedBy, appointment = job.appointmentDate) => ({
  ...update(booking, { ...fields({ status: 'confirmed', confirmedBy }), confirmedAppointmentAt: appointment }),
  updateMask: { fieldPaths: ['status', 'confirmedBy', 'confirmedAppointmentAt', 'technicianId', 'technicianName'] },
  updateTransforms: [{ fieldPath: 'confirmedAt', setToServerValue: 'REQUEST_TIME' }],
});
const decide = (confirmedBy, appointment) => [
  confirmWrite(confirmedBy, appointment),
  { delete: `${prefix}/${preview}` },
];
await commit(outsider.token, decide(outsider.id), 403);
await commit(companyTechnician.token, decide(companyTechnician.id), 403);
await commit(company.token, decide(outsider.id), 403);
await commit(company.token, decide(company.id, { timestampValue: '2026-12-02T03:00:00Z' }), 403);
await commit(company.token, [
  { ...update(booking, fields({ status: 'confirmed' })), updateMask: { fieldPaths: ['status'] } },
  { delete: `${prefix}/${preview}` },
], 403);
await commit(company.token, decide(company.id));
await request(`${documents}/${preview}`, { token: company.token, status: 404 });
const confirmedFields = (await request(`${documents}/${booking}`, { token: company.token })).fields;
assert.deepEqual(confirmedFields.address, original.address);
assert.deepEqual(confirmedFields.confirmedAppointmentAt, job.appointmentDate);
assert.equal(confirmedFields.confirmedBy.stringValue, company.id);
assert.ok(confirmedFields.confirmedAt.timestampValue);
await request(`${documents}/${booking}`, { token: outsider.token, status: 403 });
await request(`${documents}/${booking}`, { token: companyTechnician.token, status: 403 });

const acceptedQuery = {
  structuredQuery: {
    from: [{ collectionId: 'bookings' }],
    where: { compositeFilter: { op: 'AND', filters: [
      { fieldFilter: { field: { fieldPath: 'providerId' }, op: 'EQUAL', value: { stringValue: company.id } } },
      { fieldFilter: { field: { fieldPath: 'status' }, op: 'IN', value: {
        arrayValue: { values: ['confirmed', 'assigned', 'in_progress', 'completed'].map(stringValue => ({ stringValue })) },
      } } },
    ] } },
  },
};
const acceptedBookings = await request(`${documents}:runQuery`, {
  method: 'POST', token: company.token, body: acceptedQuery,
});
assert.deepEqual(acceptedBookings.flatMap(row => row.document ? [row.document.fields] : []), [confirmedFields]);
await request(`${documents}:runQuery`, {
  method: 'POST', token: outsider.token, body: acceptedQuery, status: 403,
});

const updateBooking = (token, changes, status = 200) => commit(token, [
  { ...update(booking, fields(changes)), updateMask: { fieldPaths: Object.keys(changes) } },
], status);
await updateBooking(company.token, { status: 'completed' }, 403);
await updateBooking(company.token, { status: 'in_progress', address: 'Changed address' }, 403);
await updateBooking(company.token, { status: 'assigned', technicianId: outsider.id }, 403);
await updateBooking(company.token, { status: 'assigned', technicianId: companyTechnician.id });
assert.deepEqual((await request(`${documents}/${booking}`, { token: companyTechnician.token })).fields.address, original.address);
await updateBooking(company.token, { status: 'confirmed' }, 403);
await commit(company.token, [confirmWrite(company.id)]);
await request(`${documents}/${booking}`, { token: companyTechnician.token, status: 403 });
if (storage) await readPhoto(companyTechnician.token, false);

await updateBooking(company.token, { status: 'assigned', technicianId: companyTechnician.id });
await updateBooking(companyTechnician.token, { status: 'in_progress' });
await updateBooking(companyTechnician.token, { status: 'completed' });
if (storage) {
  await readPhoto(company.token, true);
  await readPhoto(companyTechnician.token, true);
  await readPhoto(outsider.token, false);
  console.log('Booking photo privacy passed in the Storage emulator.');
}
await commit('owner', [update(`users/${company.id}`, fields({ role: 'company', status: 'suspended', companyId: company.id }))]);
await request(`${documents}/${booking}`, { token: company.token, status: 403 });
if (storage) await readPhoto(company.token, false);

console.log('Incoming booking rules passed for independent, company and unrelated accounts.');
