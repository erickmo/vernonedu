package auth

type LoginCommand struct {
	Email    string
	Password string
}

type RegisterCommand struct {
	Name     string
	Email    string
	Password string
}

type TokenPair struct {
	AccessToken  string
	RefreshToken string
}
