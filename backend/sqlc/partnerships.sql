-- name: GetPartnerByID :one
SELECT * FROM partnerships.partners WHERE id = $1 AND deleted_at IS NULL;

-- name: ListPartnersByStatus :many
SELECT * FROM partnerships.partners WHERE status = $1 AND deleted_at IS NULL ORDER BY name;

-- name: CreatePartner :one
INSERT INTO partnerships.partners (id, name, type, status, contact_name, contact_email, contact_phone, address, notes)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
RETURNING *;

-- name: GetActiveAgreementByPartner :one
SELECT * FROM partnerships.partnership_agreements
WHERE partner_id = $1 AND status = 'active';

-- name: ListAgreementsByPartner :many
SELECT * FROM partnerships.partnership_agreements WHERE partner_id = $1 ORDER BY created_at DESC;

-- name: GetFranchiseeByID :one
SELECT * FROM partnerships.franchisees WHERE id = $1 AND deleted_at IS NULL;

-- name: ListRoyaltyRecordsByAgreement :many
SELECT * FROM partnerships.royalty_payment_records
WHERE franchise_agreement_id = $1 ORDER BY period DESC;
