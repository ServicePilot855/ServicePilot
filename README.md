# service_pilot

A new Flutter project.

Before changing a screen, read the [ServicePilot design guide](DESIGN.md) for the shared Flutter components, the customer discovery palette, and the UI review checklist.

## Verify technician enrollment locally

Run `firebase emulators:exec --only auth,firestore --project demo-servicepilot "node test/firestore/incoming_booking_rules.mjs"` from the repository root. The test issues an invitation as a verified company and checks enrollment, the company roster, and booking assignment permissions.

To try the activation screen with a local Firebase app and the updated rules, create `technicianInvites/{token}` as the verified company account. Use a cryptographically random URL-safe token, the company UID in `companyId`, the lowercase invited `email`, and a future Firestore timestamp in `expiresAt`. Open `/activate?token=<token>&email=<URL-encoded invited email>`, choose a password, and sign in from a fresh app session. The technician's user record retains the company UID, and the verified company can read the technician's ID and name under `providers/{companyId}/technicians`.

Technicians with a device-only profile need a new invitation. For an existing active Firestore technician with verified company membership, a platform administrator can add the roster entry using its UID and recorded `fullName`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
