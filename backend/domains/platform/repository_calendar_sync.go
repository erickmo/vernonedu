package platform

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

// GetCalendarSyncByUser returns the calendar_sync row for a user.
// Returns apperrors.ErrNotFound when no row exists.
func (r *repository) GetCalendarSyncByUser(ctx context.Context, userID uuid.UUID) (*CalendarSync, error) {
	query := `SELECT id, user_id, provider, access_token_enc, refresh_token_enc,
	                 token_expires_at, external_calendar_id, created_at, updated_at
	          FROM platform.calendar_sync WHERE user_id = $1`

	s := &CalendarSync{}
	err := r.pool.QueryRow(ctx, query, userID).Scan(
		&s.ID, &s.UserID, &s.Provider, &s.AccessTokenEnc, &s.RefreshTokenEnc,
		&s.TokenExpiresAt, &s.ExternalCalendarID, &s.CreatedAt, &s.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("platform.GetCalendarSyncByUser: %w", err)
	}
	return s, nil
}

// UpsertCalendarSync inserts or updates a calendar_sync row keyed by user_id.
func (r *repository) UpsertCalendarSync(ctx context.Context, s *CalendarSync) error {
	query := `
		INSERT INTO platform.calendar_sync
			(id, user_id, provider, access_token_enc, refresh_token_enc, token_expires_at, external_calendar_id)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		ON CONFLICT (user_id) DO UPDATE SET
			provider             = EXCLUDED.provider,
			access_token_enc     = EXCLUDED.access_token_enc,
			refresh_token_enc    = EXCLUDED.refresh_token_enc,
			token_expires_at     = EXCLUDED.token_expires_at,
			external_calendar_id = EXCLUDED.external_calendar_id,
			updated_at           = now()
		RETURNING id, created_at, updated_at`

	err := r.pool.QueryRow(ctx, query,
		s.ID, s.UserID, s.Provider, s.AccessTokenEnc, s.RefreshTokenEnc,
		s.TokenExpiresAt, s.ExternalCalendarID,
	).Scan(&s.ID, &s.CreatedAt, &s.UpdatedAt)
	if err != nil {
		return fmt.Errorf("platform.UpsertCalendarSync: %w", err)
	}
	return nil
}
