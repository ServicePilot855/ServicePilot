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
  const email = `${crypto.randomUUID()}@example.test`;
  const password = crypto.randomUUID();
  const { localId: id, idToken: token } = await request(
    `http://${auth}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-key`,
    {
      method: 'POST',
      body: { email, password, returnSecureToken: true },
    },
  );
  if (role) {
    await request(`${documents}/users/${id}`, {
      method: 'PATCH', token: 'owner',
      body: { fields: fields({ id, role, status,
        ...(role === 'company' && { companyId: companyId ?? id }),
        ...(role === 'company_technician' && { companyId }),
      }) },
    });
  }
  return { id, token, email, password };
}

const [customer, independent, company, outsider, suspended, otherCompany] = await Promise.all([
  account('homeowner'), account('independent_provider'), account('company'),
  account('independent_provider'), account('company', { status: 'suspended' }),
  account('company'),
]);

const collection = id => `providers/${id}/incomingBookingRequests`;
const update = (path, values) => ({ update: { name: `${prefix}/${path}`, fields: values } });
const commit = (token, writes, status = 200) => request(`${documents}:commit`, {
  method: 'POST', token, body: { writes }, status,
});

const companyTechnician = await account();
const otherTechnician = await account('company_technician', { companyId: otherCompany.id });
const teammate = await account('company_technician', { companyId: company.id });
const uninvited = await account();
const companyProvider = id => update(`providers/${id}`, {
  ...fields({ id, providerType: 'company', status: 'active' }),
  isVerified: { booleanValue: true },
});
await commit('owner', [companyProvider(company.id), companyProvider(otherCompany.id)]);
const inviteId = crypto.randomUUID();
const invite = `technicianInvites/${inviteId}`;
const inviteFields = {
  ...fields({ companyId: company.id, email: companyTechnician.email }),
  expiresAt: { timestampValue: new Date(Date.now() + 60_000).toISOString() },
};
const accountPath = `users/${companyTechnician.id}`;
const profile = fields({
  id: companyTechnician.id, role: 'company_technician', status: 'active',
  companyId: company.id, technicianInviteId: inviteId,
  fullName: 'Borey Nhem', email: companyTechnician.email, phoneNumber: '',
});
const roster = `providers/${company.id}/technicians`;
const rosterPath = `${roster}/${companyTechnician.id}`;
const rosterFields = fields({ id: companyTechnician.id, fullName: 'Borey Nhem' });
const enrollment = (path, data, profileFields = profile) => [
  update(accountPath, profileFields),
  update(path, { ...data, ...fields({ redeemedBy: companyTechnician.id }) }),
  update(rosterPath, rosterFields),
];
await commit(outsider.token, [update(invite, inviteFields)], 403);
await commit(otherCompany.token, [update(invite, inviteFields)], 403);
await commit(company.token, [update(invite, inviteFields)]);
await request(`${documents}/${invite}`, { status: 403 });
await request(`${documents}/${invite}`, { token: uninvited.token, status: 403 });
await request(`${documents}/${invite}`, { token: companyTechnician.token });
await commit(companyTechnician.token, [update(accountPath, profile)], 403);
await commit(companyTechnician.token, enrollment(invite, inviteFields).slice(0, 2), 403);
await commit(companyTechnician.token, enrollment(invite, inviteFields, {
  ...profile, ...fields({ companyId: otherCompany.id }),
}), 403);
await commit(uninvited.token, enrollment(invite, inviteFields), 403);

const expiredId = crypto.randomUUID();
const expiredPath = `technicianInvites/${expiredId}`;
const expired = { ...inviteFields, expiresAt: { timestampValue: '2020-01-01T00:00:00Z' } };
await commit(company.token, [update(expiredPath, expired)], 403);
await commit('owner', [update(expiredPath, expired)]);
await commit(companyTechnician.token, enrollment(expiredPath, expired, {
  ...profile, ...fields({ technicianInviteId: expiredId }),
}), 403);

