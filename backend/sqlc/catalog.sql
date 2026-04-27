-- name: GetCourseByID :one
SELECT * FROM catalog.courses WHERE id = $1;

-- name: ListCoursesByDepartment :many
SELECT * FROM catalog.courses WHERE department_id = $1 ORDER BY name;

-- name: CreateCourse :one
INSERT INTO catalog.courses (id, name, department_id, course_creator_id, base_price, min_price, description, is_active, created_by)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
RETURNING *;

-- name: UpdateCourse :one
UPDATE catalog.courses
SET name = $2, base_price = $3, min_price = $4, description = $5, is_active = $6
WHERE id = $1
RETURNING *;

-- name: GetBatchByID :one
SELECT * FROM catalog.course_batches WHERE id = $1;

-- name: ListBatchesByCourse :many
SELECT * FROM catalog.course_batches WHERE course_id = $1 ORDER BY start_date DESC;

-- name: UpdateBatchStatus :exec
UPDATE catalog.course_batches SET status = $1 WHERE id = $2;

-- name: ListClassesByBatch :many
SELECT * FROM catalog.classes WHERE course_batch_id = $1 ORDER BY session_date, start_time;

-- name: GetModulesByCourseSorted :many
SELECT * FROM catalog.modules WHERE course_id = $1 AND is_active = TRUE ORDER BY "order";
