# Laporan Audit Go: Entrepreneurship API

**Tanggal:** 2026-03-20
**Auditor:** AI (go-code-audit skill)
**Scope:** Seluruh project (`cmd/`, `internal/`, `infrastructure/`, `pkg/`)
**Go Version:** 1.25.0
**Module:** `github.com/vernonedu/entrepreneurship-api`

---

## Ringkasan

| Kategori | Status | Score |
|---|---|---|
| AI Compliance | ✅ | 10/10 |
| Error Handling | ⚠️ | 6/10 |
| Context & Concurrency | ❌ | 2/10 |
| Database Safety | ✅ | 9/10 |
| Architecture | ⚠️ | 6/10 |
| Security | ⚠️ | 6/10 |
| Code Style & Docs | ⚠️ | 5/10 |
| Testing | ❌ | 0/10 |
| **Overall** | ⚠️ | **5.5/10** |

---

## Temuan

### 🔴 Critical

#### [C-001] `context.Context` Tidak Ada di Semua Repository Methods
- **File:** `infrastructure/database/user_repository.go` (dan semua repository lain)
- **Baris:** 44, 56, 69, 78, 87, 96, 109
- **Masalah:** Semua method repository (`Save`, `Update`, `Delete`, `GetByID`, `GetByEmail`, `List`, `Search`) tidak menerima `context.Context`. DB query tidak dapat di-cancel jika request dibatalkan oleh client.
- **Dampak:** Goroutine leak potensial, query tetap berjalan meski client sudah disconnect, tidak bisa enforce request timeout per query.
- **Perbaikan:**
  ```go
  // Sebelum
  func (r *UserRepository) Save(u *user.User) error {
      _, err := r.db.Exec(query, ...)
  }

  // Sesudah
  func (r *UserRepository) Save(ctx context.Context, u *user.User) error {
      _, err := r.db.ExecContext(ctx, query, ...)
  }
  ```
  Domain interface di `internal/domain/user/user.go` juga harus diperbarui:
  ```go
  type WriteRepository interface {
      Save(ctx context.Context, u *User) error
      Update(ctx context.Context, u *User) error
      Delete(ctx context.Context, id uuid.UUID) error
  }

  type ReadRepository interface {
      GetByID(ctx context.Context, id uuid.UUID) (*User, error)
      GetByEmail(ctx context.Context, email string) (*User, error)
      List(ctx context.Context, offset, limit int) ([]*User, error)
      Search(ctx context.Context, name string, offset, limit int) ([]*User, error)
  }
  ```

---

#### [C-002] Business Logic di HTTP Handler (Pelanggaran Clean Architecture)
- **File:** `internal/delivery/http/auth_handler.go`
- **Baris:** 53–92 (Register), 112–153 (Login)
- **Masalah:** `AuthHandler.Register` melakukan bcrypt hashing dan user creation langsung—melewati CommandBus. Padahal `register_user.Handler` sudah ada dan sudah terdaftar di `main.go`. HTTP handler seharusnya hanya dispatch ke command/query bus.
- **Dampak:** Duplikasi logika bisnis, sulit ditest, melanggar aturan arsitektur CLAUDE.md ("HTTP Handler → hanya dispatch ke CommandBus/QueryBus").
- **Perbaikan:**
  ```go
  // Sebelum (auth_handler.go Register)
  hashBytes, err := bcrypt.GenerateFromPassword([]byte(req.Password), 12)
  // ... user creation langsung ...
  h.userWriteRepo.Save(newUser)

  // Sesudah — dispatch ke CommandBus
  type AuthHandler struct {
      cmdBus commandbus.CommandBus
      qryBus querybus.QueryBus
      jwtUtil *jwtutil.JWTUtil
  }

  func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request) {
      // ... decode request ...
      cmd := &register_user.RegisterUserCommand{
          Name:     req.Name,
          Email:    req.Email,
          Password: req.Password,
      }
      if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
          // handle error
          return
      }
      w.WriteHeader(http.StatusCreated)
      // ...
  }
  ```

---

#### [C-003] ValidationHook dan LoggingHook Tidak Pernah Ditambahkan ke CommandBus
- **File:** `cmd/api/main.go`
- **Baris:** 76–82 (CommandBus setup)
- **Masalah:** `pkg/hooks/command_hooks.go` mendefinisikan `ValidationHook` dan `LoggingHook`, dan CLAUDE.md menyatakan "Validation → Di CommandBus hook (SEBELUM handler execute)". Namun `AddHook` tidak pernah dipanggil di `main.go`, sehingga validasi struct tag (`validate:"required,email"`) pada semua command tidak pernah dijalankan.
- **Dampak:** Semua `validate` tag di command struct tidak berfungsi. Input user tidak divalidasi sebelum masuk handler.
- **Perbaikan:**
  ```go
  // Di main.go, setelah NewCommandBus():
  func(cb *commandbus.SimpleCommandBus) commandbus.CommandBus {
      cb.AddHook(hooks.NewValidationHook())
      cb.AddHook(hooks.NewLoggingHook())
      return cb
  },
  ```

