package module

import (
	"context"
	"time"

	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"go.uber.org/zap"
)

// Service handles module domain business logic.
type Service struct {
	repo Repository
	log  *zap.Logger
}

// NewService constructs module Service (FX-injectable).
func NewService(repo Repository, log *zap.Logger) *Service {
	return &Service{repo: repo, log: log}
}

// ─── CourseModule ─────────────────────────────────────────────────────────────

func (s *Service) CreateModule(ctx context.Context, courseID uuid.UUID, title string, order int, actorID uuid.UUID) (*CourseModule, error) {
	m := &CourseModule{
		ID:        uuid.New(),
		CourseID:  courseID,
		Title:     title,
		Order:     order,
		IsActive:  true,
		CreatedBy: actorID,
	}
	if err := s.repo.CreateModule(ctx, m); err != nil {
		return nil, err
	}
	return m, nil
}

func (s *Service) UpdateModule(ctx context.Context, moduleID uuid.UUID, title string, order int, isActive bool) (*CourseModule, error) {
	m, err := s.repo.GetModuleByID(ctx, moduleID)
	if err != nil {
		return nil, err
	}
	m.Title = title
	m.Order = order
	m.IsActive = isActive
	if err := s.repo.UpdateModule(ctx, m); err != nil {
		return nil, err
	}
	return m, nil
}

func (s *Service) GetModule(ctx context.Context, id uuid.UUID) (*CourseModule, error) {
	return s.repo.GetModuleByID(ctx, id)
}

func (s *Service) ListModules(ctx context.Context, courseID uuid.UUID) ([]*CourseModule, error) {
	return s.repo.ListModulesByCourse(ctx, courseID)
}

// AssertCourseOwner returns ErrForbidden unless actor is admin or is the course_creator who created the course.
func (s *Service) AssertCourseOwner(ctx context.Context, courseID, actorID uuid.UUID, role string) error {
	if role == "vernonedu_admin" {
		return nil
	}
	if role == "course_creator" {
		creatorID, err := s.repo.GetCourseCreatorID(ctx, courseID)
		if err != nil {
			return err
		}
		if creatorID == actorID {
			return nil
		}
	}
	return apperrors.ErrForbidden
}

// AssertClassAccess returns ErrForbidden unless actor is admin, the course_creator who owns the class's course, or the assigned facilitator.
func (s *Service) AssertClassAccess(ctx context.Context, classID, actorID uuid.UUID, role string) error {
	if role == "vernonedu_admin" {
		return nil
	}
	if role == "course_creator" {
		batchID, err := s.repo.GetClassBatchID(ctx, classID)
		if err != nil {
			return err
		}
		courseID, err := s.repo.GetBatchCourseID(ctx, batchID)
		if err != nil {
			return err
		}
		creatorID, err := s.repo.GetCourseCreatorID(ctx, courseID)
		if err != nil {
			return err
		}
		if creatorID == actorID {
			return nil
		}
	}
	if role == "facilitator" {
		instructorID, err := s.repo.GetClassInstructorID(ctx, classID)
		if err != nil {
			return err
		}
		if instructorID == actorID {
			return nil
		}
	}
	return apperrors.ErrForbidden
}

// AssertBatchCourseOwner returns ErrForbidden unless actor is admin, dept_leader, or course_creator who owns the batch's course.
func (s *Service) AssertBatchCourseOwner(ctx context.Context, batchID, actorID uuid.UUID, role string) error {
	if role == "vernonedu_admin" || role == "dept_leader" {
		return nil
	}
	if role == "course_creator" {
		courseID, err := s.repo.GetBatchCourseID(ctx, batchID)
		if err != nil {
			return err
		}
		creatorID, err := s.repo.GetCourseCreatorID(ctx, courseID)
		if err != nil {
			return err
		}
		if creatorID == actorID {
			return nil
		}
	}
	return apperrors.ErrForbidden
}

// ─── ModuleVersion ────────────────────────────────────────────────────────────

func (s *Service) CreateModuleVersion(ctx context.Context, moduleID uuid.UUID, title string, description *string, actorID uuid.UUID) (*ModuleVersion, error) {
	count, err := s.repo.CountVersionsByModule(ctx, moduleID)
	if err != nil {
		return nil, err
	}
	mv := &ModuleVersion{
		ID:            uuid.New(),
		ModuleID:      moduleID,
		VersionNumber: count + 1,
		Title:         title,
		Description:   description,
		Status:        ModuleDraft,
		CreatedBy:     actorID,
	}
	if err := s.repo.CreateModuleVersion(ctx, mv); err != nil {
		return nil, err
	}
	return mv, nil
}

func (s *Service) GetModuleVersion(ctx context.Context, id uuid.UUID) (*ModuleVersion, error) {
	return s.repo.GetModuleVersionByID(ctx, id)
}

