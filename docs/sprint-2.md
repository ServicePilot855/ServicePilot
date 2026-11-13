# Sprint 2 — Service Browsing & Booking Flow
**Duration:** 13 Nov – 27 Nov 2026  
**Sprint Goal:** Implementation of The Business flow on the screen — Deliver end-to-end customer journey from service discovery and provider selection to booking submission, real-time status tracking, cancellation, and booking history.

---

## Sprint Board Snapshot

| Ticket | User Story | Points | Assignee | Status |
|--------|-----------|:------:|----------|:------:|
| SCRUM-41 | US-09: Browse available repair services | 13 | THANG Saoly (`TS`) | To Do |
| SCRUM-55 | US-10: Browse and select service providers | 8 | Taing Sothyvan (`TS`) | To Do |
| SCRUM-54 | US-11: View service provider details | 5 | TIEK Chhunhour (`TC`) | To Do |
| SCRUM-43 | US-12: Submit a repair booking request | 13 | KHENG Sokthearith (`KS`) | To Do |
| SCRUM-44 | US-13: Track repair booking status | 8 | YEAT David (`YD`) | To Do |
| SCRUM-45 | US-14: Cancel a repair booking | 3 | HEM Eamsocheat (`HE`) | To Do |
| SCRUM-46 | US-15: View repair booking history | 5 | YEAT David (`YD`) | To Do |

**Total Story Points:** 55 pts

---

## Story Points & Workload Allocation

| Team Member | Role | Assigned Stories | Total Points | Focus Domain |
|---|---|---|:---:|---|
| **THANG Saoly** | Scrum Master / Lead Dev | US-09 (SCRUM-41) | 13 pts | Service category architecture, data layer, empty-state UI |
| **Taing Sothyvan** | Product Owner / Developer | US-10 (SCRUM-55) | 8 pts | Provider listing, category filter, active-provider logic |
| **TIEK Chhunhour** | Developer | US-11 (SCRUM-54) | 5 pts | Provider detail screen, availability guards, booking entry |
| **KHENG Sokthearith** | Developer / UI Designer | US-12 (SCRUM-43) | 13 pts | Booking form UI, address/time pickers, submission flow |
| **YEAT David** | Developer | US-13 (SCRUM-44), US-15 (SCRUM-46) | 13 pts | Real-time status tracking, booking history timeline |
| **HEM Eamsocheat** | Developer | US-14 (SCRUM-45) | 3 pts | Booking cancellation logic, status transition guards |

---

## User Stories Specification

---

### US-09 · Browse Available Repair Services
**SCRUM-41 · 13 pts · Assignee: THANG Saoly**

> As a customer, I want to browse available repair service categories so that I can find the type of repair service I need.

#### Acceptance Criteria
- [ ] Customers can view available repair categories, such as AC repair, plumbing, and electrical repair.
- [ ] Each category displays its name, icon/image, and description.
- [ ] Customers can select a category to view available service providers.
- [ ] Categories without available providers display an appropriate empty-state message.

#### Definition of Done
- [ ] Repair service category interface is implemented in Flutter.
- [ ] Service categories are correctly retrieved from Firestore/DataConnect and displayed.
- [ ] Category selection and navigation to provider lists are tested.
- [ ] Empty-state handling is verified with automated tests.
- [ ] Code is peer-reviewed and the feature is successfully demonstrated.

#### Technical Notes
- Service categories to seed: AC Maintenance, Plumbing, Electrical Repair, Appliance Repair, Home Cleaning.
- Route: `/categories` or embedded directly on `CustomerHomeScreen`.
- Model: `CategoryModel(id, name, description, iconPath, isActive)`.

---

### US-10 · Browse and Select Service Providers
**SCRUM-55 · 8 pts · Assignee: Taing Sothyvan**

> As a customer, I want to browse and select independent technicians or repair companies offering my required service so that I can choose a suitable provider for my repair request.

#### Acceptance Criteria
- [ ] Customers can view service providers associated with their selected repair category.
- [ ] Both independent technicians and repair companies are displayed in the list.
- [ ] Each provider card displays its name, provider type (Independent vs. Company), and service area.
- [ ] Customers can select a provider to navigate to their detailed profile.
- [ ] Only approved and active service providers are available for booking (`status == 'active'`, `pending_verification` excluded).

#### Definition of Done
- [ ] Service provider listing interface is implemented.
- [ ] Provider information is correctly retrieved from the database.
- [ ] Providers are filtered by the selected service category.
- [ ] Filtering logic for approved and active providers is covered by unit tests.
- [ ] Code is peer-reviewed and the functionality is verified.

#### Technical Notes
- Route: `/categories/:categoryId/providers`.
- Provider type badge: `Company` (blue) or `Independent` (green).
- Query constraint: `where('status', isEqualTo: 'active')`.

---

### US-11 · View Service Provider Details
**SCRUM-54 · 5 pts · Assignee: TIEK Chhunhour**

> As a customer, I want to view the profile and service information of a repair provider so that I can decide whether the provider is suitable for my needs.