---

#### [C-004] Zero Unit/Integration Tests
- **File:** Seluruh project
- **Masalah:** Tidak ada satu pun file `*_test.go` di seluruh project. Test coverage = 0%.
- **Dampak:** Tidak ada jaring pengaman untuk regression, refactor berbahaya, bug mudah lolos ke production.
- **Rekomendasi:** Prioritas test:
  1. Service/Command handlers (terutama `register_user`, `create_user`)
  2. HTTP handlers (auth endpoint)
  3. Repository (integration test dengan testcontainers)

---

#### [C-005] Default JWT Secret Tanpa Validasi di Production
- **File:** `infrastructure/config/config.go`
- **Baris:** 56
- **Masalah:** `viper.SetDefault("JWT_SECRET", "development-secret-change-in-production")` — jika environment variable tidak di-set, server berjalan dengan secret yang lemah dan diketahui publik.
- **Dampak:** Penyerang bisa forge JWT token valid di production jika `.env` tidak dikonfigurasi.
- **Perbaikan:**
  ```go
  // Setelah config.Load(), tambahkan validasi:
  func Load() (*Config, error) {
      // ... existing code ...
      cfg := &Config{...}

      // Validasi production secret
      if cfg.App.Env == "production" && cfg.App.JWTSecret == "development-secret-change-in-production" {
          return nil, fmt.Errorf("JWT_SECRET must be set in production environment")
      }

      return cfg, nil
  }
  ```

---

### 🟡 Warning

#### [W-001] `UserHandler.Create` Mengirim Command Tidak Lengkap
- **File:** `internal/delivery/http/user_handler.go`
- **Baris:** 34–55
- **Masalah:** `CreateUserRequest` hanya memiliki field `Name`, tapi `CreateUserCommand` memerlukan `Email`, `PasswordHash`, dan `Role`. Handler mengirim command dengan 3 field kosong.
  ```go
  // user_handler.go baris 45
  cmd := &create_user.CreateUserCommand{Name: req.Name}
  // Email, PasswordHash, Role kosong → validasi akan gagal
  ```
- **Dampak:** Endpoint `POST /api/v1/users` selalu gagal (jika ValidationHook aktif) atau menghasilkan data tidak valid (jika hook tidak aktif).

---

#### [W-002] Canvas dan DesignThinking Tidak Terdaftar di main.go
- **File:** `cmd/api/main.go`
- **Masalah:** Repository `canvas_repository.go` dan `designthinking_repository.go` sudah ada. Command/query handler untuk Canvas dan DesignThinking sudah ada di `internal/`. Namun keduanya tidak terdaftar di `registerHandlers` dan tidak ada di router.
- **Dampak:** Endpoint Canvas dan DesignThinking tidak berfungsi (route 404).

---

#### [W-003] Error Response Tidak Set Content-Type: application/json
- **File:** Semua HTTP handler
- **Masalah:** `http.Error(w, ...)` tidak secara otomatis set header `Content-Type: application/json`. Sukses response menggunakan `w.Header().Set("Content-Type", "application/json")` tapi error response tidak.
- **Dampak:** Client yang mengharapkan JSON dari semua response akan gagal parse error response.
- **Perbaikan:**
  ```go
  // Sebelum
  http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)

  // Sesudah
  w.Header().Set("Content-Type", "application/json")
  w.WriteHeader(http.StatusBadRequest)
  w.Write([]byte(`{"error":"invalid request body"}`))
  ```

---

#### [W-004] `viper.ReadInConfig()` Error Di-ignore
- **File:** `infrastructure/config/config.go`
- **Baris:** 68
- **Masalah:** `_ = viper.ReadInConfig()` — error di-ignore tanpa logging. Jika `.env` file tidak ada, server berjalan dengan default values tanpa peringatan apapun.
- **Perbaikan:**
  ```go
  if err := viper.ReadInConfig(); err != nil {
      log.Warn().Err(err).Msg("no .env file found, using environment variables and defaults")
  }
  ```

---

#### [W-005] Tidak Ada Rate Limiting di Auth Endpoints
- **File:** `internal/delivery/http/auth_handler.go`, `cmd/api/main.go`
- **Masalah:** Endpoint `POST /api/v1/auth/login` dan `POST /api/v1/auth/register` tidak memiliki rate limiting.
- **Dampak:** Rentan terhadap brute force attack untuk login dan account enumeration.
- **Rekomendasi:** Gunakan `github.com/go-chi/httprate` atau middleware rate limiting custom.

---

#### [W-006] Error Mapping di Handler Tidak Granular
- **File:** Semua HTTP handler
- **Masalah:** Semua error dari `cmdBus.Execute` / `qryBus.Execute` selalu di-map ke `500 Internal Server Error`. Domain errors seperti `ErrNotFound`, `ErrDuplicate` seharusnya menghasilkan `404` atau `409`.
- **Dampak:** Client tidak bisa membedakan "user tidak ditemukan" dari "server error".
- **Perbaikan:**
  ```go
  if err := h.cmdBus.Execute(r.Context(), cmd); err != nil {
      switch {
      case errors.Is(err, domain.ErrNotFound):
          http.Error(w, `{"error":"not found"}`, http.StatusNotFound)
      case errors.Is(err, domain.ErrDuplicate):
          http.Error(w, `{"error":"already exists"}`, http.StatusConflict)
      default:
          http.Error(w, `{"error":"internal server error"}`, http.StatusInternalServerError)
      }
      return
  }
  ```

