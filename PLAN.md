# ServicePilot — Project Plan

## 1. What It Is

ServicePilot is a Flutter mobile app where homeowners in Phnom Penh browse, book and track home repair, maintenance and cleaning services from independent workers and small service companies.

---

## 2. Who Uses It

| Role | Signs in? | Description |
|---|---|---|
| **Visitor** (any person) | No | Browses service categories, provider profiles and prices. Cannot book or manage anything. |
| **Homeowner** (customer) | Yes | Searches providers, adds fixed-price services to a cart, requests quotes, books a time, tracks job status and views booking history. |
| **Independent Provider** | Yes | Manages own profile and service listings, sets or quotes prices, accepts/rejects bookings, updates job status. |
| **Service Company** | Yes | Manages company profile and listings, receives bookings, assigns jobs to company technicians, tracks progress. |
| **Company Technician** | Yes | Receives assigned jobs from their company, updates job status. |
| **Admin** (owner: you) | Yes | Manages users, providers, service categories; reviews bookings and helps resolve problems. |

---

## 3. What Is In and What Is Out

### In (course prototype, Dec 2026)

- Service categories: plumbing, electrical, AC maintenance, appliance repair, home cleaning.
- Homeowner: browse categories and providers; view profiles, services and prices; add fixed-price services from **one** provider to a cart; request quotes for non-fixed-price services; add description and photos; enter address and preferred time; checkout (no real payment); track booking status; view history; contact provider via Telegram/Messenger link.
- Independent provider: manage profile and listings; set prices or send quotes; accept/reject bookings; manage appointments and update job status.
- Service company: manage company profile and listings; receive bookings; assign jobs to technicians; track progress and keep records.
- Admin: manage users, providers and categories; review bookings; help resolve problems.
- Quote flow: customer sends quote request with details/photos → provider sends price → customer approves before work starts.

### Out (explicitly excluded)

- Real KHQR payments and automatic payouts.
- Live GPS tracking.
- Automatic technician assignment.
- In-app messaging (customers use Telegram/Messenger).
- Multi-provider cart / cross-provider checkout.
- Advanced AI features.
- Full property-management tools.
- Funded warranties.
- Services outside scope: furniture assembly, pest control, mounting, moving, locksmith.

---

## 4. What It Keeps

### 4.1 User Account

| Field | Type | Limits |
|---|---|---|
| Full name | text | required; max 100 characters |
| Email | text | required; unique; valid email format |
| Phone number | text | required; valid Cambodian format (+855…) |
| Password | text | required; min 8 characters; stored hashed, never plain |
| Role | enum | one of: homeowner, independent_provider, company, company_technician, admin |
| Profile photo | image | optional; max 5 MB; JPEG/PNG |
| Created at | timestamp | auto-set |

### 4.2 Service Company Profile

| Field | Type | Limits |
|---|---|---|
| Company name | text | required; max 150 characters |
| Description | text | optional; max 1 000 characters |
| Logo | image | optional; max 5 MB; JPEG/PNG |
| Contact phone | text | required |
| Telegram / Messenger link | URL | optional; valid URL |
| Address / service area | text | required; max 300 characters |
| Owner (user) | reference | one company owner |

### 4.3 Independent Provider Profile

| Field | Type | Limits |
|---|---|---|
| Display name | text | required; max 100 characters |
| Bio / description | text | optional; max 1 000 characters |
| Profile photo | image | optional; max 5 MB; JPEG/PNG |
| Contact phone | text | required |
| Telegram / Messenger link | URL | optional; valid URL |
| Service area | text | required; max 300 characters |

### 4.4 Service Category

| Field | Type | Limits |
|---|---|---|
| Category name | text | required; unique; max 100 characters |
| Icon / image | image | optional; max 2 MB |
| Description | text | optional; max 500 characters |

### 4.5 Service Listing

| Field | Type | Limits |
|---|---|---|
| Title | text | required; max 150 characters |
| Description | text | required; max 2 000 characters |
| Category | reference | required; must exist |
| Provider | reference | required; the independent provider or company that owns this listing |
| Price | number | optional (null = quote required); ≥ 0; in USD |
| Price type | enum | `fixed` or `quote_required` |
| Photos | image[] | optional; max 5 images; each max 5 MB |
| Active | boolean | default true |
| Created at | timestamp | auto-set |

### 4.6 Cart

| Field | Type | Limits |
|---|---|---|
| Homeowner | reference | required |
| Provider | reference | required; **all items must belong to the same provider** |
| Items | list of service listings | at least 1 item to checkout |
| Total price | number | computed; sum of fixed-price items |

### 4.7 Booking

| Field | Type | Limits |
|---|---|---|
| Homeowner | reference | required |
| Provider | reference | required |
| Services | list of service listing refs | at least 1 |
| Address | text | required; max 500 characters |
| Preferred date & time | datetime | required; must be in the future |
| Status | enum | `pending` → `confirmed` → `in_progress` → `completed` / `cancelled` / `rejected` |
| Total price | number | ≥ 0; in USD |
| Description / notes | text | optional; max 2 000 characters |
| Photos | image[] | optional; max 5 images; each max 5 MB |
| Created at | timestamp | auto-set |
| Updated at | timestamp | auto-set on every change |

### 4.8 Quote Request

| Field | Type | Limits |
|---|---|---|
| Homeowner | reference | required |
| Service listing | reference | required; must be a `quote_required` listing |
| Description | text | required; max 2 000 characters |
| Photos | image[] | optional; max 5 images; each max 5 MB |
| Quoted price | number | set by provider; ≥ 0; in USD |
| Status | enum | `requested` → `quoted` → `approved` / `rejected` |
| Created at | timestamp | auto-set |

