// Package post_scheduler periodically promotes scheduled marketing posts and
// PR schedule entries whose scheduled_at time has elapsed.
package post_scheduler

import (
	"context"
	"time"

	"github.com/jmoiron/sqlx"
	"github.com/rs/zerolog/log"
)

const (
	tickInterval = 1 * time.Minute

	// social_media_posts: status moves 'scheduled' -> 'posted' when due.
	updateSocialMediaPostsSQL = `
		UPDATE social_media_posts
		   SET status = 'posted',
		       updated_at = NOW()
		 WHERE status = 'scheduled'
		   AND scheduled_at <= NOW()`

	// pr_schedules: status moves 'scheduled' -> 'active' when due.
	updatePRSchedulesSQL = `
		UPDATE pr_schedules
		   SET status = 'active',
		       updated_at = NOW()
		 WHERE status = 'scheduled'
		   AND scheduled_at <= NOW()`
)

// Scheduler publishes due posts on a fixed tick interval.
type Scheduler struct {
	db *sqlx.DB
}

// New constructs a Scheduler.
func New(db *sqlx.DB) *Scheduler {
	return &Scheduler{db: db}
}

// Run blocks until ctx is cancelled. It runs publishDue every tickInterval.
func (s *Scheduler) Run(ctx context.Context) {
	log.Info().Dur("interval", tickInterval).Msg("post_scheduler: starting")
	// Run once on start so we don't wait a full tick after boot.
	s.publishDue(ctx)

	ticker := time.NewTicker(tickInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			log.Info().Msg("post_scheduler: stopped")
			return
		case <-ticker.C:
			s.publishDue(ctx)
		}
	}
}

// publishDue runs the UPDATE statements for each managed table. Errors are
// logged but do not stop the scheduler — the next tick will retry.
func (s *Scheduler) publishDue(ctx context.Context) {
	s.runUpdate(ctx, "social_media_posts", updateSocialMediaPostsSQL)
	s.runUpdate(ctx, "pr_schedules", updatePRSchedulesSQL)
}

func (s *Scheduler) runUpdate(ctx context.Context, table, query string) {
	res, err := s.db.ExecContext(ctx, query)
	if err != nil {
		log.Error().Err(err).Str("table", table).Msg("post_scheduler: update failed")
		return
	}
	rows, _ := res.RowsAffected()
	if rows > 0 {
		log.Info().Str("table", table).Int64("published", rows).Msg("post_scheduler: published due posts")
	}
}
