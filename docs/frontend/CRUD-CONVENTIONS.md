# Frontend CRUD Conventions

> Referensi pola implementasi domain CRUD baru. Pakai pola Partner (`portals/internal/pages/Partners.tsx`, `PartnerCreatePage.tsx`, `PartnerEditPage.tsx`, `detail/PartnerDetail.tsx`) sebagai template.

## File Layout

```
src/
├── portals/internal/pages/
│   ├── <Domain>s.tsx                ← list page
│   ├── <Domain>CreatePage.tsx       ← create form
│   ├── <Domain>EditPage.tsx         ← edit form
│   └── detail/
│       └── <Domain>Detail.tsx       ← detail (read-only + Edit button)
├── schemas/
│   └── <domain>.ts                  ← zod schema + TS type
├── types/
│   └── <domain>.ts                  ← API response types
└── lib/api/
    └── <bucket>.ts                  ← react-query hooks (use<Domain>List, use<Domain>, use<Domain>Mutations)
```

## Routing

Daftarkan di `src/App.tsx` di blok `/internal`. **PENTING:** route `/new` dan `/edit` HARUS sebelum `/:id` (lihat commit `ec440578`):

```tsx
<Route path="<domains>" element={<DomainList />} />
<Route path="<domains>/new" element={<DomainCreatePage />} />
<Route path="<domains>/:id/edit" element={<DomainEditPage />} />
<Route path="<domains>/:id" element={<DomainDetail />} />
```

## Layout

- List: pakai `PageHeader` + `SearchInput` + `FilterTabs` + `DataTable`
- Create / Edit: pakai `StandardPageLayout` (`components/layout/StandardPageLayout`)
- Detail: pakai `DetailPageLayout` (`components/layout/DetailPageLayout`)

## Form

- Library: `react-hook-form` + `@hookform/resolvers/zod`
- Schema di `schemas/<domain>.ts`:
  ```ts
  import { z } from 'zod'
  export const createXSchema = z.object({ ... })
  export const updateXSchema = createXSchema.partial()
  export type CreateXInput = z.infer<typeof createXSchema>
  ```
- Field wrapper: `FormField` (dari `components/shared`) untuk label + error
- Primitive input: dari `components/ui/` (`Input`, `Select`, `Textarea`)

## Data Layer

- React Query 5
- Hook naming: `useXList(filters)`, `useX(id)`, `useCreateX()`, `useUpdateX()`, `useDeleteX()`
- Query key: `['<domain>', 'list', filters]`, `['<domain>', id]`
- Invalidate setelah mutation: list + single record

## Permission

- Tiap action butuh `canAccess(action, resource)` check
- Wrap tombol dengan `<RoleGate action="create" resource="<resource>">` atau cek manual di handler
- Permission matrix: `lib/auth/permissions.ts`

## Variation Policy

`StandardPageLayout` adalah default. Body bisa diganti untuk variasi (lihat spec roadmap §5):

| Variasi | Domain |
|---|---|
| Wizard multi-step | Approval, Delegation, Certificate revocation |
| Kanban | TalentPool pipeline |
| Calendar | BatchSchedule |
| Tree / hierarchy | OKR, CoA |
| Canvas grid | BMC |
| Table inline-edit | CoA, Facilitator levels, Holiday |
| Builder | CertificateTemplate, CMS Page |
| Report viewer | BS / PL / CF / GL / TB |

## Definition of Done per Domain

1. List + Detail + Create + Edit page
2. Schema + type + API hooks lengkap
3. Permission gate di tiap aksi destruktif
4. Empty / loading / error state ada
5. Manual smoke test didokumentasi di PR
6. Typecheck + lint + test pass

## Reference Implementation

Partner domain sudah lengkap:
- `src/portals/internal/pages/Partners.tsx`
- `src/portals/internal/pages/PartnerCreatePage.tsx`
- `src/portals/internal/pages/PartnerEditPage.tsx`
- `src/portals/internal/pages/detail/PartnerDetail.tsx`

Pelajari pola di file-file ini sebelum implementasi domain baru.