await commit(companyTechnician.token, enrollment(invite, inviteFields));
await commit(companyTechnician.token, enrollment(invite, inviteFields), 403);
const { idToken: freshTechnicianToken } = await request(
  `http://${auth}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-key`,
  {
    method: 'POST',
    body: { email: companyTechnician.email, password: companyTechnician.password, returnSecureToken: true },
  },
);
const technicianAccount = (await request(`${documents}/${accountPath}`, {
  token: freshTechnicianToken,
})).fields;
assert.deepEqual(technicianAccount, profile);
await commit(companyTechnician.token, [update(accountPath, {
  ...profile, ...fields({ companyId: otherCompany.id }),
})], 403);
await commit(companyTechnician.token, [{ delete: `${prefix}/${accountPath}` }], 403);
const rosterList = await request(`${documents}/${roster}`, { token: company.token });
assert.deepEqual(rosterList.documents.map(doc => doc.fields), [rosterFields]);
await request(`${documents}/${roster}`, { token: otherCompany.token, status: 403 });
await request(`${documents}/${roster}`, { token: companyTechnician.token, status: 403 });
await request(`${documents}/${accountPath}`, { token: company.token, status: 403 });

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
  if (provider === company) {
    const assignmentFields = fields({
      status: 'assigned', technicianId: companyTechnician.id, technicianName: 'Borey Nhem',
    });
    await commit(company.token, [{
      ...update(booking, assignmentFields), updateMask: { fieldPaths: Object.keys(assignmentFields) },
    }], 403);
    assert.deepEqual((await request(`${documents}/${booking}`, { token: customer.token })).fields, cancelled.update.fields);
  }
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
const assignment = (technicianId = companyTechnician.id, technicianName = 'Borey Nhem') =>
  ({ status: 'assigned', technicianId, technicianName });
await updateBooking(company.token, assignment(outsider.id), 403);
await updateBooking(company.token, assignment(otherTechnician.id), 403);
await updateBooking(company.token, assignment(teammate.id), 403);
await updateBooking(company.token, assignment(companyTechnician.id, 'Wrong Name'), 403);
await updateBooking(company.token, { status: 'assigned', technicianId: companyTechnician.id }, 403);
await updateBooking(otherCompany.token, assignment(), 403);
await updateBooking(companyTechnician.token, assignment(), 403);
assert.deepEqual((await request(`${documents}/${booking}`, { token: company.token })).fields, confirmedFields);
await updateBooking(company.token, assignment());
const assignedFields = (await request(`${documents}/${booking}`, { token: company.token })).fields;
assert.equal(assignedFields.technicianId.stringValue, companyTechnician.id);
assert.equal(assignedFields.technicianName.stringValue, 'Borey Nhem');
assert.deepEqual(assignedFields.confirmedAppointmentAt, confirmedFields.confirmedAppointmentAt);
assert.deepEqual((await request(`${documents}/${booking}`, { token: freshTechnicianToken })).fields, assignedFields);
for (const actor of [teammate, otherTechnician, otherCompany]) {
  await request(`${documents}/${booking}`, { token: actor.token, status: 403 });
}
const assignedQuery = structuredClone(acceptedQuery);
assignedQuery.structuredQuery.where.compositeFilter.filters.push({
  fieldFilter: { field: { fieldPath: 'technicianId' }, op: 'EQUAL', value: { stringValue: companyTechnician.id } },
});
const assignedJobs = await request(`${documents}:runQuery`, {
  method: 'POST', token: freshTechnicianToken, body: assignedQuery,
});
assert.deepEqual(assignedJobs.flatMap(row => row.document ? [row.document.fields] : []), [assignedFields]);
await request(`${documents}:runQuery`, {
  method: 'POST', token: teammate.token, body: assignedQuery, status: 403,
});
await updateBooking(company.token, assignment(), 403);
await updateBooking(company.token, { status: 'confirmed' }, 403);
await commit(company.token, [confirmWrite(company.id)]);
await request(`${documents}/${booking}`, { token: companyTechnician.token, status: 403 });
if (storage) await readPhoto(companyTechnician.token, false);

