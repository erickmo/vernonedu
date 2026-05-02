// Enrollment domain types — frontend mirror of api/internal/domain/enrollment.
// Backend POST /api/v1/enrollments accepts { student_id, course_batch_id }.
// Frontend list/detail responses also expose batch_id, status, payment_status.

export type EnrollmentStatus = 'pending' | 'confirmed' | 'dropped' | 'completed'

export type EnrollmentPaymentStatus = 'pending' | 'partial' | 'paid' | 'overdue'

export const ENROLLMENT_STATUSES: EnrollmentStatus[] = [
  'pending',
  'confirmed',
  'dropped',
  'completed',
]

export const ENROLLMENT_PAYMENT_STATUSES: EnrollmentPaymentStatus[] = [
  'pending',
  'partial',
  'paid',
  'overdue',
]

// Student app access toggle states. Backend endpoints are best-effort:
// POST /api/v1/enrollments/{id}/access/grant
// POST /api/v1/enrollments/{id}/access/revoke
export type AppAccessState = 'granted' | 'revoked' | 'unknown'
