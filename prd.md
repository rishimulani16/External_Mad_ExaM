# Product Requirements Document (PRD): Smart Appointment Scheduling & Queue Management App

## 1. Product Vision
To provide a seamless, offline-first scheduling and queue management platform that eliminates long waiting times, prevents double bookings, and offers real-time queue visibility for both users and administrators across clinics, college offices, salons, and service centers.

## 2. User Roles and Main User Stories

### 2.1 User Roles
*   **Customer / User:** Individuals seeking to book a service or appointment.
*   **Admin / Provider:** Staff managing the service, controlling the queue, and handling appointments.

### 2.2 User Stories
*   **User:**
    *   As a User, I want to book an appointment by selecting a service, date, and time slot so that I can secure my spot.
    *   As a User, I want to see my current queue position and estimated wait time so I can manage my time effectively.
    *   As a User, I want to view my appointment status (Scheduled, In Progress, Completed, Cancelled).
    *   As a User, I want to book an appointment even when offline, knowing it will sync when my connection is restored.
*   **Admin:**
    *   As an Admin, I want to view all appointments for the day to prepare for incoming users.
    *   As an Admin, I want to advance the queue and mark appointments as "In Progress" or "Completed."
    *   As an Admin, I want to prevent double bookings and manage maximum slot capacities.
    *   As an Admin, I want to cancel or reschedule appointments if conflicts arise.
    *   As an Admin, I want to search and filter appointments by name, ID, date, status, or service type.

## 3. Feature List Mapped to User Stories

| Feature | Associated User Story | Description |
| :--- | :--- | :--- |
| **Appointment Booking** | User: Book appointment | Select name, service, date, time slot; generates unique Appointment ID. Validates past dates/invalid times. |
| **Live Queue Tracking** | User: See queue position | Displays current token, user's exact position, and estimated wait time. |
| **Offline Support** | User: Book offline | Uses Hive to store bookings locally; queues for background sync with Firebase upon reconnection. |
| **Admin Dashboard** | Admin: View/Manage appointments | Central hub to view daily schedule, advance queue, and change status (Scheduled/Progress/Completed). |
| **Conflict Detection** | Admin: Prevent double booking | Logic to block booking if a slot reaches maximum capacity or conflicts with another service. |
| **Search & Filter Engine** | Admin: Search/Filter | Query capabilities for finding specific users (by ID/Name) or grouping by status/date/service. |

## 4. Screen List and Navigation Flow

### Minimum 5 Key Screens:
1.  **Home / Dashboard Screen**
    *   *Navigation:* Entry point. Links to Booking, Status Check, or Admin Login.
2.  **Booking Form Screen**
    *   *Navigation:* From Home. Returns to Home or success confirmation upon completion.
3.  **Queue & Status Tracker Screen**
    *   *Navigation:* From Home or Post-Booking. Shows live queue, current token, and wait time.
4.  **Admin Appointments View Screen**
    *   *Navigation:* From Admin Login. Shows list of all appointments. Contains Search & Filter UI.
5.  **Admin Queue Control Screen**
    *   *Navigation:* Tap on appointment from Admin View. Allows changing status (Advance, Complete, Cancel).

## 5. Data Models

### 5.1 Appointment
*   `id`: String (Unique identifier)
*   `customerName`: String
*   `serviceTypeId`: String (Reference to ServiceType)
*   `date`: DateTime
*   `timeSlot`: String (e.g., "10:00 AM - 10:30 AM")
*   `status`: Enum (Scheduled, In Progress, Completed, Cancelled)
*   `queuePosition`: Integer (Nullable)
*   `estimatedWaitTime`: Integer (Minutes)
*   `isSynced`: Boolean (For offline tracking)
*   `createdAt`: DateTime

### 5.2 ServiceType
*   `id`: String
*   `name`: String (e.g., "General Checkup", "Haircut")
*   `averageDuration`: Integer (Minutes)
*   `maxCapacityPerSlot`: Integer

## 6. Queue Logic & Conflict Handling

### 6.1 Conflict Detection (Step-wise)
1.  **Input Verification:** Ensure selected date is not in the past and time slot is within business hours.
2.  **Slot Check:** Query existing appointments for the requested `date`, `timeSlot`, and `serviceTypeId`.
3.  **Capacity Validation:** Compare count of existing appointments against `ServiceType.maxCapacityPerSlot`.
4.  **Outcome:** If capacity is reached, throw a meaningful error ("Slot fully booked"). If valid, proceed to save.

### 6.2 Queue Management Logic
1.  **Position Assignment:** Appointments on a given day are sorted by `timeSlot` and `createdAt`.
2.  **Queue Advancement:** When an Admin marks the current active appointment as "Completed", the system identifies the next "Scheduled" appointment and updates its status to "In Progress".
3.  **Wait Time Calculation:** `(User Position in Queue - Current Active Position) * ServiceType.averageDuration`.

### 6.3 Offline Considerations for Logic
*   If booking offline, assign a temporary ID and a preliminary `queuePosition`.
*   Upon sync, the backend re-validates the conflict logic.
*   If an offline booking conflicts with a synced booking upon reconnection, update status to "Cancelled - Conflict" and notify the user via local UI alert to reschedule.

## 7. Offline-First Strategy

1.  **Local Storage (Hive):** All service types, past/current appointments, and queue states are cached locally using Hive boxes.
2.  **Read Operations:** The app primarily reads from Hive for immediate UI rendering (0ms latency).
3.  **Write Operations:**
    *   User creates an appointment -> Saved to Hive immediately (`isSynced = false`).
    *   Background Sync Manager listens for network connectivity.
    *   When online, pushes pending data to Firebase REST API / Firestore.
4.  **Conflict Resolution:** Last-write-wins or server-authoritative depending on the data type (Server is authoritative for Queue Position and Conflict Detection).

## 8. Tech Stack & Architecture

### 8.1 Technology Choices
*   **Frontend:** Flutter
*   **State Management:** Riverpod
*   **Local Storage:** Hive (NoSQL, fast read/write for offline)
*   **Backend / Database:** Firebase Firestore

### 8.2 High-Level Architecture Diagram
```text
[ User Interface (Flutter) ]
          |
    (Riverpod Providers)
    |                  |
[ Hive ] <------> [ Sync Manager ]
(Local)                | (Network)
                       v
              [ Firebase Firestore ]
```

## 9. Milestones / Commits Mapping

*   **Milestone 1: Init & Setup**
    *   `init`: Create Flutter project, setup Hive, add Riverpod dependencies.
    *   `setup`: Define Data Models and basic folder structure.
*   **Milestone 2: UI Implementation**
    *   `ui`: Build Home, Booking Form, and Queue Tracker screens.
    *   `ui-admin`: Build Admin Dashboard and Queue Control screens.
*   **Milestone 3: Core Logic & State Management**
    *   `feat`: Implement Riverpod providers for booking validation.
    *   `feat`: Add Admin logic (Advance Queue, Status changes).
*   **Milestone 4: Offline-First & Sync**
    *   `feat`: Integrate Hive for local caching of appointments.
    *   `feat`: Implement network listener and Firebase sync logic.
*   **Milestone 5: Enhancements & Polish**
    *   `fix`: Conflict resolution edge cases and meaningful errors.
    *   `docs`: Finalize inline documentation and code cleanup.

## 10. Future Scope Ideas
*   **Push Notifications:** Alerts for "You are next in line" or status changes.
*   **Payment Gateway Integration:** Collect booking fees or service payments in-app.
*   **Multi-Branch Support:** Allow users to select different locations/branches.
*   **Analytics Dashboard:** Insights for Admins on peak hours and popular services.
