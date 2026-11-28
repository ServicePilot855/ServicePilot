# ServicePilot — UML Use Case Diagrams by User Role

This document provides individual UML-style Use Case diagrams for each of the **5 user roles** (`AppRole`) in the ServicePilot platform.

| # | Actor | `AppRole` | Primary Responsibility |
|---|---|---|---|
| 1 | **Customer** | `homeowner` | Discover providers, request quotes, book & track repairs |
| 2 | **Independent Technician** | `independentProvider` | Manage solo profile/offerings, quote & complete jobs |
| 3 | **Service Company** | `company` | Manage company offerings, quotes, bookings & dispatch technicians |
| 4 | **Company Technician** | `companyTechnician` | Activate invite, view assigned jobs, start & complete work |
| 5 | **Platform Admin** | `admin` | Review & approve pending provider applications |

---

## 1. Customer (`homeowner`)

```mermaid
flowchart LR
    Customer(["Customer"])

    subgraph SP["ServicePilot System"]
        UC1(["Register / Sign In / Reset Password"])
        UC2(["Browse Service Categories & Search Providers"])
        UC3(["View Provider Profile & Service Offerings"])
        UC4(["Add Fixed-Price Service to Cart & Book"])
        UC5(["Pick Appointment Date, Time & Map Location"])
        UC6(["Submit Quote Request with Photos"])
        UC7(["Review & Approve Quoted Price"])
        UC8(["Book Appointment from Approved Quote"])
        UC9(["Track Live Repair Booking Status"])
        UC10(["Cancel Eligible Booking"])
        UC11(["View Active & Past Booking History"])
    end

    Customer --- UC1
    Customer --- UC2
    Customer --- UC3
    Customer --- UC4
    Customer --- UC5
    Customer --- UC6
    Customer --- UC7
    Customer --- UC8
    Customer --- UC9
    Customer --- UC10
    Customer --- UC11

    UC4 -. "«include»" .-> UC5
    UC8 -. "«include»" .-> UC7
```

---

## 2. Independent Technician (`independentProvider`)

```mermaid
flowchart LR
    Tech(["Independent Technician"])

    subgraph SP["ServicePilot System"]
        UC1(["Register & Submit Verification Profile"])
        UC2(["Sign In & Manage Availability"])
        UC3(["Update Public Profile & Coverage Areas"])
        UC4(["Publish Fixed-Price Service Offering"])
        UC5(["Publish Quote-Required Service Offering"])
        UC6(["View Incoming Booking Requests"])
        UC7(["Confirm or Decline Booking Request"])
        UC8(["View Incoming Quote Requests"])
        UC9(["Send Price Quote to Customer"])
        UC10(["View Homeowner Quote Decision"])
        UC11(["Mark Job In Progress & Completed"])
        UC12(["View Active Schedule & Past Service History"])
    end

    Tech --- UC1
    Tech --- UC2
    Tech --- UC3
    Tech --- UC4
    Tech --- UC5
    Tech --- UC6
    Tech --- UC7
    Tech --- UC8
    Tech --- UC9
    Tech --- UC10
    Tech --- UC11
    Tech --- UC12
```

---

## 3. Service Company (`company`)

```mermaid
flowchart LR
    Company(["Service Company Admin"])

    subgraph SP["ServicePilot System"]
        UC1(["Register Company & Submit Verification Details"])
        UC2(["Sign In to Company Portal"])
        UC3(["Update Company Profile & Contact Links"])
        UC4(["Publish Fixed-Price & Quote-Required Offerings"])
        UC5(["View Incoming Booking Requests"])
        UC6(["Confirm or Decline Company Bookings"])
        UC7(["View Incoming Quote Requests & Send Price"])
        UC8(["View Homeowner Quote Decision"])
        UC9(["Invite Company Technicians"])
        UC10(["Assign Eligible Booking to Company Technician"])
        UC11(["Mark Company Work In Progress & Completed"])
        UC12(["View Company Active Jobs & Past History"])
    end

    Company --- UC1
    Company --- UC2
    Company --- UC3
    Company --- UC4
    Company --- UC5
    Company --- UC6
    Company --- UC7
    Company --- UC8
    Company --- UC9
    Company --- UC10
    Company --- UC11
    Company --- UC12

    UC10 -. "«include»" .-> UC9
```

---

## 4. Company Technician (`companyTechnician`)

```mermaid
flowchart LR
    CoTech(["Company Technician"])

    subgraph SP["ServicePilot System"]
        UC1(["Activate Account via Company Invitation"])
        UC2(["Sign In with Verified Company Membership"])
        UC3(["View My Assigned Jobs"])
        UC4(["Inspect Job Appointment & Service Details"])
        UC5(["Start Assigned Job (Mark In Progress)"])
        UC6(["Complete Assigned Job (Mark Completed)"])
    end

    CoTech --- UC1
    CoTech --- UC2
    CoTech --- UC3
    CoTech --- UC4
    CoTech --- UC5
    CoTech --- UC6

    UC5 -. "«include»" .-> UC3
    UC6 -. "«include»" .-> UC5
```

---

## 5. Platform Admin (`admin`)

```mermaid
flowchart LR
    Admin(["Platform Admin"])

    subgraph SP["ServicePilot System"]
        UC1(["Sign In to Admin Dashboard"])
        UC2(["View Pending & Active Provider Counts"])
        UC3(["View Pending Provider Applications Queue"])
        UC4(["Inspect Technician or Company Application Details"])
        UC5(["Approve Pending Provider Account"])
        UC6(["View Approved Active Providers Directory"])
    end

    Admin --- UC1
    Admin --- UC2
    Admin --- UC3
    Admin --- UC4
    Admin --- UC5
    Admin --- UC6

    UC5 -. "«include»" .-> UC4
```
