// Invoice domain types — mirrors api/v1/finance/invoices contract

export const INVOICE_STATUSES = [
  'draft',
  'sent',
  'paid',
  'overdue',
  'cancelled',
] as const

export type InvoiceStatus = (typeof INVOICE_STATUSES)[number]

export interface InvoiceLineItem {
  description: string
  quantity: number
  unit_price: number
  total: number
}

export interface Invoice {
  id: string
  number: string
  student_id?: string
  course_batch_id?: string
  enrollment_id?: string
  partner_id?: string
  items: InvoiceLineItem[]
  subtotal: number
  tax_amount: number
  total: number
  status: InvoiceStatus
  issued_date: string
  due_date: string
  paid_date?: string
  notes?: string
}

export interface InvoiceListFilters {
  status?: InvoiceStatus
  batch_id?: string
  student_id?: string
  page?: number
  limit?: number
}

export interface InvoiceListResponse {
  data: Invoice[]
  total: number
  page: number
  limit: number
}

export interface CreateInvoicePayload {
  student_id?: string
  course_batch_id?: string
  amount: number
  due_date: string
  items?: InvoiceLineItem[]
  notes?: string
}
