# Domain: Approvals

> Centralized approval workflow engine for all multi-step approvals in the system.

---

## Overview

Many operations in VernonEdu require approval from one or more parties. The approval system provides a generic workflow engine that handles:
- Multi-step sequential approvals
- Approval/rejection with comments
- Notification to all parties at each step
- Audit trail of all approval actions

---

## Approval Workflows

| # | Flow | Initiator | Approver(s) | Notes |
|---|------|-----------|-------------|-------|
| 1 | Assign Dept Leader | Education Leader | Director | — |
| 2 | Propose Course | Dept Leader / Course Creator | Education Leader | Course becomes available to sell once approved |
| 3 | Course Version Change | Course Owner | Dept Leader | New modules/sessions version |
| 4 | Create Batch (from operation) | Op Administrator | Course Creator → Op Leader → Dept Leader | 3-step sequential |
| 5 | Create Batch (from course creator) | Course Creator | Op Leader (schedule) + Dept Leader (final) | 2-step sequential |
| 6 | Batch pricing (within range) | Op Leader | — | Self-approved if within normal–min price range |
| 7 | Batch pricing override (outside range) | Dept Leader | — | Dept Leader can override pricing beyond range |
| 8 | Batch min/max student override | Op Leader | Dept Leader | — |
| 9 | Schedule location overlap | Op Admin / Course Creator | Op Leader | Allow double-booking a room |
| 10 | Revoke Certificate | Dept Leader | Education Leader → Director | Requires mandatory reason |

---

## Generic Approval Model

```
ApprovalRequest
  ├── id
  ├── type (enum: assign_dept_leader | propose_course | version_change | create_batch | ...)
  ├── entity_type + entity_id (what is being approved)
  ├── initiator_id → User
  ├── current_step (int)
  ├── total_steps (int)
  ├── status: pending | approved | rejected | cancelled
  ├── reason? (required for some types, e.g. revocation)
  ├── created_at
  └──< ApprovalStep
         ├── step_number
         ├── approver_id → User
         ├── approver_role
         ├── status: pending | approved | rejected
         ├── comment?
         └── acted_at?
```

---

## Behavior

1. **Request created** → first approver notified
2. **Step approved** → next approver notified (if more steps); if final step → entity status updated
3. **Step rejected** → entire request is rejected, initiator notified
4. **Request cancelled** → initiator can cancel before completion

---

## Routes

```
/approvals     → ApprovalPage (pending approvals queue for current user)
```

## API Endpoints (planned)

```
GET    /approvals              ?status=pending&approver_id=me
GET    /approvals/:id
POST   /approvals              body: {type, entityType, entityId, reason?}
PUT    /approvals/:id/approve  body: {comment?}
PUT    /approvals/:id/reject   body: {comment}
PUT    /approvals/:id/cancel
```

---

## Integration with Notifications

Every approval action triggers a notification:
- New approval request → notify approver
- Approved → notify initiator (+ next approver if multi-step)
- Rejected → notify initiator
- Cancelled → notify all involved

---

## Status

🔴 Not implemented — new domain for v2. Currently all actions are direct (no approval gate).
