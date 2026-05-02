import { z } from 'zod'
import {
  PEMBELAJARAN_OPTIONS,
  INTERNSHIP_OPTIONS,
  CHARACTER_TEST_OPTIONS,
} from '@/types/failureconfig'

export const componentFailureConfigSchema = z.object({
  pembelajaran: z.enum(PEMBELAJARAN_OPTIONS),
  internship: z.enum(INTERNSHIP_OPTIONS),
  character_test: z.enum(CHARACTER_TEST_OPTIONS),
})

export type ComponentFailureConfigInput = z.infer<typeof componentFailureConfigSchema>

export const DEFAULT_FAILURE_CONFIG: ComponentFailureConfigInput = {
  pembelajaran: 'retry',
  internship: 'retry',
  character_test: 'retry',
}
