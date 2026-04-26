-- name: CreateEnrollment :one
INSERT INTO enrollment.enrollments
  (id, student_id, course_batch_id, format, mode, payer, partner_id, franchisee_id,
   price, final_price, voucher_id, credit_applied, payment_status, completion_status, source)
VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)
RETURNING *;

-- name: GetEnrollmentByID :one
SELECT * FROM enrollment.enrollments WHERE id = $1;

-- name: GetEnrollmentByStudentAndBatch :one
SELECT * FROM enrollment.enrollments
WHERE student_id = $1 AND course_batch_id = $2;

-- name: ListEnrollmentsByBatch :many
SELECT * FROM enrollment.enrollments WHERE course_batch_id = $1 ORDER BY created_at DESC;

-- name: UpdateEnrollmentCompletionStatus :exec
UPDATE enrollment.enrollments SET completion_status = $1 WHERE id = $2;

-- name: GetVoucherByCode :one
SELECT * FROM enrollment.vouchers WHERE code = $1 AND is_active = TRUE;

-- name: IncrementVoucherUsage :exec
UPDATE enrollment.vouchers SET used_count = used_count + 1 WHERE id = $1;
