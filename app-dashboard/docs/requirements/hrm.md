# Domain: HRM (SDM)

> Human Resource Management — employee management for VernonEdu staff.

---

## Routes

```
/hrm                → HrmPage (employee list)
/hrm/:sdmId         → SdmDetailPage (employee detail)
```

## Cubits

- `SdmListCubit` — employee list
- `SdmDetailCubit` — employee detail

## Usecases

- `GetSdmListUseCase`
- `GetSdmDetailUseCase(id)`

## API Endpoints

```
GET /hrm/sdm        → list of employees
GET /hrm/sdm/:id    → employee detail
```

## Entities

| Entity | Key Fields |
|--------|------------|
| SdmEntity | id, employeeCode, name, email, phone, role, departmentId, departmentName, position, status, joinedAt |
| SdmDetailEntity | (above) + address, birthDate, educationLevel, skills[], certifications[], salaryGrade?, attendanceSummary |

## SdmDetailPage Tabs

Program, CV, Riwayat Kelas, Pembayaran, Evaluasi, Jadwal, Dokumen

## Widgets

`sdm_card.dart`, `sdm_profile_header_widget.dart`, `sdm_cv_tab_widget.dart`, `sdm_class_history_tab_widget.dart`, `sdm_payment_tab_widget.dart`, `sdm_evaluation_tab_widget.dart`, `sdm_schedule_tab_widget.dart`, `sdm_documents_tab_widget.dart`, `sdm_program_tab_widget.dart`

## Error Pattern Note

SDM datasource uses explicit `throw ServerFailure(...)` pattern (unlike other domains that let DioException propagate). Repository impl must catch `ServerFailure` not `DioException`.

---

## Status

✅ Functional — needs v2 update: multi-role per employee support, org chart alignment.
