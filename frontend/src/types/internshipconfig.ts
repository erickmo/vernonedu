export interface InternshipConfig {
  id: string
  course_version_id: string
  partner_company_name: string
  partner_company_id?: string | null
  position_title: string
  duration_weeks: number
  supervisor_name: string
  supervisor_contact: string
  mou_document_url: string
  is_company_provided: boolean
}
