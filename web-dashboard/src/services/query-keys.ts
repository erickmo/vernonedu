export const QK = {
  profile: 'profile',
  dashboardSummary: 'dashboard-summary',

  // Curriculum
  courses: 'courses',
  courseDetail: 'course-detail',
  courseTypes: 'course-types',
  courseTypeDetail: 'course-type-detail',
  courseVersions: 'course-versions',
  courseVersionDetail: 'course-version-detail',
  pendingVersions: 'pending-versions',
  courseModules: 'course-modules',
  internshipConfig: 'internship-config',
  characterTestConfig: 'character-test-config',

  // Batches
  courseBatches: 'course-batches',
  courseBatchDetail: 'course-batch-detail',
  batchSchedules: 'batch-schedules',

  // Enrollment
  enrollments: 'enrollments',
  enrollmentSummary: 'enrollment-summary',

  // Students
  students: 'students',
  studentDetail: 'student-detail',

  // TalentPool
  talentPool: 'talentpool',

  // Certificates
  certificates: 'certificates',
  certificateTemplates: 'certificate-templates',

  // Departments
  departments: 'departments',
  departmentDetail: 'department-detail',

  // Finance
  transactions: 'transactions',
  invoices: 'invoices',
  invoiceDetail: 'invoice-detail',
  payables: 'payables',
  coa: 'coa',
  coaTree: 'coa-tree',
  bankAccounts: 'bank-accounts',
  balanceSheet: 'balance-sheet',
  profitLoss: 'profit-loss',
  cashFlow: 'cash-flow',
  ledger: 'ledger',
  trialBalance: 'trial-balance',
  financeRatios: 'finance-ratios',
  revenueAnalysis: 'revenue-analysis',
  costAnalysis: 'cost-analysis',
  batchProfit: 'batch-profit',
  cashForecast: 'cash-forecast',
  financeAlerts: 'finance-alerts',
  financeSuggestions: 'finance-suggestions',

  // HRM
  sdmList: 'sdm-list',
  sdmDetail: 'sdm-detail',
  hrmEmployees: 'hrm-employees',
  hrmEmployeeDetail: 'hrm-employee-detail',
  hrmAttendance: 'hrm-attendance',
  hrmAttendanceSummary: 'hrm-attendance-summary',
  hrmLeaves: 'hrm-leaves',
  hrmPayrollPeriods: 'hrm-payroll-periods',
  hrmPayrollPeriodDetail: 'hrm-payroll-period-detail',
  hrmPayrollItems: 'hrm-payroll-items',

  // Marketing
  marketingStats: 'marketing-stats',
  marketingPosts: 'marketing-posts',
  marketingPr: 'marketing-pr',
  referrals: 'referrals',

  // Leads
  leads: 'leads',
  leadDetail: 'lead-detail',

  // Partners
  partners: 'partners',

  // Branches
  branches: 'branches',

  // OKR
  okrObjectives: 'okr-objectives',

  // Investments
  investments: 'investments',

  // Delegations
  delegations: 'delegations',

  // CMS
  cmsPages: 'cms-pages',
  cmsArticles: 'cms-articles',
  cmsTestimonials: 'cms-testimonials',
  cmsFaq: 'cms-faq',
  cmsMedia: 'cms-media',

  // Notifications
  notifications: 'notifications',

  // Locations
  buildings: 'buildings',
  rooms: 'rooms',

  // Payments
  payments: 'payments',
} as const

export type QueryKeyValue = (typeof QK)[keyof typeof QK]
