# Sprint 6 — Plain-English Feature & QA Review Guide

This guide explains every task in **Sprint 6 ("Job progress and company dispatch")** in simple, non-technical language. Use it to quickly understand what each feature should do for real users and what to check when testing for bugs.

---

## Quick Map of Sprint 6

| Ticket | Feature Name | Owner | Status in Jira |
|---|---|---|---|
| **SCRUM-89** (`BOOK-4`) | View current appointments & job progress | THANG Saoly | Done |
| **SCRUM-90** (`BOOK-5`) | View completed & closed service records | THANG Saoly | Done |
| **SCRUM-91** (`WORK-1`) | Provider marks work as Started (`In Progress`) | HEM Eamsocheat | To Do |
| **SCRUM-92** (`WORK-2`) | Provider marks work as Completed | **YEAT David** | To Do |
| **SCRUM-198** (Bug) | Company technician login remembers their company | Taing Sothyvan | Done |
| **SCRUM-99** (`TEAM-1`) | Company assigns a technician to a booking | Taing Sothyvan | In Progress |
| **SCRUM-100** (`TECHJOB-1`) | Company technician views their assigned jobs | TIEK Chhunhour | To Do |
| **SCRUM-101** (`TECHJOB-2`) | Company technician starts an assigned job | KHENG Sokthearith | To Do |
| **SCRUM-102** (`TECHJOB-3`) | Company technician completes an assigned job | **YEAT David** | To Do |

---

## 1. Provider Schedule & History

### `SCRUM-89` (`BOOK-4`) · View Current Appointments & Job Progress
* **Owner:** THANG Saoly
* **Real-Life Story:** A technician or service company opens their app in the morning to see what repair jobs are coming up today and which ones are currently in progress.
* **What Should Happen:**
  * The provider sees a list of their **active jobs** (`Confirmed`, `Assigned`, or `In Progress`).
  * Each job shows the **appointment date/time** and **current status**.
  * If a service company assigned a staff technician to the job, the company admin sees **which technician** is assigned.
* **Bug Check (What Must Be Prevented):**
  * Provider A must **never** see jobs belonging to Provider B.

---

### `SCRUM-90` (`BOOK-5`) · View Completed & Closed Service Records
* **Owner:** THANG Saoly
* **Real-Life Story:** At the end of the week, a technician or company wants to look back at all the jobs they finished, cancelled, or declined.
* **What Should Happen:**
  * Opening **Service History** shows all past jobs (`Completed`, `Cancelled`, or `Declined`) with the service name, appointment time, and final status.
  * If there are no past jobs yet, the screen shows a friendly empty message instead of breaking or looking blank.
* **Bug Check (What Must Be Prevented):**
  * Active jobs (`Pending`, `Confirmed`, `In Progress`) should not clutter past history, and other providers' records must be hidden.

---

## 2. Provider Starting & Completing Work

### `SCRUM-91` (`WORK-1`) · Mark Authorized Provider Work as Started
* **Owner:** HEM Eamsocheat
* **Real-Life Story:** A technician arrives at the customer's house and begins repairing the problem. They tap a button so the customer knows work has started.
* **What Should Happen:**
  * On an eligible active booking, the independent technician or company admin taps **"Start Work"** (or similar).
  * The job changes to **"In Progress."**
  * The **homeowner** sees on their tracking screen that the job is now **"In Progress."**
* **Bug Check (What Must Be Prevented):**
  * Another provider cannot start someone else's job.
  * A **cancelled** booking cannot be started.
  * A quote-based job **without** the customer's recorded quote approval cannot be started.

---

### `SCRUM-92` (`WORK-2`) · Mark Authorized Provider Work as Completed *(Your Task #1)*
* **Owner:** **YEAT David**
* **Real-Life Story:** The technician finishes fixing the problem and packs up their tools. They tap one button to close the job.
* **What Should Happen:**
  * On a job that is currently **"In Progress,"** the independent technician or company admin taps **"Mark as Completed."**
  * The job changes to **"Completed"** and moves out of Active Jobs into **Past History**.
  * Both the **provider** and the **homeowner** see the job saved as **"Completed"** in their history.
* **Bug Check (What Must Be Prevented):**
  * Another provider cannot complete someone else's job.
  * A job that is **not** `"In Progress"` (for example: `Pending`, `Confirmed`, `Cancelled`, or already `Completed`) cannot be marked completed.

---

## 3. Company Dispatch & Technician Execution

### `SCRUM-198` (Bug Fix) · Technician Activation & Sign-In Preserves Company Membership
* **Owner:** Taing Sothyvan
* **Real-Life Story:** A company invites a staff technician. The technician activates their account and later logs in on a brand-new phone.
* **What Should Happen:**
  * Even on a fresh device, the app remembers that this user is a **Company Technician** belonging to that **specific company** (not reset to a regular customer).
* **Bug Check (What Must Be Prevented):**
  * A technician cannot switch themselves to another company, and expired or already-used invite links are rejected.

---

### `SCRUM-99` (`TEAM-1`) · Assign One Company Technician to a Booking
* **Owner:** Taing Sothyvan
* **Real-Life Story:** A service company receives a confirmed booking and picks one of their own technicians to go do the repair.
* **What Should Happen:**
  * The company admin opens an eligible company booking, picks a technician from **their own company's staff list**, and saves the assignment.
  * The assigned technician's name appears on the company booking, and the job becomes visible to that technician.
* **Bug Check (What Must Be Prevented):**
  * A company **cannot** assign a technician who works for a *different* company.
  * A **cancelled** booking cannot be assigned to a technician.

---

### `SCRUM-100` (`TECHJOB-1`) · View My Assigned Jobs
* **Owner:** TIEK Chhunhour
* **Real-Life Story:** A staff technician opens the app to see which jobs their company manager assigned to them today.
* **What Should Happen:**
  * When signed in as a **Company Technician**, they see a list of **only the jobs assigned to them**, including appointment time, service details, and current status.
* **Bug Check (What Must Be Prevented):**
  * Unassigned company jobs, jobs assigned to a *colleague*, and jobs from *other companies* must be completely inaccessible.

---

### `SCRUM-101` (`TECHJOB-2`) · Start My Assigned Job
* **Owner:** KHENG Sokthearith
* **Real-Life Story:** The assigned company technician reaches the customer's home and taps the button to start the job.
* **What Should Happen:**
  * The assigned technician marks their job **"In Progress."**
  * Both the **company admin** and the **homeowner** immediately see that the job is **"In Progress."**
* **Bug Check (What Must Be Prevented):**
  * A technician who is **not** assigned to that job cannot start it.
  * Cancelled jobs and unapproved quote jobs cannot be started.

---

### `SCRUM-102` (`TECHJOB-3`) · Complete My Assigned Job *(Your Task #2)*
* **Owner:** **YEAT David**
* **Real-Life Story:** The assigned company technician finishes the repair at the customer's home and marks the job as finished.
* **What Should Happen:**
  * The assigned technician marks their **"In Progress"** job as **"Completed."**
  * Both the **company admin** and the **homeowner** immediately see **"Completed"** in their history.
* **Bug Check (What Must Be Prevented):**
  * A different technician (not assigned to that booking) cannot complete it.
  * A job that is not currently **"In Progress"** cannot be completed.
