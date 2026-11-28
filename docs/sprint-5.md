# Sprint 5 — Quote to Booking
**Duration:** 26 Nov – 02 Dec 2026  
**Sprint Name:** Sprint 5 · Quote to booking  
**Sprint Goal:** Deliver the end-to-end quote-to-booking workflow so homeowners can request custom quotes, providers can review and send prices, homeowners can approve quoted prices and book appointments, and providers can track homeowner decisions.

---

## Sprint Board Snapshot

| Ticket | User Story / Feature | Assignee | Status |
|---|---|---|:---:|
| **SCRUM-83** | QUOTE-1: Submit a separate quote request | THANG Saoly (`TS`) | Done |
| **SCRUM-84** | QUOTE-2: View incoming quote requests | Taing Sothyvan (`TS`) | In Progress |
| **SCRUM-85** | QUOTE-3: Send a price for a quote request | HEM Eamsocheat (`HE`) | In Progress |
| **SCRUM-86** | QUOTE-4: Approve the quoted price | YEAT David (`YD`) | To Do |
| **SCRUM-87** | QUOTE-5: Book a time using the approved quote | KHENG Sokthearith (`KS`) | To Do |
| **SCRUM-88** | QUOTE-7: View the homeowner's quote decision | TIEK Chhunhour (`TC`) | To Do |

**Total Work Items:** 6 stories  
**Epic:** Quotes (`SCRUM-29`)

---

## Workload Allocation & Flow

| Team Member | Role | Assigned Stories | Focus Domain |
|---|---|---|---|
| **THANG Saoly** | Scrum Master / Lead Dev | QUOTE-1 (`SCRUM-83`) | Homeowner quote request submission, validation & `quoteRequests` storage |
| **Taing Sothyvan** | Product Owner / Developer | QUOTE-2 (`SCRUM-84`) | Provider quote inbox & strict provider isolation |
| **HEM Eamsocheat** | Developer | QUOTE-3 (`SCRUM-85`) | Provider pricing submission (`Requested` → `Quoted`) |
| **YEAT David** | Developer | QUOTE-4 (`SCRUM-86`) | Homeowner quote review, approval action (`Quoted` → `Approved`) & ownership guard |
| **KHENG Sokthearith** | Developer / UI Designer | QUOTE-5 (`SCRUM-87`) | Booking time-slot selection from an approved quote |
| **TIEK Chhunhour** | Developer | QUOTE-7 (`SCRUM-88`) | Provider visibility into homeowner quote decisions |

---

## User Stories Specification

---

### QUOTE-1 · Submit a Separate Quote Request
**SCRUM-83 · Assignee: THANG Saoly**  
*Epic: Quotes (SCRUM-29) · Requirement: HOME-4*

> As a homeowner, I can send details for a quote-required service so the provider can assess the job.

#### Acceptance Criteria
- [x] The customer can describe the job and attach photos.
- [x] A successful request is stored for the chosen offering and provider with `Requested` status.
- [x] The cart stays separate.

#### Subtasks
- [x] `SCRUM-134`: Collect details for the selected quote-required offering
- [x] `SCRUM-135`: Save the provider's quote request
- [x] `SCRUM-136`: Verify request submission

#### Implementation & Verification
- Implemented on `feat/SCRUM-83-submit-quote-request` and merged into `main`:
  - Shared `ProblemDescriptionField` & `ProblemPhotoStrip` controls connected to `/providers/:providerId/quote?offeringId=...`.
  - `QuoteRequestModel`, `QuoteRequestValidator`, `InMemoryQuoteService`, `FirestoreQuoteService` (`quoteRequests` collection, Cloudinary uploads under `servicepilot/quotes`), and Firestore security rules.
  - Verified with `flutter analyze`, widget/unit tests, and Firebase emulator rules tests (`test/firestore/quote_request_rules.mjs`).

---

### QUOTE-2 · View Incoming Quote Requests
**SCRUM-84 · Assignee: Taing Sothyvan**  
*Epic: Quotes (SCRUM-29) · Requirement: IND-4, CO-2*

> As a provider, I can view requests sent to me so I know which jobs need a price.

#### Acceptance Criteria
- [ ] A signed-in independent provider or authorized company administrator sees requests addressed to their provider account and can view the permitted details.
- [ ] Requests for other providers are inaccessible.

#### Subtasks
- [ ] `SCRUM-137`: Read only quotes addressed to this provider
- [ ] `SCRUM-138`: Display the provider quote inbox
- [ ] `SCRUM-139`: Verify isolation

#### Definition of Done
- [ ] The change is integrated into the shared prototype and all acceptance criteria are verified.
- [ ] Relevant success and failure paths pass, including access and data isolation checks.
- [ ] Peer review is complete, required project checks pass, and defects are resolved or accepted by the Product Owner.

---

### QUOTE-3 · Send a Price for a Quote Request
**SCRUM-85 · Assignee: HEM Eamsocheat**  
*Epic: Quotes (SCRUM-29) · Requirement: IND-4, CO-2*

> As a provider, I can submit a price for a request addressed to me so the homeowner can decide.

#### Acceptance Criteria
- [ ] The addressed independent provider or a company administrator authorized for the addressed company can save a valid price on its `Requested` record and move it to `Quoted`.
- [ ] An invalid price or a request belonging to another provider produces no update.