#### Acceptance Criteria
- [ ] Customers can view the selected provider's name, description, bio, and service specialties.
- [ ] Customers can view the provider's service coverage area (e.g., Toul Kork, Sen Sok, Chamkarmon).
- [ ] The profile identifies whether the provider is an independent technician or a repair company.
- [ ] Customers can start a booking request directly from the provider's profile.
- [ ] Unavailable providers cannot receive new booking requests (Book button disabled).

#### Definition of Done
- [ ] Service provider details interface is implemented.
- [ ] Provider information is correctly retrieved and displayed.
- [ ] Booking navigation works correctly (`Book Service` CTA).
- [ ] Provider availability restrictions are tested.
- [ ] Code is peer-reviewed and the feature is demonstrated.

#### Technical Notes
- Route: `/providers/:providerId`.
- Direct action: "Request Booking" navigates to `/providers/:providerId/book`.

---

### US-12 · Submit a Repair Booking Request
**SCRUM-43 · 13 pts · Assignee: KHENG Sokthearith**

> As a customer, I want to submit a repair request to my selected service provider by providing the problem details, address, and preferred appointment time so that I can request a technician to repair my problem.

#### Acceptance Criteria
- [ ] Customers can select the repair service they need from the chosen provider.
- [ ] Customers can provide a description of the problem.
- [ ] Customers can enter their repair address and preferred appointment date and time.
- [ ] Required fields must be completed before submission.
- [ ] Invalid or incomplete information displays appropriate field-level error messages.
- [ ] Successfully submitted requests are saved with a `Pending` status.
- [ ] Customers receive a confirmation screen/dialog that their request has been submitted.
- [ ] Requests are directed to the selected independent technician or repair company administrator.

#### Definition of Done
- [ ] Repair booking form is implemented with validation.
- [ ] Booking information is validated before submission (date in future, address length, problem description).
- [ ] Booking requests are correctly saved in the database under `bookings` collection.
- [ ] Each booking is associated with the authenticated customer (`customerId`) and target provider (`providerId`).
- [ ] Booking creation and validation tests pass.
- [ ] Code is peer-reviewed and the complete booking submission process is demonstrated.

#### Technical Notes
- Model: `BookingModel(id, customerId, providerId, serviceCategory, description, address, preferredDateTime, status, createdAt)`.
- Initial status: `BookingStatus.pending`.
- Confirmation redirects to Booking Tracking (`/bookings/:bookingId`).

---

### US-13 · Track Repair Booking Status
**SCRUM-44 · 8 pts · Assignee: YEAT David**

> As a customer, I want to track the status of my repair booking so that I can monitor the progress of my repair request.

#### Acceptance Criteria
- [ ] Customers can view the current status of their bookings.
- [ ] Booking statuses include: `Pending`, `Assigned`, `Confirmed`, `In Progress`, `Completed`, `Cancelled`, and `Declined`.
- [ ] Status changes made by authorized service providers or technicians are reflected in the customer's booking view.
- [ ] Customers can view the assigned technician's information once available.
- [ ] Customers can only track bookings belonging to their accounts (tenant/user security rule).
- [ ] Customers can view the latest status when they reopen or refresh their booking details.

#### Definition of Done
- [ ] Booking status tracking interface is implemented with a timeline/stepper UI.
- [ ] Booking statuses are correctly retrieved in real-time or on-demand from the database.
- [ ] Status updates from service providers and technicians are correctly displayed.
- [ ] Security access restrictions are implemented and tested.
- [ ] Status tracking widget and unit tests pass.
- [ ] Code is peer-reviewed and the feature is demonstrated.

#### Technical Notes
- Status Lifecycle:
  ```
  Pending ──► Confirmed ──► Assigned ──► In Progress ──► Completed
     │            │           │
     ▼            ▼           ▼
  Declined    Cancelled   Cancelled
  ```
- Visual tracker: Step indicator showing completed and upcoming milestones.

---

### US-14 · Cancel a Repair Booking
**SCRUM-45 · 3 pts · Assignee: HEM Eamsocheat**

> As a customer, I want to cancel my repair booking so that I can withdraw my request when I no longer need the repair service.

#### Acceptance Criteria
- [ ] Customers can cancel bookings with `Pending`, `Assigned`, or `Confirmed` status.
- [ ] Customers must confirm their decision before cancellation (confirmation modal).
- [ ] Successfully cancelled bookings change to `Cancelled` status.
- [ ] Customers cannot cancel bookings that are `In Progress`, `Completed`, `Cancelled`, or `Declined`.
- [ ] Cancelled bookings cannot be accepted, assigned, or started afterward.
- [ ] Only the customer who created the booking can cancel it.

#### Definition of Done
- [ ] Booking cancellation functionality and confirmation dialog are implemented.
- [ ] Booking status is correctly updated in the database.
- [ ] Cancellation restrictions (only before work starts) are enforced by service layer & backend rules.
- [ ] Valid and invalid cancellation scenarios are tested.
- [ ] Code is peer-reviewed and the cancellation workflow is demonstrated.

#### Technical Notes
- Guard condition:
  `if (booking.status == 'in_progress' || booking.status == 'completed') throw CannotCancelException();`
