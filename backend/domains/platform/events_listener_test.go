package platform_test

import (
	"context"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/platform"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	"github.com/vernonedu/vernonedu2/backend/internal/testdb"
)

func newListenerSvc(t *testing.T) (*platform.Service, events.Bus, *pgxpool.Pool) {
	t.Helper()
	pool := testdb.New(t)
	testdb.Truncate(t, pool, usersTable, templatesTable, notificationsTable, preferencesTable)
	repo := platform.NewRepository(pool)
	bus := events.NewBus(zap.NewNop())
	svc := platform.NewService(repo, bus, zap.NewNop(), nil, nil, nil)
	platform.RegisterSubscriptions(bus, svc)
	return svc, bus, pool
}

func countNotificationsByRecipient(t *testing.T, pool *pgxpool.Pool, rid uuid.UUID) int {
	t.Helper()
	var n int
	err := pool.QueryRow(context.Background(),
		`SELECT COUNT(*) FROM platform.notifications WHERE recipient_id=$1`, rid).Scan(&n)
	require.NoError(t, err)
	return n
}

func TestListener_EnrollmentConfirmed_NotifiesStudent(t *testing.T) {
	svc, bus, pool := newListenerSvc(t)
	ctx := context.Background()
	student := createUser(t, pool)

	_, err := svc.CreateTemplate(ctx, "enrollment.confirmed", platform.ChannelEmail, nil, "Enrolled in {{.course_title}}")
	require.NoError(t, err)

	require.NoError(t, bus.Publish(ctx, events.Event{
		Type: events.EnrollmentConfirmed,
		Payload: events.EnrollmentConfirmedPayload{
			EnrollmentID: uuid.New(),
			StudentID:    student,
			CourseTitle:  "Algebra 101",
		},
	}))

	assert.Equal(t, 1, countNotificationsByRecipient(t, pool, student))
	assert.Equal(t, 1, countNotifications(t, pool))
}

func TestListener_PaymentTermDue_NotifiesStudentAndAdmins(t *testing.T) {
	svc, bus, pool := newListenerSvc(t)
	ctx := context.Background()
	student := createUser(t, pool)
	a1 := createUser(t, pool)
	a2 := createUser(t, pool)

	_, err := svc.CreateTemplate(ctx, "payment.term.due", platform.ChannelEmail, nil, "Term due {{.due_date}} amount {{.amount}}")
	require.NoError(t, err)

	require.NoError(t, bus.Publish(ctx, events.Event{
		Type: events.PaymentTermDue,
		Payload: events.PaymentTermDuePayload{
			TermID:    uuid.New(),
			StudentID: student,
			AdminIDs:  []uuid.UUID{a1, a2},
			AmountDue: "100000",
			DueDate:   "2026-05-01",
		},
	}))

	assert.Equal(t, 3, countNotifications(t, pool))
	assert.Equal(t, 1, countNotificationsByRecipient(t, pool, student))
	assert.Equal(t, 1, countNotificationsByRecipient(t, pool, a1))
	assert.Equal(t, 1, countNotificationsByRecipient(t, pool, a2))
}

func TestListener_FacilitatorApproved_NotifiesCourseCreatorAndFacilitator(t *testing.T) {
	svc, bus, pool := newListenerSvc(t)
	ctx := context.Background()
	fac := createUser(t, pool)
	creator := createUser(t, pool)

	_, err := svc.CreateTemplate(ctx, "facilitator.approved", platform.ChannelEmail, nil, "Approved for {{.course_title}}")
	require.NoError(t, err)

	require.NoError(t, bus.Publish(ctx, events.Event{
		Type: events.FacilitatorApproved,
		Payload: events.FacilitatorEventPayload{
			FacilitatorID:   fac,
			CourseCreatorID: creator,
			CourseTitle:     "Calculus",
		},
	}))

	assert.Equal(t, 2, countNotifications(t, pool))
	assert.Equal(t, 1, countNotificationsByRecipient(t, pool, fac))
	assert.Equal(t, 1, countNotificationsByRecipient(t, pool, creator))
}

func TestListener_BadPayload_NoCrash_NoSends(t *testing.T) {
	svc, bus, pool := newListenerSvc(t)
	ctx := context.Background()

	// Template exists but payload type is wrong → handler should silently skip.
	_, err := svc.CreateTemplate(ctx, "user.welcome", platform.ChannelEmail, nil, "Hi {{.full_name}}")
	require.NoError(t, err)

	err = bus.Publish(ctx, events.Event{
		Type:    events.UserCreated,
		Payload: "not-a-payload-struct",
	})
	require.NoError(t, err)
	assert.Equal(t, 0, countNotifications(t, pool))
}
