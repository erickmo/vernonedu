export const FRONTEND_URL = 'http://localhost:5174' // main frontend app

export const LINKS = {
  register: `${FRONTEND_URL}/register`,
  login: `${FRONTEND_URL}/login`,
  verify: `${FRONTEND_URL}/certificate-verify`,
  talentPool: `${FRONTEND_URL}/talent-pool`,
} as const