#### Subtasks
- [ ] `SCRUM-140`: Apply the authorized Quoted update
- [ ] `SCRUM-141`: Connect the price input
- [ ] `SCRUM-142`: Verify quote price changes

#### Definition of Done
- [ ] Valid price input and authorization guard (`Requested` → `Quoted`) implemented.
- [ ] Firestore security rules enforce provider ownership and valid pricing.
- [ ] Unit, widget, and rules tests pass.

---

### QUOTE-4 · Approve the Quoted Price
**SCRUM-86 · Assignee: YEAT David**  
*Epic: Quotes (SCRUM-29) · Requirement: HOME-4*

> As a homeowner, I can see and approve my quoted price so the provider has a recorded agreement.

#### Acceptance Criteria
- [ ] The homeowner sees the provider's price on their own request.
- [ ] Approval records the agreed amount and sets the request to `Approved`.
- [ ] Other accounts cannot approve it.

#### Subtasks
- [ ] `SCRUM-143`: Record the homeowner's quote approval
- [ ] `SCRUM-144`: Show the quoted amount and approval action
- [ ] `SCRUM-145`: Verify the approval outcome

#### Definition of Done
- [ ] Customer quote detail view clearly displays `quotedPrice` and the primary approval action (`Quoted` → `Approved`).
- [ ] Backend service & Firestore rules strictly enforce `customerId == request.auth.uid` and `status == 'quoted'`.
- [ ] Automated unit, widget, and security tests verify approval and unauthorized-user rejection.

---

### QUOTE-5 · Book a Time Using the Approved Quote
**SCRUM-87 · Assignee: KHENG Sokthearith**  
*Epic: Quotes (SCRUM-29) · Requirement: HOME-4*

> As a homeowner, I can request an appointment using my approved price so the job can follow the usual booking process.

#### Acceptance Criteria
- [ ] Once the agreed booking action occurs, a `Pending` booking retains the approved price and links to the quote and chosen provider.
- [ ] An unapproved quote cannot enter the booking flow.
- [ ] Provider confirmation is a separate story.

#### Subtasks
- [ ] `SCRUM-146`: Validate eligibility and save the linked booking
- [ ] `SCRUM-147`: Connect the agreed appointment step
- [ ] `SCRUM-148`: Verify the approval gate

#### Definition of Done
- [ ] Booking flow accepts an `Approved` quote, carries forward `quotedPrice`, and links `quoteId`.
- [ ] Unapproved quotes (`requested`, `quoted`, etc.) are blocked from entering booking.
- [ ] Automated tests verify eligibility gating and booking creation.

---

### QUOTE-7 · View the Homeowner's Quote Decision
**SCRUM-88 · Assignee: TIEK Chhunhour**  
*Epic: Quotes (SCRUM-29) · Requirement: IND-4, CO-2*

> As a provider account manager, I can see the homeowner's decision so I know whether my quoted price has been accepted.

#### Acceptance Criteria
- [ ] A signed-in independent provider or service company administrator can see the price and latest decision on a quote addressed to them.
- [ ] Other providers' quotes are inaccessible.

#### Subtasks
- [ ] `SCRUM-149`: Display the decision on the provider's quote
- [ ] `SCRUM-150`: Verify both provider types

#### Definition of Done
- [ ] Provider quote views reflect homeowner decisions (`Approved` / declined) and agreed price.
- [ ] Both independent providers and company administrators are verified with isolation checks.

---

## Technical Notes & Architecture — Sprint 5 Scope

```
lib/
├── core/
│   └── router/
│       └── app_router.dart                          # Quote request, detail, and booking routes
└── features/
    └── quotes/
        ├── models/
        │   ├── quote_request_input.dart
        │   ├── quote_request_model.dart             # QuoteRequestModel (customerId, providerId, quotedPrice, status)
        │   └── quote_status.dart                    # requested, quoted, approved, etc.
        ├── providers/
        │   └── quote_provider.dart                  # Riverpod providers & streams for quotes
        ├── screens/
        │   ├── create_quote_request_screen.dart     # QUOTE-1 (THANG Saoly)
        │   ├── quote_request_confirmation_screen.dart
        │   └── quote_request_detail_screen.dart     # QUOTE-4 (YEAT David) & detail views
        ├── services/
        │   ├── quote_service.dart                   # IQuoteService & InMemoryQuoteService
        │   └── firestore_quote_service.dart         # Firestore 'quoteRequests' mutations
        └── widgets/
            └── quote_status_badge.dart              # DESIGN.md status pills
```

---

## Sprint 5 Definition of Done

A user story in Sprint 5 is **Done** when:
1. Flutter screens follow the **Blue Pipe** design tokens and rules in `DESIGN.md`.
2. Role-based and ownership security guards enforce strict isolation (customers only manage their own quotes; providers only access quotes addressed to them).
3. Backend mutations persist cleanly in Firebase Firestore (`quoteRequests` and linked `bookings`) and pass `firestore.rules` checks.
4. Happy paths and failure/unauthorized edge cases are covered by unit, widget, and Firestore rules tests.
5. `flutter analyze` passes with 0 issues.
6. Acceptance criteria are reviewed and signed off by the Product Owner (Taing Sothyvan).
