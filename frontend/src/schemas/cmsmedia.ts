import { z } from 'zod'

export const uploadCmsMediaSchema = z.object({
  url: z.string().min(1, 'URL wajib').max(1000),
  file_name: z.string().min(1, 'File name wajib').max(255),
  file_type: z.string().min(1, 'File type wajib').max(100),
  file_size: z.number().int().min(0).optional().default(0),
})

export type UploadCmsMediaInput = z.infer<typeof uploadCmsMediaSchema>
