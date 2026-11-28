# SCRUM-46 / US-15: View Repair Booking History — Implementation Guide
**Assignee:** YEAT David (`YD`)  
**Role:** Junior Developer  
**Sprint:** Sprint 2 (5 Story Points)  
**Feature Module:** `lib/features/bookings/`  
**Reference Design:** [DESIGN.md](file:///e:/IDT-Gen11-Y3-SEG3/Project/ServicePilot/DESIGN.md)

---

## 1. Executive Summary: Is SCRUM-46 / US-15 Completed?

> **Verdict: NOT STARTED (0% Completed).**  
> While the data queries (`getCustomerBookings`) and booking cards exist on Customer Home, the dedicated **Booking History Screen** (`/bookings/history`), tabs (`Active` vs. `Past`), empty states, router integration, and tests **have not been created yet**.

### Acceptance Criteria (AC) Status Matrix

| Acceptance Criteria | Status | What Needs to be Done |
|---|:---:|---|
| **AC 1: View a list of their bookings** | ❌ Missing | Create `BookingHistoryScreen` at `/bookings/history`. |
| **AC 2: Card displays service type, provider name, date & status tag** | ⚠️ Partial | Existing `_CustomerBookingCard` in `customer_home.dart` shows address instead of appointment date. Must show requested appointment date. |
| **AC 3: Select a booking to view full details** | ❌ Missing | Tapping a booking card in history must navigate to `/bookings/:bookingId` (Tracking screen). |
| **AC 4: Tabbed or grouped into Active vs. Past** | ❌ Missing | Implement TabBar with two tabs: **Active** (`pending`, `confirmed`, `assigned`, `in_progress`) and **Past** (`completed`, `cancelled`, `declined`). |
| **AC 5: Tenant Data Isolation** | ⚠️ Partial | Queries must be scoped to `customerId == currentUserId` (already supported by `customerBookingsProvider`). |
| **AC 6: Empty-state message** | ❌ Missing | Show a friendly empty-state (`SpNotice` or `SpStatusHero`) when a customer has no bookings in the Active or Past tabs. |

### Definition of Done (DoD) Status Matrix

| Definition of Done Requirement | Status | What Remains |
|---|:---:|---|
| **DoD 1: Tabbed history interface** | ❌ Missing | Build `BookingHistoryScreen` with `DefaultTabController` and 2 tabs. |
| **DoD 2: Database query filtered by `customerId`** | ✅ Ready | `customerBookingsProvider` already filters by `activeCustomerId`. |
| **DoD 3: Accurate styling & status badges** | ❌ Missing | Use `StatusBadge`, `AppTheme` card styling, and date formatting. |
| **DoD 4: Data access restrictions tested** | ❌ Missing | Write automated tests verifying customer isolation. |
| **DoD 5: Empty-state & history tests pass** | ❌ Missing | Create `test/features/bookings/booking_history_screen_test.dart`. |
| **DoD 6: Peer review & demo ready** | ⏳ Pending | Complete tasks below. |

---

## 2. Technical Architecture & Design System (DESIGN.md)

1. **Routing:**
   - Route path: `/bookings/history`
   - Navigation entry:
     - On [customer_home.dart](file:///e:/IDT-Gen11-Y3-SEG3/Project/ServicePilot/lib/shared/home/customer_home.dart), add a **"View all"** or **"History"** action next to *My repair bookings* that navigates to `/bookings/history`.
2. **Tab Segmentation:**
   - **Active Tab:** `BookingStatus.isActive` (`pending`, `confirmed`, `assigned`, `in_progress`).
   - **Past Tab:** `BookingStatus.isTerminal` (`completed`, `cancelled`, `declined`).
   *(Both helper getters `isActive` and `isTerminal` are already defined on `BookingStatus` in `booking_status.dart`!)*
3. **Card Presentation:**
   - Reusable `BookingHistoryCard`:
     - Service Title (Bold) + `StatusBadge` on the top row.
     - Service Provider Name.
     - Scheduled appointment date and time (formatted: `EEE, d MMM • h:mm a`).
     - Tapping calls `context.push('/bookings/${booking.id}', extra: booking)`.
4. **Empty State:**
   - Active tab empty: *"No active bookings right now."* + CTA *"Book a Service"*.
   - Past tab empty: *"No past bookings yet."*.

---

## 3. Step-by-Step Implementation Guide for David

### Task 1: Create `BookingHistoryScreen`
File: `lib/features/bookings/screens/booking_history_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:service_pilot/core/constants/booking_status.dart';
import 'package:service_pilot/core/theme/app_theme.dart';
import 'package:service_pilot/features/bookings/models/booking_model.dart';
import 'package:service_pilot/features/bookings/providers/booking_provider.dart';
import 'package:service_pilot/shared/widgets/sp_button.dart';
import 'package:service_pilot/shared/widgets/sp_layout.dart';
import 'package:service_pilot/shared/widgets/status_badge.dart';

class BookingHistoryScreen extends ConsumerWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(customerBookingsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.surface,
          elevation: 0,
          leading: SpBackButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home/customer');
              }
            },
          ),
          title: Text('Booking History', style: AppTheme.display(size: 18)),
          bottom: TabBar(
            indicatorColor: AppTheme.primary,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            labelStyle: AppTheme.text(size: 14.5, weight: FontWeight.w600),
            tabs: const [
              Tab(key: Key('booking_history_tab_active'), text: 'Active'),
              Tab(key: Key('booking_history_tab_past'), text: 'Past'),
            ],
          ),
        ),
        body: bookingsAsync.when(
          data: (bookings) {
            final activeBookings =
                bookings.where((b) => b.status.isActive).toList();
            final pastBookings =
                bookings.where((b) => b.status.isTerminal).toList();

            return TabBarView(
              children: [
                _BookingListView(
                  key: const Key('booking_history_list_active'),
                  bookings: activeBookings,
                  emptyMessage: 'You have no active repair bookings.',
                  emptyIcon: Icons.calendar_today_rounded,
                ),
                _BookingListView(
                  key: const Key('booking_history_list_past'),
                  bookings: pastBookings,
                  emptyMessage: 'You have no past repair history.',
                  emptyIcon: Icons.history_rounded,
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
          error: (err, _) => Center(
            child: SpNotice(
              icon: Icons.error_outline_rounded,
              message: 'Failed to load bookings: $err',
              tone: SpTone.danger,
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingListView extends StatelessWidget {
  final List<BookingModel> bookings;
  final String emptyMessage;
  final IconData emptyIcon;

  const _BookingListView({
    super.key,
    required this.bookings,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SpNotice(
                icon: emptyIcon,
                message: emptyMessage,
                tone: SpTone.neutral,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.gutter),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final dateFormatted = DateFormat(
          'EEE, d MMM yyyy • h:mm a',
        ).format(booking.preferredDateTime);

        return Material(
          color: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            side: const BorderSide(color: AppTheme.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('/bookings/${booking.id}', extra: booking),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          booking.serviceTitle,
                          style: AppTheme.display(size: 15.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(status: booking.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    booking.providerName,
                    style: AppTheme.text(
                      size: 13.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateFormatted,
                        style: AppTheme.text(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
```

---

### Task 2: Register Route in `app_router.dart`
File: [app_router.dart](file:///e:/IDT-Gen11-Y3-SEG3/Project/ServicePilot/lib/core/router/app_router.dart)

Add the route before `/bookings/:bookingId`:
```dart
GoRoute(
  path: '/bookings/history',
  builder: (_, __) => const BookingHistoryScreen(),
),
```

---

### Task 3: Add "View All" Entry Point on `CustomerHomeScreen`
File: [customer_home.dart](file:///e:/IDT-Gen11-Y3-SEG3/Project/ServicePilot/lib/shared/home/customer_home.dart)

Add a header row with a "View history" button:
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(
      l10n.discoveryHomeBookings,
      style: AppTheme.display(size: 18, color: AppTheme.browseInk),
    ),
    TextButton(
      key: const Key('home_view_booking_history_button'),
      onPressed: () => context.push('/bookings/history'),
      child: const Text('View history'),
    ),
  ],
),
```

---

### Task 4: Write Automated Widget Tests
Create: `test/features/bookings/booking_history_screen_test.dart`

Cover:
1. **Tabs segment correctly:** Active tab shows `pending`, `confirmed`, `assigned`, `in_progress`. Past tab shows `completed`, `cancelled`, `declined`.
2. **Card contents:** Shows title, provider name, formatted appointment date, and `StatusBadge`.
3. **Selection navigation:** Tapping card navigates to `/bookings/:bookingId`.
4. **Empty states:** Empty active tab displays empty message; empty past tab displays empty message.
5. **Data isolation:** Customer A only sees Customer A's bookings.

---

## 4. Definition of Done Checklist for David

- [ ] `BookingHistoryScreen` created with `Active` and `Past` tabs.
- [ ] Registered route `/bookings/history`.
- [ ] Connected from Customer Home.
- [ ] `flutter analyze` passes with **0 issues**.
- [ ] `flutter test test/features/bookings/booking_history_screen_test.dart` passes **100%**.