await updateBooking(company.token, assignment());
await updateBooking(companyTechnician.token, { status: 'in_progress' });
await updateBooking(companyTechnician.token, { status: 'completed' });
if (storage) {
  await readPhoto(company.token, true);
  await readPhoto(companyTechnician.token, true);
  await readPhoto(otherTechnician.token, false);
  await readPhoto(outsider.token, false);
  console.log('Booking photo privacy passed in the Storage emulator.');
}

const platformAdmin = await account();
await request(`http://${auth}/identitytoolkit.googleapis.com/v1/projects/${project}/accounts:update`, {
  method: 'POST', token: 'owner',
  body: { localId: platformAdmin.id, customAttributes: JSON.stringify({ admin: true }) },
});
const { idToken: adminToken } = await request(
  `http://${auth}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-key`,
  {
    method: 'POST',
    body: { email: platformAdmin.email, password: platformAdmin.password, returnSecureToken: true },
  },
);
const suspendTechnician = update(accountPath, { ...profile, ...fields({ status: 'suspended' }) });
const removeRosterEntry = { delete: `${prefix}/${rosterPath}` };
await commit(adminToken, [suspendTechnician], 403);
await commit(adminToken, [removeRosterEntry], 403);
await commit(adminToken, [suspendTechnician, removeRosterEntry]);
assert.deepEqual((await request(`${documents}/${roster}`, { token: company.token })).documents ?? [], []);
await request(`${documents}/${booking}`, { token: freshTechnicianToken, status: 403 });
if (storage) await readPhoto(freshTechnicianToken, false);

await commit('owner', [update(`users/${company.id}`, fields({ role: 'company', status: 'suspended', companyId: company.id }))]);
await request(`${documents}/${booking}`, { token: company.token, status: 403 });
if (storage) await readPhoto(company.token, false);

// BOOK-3 (SCRUM-105): only the addressed provider can decline a Pending request,
// and the decline may change only status, updatedAt and declinedReason.
await commit('owner', [update(`users/${company.id}`, fields({ role: 'company', status: 'active', companyId: company.id }))]);
for (const provider of [independent, company]) {
  const declineId = crypto.randomUUID();
  const declineBooking = `bookings/${declineId}`;
  const declinePreview = `${collection(provider.id)}/${declineId}`;
  const archive = `providers/${provider.id}/declinedBookingRequests`;
  const archivedRequest = `${archive}/${declineId}`;
  const pending = bookingFor(provider.id, declineId);
  const pendingWithReason = { ...pending, declinedReason: { stringValue: 'Pre-existing reason' } };
  await commit(customer.token, [
    update(declineBooking, pendingWithReason), update(declinePreview, job),
  ], 403);
  await commit(customer.token, [update(declineBooking, pending), update(declinePreview, job)]);
  await commit(customer.token, [update(declineBooking, pendingWithReason)], 403);

  const declineWrite = (token, extra = {}, status = 200, archiveData = job) => commit(token, [
    {
      ...update(declineBooking, {
        ...pending,
        status: { stringValue: 'declined' },
        updatedAt: { timestampValue: '2026-11-27T03:00:00Z' },
        ...extra,
      }),
    },
    { delete: `${prefix}/${declinePreview}` },
    ...(archiveData ? [update(archivedRequest, archiveData)] : []),
  ], status);

  await request(`${documents}/${declineBooking}`, { token: provider.token, status: 403 });
  await commit(provider.token, [update(archivedRequest, job)], 403);
  await declineWrite(customer.token, {}, 403);
  await declineWrite(outsider.token, {}, 403);
  await declineWrite(provider.token, { technicianId: { stringValue: outsider.id } }, 403);
  await declineWrite(provider.token, {}, 403, null);
  await declineWrite(provider.token, {}, 403, { ...job, address: pending.address });
  await declineWrite(provider.token, { declinedReason: { stringValue: 'Outside our service area that day' } });

  await request(`${documents}/${declineBooking}`, { token: provider.token, status: 403 });
  const declinedFields = (await request(`${documents}/${declineBooking}`, { token: customer.token })).fields;
  assert.equal(declinedFields.status.stringValue, 'declined');
  assert.equal(declinedFields.declinedReason.stringValue, 'Outside our service area that day');
  const providerHistory = await request(`${documents}/${archive}`, { token: provider.token });
  assert.deepEqual(providerHistory.documents.map(doc => doc.fields), [job]);
  assert.deepEqual((await request(`${documents}/${archivedRequest}`, { token: provider.token })).fields, job);
  await request(`${documents}/${declineBooking}`, { token: outsider.token, status: 403 });
  await request(`${documents}/${archivedRequest}`, { token: outsider.token, status: 403 });
  await request(`${documents}/${archive}`, { token: outsider.token, status: 403 });
  await request(`${documents}/${declinePreview}`, { token: provider.token, status: 404 });
  await declineWrite(provider.token, { declinedReason: { stringValue: 'Again' } }, 403);
}

