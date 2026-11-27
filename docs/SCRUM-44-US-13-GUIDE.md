# SCRUM-44 / US-13: Track Repair Booking Status — Implementation Guide
**Assignee:** YEAT David (`YD`)  
**Role:** Junior Developer  
**Sprint:** Sprint 2 (8 Story Points)  
**Feature Module:** `lib/features/bookings/`  
**Reference Design:** [DESIGN.md](file:///e:/IDT-Gen11-Y3-SEG3/Project/ServicePilot/DESIGN.md)

---

## 1. Executive Summary: What Is Completed vs. What Remains

Currently, the groundwork for repair bookings and cancellation (US-14 / SCRUM-45 by HEM Eamsocheat) has been implemented, but **US-13 (SCRUM-44) is NOT yet complete**.

### Acceptance Criteria (AC) Status Matrix

| Acceptance Criteria | Status | What Is Missing / Needs Work |
|---|:---:|---|
| **AC 1: View current status** | ⚠️ Partial | Screen displays a status badge & notice, but **lacks the required Timeline / Stepper milestone tracker**. |
| **AC 2: All 7 lifecycle statuses handled** (`Pending`, `Assigned`, `Confirmed`, `In Progress`, `Completed`, `Cancelled`, `Declined`) | ⚠️ Partial | Enums and badges exist, but the visual progression stepper does not map these branches (happy path vs. cancelled/declined terminal states). |
| **AC 3: Status changes reflected to customer** | ❌ Missing | Screen uses a static one-off fetch (`FutureProvider`). Real-time stream updates (`StreamProvider` / Firestore snapshot stream) are not implemented. |
| **AC 4: View assigned technician info** | ✅ Done | Displayed in `_DetailRow` when `booking.assignedTechnicianName` is present. |
| **AC 5: Tenant security / Ownership isolation** | ⚠️ Partial | Firestore rules block unauthorized reads on the server, but the UI allows unauthorized viewers to see the details if navigated to; no access-denied UI guard or automated tests. |
| **AC 6: Reopen or refresh to view latest status** | ❌ Missing | No `RefreshIndicator` (pull-to-refresh) implemented on the tracking view. Cached state in `_currentBooking` prevents refreshed data from rendering. |

### Definition of Done (DoD) Status Matrix

| Definition of Done Requirement | Status | What Remains |
|---|:---:|---|
| **DoD 1: Timeline / Stepper UI** | ❌ Missing | Must build `BookingStatusStepper` using ServicePilot's **Blue Pipe** design system. |
| **DoD 2: Real-time or On-demand retrieval** | ❌ Missing | Add snapshot stream in `IBookingService` / `FirestoreBookingService` and pull-to-refresh. |
| **DoD 3: Status updates from providers displayed** | ⚠️ Partial | Basic text notice exists, but visual tracker does not dynamically animate/update on provider changes. |
| **DoD 4: Security access restrictions tested** | ❌ Missing | Write unit and widget tests verifying customer A cannot track customer B's booking. |
| **DoD 5: Status tracking widget & unit tests** | ❌ Missing | Existing tests only cover US-14 cancellation. Need dedicated tests for US-13. |
| **DoD 6: Peer review & demo ready** | ⏳ Pending | Follow the step-by-step instructions below. |

---

## 2. Architecture & Design System Guidelines

Before writing code, keep in mind ServicePilot's core design rules from [DESIGN.md](file:///e:/IDT-Gen11-Y3-SEG3/Project/ServicePilot/DESIGN.md):

1. **The Blue Pipe Metaphor:**
   - Completed milestones & reached joints: **Pipe Blue** (`AppTheme.primary`).
   - Active milestone waiting for provider/technician action: **Tape Yellow** (`AppTheme.accent`).
   - Upcoming milestones: White with Field Border outline (`AppTheme.fieldBorder`).
   - Terminal negative states (`Cancelled`, `Declined`): Red/Neutral warning node (`AppTheme.error`).
2. **The Khmer Room Rule & No Literals:**
   - Never hardcode strings in widgets. Add localized labels to `lib/l10n/app_en.arb` and `lib/l10n/app_km.arb`.
3. **No Card-in-Card Rule:**
   - Keep the layout flat with 16dp / 20dp gutters.

---

## 3. Step-by-Step Implementation Tasks for David

### Task 1: Build the Blue Pipe Timeline / Stepper Widget (`BookingStatusStepper`)

Create a new reusable widget: `lib/features/bookings/widgets/booking_status_stepper.dart`.

#### Happy Path Milestones:
```
1. Request Submitted (Pending)
   └─► 2. Booking Confirmed (Confirmed)
        └─► 3. Technician Assigned (Assigned)
             └─► 4. Repair In Progress (In Progress)
                  └─► 5. Repair Completed (Completed)
```

#### Cancelled / Declined Exceptions:
If the booking is `cancelled` or `declined`, replace the active step indicator with an alert node showing cancellation/declined info while preserving preceding completed steps.

#### Implementation Blueprint:
```dart
import 'package:flutter/material.dart';
import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/core/theme/app_theme.dart';

class BookingStatusStepper extends StatelessWidget {
  final BookingStatus status;

  const BookingStatusStepper({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    // 1. Define standard lifecycle milestones
    // 2. Render each milestone with Pipe Blue joint for completed,
    //    Tape Yellow joint for active, and hairline connecting pipes.
    // 3. Highlight terminal state (Cancelled / Declined) if applicable.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Service Progress', style: AppTheme.display(size: 16)),
          const SizedBox(height: 16),
          // Stepper Items...
        ],
      ),
    );
  }
}
```

---

### Task 2: Implement Real-Time Firestore Streaming in Services & Providers

#### 2.1 Update `IBookingService` (`lib/features/bookings/services/booking_service.dart`)
Add a stream contract to watch booking changes:
```dart
/// Emits real-time updates for a single booking document.
Stream<BookingModel?> watchBookingById(String bookingId);
```

#### 2.2 Implement in `BookingService` (In-Memory for Widget Tests)
Use a `StreamController` or `Stream.value`:
```dart
@override
Stream<BookingModel?> watchBookingById(String bookingId) {
  return Stream.periodic(const Duration(milliseconds: 100), (_) {
    return _bookings.cast<BookingModel?>().firstWhere(
      (b) => b?.id == bookingId,
      orElse: () => null,
    );
  }).distinct();
}
```

#### 2.3 Implement in `FirestoreBookingService` (`lib/features/bookings/services/firestore_booking_service.dart`)
```dart
@override
Stream<BookingModel?> watchBookingById(String bookingId) {
  return _bookings.doc(bookingId).snapshots().map((doc) {
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return BookingModel.fromFirestore(doc.id, data);
  });
}
```

#### 2.4 Add `StreamProvider` in `booking_provider.dart`
```dart
/// Emits live updates whenever the booking status changes in Firestore.
final liveBookingDetailProvider =
    StreamProvider.autoDispose.family<BookingModel?, String>((ref, bookingId) {
  final service = ref.watch(bookingServiceProvider);
  return service.watchBookingById(bookingId);
});
```

---

### Task 3: Upgrade `BookingTrackingScreen`

File: [booking_tracking_screen.dart](file:///e:/IDT-Gen11-Y3-SEG3/Project/ServicePilot/lib/features/bookings/screens/booking_tracking_screen.dart)

1. **Add Tenant Security Guard (AC 5):**
   Check ownership before rendering content:
   ```dart
   if (!booking.isOwnedBy(currentUserId)) {
     return Center(
       child: SpContentWidth(
         child: Padding(
           padding: const EdgeInsets.all(AppTheme.gutter),
           child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               const SpStatusHero(
                 key: Key('booking_access_denied_hero'),
                 icon: Icons.shield_outlined,
                 title: 'Access Restricted',
                 message: 'You are not authorized to view this booking record.',
                 tone: SpTone.danger,
               ),
               const SizedBox(height: 20),
               SpPrimaryButton(
                 label: 'Back to Home',
                 onPressed: () => context.go('/home/customer'),
               ),
             ],
           ),
         ),
       ),
     );
   }
   ```

2. **Add Pull-To-Refresh (`RefreshIndicator`) (AC 6):**
   Wrap the scroll view:
   ```dart
   RefreshIndicator(
     color: AppTheme.primary,
     onRefresh: () async {
       ref.invalidate(bookingDetailProvider(widget.bookingId));
       ref.invalidate(liveBookingDetailProvider(widget.bookingId));
     },
     child: SingleChildScrollView(
       physics: const AlwaysScrollableScrollPhysics(),
       ...
     ),
   )
   ```

3. **Integrate the `BookingStatusStepper` Widget:**
   Place the stepper directly below the status card and above the appointment details.

4. **Synchronize State:**
   Ensure `_currentBooking` gets updated when `liveBookingDetailProvider` emits a new status so provider updates reflect immediately.

---

### Task 4: Write Automated Tests (DoD 4 & DoD 5)

Create: `test/features/bookings/booking_status_tracking_test.dart`

Cover the following test cases:
1. **Stepper Displays Correct Milestones:**
   - Verify all steps for `Pending`, `Confirmed`, `Assigned`, `In Progress`, and `Completed`.
2. **Assigned Technician Details Displayed (AC 4):**
   - Verify technician name and icon appear when assigned.
3. **Data Isolation / Security Access Guard (AC 5):**
   - Attempt to open `bk-other-customer-99` as `customer-1`.
   - Verify `booking_access_denied_hero` appears and details are NOT revealed.
4. **Pull-to-refresh Updates Status (AC 6):**
   - Mutate booking in `BookingService` from `pending` to `confirmed`.
   - Trigger refresh on `RefreshIndicator` and verify updated status is rendered.

---

## 4. Verification & Definition of Done Checklist

Before submitting for PR review:
- [ ] Run `flutter analyze` — ensure **0 issues**.
- [ ] Run `flutter test test/features/bookings/booking_status_tracking_test.dart` — ensure **all tests pass**.
- [ ] Check both English (`app_en.arb`) and Khmer (`app_km.arb`) translations.
- [ ] Verify at 360dp width and 130% font scale per DESIGN.md.
