# Course Form Grouping Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reorganize `Course/CourseFormPage.tsx` flat field list into 3 FieldSection cards for clearer UX.

**Architecture:** Pure JSX reorganization — add `FieldSection` + `FieldRow` imports, wrap existing fields into 3 titled sections. Zero logic/state/API changes.

**Tech Stack:** React 18, TypeScript, CSS Modules, `@/widgets/FormPageTemplate` (FieldSection, FieldRow already exported)

---

### Task 1: Update imports + reorganize JSX

**Files:**
- Modify: `web-dashboard/src/pages/Course/CourseFormPage.tsx`

- [ ] **Step 1: Add FieldSection and FieldRow to imports**

In `CourseFormPage.tsx` line 6-10, change:
```tsx
import {
  FormPageTemplate,
  Field,
  FormGrid,
  FormColumn,
} from '@/widgets/FormPageTemplate'
```
to:
```tsx
import {
  FormPageTemplate,
  Field,
  FieldRow,
  FieldSection,
  FormGrid,
  FormColumn,
} from '@/widgets/FormPageTemplate'
```

- [ ] **Step 2: Replace tab content JSX**

Replace the entire `tabs` prop content (lines 188–292) with the grouped layout below:

```tsx
tabs={[
  {
    id: 'general',
    label: 'Informasi Umum',
    content: (
      <FormGrid>
        <FormColumn>
          <FieldSection title="Identitas Kursus">
            {!isEdit ? (
              <FieldRow>
                <Field
                  label="Kode Kursus"
                  required
                  error={errors.course_code}
                  hint="Kode unik, tidak bisa diubah setelah disimpan. Contoh: WD-001"
                  style={{ flex: '0 0 160px' }}
                >
                  <input
                    type="text"
                    value={courseCode}
                    onChange={(e) => setCourseCode(e.target.value)}
                    placeholder="cth. WD-001"
                    className={`${formStyles.input} ${errors.course_code ? formStyles.inputError : ''}`}
                    autoFocus
                  />
                </Field>
                <Field label="Nama Kursus" required error={errors.course_name} style={{ flex: 1 }}>
                  <input
                    type="text"
                    value={courseName}
                    onChange={(e) => setCourseName(e.target.value)}
                    placeholder="cth. Web Development Fundamentals"
                    className={`${formStyles.input} ${errors.course_name ? formStyles.inputError : ''}`}
                  />
                </Field>
              </FieldRow>
            ) : (
              <Field label="Nama Kursus" required error={errors.course_name}>
                <input
                  type="text"
                  value={courseName}
                  onChange={(e) => setCourseName(e.target.value)}
                  placeholder="cth. Web Development Fundamentals"
                  className={`${formStyles.input} ${errors.course_name ? formStyles.inputError : ''}`}
                  autoFocus
                />
              </Field>
            )}
            <Field label="Bidang Studi" required error={errors.field}>
              <SearchableSelect
                value={field}
                displayLabel={fieldLabel}
                placeholder="— Pilih Bidang Studi —"
                error={errors.field}
                fetchOptions={fetchFieldOptions}
                onSelect={(opt) => {
                  setField(opt?.value ?? '')
                  setFieldLabel(opt?.label ?? '')
                }}
              />
            </Field>
          </FieldSection>

          <FieldSection title="Organisasi & Konfigurasi">
            <FieldRow>
              <Field label="Departemen" style={{ flex: 1 }}>
                <SearchableSelect
                  value={departmentId}
                  displayLabel={departmentLabel}
                  placeholder="Cari departemen..."
                  fetchOptions={fetchDepartments}
                  onSelect={(opt) => {
                    setDepartmentId(opt?.value ?? '')
                    setDepartmentLabel(opt?.label ?? '')
                  }}
                />
              </Field>
              <Field label="Course Owner" style={{ flex: 1 }}>
                <SearchableSelect
                  value={ownerId}
                  displayLabel={ownerLabel}
                  placeholder="Cari course owner..."
                  fetchOptions={fetchOwners}
                  onSelect={(opt) => {
                    setOwnerId(opt?.value ?? '')
                    setOwnerLabel(opt?.label ?? '')
                  }}
                />
              </Field>
            </FieldRow>
            <Field label="URL Supporting App" hint="Opsional. Link ke aplikasi pendukung (contoh: app-entrepreneur).">
              <input
                type="url"
                value={supportingAppUrl}
                onChange={(e) => setSupportingAppUrl(e.target.value)}
                placeholder="https://..."
                className={formStyles.input}
              />
            </Field>
          </FieldSection>

          <FieldSection title="Konten Kurikulum">
            <Field label="Kompetensi Inti" hint="Ketik lalu tekan Enter untuk menambah.">
              <TagInput
                value={coreCompetencies}
                onChange={setCoreCompetencies}
                placeholder="cth. Problem Solving, Teamwork..."
              />
            </Field>
            <Field label="Deskripsi">
              <textarea
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Deskripsi singkat tentang kursus ini..."
                className={formStyles.input}
                rows={4}
                style={{ resize: 'vertical' }}
              />
            </Field>
          </FieldSection>
        </FormColumn>
        {sidebarContent}
      </FormGrid>
    ),
  },
]}
```

- [ ] **Step 3: Check FieldRow supports style prop**

Run:
```bash
grep -n "style\|className" /Users/erickmo/Desktop/Project/vernonedu2/web-dashboard/src/widgets/FormPageTemplate/FieldRow.tsx
grep -n "style\|className" /Users/erickmo/Desktop/Project/vernonedu2/web-dashboard/src/widgets/FormPageTemplate/Field.tsx | head -10
```

If `Field` does not accept `style` prop, remove `style` from Field wrappers and instead wrap each Field in a `<div style={{flex:'0 0 160px'}}>` / `<div style={{flex:1}}>`.

- [ ] **Step 4: TypeScript check**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | grep CourseFormPage
```
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add web-dashboard/src/pages/Course/CourseFormPage.tsx docs/superpowers/specs/2026-05-06-course-form-grouping-design.md docs/superpowers/plans/2026-05-06-course-form-grouping.md
git commit -m "feat(course-form): group fields into FieldSection cards for better UX"
```