func (s *Service) PublishVersion(ctx context.Context, moduleID, versionID uuid.UUID, actorID uuid.UUID) error {
	mv, err := s.repo.GetModuleVersionByID(ctx, versionID)
	if err != nil {
		return err
	}
	if mv.ModuleID != moduleID {
		return apperrors.ErrNotFound
	}
	if mv.Status != ModuleDraft {
		return apperrors.Validationf("only draft versions can be published")
	}
	if err := s.repo.ArchivePreviousPublished(ctx, moduleID); err != nil {
		return err
	}
	return s.repo.PublishVersion(ctx, versionID, actorID, time.Now())
}

// ─── ModuleAsset ──────────────────────────────────────────────────────────────

func (s *Service) CreateAsset(ctx context.Context, versionID uuid.UUID, title string, assetType AssetType, url string, sizeBytes *int64, order int, isDownloadable bool, actorID uuid.UUID) (*ModuleAsset, error) {
	a := &ModuleAsset{
		ID:              uuid.New(),
		ModuleVersionID: versionID,
		Title:           title,
		AssetType:       assetType,
		URL:             url,
		SizeBytes:       sizeBytes,
		Order:           order,
		IsDownloadable:  isDownloadable,
		CreatedBy:       actorID,
	}
	if err := s.repo.CreateAsset(ctx, a); err != nil {
		return nil, err
	}
	return a, nil
}

func (s *Service) UpdateAsset(ctx context.Context, assetID uuid.UUID, title string, assetType AssetType, url string, sizeBytes *int64, order int, isDownloadable bool) (*ModuleAsset, error) {
	a, err := s.repo.GetAssetByID(ctx, assetID)
	if err != nil {
		return nil, err
	}
	a.Title = title
	a.AssetType = assetType
	a.URL = url
	a.SizeBytes = sizeBytes
	a.Order = order
	a.IsDownloadable = isDownloadable
	if err := s.repo.UpdateAsset(ctx, a); err != nil {
		return nil, err
	}
	return a, nil
}

func (s *Service) DeleteAsset(ctx context.Context, assetID uuid.UUID) error {
	return s.repo.DeleteAsset(ctx, assetID)
}

func (s *Service) ListAssets(ctx context.Context, versionID uuid.UUID) ([]*ModuleAsset, error) {
	return s.repo.ListAssetsByVersion(ctx, versionID)
}

// ─── BatchModuleConfig ────────────────────────────────────────────────────────

func (s *Service) UpsertBatchModuleConfig(ctx context.Context, batchID, moduleID uuid.UUID, policy VersionPolicy, lockedVersionID *uuid.UUID, actorID uuid.UUID) (*BatchModuleConfig, error) {
	if policy == PolicyLocked && lockedVersionID == nil {
		return nil, apperrors.Validationf("locked_version_id required when policy is locked")
	}
	if policy == PolicyLocked && lockedVersionID != nil {
		lv, err := s.repo.GetModuleVersionByID(ctx, *lockedVersionID)
		if err != nil {
			return nil, err
		}
		if lv.ModuleID != moduleID || lv.Status != ModulePublished {
			return nil, apperrors.Validationf("locked_version_id must reference a published version of the same module")
		}
	}
	c := &BatchModuleConfig{
		ID:              uuid.New(),
		CourseBatchID:   batchID,
		ModuleID:        moduleID,
		VersionPolicy:   policy,
		LockedVersionID: lockedVersionID,
		SetBy:           actorID,
	}
	if err := s.repo.UpsertBatchModuleConfig(ctx, c); err != nil {
		return nil, err
	}
	return c, nil
}

func (s *Service) ListBatchModuleConfigs(ctx context.Context, batchID uuid.UUID) ([]*BatchModuleConfig, error) {
	return s.repo.ListBatchModuleConfigs(ctx, batchID)
}

// ─── ClassModuleCoverage ──────────────────────────────────────────────────────

func (s *Service) CreateCoverage(ctx context.Context, classID, moduleID uuid.UUID, notes *string, actorID uuid.UUID) (*ClassModuleCoverage, error) {
	c := &ClassModuleCoverage{
		ID:        uuid.New(),
		ClassID:   classID,
		ModuleID:  moduleID,
		Status:    CoveragePlanned,
		Notes:     notes,
		CreatedBy: actorID,
	}
	if err := s.repo.CreateCoverage(ctx, c); err != nil {
		return nil, err
	}
	return c, nil
}

func (s *Service) GetCoverage(ctx context.Context, id uuid.UUID) (*ClassModuleCoverage, error) {
	return s.repo.GetCoverageByID(ctx, id)
}

func (s *Service) ListCoverage(ctx context.Context, classID uuid.UUID) ([]*ClassModuleCoverage, error) {
	return s.repo.ListCoverageByClass(ctx, classID)
}

func (s *Service) MarkCovered(ctx context.Context, coverageID, actorID uuid.UUID, notes *string) (*ClassModuleCoverage, error) {
	c, err := s.repo.GetCoverageByID(ctx, coverageID)
	if err != nil {
		return nil, err
	}
	now := time.Now()
	c.Status = CoverageCovered
	c.CoveredBy = &actorID
	c.CoveredAt = &now
	c.Notes = notes
	if err := s.repo.UpdateCoverage(ctx, c); err != nil {
		return nil, err
	}
	return c, nil
}