const legacyDeclinedId = crypto.randomUUID();
const legacyDeclined = `bookings/${legacyDeclinedId}`;
const legacyArchive = `providers/${independent.id}/declinedBookingRequests/${legacyDeclinedId}`;
await commit('owner', [update(legacyDeclined, {
  ...bookingFor(independent.id, legacyDeclinedId), status: { stringValue: 'declined' },
})]);
await request(`${documents}/${legacyArchive}`, { token: independent.token, status: 404 });
assert.match(backfill('--declined'), /3 declined booking\(s\) found \(dry run\)/);
assert.match(backfill('--declined', '--apply'), /3 declined booking\(s\) processed/);
assert.deepEqual((await request(`${documents}/${legacyArchive}`, { token: independent.token })).fields, job);
await request(`${documents}/${legacyDeclined}`, { token: independent.token, status: 403 });

// WORK-1 (SCRUM-91): quote-based work cannot start before the homeowner approves.
{
  const quoteId = crypto.randomUUID();
  const quotePath = `quoteRequests/${quoteId}`;
  const startId = crypto.randomUUID();
  const startPath = `bookings/${startId}`;
  const quoteFields = {
    ...fields({ id: quoteId, customerId: customer.id, providerId: independent.id,
      offeringId: 'offering-quote-start', offeringTitle: 'AC deep clean',
      description: 'Please quote a deep clean for two units.', status: 'quoted' }),
    quotedPrice: { doubleValue: 45 },
    createdAt: { timestampValue: '2026-11-28T02:00:00Z' },
  };
  const startFields = {
    ...bookingFor(independent.id, startId),
    quoteId: { stringValue: quoteId },
    status: { stringValue: 'confirmed' },
    confirmedAppointmentAt: job.appointmentDate,
    confirmedBy: { stringValue: independent.id },
    confirmedAt: { timestampValue: '2026-11-28T03:00:00Z' },
  };
  await commit('owner', [update(quotePath, quoteFields)]);
  await commit('owner', [update(startPath, startFields)]);

  const start = (token, status = 200) => commit(token, [{
    ...update(startPath, { ...startFields, status: { stringValue: 'in_progress' },
      updatedAt: { timestampValue: '2026-11-28T04:00:00Z' } }),
    updateMask: { fieldPaths: ['status', 'updatedAt'] },
  }], status);

  await start(outsider.token, 403);
  await start(independent.token, 403); // quote is still only 'quoted'
  await commit('owner', [update(quotePath, { ...quoteFields,
    status: { stringValue: 'approved' }, approvedPrice: { doubleValue: 45 },
    approvedAt: { timestampValue: '2026-11-28T03:30:00Z' } })]);
  await start(independent.token);
  assert.equal(
    (await request(`${documents}/${startPath}`, { token: independent.token })).fields.status.stringValue,
    'in_progress',
  );
}

console.log('Technician enrollment, company roster isolation, and incoming booking rules passed.');

