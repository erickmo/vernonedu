// Business Model Canvas — 9 components.
export type BMCKey =
  | 'key_partners'
  | 'key_activities'
  | 'key_resources'
  | 'value_propositions'
  | 'customer_relationships'
  | 'channels'
  | 'customer_segments'
  | 'cost_structure'
  | 'revenue_streams'

export interface BMCComponent {
  key: BMCKey
  label: string
  content: string
  partner_count?: number
}

export interface BMCCanvas {
  id?: string
  components: BMCComponent[]
  updated_at?: string
}

export const BMC_COMPONENTS: { key: BMCKey; label: string; abbr: string }[] = [
  { key: 'key_partners', label: 'Key Partners', abbr: 'KP' },
  { key: 'key_activities', label: 'Key Activities', abbr: 'KA' },
  { key: 'key_resources', label: 'Key Resources', abbr: 'KR' },
  { key: 'value_propositions', label: 'Value Propositions', abbr: 'VP' },
  { key: 'customer_relationships', label: 'Customer Relationships', abbr: 'CR' },
  { key: 'channels', label: 'Channels', abbr: 'CH' },
  { key: 'customer_segments', label: 'Customer Segments', abbr: 'CS' },
  { key: 'cost_structure', label: 'Cost Structure', abbr: 'C$' },
  { key: 'revenue_streams', label: 'Revenue Streams', abbr: 'R$' },
]
