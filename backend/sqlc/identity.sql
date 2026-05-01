-- name: GetUserByEmail :one
SELECT * FROM identity.users WHERE email = $1 AND is_active = TRUE;

-- name: GetUserByID :one
SELECT * FROM identity.users WHERE id = $1;

-- name: CreateUser :one
INSERT INTO identity.users (id, email, password_hash, role, is_active)
VALUES ($1, $2, $3, $4, $5)
RETURNING *;

-- name: DeactivateUser :exec
UPDATE identity.users SET is_active = FALSE WHERE id = $1;

-- name: GetStudentByUserID :one
SELECT * FROM identity.students WHERE user_id = $1;

-- name: CreateStudent :one
INSERT INTO identity.students (id, user_id, name, email, phone, source, partner_id)
VALUES ($1, $2, $3, $4, $5, $6, $7)
RETURNING *;

-- name: ListStudents :many
SELECT * FROM identity.students ORDER BY created_at DESC LIMIT $1 OFFSET $2;

-- name: GetTeamMemberByID :one
SELECT * FROM identity.team_members WHERE id = $1;

-- name: ListActiveFacilitatorsByDepartment :many
SELECT tm.*, fp.specialization, fp.bio
FROM identity.team_members tm
JOIN identity.facilitator_profiles fp ON fp.team_member_id = tm.id
WHERE tm.department_id = $1
  AND tm.is_facilitator = TRUE
  AND tm.employment_status = 'active';