---

### 🟢 Improvement

#### [I-001] `json.NewEncoder(w).Encode()` Error Tidak Dihandle
- **File:** Semua HTTP handler
- **Masalah:** Error dari `json.NewEncoder(w).Encode(...)` tidak di-check di manapun.
- **Perbaikan:**
  ```go
  if err := json.NewEncoder(w).Encode(resp); err != nil {
      log.Error().Err(err).Msg("failed to encode response")
  }
  ```

---

#### [I-002] HTTP Server Tidak Memiliki Timeout
- **File:** `cmd/api/main.go`
- **Baris:** 301–304
- **Masalah:** `http.Server` dibuat tanpa `ReadTimeout`, `WriteTimeout`, `IdleTimeout`.
- **Dampak:** Rentan terhadap slowloris attack.
- **Perbaikan:**
  ```go
  server := &http.Server{
      Addr:         ":" + cfg.App.HTTPPort,
      Handler:      r,
      ReadTimeout:  15 * time.Second,
      WriteTimeout: 30 * time.Second,
      IdleTimeout:  60 * time.Second,
  }
  ```

---

#### [I-003] `list_item` Query Handler Tidak Terdaftar
- **File:** `cmd/api/main.go`, `internal/query/list_item/handler.go`
- **Masalah:** Handler `list_item` ada tapi tidak terdaftar di query bus. Hanya `list_items_by_canvas` yang terdaftar.
- **Dampak:** Endpoint `GET /api/v1/items` tidak berfungsi.

---

#### [I-004] Token Refresh Endpoint Tidak Ada
- **File:** `internal/delivery/http/auth_handler.go`
- **Masalah:** `jwtutil.GenerateTokenPair` menghasilkan access + refresh token, tapi tidak ada endpoint untuk menukar refresh token menjadi access token baru.
- **Dampak:** Client harus login ulang setiap kali access token expired (24 jam).

---

#### [I-005] Exported Symbols Tidak Memiliki Godoc Comment
- **File:** `pkg/commandbus/commandbus.go`, `pkg/querybus/querybus.go`, `pkg/eventbus/eventbus.go`
- **Masalah:** Interface dan struct publik seperti `CommandBus`, `QueryBus`, `EventBus` tidak memiliki godoc comment.

---

## Rekomendasi Prioritas

### 1. Segera (Sprint ini)
| # | Temuan | File |
|---|--------|------|
| C-001 | Tambahkan `context.Context` ke semua repository method | `infrastructure/database/*.go` + `internal/domain/*/` |
| C-002 | Refactor `auth_handler.go` agar dispatch ke CommandBus | `internal/delivery/http/auth_handler.go` |
| C-003 | Tambahkan `ValidationHook` dan `LoggingHook` di `main.go` | `cmd/api/main.go` |
| C-005 | Tambahkan validasi JWT secret di production | `infrastructure/config/config.go` |
| W-001 | Perbaiki `CreateUserRequest` agar field lengkap | `internal/delivery/http/user_handler.go` |
| W-002 | Daftarkan Canvas & DesignThinking di main.go | `cmd/api/main.go` |

### 2. Sprint Berikutnya
| # | Temuan | File |
|---|--------|------|
| C-004 | Buat unit test untuk command handlers | `internal/command/**/*_test.go` |
| W-003 | Standarisasi error response dengan Content-Type JSON | Semua handler |
| W-006 | Granular error mapping di handler | Semua handler |
| I-002 | Tambahkan HTTP server timeouts | `cmd/api/main.go` |
| I-003 | Daftarkan `list_item` query handler | `cmd/api/main.go` |

### 3. Backlog
| # | Temuan |
|---|--------|
| W-005 | Implementasi rate limiting di auth endpoints |
| I-001 | Handle error dari `json.NewEncoder.Encode()` |
| I-004 | Buat token refresh endpoint |
| I-005 | Tambahkan godoc comment di exported symbols |
| W-004 | Log warning jika `.env` tidak ditemukan |

---

## Summary Temuan per Kategori

| Kategori | Critical | Warning | Improvement |
|---|---|---|---|
| Context & Concurrency | C-001 | — | — |
| Architecture | C-002, C-003 | W-001, W-002 | — |
| Security | C-005 | W-005 | — |
| Testing | C-004 | — | — |
| Error Handling | — | W-003, W-006 | I-001 |
| Config | — | W-004 | — |
| Features | — | — | I-003, I-004 |
| Code Style | — | — | I-005 |
| Performance | — | — | I-002 |

---

*Di-generate oleh AI (go-code-audit skill). Konfirmasi temuan oleh developer tetap disarankan.*
