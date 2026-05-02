export const PEMBELAJARAN_OPTIONS = ['retry', 'continue_no_cert', 'disqualified'] as const
export const INTERNSHIP_OPTIONS = ['retry', 'continue_no_cert', 'disqualified'] as const
export const CHARACTER_TEST_OPTIONS = ['retry', 'continue_no_talentpool', 'disqualified'] as const

export type PembelajaranAction = (typeof PEMBELAJARAN_OPTIONS)[number]
export type InternshipAction = (typeof INTERNSHIP_OPTIONS)[number]
export type CharacterTestAction = (typeof CHARACTER_TEST_OPTIONS)[number]

export interface ComponentFailureConfig {
  pembelajaran: PembelajaranAction
  internship: InternshipAction
  character_test: CharacterTestAction
}