- Update payload: `{ status: 'cancelled', cancelledAt: DateTime.now(), cancelledBy: userId }`.

---

### US-15 · View Repair Booking History
**SCRUM-46 · 5 pts · Assignee: YEAT David**

> As a customer, I want to view my previous and current repair bookings so that I can keep track of the repair services I have requested.

#### Acceptance Criteria
- [ ] Customers can view a list of their bookings.
- [ ] Each booking card displays the service type, provider name, requested appointment date, and current status tag.
- [ ] Customers can select a booking to view its full details.
- [ ] Customers can view completed, cancelled, and declined bookings (tabbed or grouped into Active vs. Past).
- [ ] Customers cannot view another customer's booking history.
- [ ] Customers without booking history see an appropriate empty-state message.

#### Definition of Done
- [ ] Booking history interface is implemented with tabs (`Upcoming / Active` and `Past / History`).
- [ ] Booking records are correctly queried from the database filtered by `customerId == currentUserId`.
- [ ] Booking details and status badges are styled accurately.
- [ ] Customer data access restrictions are tested.
- [ ] Empty-state handling and booking history tests pass.
- [ ] Code is peer-reviewed and the feature is demonstrated.

#### Technical Notes
- Route: `/bookings/history`.
- Tabs:
  - **Active**: `pending`, `confirmed`, `assigned`, `in_progress`.
  - **Past**: `completed`, `cancelled`, `declined`.

---

## App Architecture — Sprint 2 Scope

```
lib/
├── core/
│   ├── router/
│   │   └── app_router.dart           # Updated with Sprint 2 routes
│   └── constants/
│       └── booking_status.dart       # Booking status enum & helpers
├── features/
│   ├── auth/                         # Existing Sprint 1 Auth
│   ├── services/
│   │   ├── models/category_model.dart
│   │   ├── services/category_service.dart
│   │   └── screens/categories_screen.dart
│   ├── providers/
│   │   ├── models/provider_model.dart
│   │   ├── services/provider_service.dart
│   │   └── screens/
│   │       ├── provider_list_screen.dart
│   │       └── provider_detail_screen.dart
│   └── bookings/
│       ├── models/booking_model.dart
│       ├── services/booking_service.dart
│       └── screens/
│           ├── create_booking_screen.dart
│           ├── booking_confirmation_screen.dart
│           ├── booking_tracking_screen.dart
│           └── booking_history_screen.dart
└── shared/
    └── widgets/
        ├── status_badge.dart
        └── empty_state_view.dart
```

---

## Screen Navigation Flow (Sprint 2)

```
Customer Home
  │
  ├──► [Browse Categories] ──► Category View (US-09)
  │                                │
  │                                └──► Select Category ──► Provider List (US-10)
  │                                                              │
  │                                                              └──► Select Provider ──► Provider Details (US-11)
  │                                                                                            │
  │                                                                                            └──► [Book Now] ──► Booking Form (US-12)
  │                                                                                                                  │
  │                                                                                                                  └──► [Submit] ──► Confirmation (US-12)
  │                                                                                                                                      │
  │                                                                                                                                      └──► Tracking (US-13)
  │                                                                                                                                             │
  │                                                                                                                                             ├──► [Cancel] (US-14)
  │
  └──► [My Bookings] ──► Booking History (US-15) ──► Select Booking ──► Tracking (US-13)
```

---

## Non-Functional Requirements (Sprint 2)

| Concern | Requirement |
|---|---|
| **Data Isolation** | Homeowners can only read/mutate their own bookings (`customerId == auth.uid`). |
| **Provider Validation** | Unverified / pending providers are filtered out of customer searches. |
| **Booking Integrity** | Cancellation is rejected if status is already `In Progress` or `Completed`. |
| **Performance** | Category and provider queries execute in < 1 second. |
| **Mobile UX** | Date and time pickers adhere to native platform patterns (Material / Cupertino). |

---

## Sprint 2 Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|:---:|:---:|---|
| **Booking State Synchronization** | Medium | High | Use real-time Firestore snapshots for status tracking so customer sees status updates immediately. |
| **Mock to Real Data Drift** | Low | Medium | Build standard seed scripts for Phnom Penh service categories and demo providers. |
| **Concurrent Booking Cancellations** | Medium | Medium | Wrap cancellation status mutations in Firestore transactions. |

---

## Sprint-Level Definition of Done

A user story in Sprint 2 is **Done** when:
1. The Flutter screens match Figma prototype specifications for ServicePilot.
2. All inputs (address, preferred time, description) are validated before submission.
3. Bookings are persisted and queried from Firebase Firestore.
4. Happy path and edge cases (cancellation disallowed, empty categories) are covered by automated tests.
5. Code passes peer review and static analysis (`flutter analyze` with 0 issues).
6. Feature is manually validated on Android/iOS/Web simulator.
7. Acceptance criteria are signed off by Product Owner (Taing Sothyvan).

---

*Sprint 2 active in Jira: SCRUM Sprint 2 (ID: 41) — Created 13 Nov 2026*
