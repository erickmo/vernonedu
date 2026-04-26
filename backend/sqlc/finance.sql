-- name: GetPaymentByEnrollmentID :one
SELECT * FROM finance.payments WHERE enrollment_id = $1;

-- name: CreatePayment :one
INSERT INTO finance.payments (id, enrollment_id, payment_type, total_amount, paid_amount, status)
VALUES ($1, $2, $3, $4, $5, $6)
RETURNING *;

-- name: UpdatePaymentStatus :exec
UPDATE finance.payments SET status = $1, paid_amount = $2 WHERE id = $3;

-- name: ListOverduePaymentTerms :many
SELECT * FROM finance.payment_terms
WHERE status = 'unpaid' AND due_date < now()
ORDER BY due_date;

-- name: GetInvoiceByID :one
SELECT * FROM finance.invoices WHERE id = $1;

-- name: ListInvoicesByPartner :many
SELECT * FROM finance.invoices WHERE partner_id = $1 ORDER BY issued_date DESC;

-- name: UpdateInvoiceStatus :exec
UPDATE finance.invoices SET status = $1 WHERE id = $2;

-- name: ListBudgetItemsByBatch :many
SELECT * FROM finance.batch_budget_items WHERE course_batch_id = $1 ORDER BY created_at;