### 4.9 Job Assignment (company only)

| Field | Type | Limits |
|---|---|---|
| Booking | reference | required |
| Company | reference | required |
| Assigned technician | reference | required; must belong to that company |
| Assigned at | timestamp | auto-set |

---

## 5. Who May Do What

| Action | Visitor | Homeowner | Indep. Provider | Company | Technician | Admin |
|---|---|---|---|---|---|---|
| Browse categories & providers | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| View service listings & prices | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Sign up / sign in | ✅ | ✅ | ✅ | ✅ | ✅ | — |
| Add to cart & checkout | — | ✅ | — | — | — | — |
| Send quote request | — | ✅ | — | — | — | — |
| Approve / reject a quote | — | ✅ (own) | — | — | — | — |
| View own booking history | — | ✅ (own) | — | — | — | — |
| Manage own profile & listings | — | — | ✅ (own) | ✅ (own) | — | — |
| Set / update service prices | — | — | ✅ (own) | ✅ (own) | — | — |
| Send a quote price | — | — | ✅ (own) | ✅ (own) | — | — |
| Accept / reject booking | — | — | ✅ (own) | ✅ (own) | — | — |
| Update job status | — | — | ✅ (own) | ✅ (own) | ✅ (assigned) | — |
| Assign technician to job | — | — | — | ✅ (own) | — | — |
| Manage all users & providers | — | — | — | — | — | ✅ |
| Manage service categories | — | — | — | — | — | ✅ |
| Review / resolve any booking | — | — | — | — | — | ✅ |
| Delete a booking | — | — | — | — | — | ✅ |
| Delete a user account | — | — | — | — | — | ✅ |

- **"own"** = the record belongs to that user.
- **"assigned"** = the technician was assigned by their company.
- Homeowners **cannot** delete bookings; they can cancel a pending booking (status change, not deletion).
- Only Admin can permanently delete records.

---

## 6. Done When

Each check below maps to one decision above. A tester can verify each independently.

| # | Decision | Done-when check |
|---|---|---|
| 1 | It is a home-service booking mobile app | A tester opens the app on a phone, sees service categories, and can follow the flow from browse → cart → checkout without errors. |
| 2 | Visitors can browse without signing in | A tester who is **not** signed in can view categories, providers and prices. Attempting to add to cart or book redirects to the sign-in screen. |
| 3 | Homeowners sign in and book | A signed-in homeowner adds a fixed-price service to the cart, enters address and time, submits the booking, and sees it in booking history with status `pending`. |
| 4 | Quote flow works | A homeowner sends a quote request with description and photo → the provider sees it and sends a price → the homeowner approves → booking is created with the quoted price. |
| 5 | Cart is single-provider only | A homeowner with items from Provider A in the cart tries to add an item from Provider B → the app prevents it or asks to clear the cart first. |
| 6 | Provider accepts/rejects booking | A provider sees an incoming booking and can confirm or reject it; the homeowner sees the updated status. |
| 7 | Provider manages listings | A provider creates a new service listing with title, description, category, price and photo → it appears in the public browse view. The provider edits it → changes are visible. |
| 8 | Company assigns a technician | A company user assigns a confirmed booking to one of their technicians → the technician sees the assigned job and can update its status. |
| 9 | Job status updates end-to-end | A provider (or assigned technician) moves a booking through `confirmed` → `in_progress` → `completed` → the homeowner sees each status change. |
| 10 | Admin manages categories | Admin creates, edits and deletes a service category → changes are reflected in the public browse view. |
| 11 | Admin manages users | Admin can view, edit roles and delete user accounts. A deleted account can no longer sign in. |
| 12 | Admin reviews bookings | Admin can see all bookings and change their status (e.g., cancel a disputed booking). |
| 13 | Only admin can delete | A non-admin user has no delete button or API route for bookings/users. Attempting the API directly returns 403. |
| 14 | Data limits enforced | Submitting a service title longer than 150 characters, an image over 5 MB, or a password under 8 characters is rejected with a clear error message. |
| 15 | Excluded features are absent | There is no payment form, no GPS map, no in-app chat, no multi-provider cart, and no auto-assign button in the prototype. |

---

## Questions for Me

The following points are **not decided** in the Business Case or Charter. I need your answers before building.

1. **Backend & database** — Flutter is decided for the mobile app. What backend language/framework (Node/Express, Django, Laravel, Spring Boot…) and database (PostgreSQL, MySQL, MongoDB, Firebase…) should we use?
2. **Authentication method** — Email + password only? Or also Google / Facebook social login?
3. **Homeowner cancel policy** — Can a homeowner cancel a `confirmed` booking, or only a `pending` one? Is there any cancellation reason field?
4. **Company technician sign-up** — Does the company admin invite/create technician accounts, or do technicians sign up independently and get linked?
5. **Provider verification** — The Business Case mentions checking provider identity and experience. Should the prototype include an admin-approval step before a provider's profile goes live?
6. **Ratings and reviews** — The Business Case mentions "customer feedback." Should the prototype include a rating/review system for completed bookings?
7. **Notifications** — Should the app send email or push notifications for booking status changes, or is the prototype manual-check only?
8. **Multi-language** — Should the UI support both Khmer and English, or English only for the prototype?
9. **Image storage** — Should uploaded photos be stored locally on the server, or on a cloud service (e.g., AWS S3, Cloudinary)?
10. **Deployment target** — Where will the prototype be hosted for the course demo (e.g., Vercel, Railway, a university server, local only)?
