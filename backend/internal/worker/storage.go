package worker

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/google/uuid"
)

// File system layout constants.
const (
	defaultCertStorageRoot = "./storage/certs"
	certFileExt            = ".pdf"
	storageDirPerm         = 0o755
	storageFilePerm        = 0o644
)

// CertStorage persists rendered certificate PDFs.
// TODO: swap for S3-backed implementation in production.
type CertStorage interface {
	Save(certID uuid.UUID, data []byte) (path string, err error)
	Load(path string) ([]byte, error)
}

type fsCertStorage struct {
	root string
}

// NewFSCertStorage returns a filesystem-backed CertStorage rooted at root.
// Pass empty string to use the default ./storage/certs path.
func NewFSCertStorage(root string) CertStorage {
	if root == "" {
		root = defaultCertStorageRoot
	}
	return &fsCertStorage{root: root}
}

func (s *fsCertStorage) Save(certID uuid.UUID, data []byte) (string, error) {
	if err := os.MkdirAll(s.root, storageDirPerm); err != nil {
		return "", fmt.Errorf("storage mkdir: %w", err)
	}
	path := filepath.Join(s.root, certID.String()+certFileExt)
	if err := os.WriteFile(path, data, storageFilePerm); err != nil {
		return "", fmt.Errorf("storage write: %w", err)
	}
	return path, nil
}

func (s *fsCertStorage) Load(path string) ([]byte, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("storage read: %w", err)
	}
	return data, nil
}
