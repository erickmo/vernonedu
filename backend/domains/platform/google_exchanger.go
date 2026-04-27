package platform

import (
	"context"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
)

// googleCalendarScope grants read/write access to a user's Google Calendar.
const googleCalendarScope = "https://www.googleapis.com/auth/calendar"

// googleTokenExchanger is the production TokenExchanger backed by golang.org/x/oauth2.
type googleTokenExchanger struct {
	cfg *oauth2.Config
}

// NewGoogleTokenExchanger constructs a production TokenExchanger for Google
// Calendar OAuth. Returns nil when client credentials are not configured.
func NewGoogleTokenExchanger(clientID, clientSecret, redirectURL string) TokenExchanger {
	if clientID == "" || clientSecret == "" {
		return nil
	}
	return &googleTokenExchanger{
		cfg: &oauth2.Config{
			ClientID:     clientID,
			ClientSecret: clientSecret,
			RedirectURL:  redirectURL,
			Scopes:       []string{googleCalendarScope},
			Endpoint:     google.Endpoint,
		},
	}
}

func (g *googleTokenExchanger) AuthURL(state string) string {
	return g.cfg.AuthCodeURL(state, oauth2.AccessTypeOffline, oauth2.ApprovalForce)
}

func (g *googleTokenExchanger) Exchange(ctx context.Context, code string) (*OAuthTokens, error) {
	tok, err := g.cfg.Exchange(ctx, code)
	if err != nil {
		return nil, err
	}
	return &OAuthTokens{
		AccessToken:  tok.AccessToken,
		RefreshToken: tok.RefreshToken,
		ExpiresAt:    tok.Expiry,
	}, nil
}

func (g *googleTokenExchanger) Refresh(ctx context.Context, refreshToken string) (*OAuthTokens, error) {
	tok, err := g.cfg.TokenSource(ctx, &oauth2.Token{RefreshToken: refreshToken}).Token()
	if err != nil {
		return nil, err
	}
	return &OAuthTokens{
		AccessToken:  tok.AccessToken,
		RefreshToken: tok.RefreshToken,
		ExpiresAt:    tok.Expiry,
	}, nil
}