func (s *Service) DeleteCoverage(ctx context.Context, id uuid.UUID) error {
	return s.repo.DeleteCoverage(ctx, id)
}

func (s *Service) AutoFlipPlannedToCovered(ctx context.Context, classID uuid.UUID) error {
	return s.repo.AutoFlipPlannedToCovered(ctx, classID, time.Now())
}

// ─── Progress ─────────────────────────────────────────────────────────────────

func (s *Service) GetBatchProgress(ctx context.Context, batchID uuid.UUID) (*BatchProgress, error) {
	return s.repo.GetBatchProgress(ctx, batchID)
}

// ─── Student Access ───────────────────────────────────────────────────────────

// ResolveStudentModules returns student-visible modules for an enrollment.
func (s *Service) ResolveStudentModules(ctx context.Context, enrollmentID, studentID uuid.UUID) ([]*StudentModuleView, error) {
	batchID, err := s.repo.GetEnrollmentBatchID(ctx, enrollmentID)
	if err != nil {
		return nil, err
	}
	enrolled, err := s.repo.IsStudentEnrolled(ctx, studentID, batchID)
	if err != nil {
		return nil, err
	}
	if !enrolled {
		return nil, apperrors.ErrForbidden
	}

	batchCourseID, err := s.repo.GetBatchCourseID(ctx, batchID)
	if err != nil {
		return nil, err
	}
	modules, err := s.repo.ListActiveModulesWithPublishedVersion(ctx, batchCourseID)
	if err != nil {
		return nil, err
	}

	configs, err := s.repo.ListBatchModuleConfigs(ctx, batchID)
	if err != nil {
		return nil, err
	}
	configMap := make(map[uuid.UUID]*BatchModuleConfig, len(configs))
	for _, cfg := range configs {
		configMap[cfg.ModuleID] = cfg
	}

	var out []*StudentModuleView
	for _, m := range modules {
		version, err := s.resolveVersion(ctx, m.ID, configMap)
		if err != nil {
			s.log.Warn("module: skipping module, no published version", zap.String("module_id", m.ID.String()))
			continue
		}
		assets, err := s.repo.ListAssetsByVersion(ctx, version.ID)
		if err != nil {
			s.log.Warn("module: failed to list assets", zap.String("version_id", version.ID.String()), zap.Error(err))
			assets = nil
		}
		out = append(out, &StudentModuleView{
			ModuleID:      m.ID,
			Title:         m.Title,
			Order:         m.Order,
			VersionID:     version.ID,
			VersionTitle:  version.Title,
			VersionNumber: version.VersionNumber,
			Assets:        assets,
		})
	}
	return out, nil
}

// ResolveStudentModule returns student-visible detail for a single module.
func (s *Service) ResolveStudentModule(ctx context.Context, enrollmentID, moduleID, studentID uuid.UUID) (*StudentModuleView, error) {
	batchID, err := s.repo.GetEnrollmentBatchID(ctx, enrollmentID)
	if err != nil {
		return nil, err
	}
	enrolled, err := s.repo.IsStudentEnrolled(ctx, studentID, batchID)
	if err != nil {
		return nil, err
	}
	if !enrolled {
		return nil, apperrors.ErrForbidden
	}

	m, err := s.repo.GetModuleByID(ctx, moduleID)
	if err != nil {
		return nil, err
	}
	if !m.IsActive {
		return nil, apperrors.ErrNotFound
	}

	configs, err := s.repo.ListBatchModuleConfigs(ctx, batchID)
	if err != nil {
		return nil, err
	}
	configMap := make(map[uuid.UUID]*BatchModuleConfig, len(configs))
	for _, cfg := range configs {
		configMap[cfg.ModuleID] = cfg
	}

	version, err := s.resolveVersion(ctx, moduleID, configMap)
	if err != nil {
		return nil, err
	}
	assets, err := s.repo.ListAssetsByVersion(ctx, version.ID)
	if err != nil {
		s.log.Warn("module: failed to list assets", zap.String("version_id", version.ID.String()), zap.Error(err))
		assets = nil
	}
	return &StudentModuleView{
		ModuleID:      m.ID,
		Title:         m.Title,
		Order:         m.Order,
		VersionID:     version.ID,
		VersionTitle:  version.Title,
		VersionNumber: version.VersionNumber,
		Assets:        assets,
	}, nil
}

func (s *Service) resolveVersion(ctx context.Context, moduleID uuid.UUID, configMap map[uuid.UUID]*BatchModuleConfig) (*ModuleVersion, error) {
	if cfg, ok := configMap[moduleID]; ok && cfg.VersionPolicy == PolicyLocked && cfg.LockedVersionID != nil {
		return s.repo.GetModuleVersionByID(ctx, *cfg.LockedVersionID)
	}
	return s.repo.GetLatestPublishedVersion(ctx, moduleID)
}
