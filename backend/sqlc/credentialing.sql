-- name: GetCertificateByNumber :one
SELECT * FROM credentialing.student_certificates WHERE certificate_number = $1;

-- name: ListCertificatesByEnrollment :many
SELECT * FROM credentialing.student_certificates WHERE enrollment_id = $1;

-- name: CreateCertificate :one
INSERT INTO credentialing.student_certificates
  (id, enrollment_id, certificate_type_id, certificate_config_id, certificate_number, status, expires_at)
VALUES ($1, $2, $3, $4, $5, $6, $7)
RETURNING *;

-- name: UpdateCertificateStatus :exec
UPDATE credentialing.student_certificates SET status = $1 WHERE id = $2;

-- name: ListActiveCertificateTypes :many
SELECT * FROM credentialing.certificate_types WHERE is_active = TRUE ORDER BY name;

-- name: GetCertificateConfigsByCourse :many
SELECT * FROM credentialing.certificate_configs WHERE course_id = $1;

-- name: ListPendingActionRequests :many
SELECT * FROM credentialing.certificate_action_requests WHERE status = 'pending' ORDER BY created_at;
