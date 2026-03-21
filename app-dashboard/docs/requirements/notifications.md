# Domain: Notification Center

> Centralized notification system distributed across all apps based on user/role.

---

## Overview

Single notification center in the API that distributes notifications to the correct app and channel based on the user's role and preferences.

---

## Channels

| Channel | Description | Target |
|---------|-------------|--------|
| In-app | Bell icon / notification panel within each app | All apps |
| Push (FCM) | Mobile push notifications | app-mentors, app-student |
| Email | Email notifications | All users |
| WhatsApp / SMS | Messaging notifications | All users |

---

## Distribution Targets

| User Type | App(s) |
|-----------|--------|
| Staff (all roles) | `app-dashboard` |
| Facilitator | `app-dashboard` + `app-mentors` |
| Student | `app-student` + supporting apps (if enrolled) |

---

## Notification-Worthy Events

### Approvals
- Approval requested (to approver)
- Approval granted / rejected (to initiator)

### Enrollment & Batch
- Student enrolled in batch
- Batch status change (approved, active, completed)
- Schedule change / update

### Payment
- Invoice generated
- Payment received
- Payment overdue alert
- Access revoked due to non-payment

### Certificate
- Certificate issued
- Certificate revoked

### Access
- Supporting app access granted
- Supporting app access revoked

### Course
- New course approved and available
- Course batch available on website
- Course version updated

### General
- System announcements
- Batch reminders (upcoming session)

---

## Routes

```
/notifications     → NotificationPage (notification center / inbox)
```

---

## API Endpoints (planned)

```
GET    /notifications              ?offset, limit, read?, type?
GET    /notifications/unread-count
PUT    /notifications/:id/read
PUT    /notifications/read-all
POST   /notifications              (internal — triggered by events, not user-facing)
```

---

## Architecture Notes

- Notifications are **event-driven** — domain events (e.g. `EnrollmentCreatedEvent`, `CertificateRevokedEvent`) trigger notification creation via event handlers
- Each notification record stores: `recipientId, type, title, body, channel, metadata (JSON), readAt?, createdAt`
- Channel delivery (push, email, WhatsApp) is handled asynchronously by dedicated event handlers

---

## Status

🔴 Not implemented — new domain for v2.
