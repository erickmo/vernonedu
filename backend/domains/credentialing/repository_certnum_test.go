package credentialing

import (
	"context"
	"sync"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestNextCertificateNumber_PerYearAndZeroPadded(t *testing.T) {
	repo := newFakeCredRepo()
	ctx := context.Background()

	n1, err := repo.NextCertificateNumber(ctx, 2026)
	require.NoError(t, err)
	n2, err := repo.NextCertificateNumber(ctx, 2026)
	require.NoError(t, err)
	n3, err := repo.NextCertificateNumber(ctx, 2026)
	require.NoError(t, err)

	require.Equal(t, "VE-2026-00001", n1)
	require.Equal(t, "VE-2026-00002", n2)
	require.Equal(t, "VE-2026-00003", n3)

	n4, err := repo.NextCertificateNumber(ctx, 2027)
	require.NoError(t, err)
	require.Equal(t, "VE-2027-00001", n4)
}

func TestNextCertificateNumber_ConcurrentSafe(t *testing.T) {
	repo := newFakeCredRepo()
	ctx := context.Background()

	const goroutines = 10
	var wg sync.WaitGroup
	seen := sync.Map{}
	var mu sync.Mutex
	var dups int

	for i := 0; i < goroutines; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			n, err := repo.NextCertificateNumber(ctx, 2026)
			if err != nil {
				return
			}
			if _, loaded := seen.LoadOrStore(n, true); loaded {
				mu.Lock()
				dups++
				mu.Unlock()
			}
		}()
	}
	wg.Wait()
	require.Equal(t, 0, dups)
}
