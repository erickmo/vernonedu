# VernonEdu Web Landing Page — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a public-facing multi-page marketing website for VernonEdu in `/web` directory using React + Vite + Tailwind CSS.

**Architecture:** Standalone Vite React app in `/web`, separate from `/frontend`. React Router v6 for routing. Static TypeScript arrays in `src/data/` for all content (batches, partners, blog, testimonials, FAQs). Homepage composed from focused single-responsibility section components.

**Tech Stack:** React 18, Vite 5, TypeScript, Tailwind CSS v3, React Router v6, Vitest, @testing-library/react

---

## File Map

```
web/
├── index.html
├── package.json
├── vite.config.ts
├── tailwind.config.ts
├── postcss.config.js
├── tsconfig.json
├── tsconfig.node.json
└── src/
    ├── main.tsx
    ├── App.tsx                        ← router + layout shell
    ├── index.css                      ← Google Fonts import + Tailwind directives + keyframes
    ├── tokens.ts                      ← brand color/font constants (no Tailwind dependency)
    ├── data/
    │   ├── batches.ts                 ← BatchItem[]
    │   ├── partners.ts                ← string[]
    │   ├── testimonials.ts            ← Testimonial[]
    │   ├── features.ts                ← Feature[]
    │   ├── faqs.ts                    ← FaqItem[]
    │   └── blog-posts.ts              ← BlogPost[]
    ├── components/
    │   ├── layout/
    │   │   ├── Nav.tsx                ← sticky frosted-glass nav
    │   │   └── Footer.tsx             ← 4-col dark footer
    │   └── shared/
    │       ├── SectionHeader.tsx      ← eyebrow + title + optional "see all" link
    │       ├── BatchCard.tsx          ← single batch card with CTA
    │       └── BlogCard.tsx           ← blog card (featured or compact variant)
    └── pages/
        ├── Home/
        │   ├── index.tsx              ← assembles all sections
        │   ├── Hero.tsx
        │   ├── CertBand.tsx
        │   ├── PartnerList.tsx
        │   ├── CourseTicker.tsx
        │   ├── BatchSection.tsx       ← 3-card preview
        │   ├── FeaturesSection.tsx    ← 5 features + sticky B2B card
        │   ├── TestimonialSection.tsx
        │   ├── B2BSection.tsx
        │   ├── BlogPreviewSection.tsx ← 3-article preview
        │   ├── CtaBand.tsx
        │   └── FaqSection.tsx
        ├── Students.tsx
        ├── Partners.tsx
        ├── Batch.tsx                  ← full batch listing
        ├── Blog.tsx                   ← article index
        ├── BlogPost.tsx               ← single article
        └── About.tsx
```

---

## Task 1: Scaffold `/web` Vite Project

**Files:**
- Create: `web/package.json`
- Create: `web/vite.config.ts`
- Create: `web/tailwind.config.ts`
- Create: `web/postcss.config.js`
- Create: `web/tsconfig.json`
- Create: `web/tsconfig.node.json`
- Create: `web/index.html`

- [ ] **Step 1: Init Vite project**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2
npm create vite@latest web -- --template react-ts
cd web
```

- [ ] **Step 2: Install dependencies**

```bash
npm install react-router-dom
npm install -D tailwindcss postcss autoprefixer vitest @testing-library/react @testing-library/jest-dom @testing-library/user-event jsdom @vitejs/plugin-react
npx tailwindcss init -p
```

- [ ] **Step 3: Configure `web/vite.config.ts`**

```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/test-setup.ts'],
  },
})
```

- [ ] **Step 4: Create `web/src/test-setup.ts`**

```typescript
import '@testing-library/jest-dom'
```

- [ ] **Step 5: Configure `web/tailwind.config.ts`**

```typescript
import type { Config } from 'tailwindcss'

const config: Config = {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          50:  '#f8f0fd',
          100: '#edd5f8',
          200: '#d8a8f0',
          300: '#be79e4',
          400: '#a96bd0',
          500: '#9561ab',
          600: '#7a4e90',
          700: '#603c72',
          800: '#472a54',
          900: '#2e1a37',
          950: '#1a0d20',
        },
      },
      fontFamily: {
        sans: ['"Plus Jakarta Sans"', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
}

export default config
```

- [ ] **Step 6: Update `web/tsconfig.json`**

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "types": ["vitest/globals"]
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
```

- [ ] **Step 7: Verify scaffold runs**

```bash
cd web && npm run dev
```
Expected: Vite dev server starts at `http://localhost:5173`

- [ ] **Step 8: Commit**

```bash
git add web/
git commit -m "feat(web): scaffold vite react ts project with tailwind and vitest"
```

---

## Task 2: Brand Tokens + Global CSS

**Files:**
- Create: `web/src/tokens.ts`
- Modify: `web/src/index.css`

- [ ] **Step 1: Create `web/src/tokens.ts`**

```typescript
export const FRONTEND_URL = 'http://localhost:5174' // main frontend app

export const LINKS = {
  register: `${FRONTEND_URL}/register`,
  login: `${FRONTEND_URL}/login`,
  verify: `${FRONTEND_URL}/certificate-verify`,
  talentPool: `${FRONTEND_URL}/talent-pool`,
} as const
```

- [ ] **Step 2: Replace `web/src/index.css`**

```css
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:ital,wght@0,400;0,500;0,600;0,700;0,800;0,900;1,400;1,700&display=swap');

@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  body {
    font-family: 'Plus Jakarta Sans', system-ui, sans-serif;
    -webkit-font-smoothing: antialiased;
  }
}

@layer utilities {
  .ticker-track {
    animation: ticker 28s linear infinite;
    display: inline-flex;
  }

  @keyframes ticker {
    from { transform: translateX(0); }
    to   { transform: translateX(-50%); }
  }
}
```

- [ ] **Step 3: Write render test for tokens**

Create `web/src/tokens.test.ts`:

```typescript
import { LINKS } from './tokens'

it('LINKS.register points to frontend app', () => {
  expect(LINKS.register).toContain('/register')
})
```

- [ ] **Step 4: Run test**

```bash
cd web && npx vitest run src/tokens.test.ts
```
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add web/src/tokens.ts web/src/index.css web/src/tokens.test.ts
git commit -m "feat(web): add brand tokens and global css with ticker keyframe"
```

---

## Task 3: Static Data Files

**Files:**
- Create: `web/src/data/batches.ts`
- Create: `web/src/data/partners.ts`
- Create: `web/src/data/testimonials.ts`
- Create: `web/src/data/features.ts`
- Create: `web/src/data/faqs.ts`
- Create: `web/src/data/blog-posts.ts`

- [ ] **Step 1: Create `web/src/data/batches.ts`**

```typescript
export type DeliveryMode = 'online' | 'offline'

export interface BatchItem {
  id: string
  name: string
  batchNumber: number
  category: string
  mode: DeliveryMode
  emoji: string
  colorVariant: 'purple' | 'lavender' | 'rose'
  description: string
  startDate: string        // "15 Mei 2025"
  seatsLeft: number | null // null = "Masih tersedia"
}

export const BATCHES: BatchItem[] = [
  {
    id: 'english-batch-12',
    name: 'English for Professionals',
    batchNumber: 12,
    category: 'Bahasa',
    mode: 'online',
    emoji: '🗣️',
    colorVariant: 'purple',
    description: 'Komunikasi bisnis, presentasi, dan negosiasi dalam bahasa Inggris. 8 sesi intensif.',
    startDate: '15 Mei 2025',
    seatsLeft: 12,
  },
  {
    id: 'uiux-batch-7',
    name: 'UI/UX Design Fundamentals',
    batchNumber: 7,
    category: 'Desain',
    mode: 'offline',
    emoji: '🎨',
    colorVariant: 'lavender',
    description: 'Figma, user research, wireframing, dan prototyping dari nol. Cocok untuk pemula.',
    startDate: '20 Mei 2025',
    seatsLeft: 5,
  },
  {
    id: 'python-batch-5',
    name: 'Python for Data Analysis',
    batchNumber: 5,
    category: 'Teknologi',
    mode: 'online',
    emoji: '💻',
    colorVariant: 'rose',
    description: 'Pandas, NumPy, visualisasi data, dan studi kasus nyata dari industri.',
    startDate: '1 Juni 2025',
    seatsLeft: null,
  },
]
```

- [ ] **Step 2: Create `web/src/data/partners.ts`**

```typescript
export const PARTNERS: string[] = [
  'Universitas Indonesia',
  'Institut Teknologi Bandung',
  'Universitas Gadjah Mada',
  'Universitas Airlangga',
  'SMA Negeri 1 Jakarta',
  'SMKN 2 Surabaya',
  'MAN 1 Yogyakarta',
  'Politeknik Negeri Bandung',
]

export const COURSE_TICKER_ITEMS: string[] = [
  'BAHASA INGGRIS',
  'DESAIN GRAFIS',
  'PEMROGRAMAN',
  'PUBLIC SPEAKING',
  'AKUNTANSI',
  'DIGITAL MARKETING',
  'MATEMATIKA',
  'MUSIK',
  'BAHASA MANDARIN',
  'DATA ANALYST',
]
```

- [ ] **Step 3: Create `web/src/data/testimonials.ts`**

```typescript
export interface Testimonial {
  id: string
  quote: string
  name: string
  role: string
  featured: boolean
}

export const TESTIMONIALS: Testimonial[] = [
  {
    id: 't1',
    quote: 'Program-nya sangat relevan dengan industri. Saya dapat kerja di agency desain dua minggu setelah lulus — langsung lewat talent pool VernonEdu.',
    name: 'Rina Kusuma',
    role: 'Alumni Desain Grafis · Jakarta',
    featured: true,
  },
  {
    id: 't2',
    quote: 'Kerjasama B2B sangat fleksibel. Kurikulum disesuaikan dengan kebutuhan mahasiswa kami.',
    name: 'Dr. Hendra Wijaya',
    role: 'Dekan, Universitas Nusantara',
    featured: false,
  },
  {
    id: 't3',
    quote: 'Kelas batch English-nya sangat worth it. Langsung praktek dari sesi pertama.',
    name: 'Ayu Permata',
    role: 'Peserta Batch English · Bandung',
    featured: false,
  },
]
```

- [ ] **Step 4: Create `web/src/data/features.ts`**

```typescript
export interface Feature {
  id: string
  icon: string
  title: string
  description: string
}

export const FEATURES: Feature[] = [
  {
    id: 'curriculum',
    icon: '📋',
    title: 'Kurikulum Relevan Industri',
    description: 'Dirancang bersama praktisi, diperbarui secara berkala sesuai kebutuhan pasar kerja.',
  },
  {
    id: 'delivery',
    icon: '🌐',
    title: 'Online & Offline',
    description: 'Fleksibel belajar dari mana saja atau hadir langsung di cabang terdekat.',
  },
  {
    id: 'certification',
    icon: '🏆',
    title: 'Sertifikasi BNSP & SKKNI',
    description: 'Sertifikat terverifikasi digital berbasis standar nasional, diakui oleh industri dan mitra kami.',
  },
  {
    id: 'format',
    icon: '👤',
    title: 'Regular & Private Class',
    description: 'Pilih belajar dalam grup atau sesi 1-on-1 intensif sesuai kebutuhan Anda.',
  },
  {
    id: 'talent-pool',
    icon: '🎯',
    title: 'Talent Pool Alumni',
    description: 'Alumni VernonEdu masuk ke database talent pool kami — terhubung langsung dengan perusahaan mitra yang aktif mencari kandidat berkompeten.',
  },
]
```

- [ ] **Step 5: Create `web/src/data/faqs.ts`**

```typescript
export interface FaqItem {
  id: string
  question: string
  answer: string
}

export const FAQS: FaqItem[] = [
  {
    id: 'batch',
    question: 'Apa itu Kelas Batch?',
    answer: 'Kelas Batch adalah kelas terjadwal yang dibuka dalam periode tertentu. Peserta mendaftar sebelum batch dimulai, lalu belajar bersama dalam grup kecil dengan jadwal tetap.',
  },
  {
    id: 'talent-pool',
    question: 'Apa itu Talent Pool VernonEdu?',
    answer: 'Alumni VernonEdu yang telah menyelesaikan kursus dan mendapatkan sertifikat akan masuk ke database talent pool kami. Perusahaan mitra dapat mengakses pool ini untuk menemukan kandidat yang sudah terverifikasi kompetensinya.',
  },
  {
    id: 'certification',
    question: 'Sertifikasi apa yang dikeluarkan VernonEdu?',
    answer: 'VernonEdu mengeluarkan sertifikat berbasis SKKNI (Standar Kompetensi Kerja Nasional Indonesia) dan terakreditasi BNSP (Badan Nasional Sertifikasi Profesi). Semua sertifikat dapat diverifikasi secara digital.',
  },
  {
    id: 'online',
    question: 'Apakah kelas tersedia secara online?',
    answer: 'Ya, banyak kursus dan kelas batch tersedia online. Ketersediaan tergantung kursus — cek detail di halaman masing-masing program.',
  },
  {
    id: 'b2b',
    question: 'Bagaimana cara institusi mendaftar sebagai mitra?',
    answer: 'Isi form di halaman Mitra atau hubungi langsung tim partnership kami. Kami akan mengatur pertemuan untuk membahas kebutuhan institusi Anda.',
  },
]
```

- [ ] **Step 6: Create `web/src/data/blog-posts.ts`**

```typescript
export interface BlogPost {
  id: string
  slug: string
  category: string
  title: string
  excerpt: string
  date: string         // "12 April 2025"
  readMinutes: number
  emoji: string
  colorVariant: 'a' | 'b' | 'c'
  featured: boolean
  content: string      // plain text / markdown string for v1
}

export const BLOG_POSTS: BlogPost[] = [
  {
    id: 'bp1',
    slug: '5-skill-paling-dicari-2025',
    category: 'Tips Karier',
    title: '5 Skill yang Paling Dicari Perusahaan di 2025 — dan Cara Menguasainya',
    excerpt: 'Data terbaru dari LinkedIn dan Jobstreet menunjukkan pergeseran signifikan di dunia kerja. Skill teknis saja tidak cukup...',
    date: '12 April 2025',
    readMinutes: 5,
    emoji: '✍️',
    colorVariant: 'a',
    featured: true,
    content: 'Artikel lengkap tentang 5 skill yang paling dicari di 2025...',
  },
  {
    id: 'bp2',
    slug: 'kenapa-kelas-batch-lebih-efektif',
    category: 'Kelas Batch',
    title: 'Kenapa Kelas Batch Lebih Efektif dari Kursus Mandiri?',
    excerpt: 'Belajar bersama angkatan membuat progres lebih terstruktur dan konsisten...',
    date: '8 April 2025',
    readMinutes: 3,
    emoji: '🎓',
    colorVariant: 'b',
    featured: false,
    content: 'Artikel tentang keefektifan kelas batch...',
  },
  {
    id: 'bp3',
    slug: 'apa-itu-skkni',
    category: 'Sertifikasi',
    title: 'Apa Itu SKKNI dan Mengapa Penting untuk Karier Anda?',
    excerpt: 'Standar Kompetensi Kerja Nasional Indonesia menjadi acuan rekrutmen di banyak industri...',
    date: '2 April 2025',
    readMinutes: 4,
    emoji: '📊',
    colorVariant: 'c',
    featured: false,
    content: 'Artikel tentang SKKNI dan BNSP...',
  },
]
```

- [ ] **Step 7: Write data integrity tests**

Create `web/src/data/data.test.ts`:

```typescript
import { BATCHES } from './batches'
import { PARTNERS, COURSE_TICKER_ITEMS } from './partners'
import { TESTIMONIALS } from './testimonials'
import { FEATURES } from './features'
import { FAQS } from './faqs'
import { BLOG_POSTS } from './blog-posts'

it('BATCHES has exactly one featured per color variant', () => {
  const variants = BATCHES.map(b => b.colorVariant)
  expect(new Set(variants).size).toBe(BATCHES.length) // all unique
})

it('TESTIMONIALS has exactly one featured', () => {
  expect(TESTIMONIALS.filter(t => t.featured).length).toBe(1)
})

it('BLOG_POSTS has exactly one featured', () => {
  expect(BLOG_POSTS.filter(p => p.featured).length).toBe(1)
})

it('all blog post slugs are unique', () => {
  const slugs = BLOG_POSTS.map(p => p.slug)
  expect(new Set(slugs).size).toBe(slugs.length)
})

it('PARTNERS is non-empty', () => {
  expect(PARTNERS.length).toBeGreaterThan(0)
})

it('COURSE_TICKER_ITEMS is non-empty', () => {
  expect(COURSE_TICKER_ITEMS.length).toBeGreaterThan(0)
})

it('FEATURES has talent-pool entry', () => {
  expect(FEATURES.find(f => f.id === 'talent-pool')).toBeDefined()
})

it('FAQS has certification entry', () => {
  expect(FAQS.find(f => f.id === 'certification')).toBeDefined()
})
```

- [ ] **Step 8: Run tests**

```bash
cd web && npx vitest run src/data/data.test.ts
```
Expected: all PASS

- [ ] **Step 9: Commit**

```bash
git add web/src/data/ web/src/data/data.test.ts
git commit -m "feat(web): add static data files for batches, partners, blog, faqs, testimonials"
```

---

## Task 4: Shared Components

**Files:**
- Create: `web/src/components/shared/SectionHeader.tsx`
- Create: `web/src/components/shared/BatchCard.tsx`
- Create: `web/src/components/shared/BlogCard.tsx`

- [ ] **Step 1: Write failing tests**

Create `web/src/components/shared/SectionHeader.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import { SectionHeader } from './SectionHeader'

it('renders eyebrow and title', () => {
  render(<SectionHeader eyebrow="Kelas Batch" title={<>Kelas <em>Terjadwal</em></>} />)
  expect(screen.getByText('Kelas Batch')).toBeInTheDocument()
  expect(screen.getByText('Terjadwal')).toBeInTheDocument()
})

it('renders seeAll link when provided', () => {
  render(
    <SectionHeader
      eyebrow="Blog"
      title="Blog"
      seeAll={{ label: 'Lihat Semua', href: '/blog' }}
    />
  )
  expect(screen.getByRole('link', { name: /lihat semua/i })).toHaveAttribute('href', '/blog')
})
```

Create `web/src/components/shared/BatchCard.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { BatchCard } from './BatchCard'
import { BATCHES } from '../../data/batches'

const batch = BATCHES[0] // english-batch-12

it('renders batch name and number', () => {
  render(<BrowserRouter><BatchCard batch={batch} /></BrowserRouter>)
  expect(screen.getByText(/English for Professionals/i)).toBeInTheDocument()
  expect(screen.getByText(/Batch 12/i)).toBeInTheDocument()
})

it('renders start date', () => {
  render(<BrowserRouter><BatchCard batch={batch} /></BrowserRouter>)
  expect(screen.getByText(/15 Mei 2025/i)).toBeInTheDocument()
})

it('renders seats left when not null', () => {
  render(<BrowserRouter><BatchCard batch={batch} /></BrowserRouter>)
  expect(screen.getByText(/12 kursi tersisa/i)).toBeInTheDocument()
})

it('shows "Masih tersedia" when seatsLeft is null', () => {
  const batch = BATCHES[2] // python-batch-5 seatsLeft: null
  render(<BrowserRouter><BatchCard batch={batch} /></BrowserRouter>)
  expect(screen.getByText(/masih tersedia/i)).toBeInTheDocument()
})
```

Create `web/src/components/shared/BlogCard.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { BlogCard } from './BlogCard'
import { BLOG_POSTS } from '../../data/blog-posts'

it('renders blog title and category', () => {
  render(<BrowserRouter><BlogCard post={BLOG_POSTS[0]} /></BrowserRouter>)
  expect(screen.getByText(/5 Skill/i)).toBeInTheDocument()
  expect(screen.getByText('Tips Karier')).toBeInTheDocument()
})

it('renders read time', () => {
  render(<BrowserRouter><BlogCard post={BLOG_POSTS[0]} /></BrowserRouter>)
  expect(screen.getByText(/5 min/i)).toBeInTheDocument()
})
```

- [ ] **Step 2: Run tests — expect FAIL**

```bash
cd web && npx vitest run src/components/shared/
```
Expected: FAIL — components not defined

- [ ] **Step 3: Create `web/src/components/shared/SectionHeader.tsx`**

```tsx
import { ReactNode } from 'react'
import { Link } from 'react-router-dom'

interface SectionHeaderProps {
  eyebrow: string
  title: ReactNode
  seeAll?: { label: string; href: string }
}

export function SectionHeader({ eyebrow, title, seeAll }: SectionHeaderProps) {
  return (
    <div className="flex justify-between items-end mb-12">
      <div>
        <p className="text-xs font-bold tracking-[3px] uppercase text-brand-500 mb-2.5">
          {eyebrow}
        </p>
        <h2 className="text-4xl font-black tracking-tight text-brand-900 leading-tight">
          {title}
        </h2>
      </div>
      {seeAll && (
        <Link
          to={seeAll.href}
          className="text-sm font-semibold text-brand-500 flex items-center gap-1 hover:text-brand-700 whitespace-nowrap"
        >
          {seeAll.label} →
        </Link>
      )}
    </div>
  )
}
```

- [ ] **Step 4: Create `web/src/components/shared/BatchCard.tsx`**

```tsx
import { BatchItem } from '../../data/batches'
import { LINKS } from '../../tokens'

const COLOR_MAP = {
  purple:   'from-brand-50 to-brand-100',
  lavender: 'from-violet-50 to-violet-100',
  rose:     'from-pink-50 to-pink-100',
} as const

const MODE_BADGE: Record<string, string> = {
  online:  'bg-emerald-100 text-emerald-800',
  offline: 'bg-amber-100  text-amber-800',
}

interface BatchCardProps {
  batch: BatchItem
}

export function BatchCard({ batch }: BatchCardProps) {
  const seatsLabel = batch.seatsLeft !== null
    ? `${batch.seatsLeft} kursi tersisa`
    : 'Masih tersedia'

  return (
    <div className="border border-brand-100 rounded-2xl overflow-hidden hover:shadow-lg hover:-translate-y-1 transition-all duration-200 bg-white">
      {/* image area */}
      <div className={`h-40 flex items-center justify-center text-6xl bg-gradient-to-br ${COLOR_MAP[batch.colorVariant]}`}>
        {batch.emoji}
      </div>

      <div className="p-6">
        {/* tags */}
        <div className="flex gap-2 mb-3 flex-wrap">
          <span className="text-xs font-bold px-3 py-1 rounded-full bg-brand-50 text-brand-500">
            {batch.category}
          </span>
          <span className={`text-xs font-bold px-3 py-1 rounded-full ${MODE_BADGE[batch.mode]}`}>
            {batch.mode === 'online' ? 'Online' : 'Offline'}
          </span>
        </div>

        <h3 className="text-base font-black text-brand-900 mb-1 leading-tight">
          {batch.name} — Batch {batch.batchNumber}
        </h3>
        <p className="text-xs text-slate-500 leading-relaxed mb-5">{batch.description}</p>

        <div className="flex justify-between items-center mb-4">
          <p className="text-xs text-slate-400">
            Mulai <strong className="text-brand-900 font-bold">{batch.startDate}</strong>
          </p>
          <span className="text-xs font-bold text-brand-500 bg-brand-50 px-3 py-1 rounded-full">
            {seatsLabel}
          </span>
        </div>

        <a
          href={LINKS.register}
          className="block w-full py-2.5 bg-brand-500 text-white text-sm font-bold text-center rounded-xl hover:bg-brand-600 transition-colors"
        >
          Daftar Sekarang
        </a>
      </div>
    </div>
  )
}
```

- [ ] **Step 5: Create `web/src/components/shared/BlogCard.tsx`**

```tsx
import { Link } from 'react-router-dom'
import { BlogPost } from '../../data/blog-posts'

const THUMB_BG: Record<string, string> = {
  a: 'from-violet-100 to-purple-100',
  b: 'from-pink-100 to-rose-100',
  c: 'from-indigo-100 to-violet-100',
}

interface BlogCardProps {
  post: BlogPost
  featured?: boolean
}

export function BlogCard({ post, featured = false }: BlogCardProps) {
  return (
    <Link
      to={`/blog/${post.slug}`}
      className="block border border-brand-100 rounded-2xl overflow-hidden hover:shadow-md hover:-translate-y-0.5 transition-all duration-200 bg-white"
    >
      <div className={`flex items-center justify-center bg-gradient-to-br ${THUMB_BG[post.colorVariant]} ${featured ? 'h-60 text-6xl' : 'h-44 text-4xl'}`}>
        {post.emoji}
      </div>
      <div className="p-6">
        <p className="text-xs font-bold tracking-widest uppercase text-brand-500 mb-2">{post.category}</p>
        <h3 className={`font-black text-brand-900 leading-tight mb-2 ${featured ? 'text-xl' : 'text-base'}`}>
          {post.title}
        </h3>
        <p className="text-xs text-slate-500 leading-relaxed mb-4">{post.excerpt}</p>
        <div className="flex gap-4 text-xs text-slate-400">
          <span>{post.date}</span>
          <span>{post.readMinutes} min baca</span>
        </div>
      </div>
    </Link>
  )
}
```

- [ ] **Step 6: Run tests**

```bash
cd web && npx vitest run src/components/shared/
```
Expected: all PASS

- [ ] **Step 7: Commit**

```bash
git add web/src/components/shared/
git commit -m "feat(web): add shared components SectionHeader, BatchCard, BlogCard"
```

---

## Task 5: Nav + Footer Layout Components

**Files:**
- Create: `web/src/components/layout/Nav.tsx`
- Create: `web/src/components/layout/Footer.tsx`

- [ ] **Step 1: Write failing tests**

Create `web/src/components/layout/Nav.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { Nav } from './Nav'

it('renders logo text', () => {
  render(<BrowserRouter><Nav /></BrowserRouter>)
  expect(screen.getByText('Vernon')).toBeInTheDocument()
})

it('renders Kelas Batch nav link', () => {
  render(<BrowserRouter><Nav /></BrowserRouter>)
  expect(screen.getByRole('link', { name: /kelas batch/i })).toBeInTheDocument()
})

it('renders Blog nav link', () => {
  render(<BrowserRouter><Nav /></BrowserRouter>)
  expect(screen.getByRole('link', { name: /blog/i })).toBeInTheDocument()
})

it('renders Daftar Sekarang CTA', () => {
  render(<BrowserRouter><Nav /></BrowserRouter>)
  expect(screen.getByText(/daftar sekarang/i)).toBeInTheDocument()
})
```

Create `web/src/components/layout/Footer.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { Footer } from './Footer'

it('renders brand name', () => {
  render(<BrowserRouter><Footer /></BrowserRouter>)
  expect(screen.getAllByText(/vernonedu/i).length).toBeGreaterThan(0)
})

it('renders Talent Pool link', () => {
  render(<BrowserRouter><Footer /></BrowserRouter>)
  expect(screen.getByRole('link', { name: /talent pool/i })).toBeInTheDocument()
})

it('renders Verifikasi Sertifikat link', () => {
  render(<BrowserRouter><Footer /></BrowserRouter>)
  expect(screen.getByRole('link', { name: /verifikasi sertifikat/i })).toBeInTheDocument()
})
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd web && npx vitest run src/components/layout/
```

- [ ] **Step 3: Create `web/src/components/layout/Nav.tsx`**

```tsx
import { NavLink } from 'react-router-dom'
import { LINKS } from '../../tokens'

const NAV_LINKS = [
  { to: '/',        label: 'Beranda' },
  { to: '/batch',   label: 'Kelas Batch' },
  { to: '/partners',label: 'Mitra' },
  { to: '/blog',    label: 'Blog' },
  { to: '/about',   label: 'Tentang' },
]

export function Nav() {
  return (
    <nav className="fixed top-0 inset-x-0 z-50 flex justify-between items-center px-12 py-4 bg-white/85 backdrop-blur-md border-b border-brand-100">
      <NavLink to="/" className="text-[1.1rem] font-black tracking-tight text-brand-900">
        Vernon<span className="text-brand-500">Edu</span>
      </NavLink>

      <ul className="flex gap-8 list-none">
        {NAV_LINKS.map(link => (
          <li key={link.to}>
            <NavLink
              to={link.to}
              end={link.to === '/'}
              className={({ isActive }) =>
                `text-[0.82rem] font-semibold transition-colors ${isActive ? 'text-brand-900' : 'text-slate-400 hover:text-brand-500'}`
              }
            >
              {link.label}
            </NavLink>
          </li>
        ))}
      </ul>

      <a
        href={LINKS.register}
        className="bg-brand-500 text-white text-[0.8rem] font-bold px-5 py-2 rounded-full hover:bg-brand-600 transition-colors"
      >
        Daftar Sekarang
      </a>
    </nav>
  )
}
```

- [ ] **Step 4: Create `web/src/components/layout/Footer.tsx`**

```tsx
import { Link } from 'react-router-dom'
import { LINKS } from '../../tokens'

const LEARN_LINKS = [
  { label: 'Katalog Kursus', to: '/students' },
  { label: 'Kelas Batch',    to: '/batch' },
  { label: 'Kelas Private',  to: '/students#private' },
  { label: 'Talent Pool',    href: LINKS.talentPool },
  { label: 'Verifikasi Sertifikat', href: LINKS.verify },
]

const PARTNER_LINKS = [
  { label: 'Program Mitra',       to: '/partners' },
  { label: 'Hubungi Partnership', to: '/partners#contact' },
  { label: 'Akses Talent Pool',   href: LINKS.talentPool },
]

const COMPANY_LINKS = [
  { label: 'Tentang Kami',     to: '/about' },
  { label: 'Blog',             to: '/blog' },
  { label: 'Kontak',           to: '/about#contact' },
  { label: 'Kebijakan Privasi',to: '/privacy' },
]

type FooterLink = { label: string; to?: string; href?: string }

function FooterLink({ link }: { link: FooterLink }) {
  if (link.href) {
    return (
      <a href={link.href} className="block text-[0.8rem] text-white/40 hover:text-brand-200 transition-colors mb-2.5">
        {link.label}
      </a>
    )
  }
  return (
    <Link to={link.to!} className="block text-[0.8rem] text-white/40 hover:text-brand-200 transition-colors mb-2.5">
      {link.label}
    </Link>
  )
}

export function Footer() {
  return (
    <footer className="bg-brand-900">
      <div className="max-w-[1200px] mx-auto px-12 pt-16 pb-12 grid grid-cols-[2fr_1fr_1fr_1fr] gap-12">
        <div>
          <div className="text-[1.35rem] font-black text-white mb-3">
            Vernon<span className="text-brand-200">Edu</span>
          </div>
          <p className="text-[0.8rem] text-white/25 leading-relaxed max-w-[240px]">
            Pendidikan yang relevan, fleksibel, dan berdampak untuk semua kalangan di Indonesia.
          </p>
        </div>

        <div>
          <h5 className="text-[0.65rem] font-bold tracking-[2px] uppercase text-white/25 mb-5">Belajar</h5>
          {LEARN_LINKS.map(link => <FooterLink key={link.label} link={link} />)}
        </div>

        <div>
          <h5 className="text-[0.65rem] font-bold tracking-[2px] uppercase text-white/25 mb-5">Institusi</h5>
          {PARTNER_LINKS.map(link => <FooterLink key={link.label} link={link} />)}
        </div>

        <div>
          <h5 className="text-[0.65rem] font-bold tracking-[2px] uppercase text-white/25 mb-5">Perusahaan</h5>
          {COMPANY_LINKS.map(link => <FooterLink key={link.label} link={link} />)}
        </div>
      </div>

      <div className="border-t border-white/5 max-w-[1200px] mx-auto px-12 py-5 flex justify-between text-[0.72rem] text-white/20">
        <span>© 2025 VernonEdu. All rights reserved.</span>
        <span>Made in Indonesia 🇮🇩</span>
      </div>
    </footer>
  )
}
```

- [ ] **Step 5: Run tests**

```bash
cd web && npx vitest run src/components/layout/
```
Expected: all PASS

- [ ] **Step 6: Commit**

```bash
git add web/src/components/layout/
git commit -m "feat(web): add Nav and Footer layout components"
```

---

## Task 6: App Router + Layout Shell

**Files:**
- Modify: `web/src/main.tsx`
- Create: `web/src/App.tsx`

- [ ] **Step 1: Write test**

Create `web/src/App.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import App from './App'

it('renders nav on home route', () => {
  render(<MemoryRouter initialEntries={['/']}><App /></MemoryRouter>)
  expect(screen.getAllByText(/vernonedu/i).length).toBeGreaterThan(0)
})

it('renders 404 on unknown route', () => {
  render(<MemoryRouter initialEntries={['/xxxxunknown']}><App /></MemoryRouter>)
  expect(screen.getByText(/404/i)).toBeInTheDocument()
})
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd web && npx vitest run src/App.test.tsx
```

- [ ] **Step 3: Create `web/src/App.tsx`**

```tsx
import { Routes, Route } from 'react-router-dom'
import { Nav } from './components/layout/Nav'
import { Footer } from './components/layout/Footer'
import { Home } from './pages/Home'
import { Students } from './pages/Students'
import { Partners } from './pages/Partners'
import { Batch } from './pages/Batch'
import { Blog } from './pages/Blog'
import { BlogPost } from './pages/BlogPost'
import { About } from './pages/About'

function NotFound() {
  return (
    <div className="min-h-screen flex items-center justify-center">
      <div className="text-center">
        <p className="text-6xl font-black text-brand-200 mb-4">404</p>
        <p className="text-brand-500 font-semibold">Halaman tidak ditemukan</p>
      </div>
    </div>
  )
}

export default function App() {
  return (
    <>
      <Nav />
      <main>
        <Routes>
          <Route path="/"           element={<Home />} />
          <Route path="/students"   element={<Students />} />
          <Route path="/partners"   element={<Partners />} />
          <Route path="/batch"      element={<Batch />} />
          <Route path="/blog"       element={<Blog />} />
          <Route path="/blog/:slug" element={<BlogPost />} />
          <Route path="/about"      element={<About />} />
          <Route path="*"           element={<NotFound />} />
        </Routes>
      </main>
      <Footer />
    </>
  )
}
```

- [ ] **Step 4: Create stub pages** (needed for App to compile)

Create `web/src/pages/Home/index.tsx`:
```tsx
export function Home() { return <div>Home</div> }
```

Create `web/src/pages/Students.tsx`:
```tsx
export function Students() { return <div>Students</div> }
```

Create `web/src/pages/Partners.tsx`:
```tsx
export function Partners() { return <div>Partners</div> }
```

Create `web/src/pages/Batch.tsx`:
```tsx
export function Batch() { return <div>Batch</div> }
```

Create `web/src/pages/Blog.tsx`:
```tsx
export function Blog() { return <div>Blog</div> }
```

Create `web/src/pages/BlogPost.tsx`:
```tsx
export function BlogPost() { return <div>BlogPost</div> }
```

Create `web/src/pages/About.tsx`:
```tsx
export function About() { return <div>About</div> }
```

- [ ] **Step 5: Update `web/src/main.tsx`**

```tsx
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import './index.css'
import App from './App'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter>
      <App />
    </BrowserRouter>
  </StrictMode>
)
```

- [ ] **Step 6: Run tests**

```bash
cd web && npx vitest run src/App.test.tsx
```
Expected: PASS

- [ ] **Step 7: Smoke test in browser**

```bash
cd web && npm run dev
```
Visit `http://localhost:5173` — nav and footer should render.

- [ ] **Step 8: Commit**

```bash
git add web/src/
git commit -m "feat(web): add app router with nav/footer shell and stub pages"
```

---

## Task 7: Home Page — Hero Section

**Files:**
- Create: `web/src/pages/Home/Hero.tsx`

- [ ] **Step 1: Write failing test**

Create `web/src/pages/Home/Hero.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { Hero } from './Hero'

it('renders headline', () => {
  render(<BrowserRouter><Hero /></BrowserRouter>)
  expect(screen.getByText(/belajar lebih/i)).toBeInTheDocument()
})

it('renders audience chooser options', () => {
  render(<BrowserRouter><Hero /></BrowserRouter>)
  expect(screen.getByText(/siswa \/ pelajar/i)).toBeInTheDocument()
  expect(screen.getByText(/mitra institusi/i)).toBeInTheDocument()
})

it('renders stat: 12K+ Siswa Aktif', () => {
  render(<BrowserRouter><Hero /></BrowserRouter>)
  expect(screen.getByText('12K+')).toBeInTheDocument()
  expect(screen.getByText(/siswa aktif/i)).toBeInTheDocument()
})
```

- [ ] **Step 2: Run — FAIL**

```bash
cd web && npx vitest run src/pages/Home/Hero.test.tsx
```

- [ ] **Step 3: Create `web/src/pages/Home/Hero.tsx`**

```tsx
import { Link } from 'react-router-dom'
import { LINKS } from '../../tokens'

const STATS = [
  { value: '12K+', label: 'Siswa Aktif' },
  { value: '500+', label: 'Kursus Tersedia' },
  { value: '80+',  label: 'Mitra Institusi' },
  { value: '15+',  label: 'Kota di Indonesia' },
]

const CHOOSER_ITEMS = [
  {
    icon: '🎓',
    name: 'Siswa / Pelajar',
    sub: 'Daftar kursus regular, private, atau kelas batch',
    to: '/students',
  },
  {
    icon: '🏫',
    name: 'Mitra Institusi',
    sub: 'Sekolah, kampus, atau perusahaan',
    to: '/partners',
  },
]

export function Hero() {
  return (
    <section className="min-h-screen pt-28 flex flex-col relative overflow-hidden bg-white">
      {/* blobs */}
      <div className="absolute -top-32 -right-32 w-[600px] h-[600px] rounded-full bg-gradient-radial from-brand-200/35 to-transparent pointer-events-none" />
      <div className="absolute bottom-32 -left-24 w-[400px] h-[400px] rounded-full bg-gradient-radial from-brand-500/12 to-transparent pointer-events-none" />

      {/* main content */}
      <div className="flex-1 max-w-[1200px] w-full mx-auto px-12 grid grid-cols-2 gap-16 items-center py-12">
        {/* left */}
        <div>
          <div className="inline-flex items-center gap-2 bg-brand-50 border border-brand-100 rounded-full px-4 py-1.5 text-[0.7rem] font-bold text-brand-500 tracking-[1.5px] uppercase mb-6">
            <span className="text-[0.55rem]">●</span>
            Lembaga Pendidikan Informal
          </div>

          <h1 className="text-[clamp(2.75rem,5.5vw,4.25rem)] font-black leading-[1.0] tracking-[-2.5px] text-brand-900 mb-5">
            Belajar Lebih.<br />
            Raih <em className="italic text-brand-500 font-bold not-italic">Lebih.</em>
          </h1>

          <p className="text-base text-slate-400 leading-[1.75] max-w-[420px] mb-8">
            Kursus berkualitas, kelas batch terjadwal, dan program kemitraan untuk individu dan institusi di seluruh Indonesia.
          </p>

          <div className="flex items-center gap-4">
            <a
              href={LINKS.register}
              className="bg-brand-500 text-white text-sm font-bold px-7 py-3 rounded-full hover:bg-brand-600 transition-colors"
            >
              Mulai Belajar
            </a>
            <Link
              to="/batch"
              className="border-[1.5px] border-brand-100 text-brand-600 text-sm font-semibold px-6 py-[0.75rem] rounded-full hover:border-brand-300 transition-colors"
            >
              Lihat Kelas Batch ↗
            </Link>
          </div>
        </div>

        {/* right — audience chooser */}
        <div className="bg-brand-50 border border-brand-100 rounded-3xl p-8">
          <p className="text-[0.65rem] font-bold tracking-[2.5px] uppercase text-brand-500 mb-5">
            Saya adalah...
          </p>
          {CHOOSER_ITEMS.map(item => (
            <Link
              key={item.to}
              to={item.to}
              className="flex items-center gap-4 p-4 bg-white rounded-2xl border border-brand-100 mb-3 last:mb-0 hover:border-brand-300 hover:shadow-md hover:translate-x-1 transition-all group"
            >
              <div className="w-11 h-11 rounded-xl bg-brand-50 flex items-center justify-center text-xl shrink-0">
                {item.icon}
              </div>
              <div className="flex-1">
                <p className="text-[0.9rem] font-black text-brand-900">{item.name}</p>
                <p className="text-[0.72rem] text-slate-400 mt-0.5">{item.sub}</p>
              </div>
              <span className="text-brand-500 group-hover:translate-x-0.5 transition-transform">→</span>
            </Link>
          ))}
        </div>
      </div>

      {/* stats strip */}
      <div className="max-w-[1200px] w-full mx-auto border-t border-brand-100">
        <div className="grid grid-cols-4 divide-x divide-brand-100">
          {STATS.map(stat => (
            <div key={stat.label} className="px-6 py-7 flex flex-col gap-1">
              <span className="text-[1.75rem] font-black text-brand-500 tracking-tight">{stat.value}</span>
              <span className="text-[0.72rem] text-slate-400 font-medium">{stat.label}</span>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
```

- [ ] **Step 4: Run tests**

```bash
cd web && npx vitest run src/pages/Home/Hero.test.tsx
```
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add web/src/pages/Home/Hero.tsx web/src/pages/Home/Hero.test.tsx
git commit -m "feat(web): add hero section with audience chooser and stats strip"
```

---

## Task 8: Home Page — CertBand + PartnerList + CourseTicker

**Files:**
- Create: `web/src/pages/Home/CertBand.tsx`
- Create: `web/src/pages/Home/PartnerList.tsx`
- Create: `web/src/pages/Home/CourseTicker.tsx`

- [ ] **Step 1: Write failing tests**

Create `web/src/pages/Home/CertBand.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import { CertBand } from './CertBand'

it('renders BNSP', () => {
  render(<CertBand />)
  expect(screen.getByText(/BNSP/i)).toBeInTheDocument()
})

it('renders SKKNI', () => {
  render(<CertBand />)
  expect(screen.getByText(/SKKNI/i)).toBeInTheDocument()
})
```

Create `web/src/pages/Home/PartnerList.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import { PartnerList } from './PartnerList'

it('renders partner heading', () => {
  render(<PartnerList />)
  expect(screen.getByText(/dipercaya oleh/i)).toBeInTheDocument()
})

it('renders at least one partner chip', () => {
  render(<PartnerList />)
  expect(screen.getByText('Universitas Indonesia')).toBeInTheDocument()
})
```

Create `web/src/pages/Home/CourseTicker.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import { CourseTicker } from './CourseTicker'

it('renders at least one course item', () => {
  render(<CourseTicker />)
  expect(screen.getAllByText(/bahasa inggris/i).length).toBeGreaterThan(0)
})
```

- [ ] **Step 2: Run — FAIL**

```bash
cd web && npx vitest run src/pages/Home/CertBand.test.tsx src/pages/Home/PartnerList.test.tsx src/pages/Home/CourseTicker.test.tsx
```

- [ ] **Step 3: Create `web/src/pages/Home/CertBand.tsx`**

```tsx
const CERTS = [
  { icon: '🏛️', name: 'Terakreditasi BNSP', sub: 'Badan Nasional Sertifikasi Profesi' },
  { icon: '📜', name: 'Berbasis SKKNI',    sub: 'Standar Kompetensi Kerja Nasional Indonesia' },
  { icon: '✅', name: 'Sertifikat Terverifikasi Digital', sub: 'Dapat dicek online kapan saja' },
]

export function CertBand() {
  return (
    <div className="bg-brand-900 py-6 px-12">
      <div className="max-w-[1200px] mx-auto flex items-center justify-center gap-12">
        {CERTS.map((cert, i) => (
          <div key={cert.name} className="flex items-center gap-3">
            {i > 0 && <div className="w-px h-9 bg-white/10 mr-9" />}
            <div className="w-11 h-11 rounded-xl bg-white/10 border border-white/15 flex items-center justify-center text-xl shrink-0">
              {cert.icon}
            </div>
            <div>
              <p className="text-[0.875rem] font-black text-white">{cert.name}</p>
              <p className="text-[0.7rem] text-white/40 mt-0.5">{cert.sub}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
```

- [ ] **Step 4: Create `web/src/pages/Home/PartnerList.tsx`**

```tsx
import { PARTNERS } from '../../data/partners'

export function PartnerList() {
  return (
    <section className="py-14 px-12 bg-slate-50 border-b border-brand-100">
      <div className="max-w-[1200px] mx-auto">
        <p className="text-[0.65rem] font-bold tracking-[2.5px] uppercase text-slate-400 text-center mb-8">
          Dipercaya oleh institusi terkemuka
        </p>
        <div className="flex flex-wrap justify-center gap-3">
          {PARTNERS.map(name => (
            <div
              key={name}
              className="flex items-center gap-2 px-5 py-2.5 bg-white border border-brand-100 rounded-full text-[0.82rem] font-bold text-brand-800"
            >
              <span className="w-2 h-2 rounded-full bg-brand-100" />
              {name}
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
```

- [ ] **Step 5: Create `web/src/pages/Home/CourseTicker.tsx`**

```tsx
import { COURSE_TICKER_ITEMS } from '../../data/partners'

export function CourseTicker() {
  // double the items so seamless loop
  const items = [...COURSE_TICKER_ITEMS, ...COURSE_TICKER_ITEMS]

  return (
    <div className="bg-brand-50 py-3.5 overflow-hidden whitespace-nowrap border-y border-brand-100">
      <div className="ticker-track gap-0 text-[0.7rem] font-black tracking-[2px] text-slate-400 uppercase">
        {items.map((item, i) => (
          <span key={i} className="inline-flex items-center">
            {item}
            <span className="text-brand-200 mx-6">✦</span>
          </span>
        ))}
      </div>
    </div>
  )
}
```

- [ ] **Step 6: Run tests**

```bash
cd web && npx vitest run src/pages/Home/CertBand.test.tsx src/pages/Home/PartnerList.test.tsx src/pages/Home/CourseTicker.test.tsx
```
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add web/src/pages/Home/CertBand.tsx web/src/pages/Home/CertBand.test.tsx web/src/pages/Home/PartnerList.tsx web/src/pages/Home/PartnerList.test.tsx web/src/pages/Home/CourseTicker.tsx web/src/pages/Home/CourseTicker.test.tsx
git commit -m "feat(web): add CertBand, PartnerList, CourseTicker home sections"
```

---

## Task 9: Home Page — BatchSection + FeaturesSection + TestimonialSection

**Files:**
- Create: `web/src/pages/Home/BatchSection.tsx`
- Create: `web/src/pages/Home/FeaturesSection.tsx`
- Create: `web/src/pages/Home/TestimonialSection.tsx`

- [ ] **Step 1: Write failing tests**

Create `web/src/pages/Home/BatchSection.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { BatchSection } from './BatchSection'

it('renders section title', () => {
  render(<BrowserRouter><BatchSection /></BrowserRouter>)
  expect(screen.getByText(/kelas batch/i)).toBeInTheDocument()
})

it('renders first 3 batches', () => {
  render(<BrowserRouter><BatchSection /></BrowserRouter>)
  expect(screen.getByText(/English for Professionals/i)).toBeInTheDocument()
  expect(screen.getByText(/UI\/UX Design/i)).toBeInTheDocument()
  expect(screen.getByText(/Python for Data/i)).toBeInTheDocument()
})
```

Create `web/src/pages/Home/FeaturesSection.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { FeaturesSection } from './FeaturesSection'

it('renders Talent Pool feature', () => {
  render(<BrowserRouter><FeaturesSection /></BrowserRouter>)
  expect(screen.getByText(/talent pool alumni/i)).toBeInTheDocument()
})

it('renders BNSP & SKKNI feature', () => {
  render(<BrowserRouter><FeaturesSection /></BrowserRouter>)
  expect(screen.getByText(/BNSP & SKKNI/i)).toBeInTheDocument()
})

it('renders B2B partnership card', () => {
  render(<BrowserRouter><FeaturesSection /></BrowserRouter>)
  expect(screen.getByText(/hubungi tim partnership/i)).toBeInTheDocument()
})
```

Create `web/src/pages/Home/TestimonialSection.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { TestimonialSection } from './TestimonialSection'

it('renders featured testimonial author', () => {
  render(<BrowserRouter><TestimonialSection /></BrowserRouter>)
  expect(screen.getByText('Rina Kusuma')).toBeInTheDocument()
})

it('renders all 3 testimonials', () => {
  render(<BrowserRouter><TestimonialSection /></BrowserRouter>)
  expect(screen.getByText('Dr. Hendra Wijaya')).toBeInTheDocument()
  expect(screen.getByText('Ayu Permata')).toBeInTheDocument()
})
```

- [ ] **Step 2: Run — FAIL**

```bash
cd web && npx vitest run src/pages/Home/BatchSection.test.tsx src/pages/Home/FeaturesSection.test.tsx src/pages/Home/TestimonialSection.test.tsx
```

- [ ] **Step 3: Create `web/src/pages/Home/BatchSection.tsx`**

```tsx
import { SectionHeader } from '../../components/shared/SectionHeader'
import { BatchCard } from '../../components/shared/BatchCard'
import { BATCHES } from '../../data/batches'

export function BatchSection() {
  const preview = BATCHES.slice(0, 3)

  return (
    <section className="py-24 px-12 bg-white">
      <div className="max-w-[1200px] mx-auto">
        <SectionHeader
          eyebrow="Kelas Batch"
          title={<>Kelas <em className="italic text-brand-500">Terjadwal</em><br />Mulai Segera</>}
          seeAll={{ label: 'Lihat Semua Batch', href: '/batch' }}
        />
        <div className="grid grid-cols-3 gap-5">
          {preview.map(batch => <BatchCard key={batch.id} batch={batch} />)}
        </div>
      </div>
    </section>
  )
}
```

- [ ] **Step 4: Create `web/src/pages/Home/FeaturesSection.tsx`**

```tsx
import { FEATURES } from '../../data/features'
import { LINKS } from '../../tokens'

const B2B_CHECKLIST = [
  'Kursus standar dari katalog VernonEdu',
  'Program custom sesuai kebutuhan institusi',
  'Seminar & workshop on-site',
  'Model pembayaran fleksibel (per kunjungan / per siswa)',
  'Akses talent pool alumni untuk rekrutmen',
]

export function FeaturesSection() {
  return (
    <section className="py-24 px-12 bg-slate-50">
      <div className="max-w-[1200px] mx-auto grid grid-cols-[5fr_4fr] gap-20 items-start">
        {/* left — feature list */}
        <div>
          <p className="text-[0.65rem] font-bold tracking-[3px] uppercase text-brand-500 mb-2.5">
            Mengapa VernonEdu
          </p>
          <h2 className="text-4xl font-black tracking-tight text-brand-900 leading-tight mb-8">
            Ekosistem belajar<br />
            yang <em className="italic text-brand-500">nyata.</em>
          </h2>
          <div className="flex flex-col gap-4">
            {FEATURES.map(feat => (
              <div
                key={feat.id}
                className="flex gap-5 items-start p-5 bg-white border border-brand-100 rounded-2xl"
              >
                <div className="w-11 h-11 rounded-xl bg-brand-50 shrink-0 flex items-center justify-center text-xl">
                  {feat.icon}
                </div>
                <div>
                  <p className="text-[0.9rem] font-black text-brand-900 mb-1">{feat.title}</p>
                  <p className="text-[0.78rem] text-slate-400 leading-relaxed">{feat.description}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* right — sticky B2B card */}
        <div className="bg-brand-500 text-white rounded-3xl p-10 sticky top-24">
          <p className="text-[0.65rem] font-bold tracking-[2px] uppercase text-white/50 mb-4">
            Program B2B
          </p>
          <h3 className="text-[1.75rem] font-black leading-tight tracking-tight mb-4">
            Untuk Sekolah &amp; Kampus
          </h3>
          <p className="text-[0.82rem] text-white/65 leading-[1.75] mb-7">
            Program kemitraan fleksibel untuk menghadirkan kursus VernonEdu langsung ke institusi Anda.
          </p>
          <ul className="flex flex-col gap-3 mb-8">
            {B2B_CHECKLIST.map(item => (
              <li key={item} className="flex gap-3 items-start text-[0.82rem] text-white/75">
                <span className="text-brand-200 font-black shrink-0 mt-0.5">✓</span>
                {item}
              </li>
            ))}
          </ul>
          <a
            href="mailto:partnership@vernonedu.id"
            className="block bg-white text-brand-500 text-[0.875rem] font-black py-3.5 rounded-xl text-center hover:bg-brand-50 transition-colors"
          >
            Hubungi Tim Partnership →
          </a>
        </div>
      </div>
    </section>
  )
}
```

- [ ] **Step 5: Create `web/src/pages/Home/TestimonialSection.tsx`**

```tsx
import { TESTIMONIALS } from '../../data/testimonials'

export function TestimonialSection() {
  const featured = TESTIMONIALS.find(t => t.featured)!
  const compact  = TESTIMONIALS.filter(t => !t.featured)

  return (
    <section className="py-24 px-12 bg-white">
      <div className="max-w-[1200px] mx-auto">
        <div className="flex justify-between items-end mb-12">
          <div>
            <p className="text-[0.65rem] font-bold tracking-[3px] uppercase text-brand-500 mb-2.5">Testimoni</p>
            <h2 className="text-4xl font-black tracking-tight text-brand-900 leading-tight">
              Apa kata <em className="italic text-brand-500">mereka?</em>
            </h2>
          </div>
          <a href="#" className="text-[0.8rem] font-semibold text-brand-500 hover:text-brand-700">
            Lihat semua →
          </a>
        </div>

        <div className="grid grid-cols-[2fr_1fr_1fr] gap-5 items-start">
          {/* featured */}
          <div className="bg-brand-900 rounded-2xl p-8">
            <p className="text-[0.7rem] text-brand-500 tracking-[2px] mb-4">★ ★ ★ ★ ★</p>
            <p className="text-base text-white/80 leading-[1.75] italic mb-6">{`"${featured.quote}"`}</p>
            <p className="text-[0.85rem] font-black text-brand-200">{featured.name}</p>
            <p className="text-[0.72rem] text-white/35 mt-0.5">{featured.role}</p>
          </div>

          {/* compact */}
          {compact.map(t => (
            <div key={t.id} className="bg-slate-50 border border-brand-100 rounded-2xl p-8">
              <p className="text-[0.7rem] text-brand-500 tracking-[2px] mb-4">★ ★ ★ ★ ★</p>
              <p className="text-[0.875rem] text-brand-800 leading-[1.75] italic mb-6">{`"${t.quote}"`}</p>
              <p className="text-[0.85rem] font-black text-brand-600">{t.name}</p>
              <p className="text-[0.72rem] text-slate-400 mt-0.5">{t.role}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
```

- [ ] **Step 6: Run tests**

```bash
cd web && npx vitest run src/pages/Home/BatchSection.test.tsx src/pages/Home/FeaturesSection.test.tsx src/pages/Home/TestimonialSection.test.tsx
```
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add web/src/pages/Home/
git commit -m "feat(web): add BatchSection, FeaturesSection, TestimonialSection"
```

---

## Task 10: Home Page — B2BSection + BlogPreviewSection + CtaBand + FaqSection

**Files:**
- Create: `web/src/pages/Home/B2BSection.tsx`
- Create: `web/src/pages/Home/BlogPreviewSection.tsx`
- Create: `web/src/pages/Home/CtaBand.tsx`
- Create: `web/src/pages/Home/FaqSection.tsx`

- [ ] **Step 1: Write failing tests**

Create `web/src/pages/Home/B2BSection.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import { B2BSection } from './B2BSection'

it('renders headline', () => {
  render(<B2BSection />)
  expect(screen.getByText(/tingkatkan kualitas/i)).toBeInTheDocument()
})

it('renders Akses Talent Pool card', () => {
  render(<B2BSection />)
  expect(screen.getByText('Akses Talent Pool')).toBeInTheDocument()
})
```

Create `web/src/pages/Home/BlogPreviewSection.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { BlogPreviewSection } from './BlogPreviewSection'

it('renders featured blog post title', () => {
  render(<BrowserRouter><BlogPreviewSection /></BrowserRouter>)
  expect(screen.getByText(/5 Skill/i)).toBeInTheDocument()
})

it('renders 3 blog posts total', () => {
  render(<BrowserRouter><BlogPreviewSection /></BrowserRouter>)
  expect(screen.getAllByText(/april 2025/i).length).toBe(3)
})
```

Create `web/src/pages/Home/FaqSection.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import { FaqSection } from './FaqSection'

it('renders all 5 FAQ questions', () => {
  render(<FaqSection />)
  expect(screen.getByText(/apa itu kelas batch/i)).toBeInTheDocument()
  expect(screen.getByText(/talent pool/i)).toBeInTheDocument()
  expect(screen.getByText(/SKKNI/i)).toBeInTheDocument()
})
```

- [ ] **Step 2: Run — FAIL**

```bash
cd web && npx vitest run src/pages/Home/B2BSection.test.tsx src/pages/Home/BlogPreviewSection.test.tsx src/pages/Home/FaqSection.test.tsx
```

- [ ] **Step 3: Create `web/src/pages/Home/B2BSection.tsx`**

```tsx
const B2B_CARDS = [
  { title: 'Kursus Standar',     desc: 'Katalog kursus existing langsung tersedia untuk siswa/mahasiswa mitra Anda.' },
  { title: 'Program Custom',     desc: 'Kurikulum yang dirancang khusus sesuai kebutuhan spesifik institusi Anda.' },
  { title: 'Seminar & Workshop', desc: 'Acara satu kali atau reguler dengan pembicara dan instruktur pilihan.' },
  { title: 'Akses Talent Pool',  desc: 'Perusahaan mitra dapat mengakses database alumni VernonEdu untuk kebutuhan rekrutmen.' },
]

export function B2BSection() {
  return (
    <section className="py-24 px-12 bg-brand-50">
      <div className="max-w-[1200px] mx-auto grid grid-cols-2 gap-20 items-start">
        <div>
          <p className="text-[0.65rem] font-bold tracking-[3px] uppercase text-brand-500 mb-5">
            Kemitraan B2B
          </p>
          <h2 className="text-[clamp(2rem,4vw,3rem)] font-black leading-[1.05] tracking-[-1.5px] text-brand-900 mb-4">
            Tingkatkan Kualitas<br />
            <em className="italic text-brand-500">Siswa Anda</em><br />
            Bersama Kami.
          </h2>
          <p className="text-[0.9rem] text-slate-400 leading-[1.8] mb-7">
            Kami bekerja sama dengan sekolah dan universitas untuk menghadirkan kursus, seminar, dan workshop berkualitas langsung ke institusi Anda. Kurikulum fleksibel, instruktur berpengalaman, dan model pembayaran yang disesuaikan.
          </p>
          <a
            href="mailto:partnership@vernonedu.id"
            className="inline-flex items-center gap-2 bg-brand-900 text-white text-[0.875rem] font-bold px-8 py-3.5 rounded-full hover:bg-brand-800 transition-colors"
          >
            Hubungi Tim Partnership →
          </a>
        </div>

        <div className="flex flex-col gap-3.5">
          {B2B_CARDS.map(card => (
            <div key={card.title} className="bg-white border border-brand-100 rounded-2xl px-6 py-5">
              <p className="text-[0.9rem] font-black text-brand-900 mb-1.5">{card.title}</p>
              <p className="text-[0.78rem] text-slate-400 leading-relaxed">{card.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
```

- [ ] **Step 4: Create `web/src/pages/Home/BlogPreviewSection.tsx`**

```tsx
import { BLOG_POSTS } from '../../data/blog-posts'
import { BlogCard } from '../../components/shared/BlogCard'
import { SectionHeader } from '../../components/shared/SectionHeader'

export function BlogPreviewSection() {
  const featured = BLOG_POSTS.find(p => p.featured)!
  const compact  = BLOG_POSTS.filter(p => !p.featured).slice(0, 2)

  return (
    <section className="py-24 px-12 bg-white">
      <div className="max-w-[1200px] mx-auto">
        <SectionHeader
          eyebrow="Blog"
          title={<>Tips, insight, &amp;<br /><em className="italic text-brand-500">inspirasi belajar.</em></>}
          seeAll={{ label: 'Semua Artikel', href: '/blog' }}
        />
        <div className="grid grid-cols-[2fr_1fr_1fr] gap-5">
          <BlogCard post={featured} featured />
          {compact.map(post => <BlogCard key={post.id} post={post} />)}
        </div>
      </div>
    </section>
  )
}
```

- [ ] **Step 5: Create `web/src/pages/Home/CtaBand.tsx`**

```tsx
import { LINKS } from '../../tokens'

export function CtaBand() {
  return (
    <section className="bg-brand-900 py-20 px-12 text-center">
      <div className="max-w-[600px] mx-auto">
        <h2 className="text-[2.5rem] font-black tracking-[-2px] text-white leading-[1.1] mb-4">
          Siap mulai<br />
          <em className="italic text-brand-200">perjalananmu?</em>
        </h2>
        <p className="text-[0.9rem] text-white/45 leading-[1.7] mb-8">
          Bergabung dengan 12.000+ siswa yang sudah belajar bersama VernonEdu.
        </p>
        <div className="flex gap-4 justify-center">
          <a
            href={LINKS.register}
            className="bg-white text-brand-900 text-[0.875rem] font-black px-8 py-3.5 rounded-full hover:bg-brand-50 transition-colors"
          >
            Daftar Gratis
          </a>
          <a
            href="mailto:hello@vernonedu.id"
            className="border-[1.5px] border-white/20 text-white/60 text-[0.875rem] font-semibold px-7 py-3.5 rounded-full hover:border-white/40 transition-colors"
          >
            Hubungi Kami
          </a>
        </div>
      </div>
    </section>
  )
}
```

- [ ] **Step 6: Create `web/src/pages/Home/FaqSection.tsx`**

```tsx
import { useState } from 'react'
import { FAQS } from '../../data/faqs'

export function FaqSection() {
  const [open, setOpen] = useState<string | null>(null)

  return (
    <section className="py-24 px-12 bg-slate-50">
      <div className="max-w-[720px] mx-auto">
        <h2 className="text-[2.25rem] font-black tracking-[-1.5px] text-brand-900 leading-[1.1] mb-10">
          Pertanyaan<br />yang sering ditanya.
        </h2>
        {FAQS.map(faq => (
          <div key={faq.id} className="border-t border-brand-100 py-5">
            <button
              className="w-full flex justify-between items-center text-[0.925rem] font-bold text-brand-900 text-left"
              onClick={() => setOpen(open === faq.id ? null : faq.id)}
            >
              {faq.question}
              <span className="text-brand-500 text-xl font-light ml-4 shrink-0">
                {open === faq.id ? '−' : '+'}
              </span>
            </button>
            {open === faq.id && (
              <p className="text-[0.82rem] text-slate-400 leading-[1.75] mt-3.5">{faq.answer}</p>
            )}
          </div>
        ))}
      </div>
    </section>
  )
}
```

- [ ] **Step 7: Run tests**

```bash
cd web && npx vitest run src/pages/Home/B2BSection.test.tsx src/pages/Home/BlogPreviewSection.test.tsx src/pages/Home/FaqSection.test.tsx
```
Expected: PASS

- [ ] **Step 8: Commit**

```bash
git add web/src/pages/Home/
git commit -m "feat(web): add B2BSection, BlogPreviewSection, CtaBand, FaqSection"
```

---

## Task 11: Assemble Home Page

**Files:**
- Modify: `web/src/pages/Home/index.tsx`

- [ ] **Step 1: Write failing test**

Create `web/src/pages/Home/Home.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { Home } from './index'

it('renders hero headline', () => {
  render(<MemoryRouter><Home /></MemoryRouter>)
  expect(screen.getByText(/belajar lebih/i)).toBeInTheDocument()
})

it('renders BNSP in cert band', () => {
  render(<MemoryRouter><Home /></MemoryRouter>)
  expect(screen.getByText(/terakreditasi BNSP/i)).toBeInTheDocument()
})

it('renders kelas batch section', () => {
  render(<MemoryRouter><Home /></MemoryRouter>)
  expect(screen.getByText(/English for Professionals/i)).toBeInTheDocument()
})

it('renders talent pool feature', () => {
  render(<MemoryRouter><Home /></MemoryRouter>)
  expect(screen.getByText(/talent pool alumni/i)).toBeInTheDocument()
})

it('renders blog preview', () => {
  render(<MemoryRouter><Home /></MemoryRouter>)
  expect(screen.getByText(/5 Skill/i)).toBeInTheDocument()
})
```

- [ ] **Step 2: Run — FAIL (Home is still stub)**

```bash
cd web && npx vitest run src/pages/Home/Home.test.tsx
```

- [ ] **Step 3: Replace `web/src/pages/Home/index.tsx`**

```tsx
import { Hero } from './Hero'
import { CertBand } from './CertBand'
import { PartnerList } from './PartnerList'
import { CourseTicker } from './CourseTicker'
import { BatchSection } from './BatchSection'
import { FeaturesSection } from './FeaturesSection'
import { TestimonialSection } from './TestimonialSection'
import { B2BSection } from './B2BSection'
import { BlogPreviewSection } from './BlogPreviewSection'
import { CtaBand } from './CtaBand'
import { FaqSection } from './FaqSection'

export function Home() {
  return (
    <>
      <Hero />
      <CertBand />
      <PartnerList />
      <CourseTicker />
      <BatchSection />
      <FeaturesSection />
      <TestimonialSection />
      <B2BSection />
      <BlogPreviewSection />
      <CtaBand />
      <FaqSection />
    </>
  )
}
```

- [ ] **Step 4: Run tests**

```bash
cd web && npx vitest run src/pages/Home/Home.test.tsx
```
Expected: PASS

- [ ] **Step 5: Visual smoke test**

```bash
cd web && npm run dev
```
Visit `http://localhost:5173` — scroll through full homepage.

- [ ] **Step 6: Commit**

```bash
git add web/src/pages/Home/
git commit -m "feat(web): assemble full home page from section components"
```

---

## Task 12: Batch Listing Page

**Files:**
- Modify: `web/src/pages/Batch.tsx`

- [ ] **Step 1: Write failing test**

Create `web/src/pages/Batch.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { Batch } from './Batch'
import { BATCHES } from '../data/batches'

it('renders page title', () => {
  render(<BrowserRouter><Batch /></BrowserRouter>)
  expect(screen.getByText(/semua kelas batch/i)).toBeInTheDocument()
})

it('renders all batches', () => {
  render(<BrowserRouter><Batch /></BrowserRouter>)
  BATCHES.forEach(b => {
    expect(screen.getByText(new RegExp(b.name, 'i'))).toBeInTheDocument()
  })
})
```

- [ ] **Step 2: Run — FAIL**

```bash
cd web && npx vitest run src/pages/Batch.test.tsx
```

- [ ] **Step 3: Replace `web/src/pages/Batch.tsx`**

```tsx
import { BATCHES, DeliveryMode } from '../data/batches'
import { BatchCard } from '../components/shared/BatchCard'
import { useState } from 'react'

const ALL_CATEGORIES = ['Semua', ...Array.from(new Set(BATCHES.map(b => b.category)))]
const ALL_MODES: (DeliveryMode | 'semua')[] = ['semua', 'online', 'offline']

export function Batch() {
  const [category, setCategory] = useState('Semua')
  const [mode, setMode] = useState<DeliveryMode | 'semua'>('semua')

  const filtered = BATCHES.filter(b => {
    const catOk  = category === 'Semua' || b.category === category
    const modeOk = mode === 'semua' || b.mode === mode
    return catOk && modeOk
  })

  return (
    <div className="pt-24 min-h-screen bg-white">
      {/* header */}
      <div className="bg-brand-900 px-12 py-16">
        <div className="max-w-[1200px] mx-auto">
          <p className="text-[0.7rem] font-bold tracking-[3px] uppercase text-brand-300 mb-3">
            Jadwal Kelas
          </p>
          <h1 className="text-[2.5rem] font-black tracking-[-2px] text-white leading-tight">
            Semua Kelas Batch
          </h1>
          <p className="text-[0.9rem] text-white/45 mt-3 max-w-[480px] leading-relaxed">
            Kelas terjadwal dengan angkatan bersama. Daftar sebelum batch mulai.
          </p>
        </div>
      </div>

      {/* filters */}
      <div className="border-b border-brand-100 px-12 py-4 bg-white sticky top-16 z-10">
        <div className="max-w-[1200px] mx-auto flex gap-3 flex-wrap items-center">
          <span className="text-[0.72rem] font-bold text-slate-400 mr-2">Kategori:</span>
          {ALL_CATEGORIES.map(cat => (
            <button
              key={cat}
              onClick={() => setCategory(cat)}
              className={`text-[0.78rem] font-bold px-4 py-1.5 rounded-full transition-colors ${
                category === cat
                  ? 'bg-brand-500 text-white'
                  : 'bg-brand-50 text-brand-500 hover:bg-brand-100'
              }`}
            >
              {cat}
            </button>
          ))}
          <span className="text-[0.72rem] font-bold text-slate-400 ml-4 mr-2">Mode:</span>
          {ALL_MODES.map(m => (
            <button
              key={m}
              onClick={() => setMode(m)}
              className={`text-[0.78rem] font-bold px-4 py-1.5 rounded-full capitalize transition-colors ${
                mode === m
                  ? 'bg-brand-500 text-white'
                  : 'bg-brand-50 text-brand-500 hover:bg-brand-100'
              }`}
            >
              {m}
            </button>
          ))}
        </div>
      </div>

      {/* grid */}
      <div className="px-12 py-16">
        <div className="max-w-[1200px] mx-auto">
          {filtered.length === 0 ? (
            <p className="text-slate-400 text-center py-16">Tidak ada batch yang sesuai filter.</p>
          ) : (
            <div className="grid grid-cols-3 gap-5">
              {filtered.map(batch => <BatchCard key={batch.id} batch={batch} />)}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
```

- [ ] **Step 4: Run tests**

```bash
cd web && npx vitest run src/pages/Batch.test.tsx
```
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add web/src/pages/Batch.tsx web/src/pages/Batch.test.tsx
git commit -m "feat(web): add batch listing page with category and mode filters"
```

---

## Task 13: Students + Partners Pages

**Files:**
- Modify: `web/src/pages/Students.tsx`
- Modify: `web/src/pages/Partners.tsx`

- [ ] **Step 1: Write failing tests**

Create `web/src/pages/Students.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { Students } from './Students'

it('renders page heading', () => {
  render(<BrowserRouter><Students /></BrowserRouter>)
  expect(screen.getByText(/kursus untuk anda/i)).toBeInTheDocument()
})

it('renders Regular Class info', () => {
  render(<BrowserRouter><Students /></BrowserRouter>)
  expect(screen.getByText(/kelas regular/i)).toBeInTheDocument()
})

it('renders Private Class info', () => {
  render(<BrowserRouter><Students /></BrowserRouter>)
  expect(screen.getByText(/kelas private/i)).toBeInTheDocument()
})

it('renders Daftar Sekarang CTA', () => {
  render(<BrowserRouter><Students /></BrowserRouter>)
  expect(screen.getByRole('link', { name: /daftar sekarang/i })).toBeInTheDocument()
})
```

Create `web/src/pages/Partners.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { Partners } from './Partners'

it('renders page heading', () => {
  render(<BrowserRouter><Partners /></BrowserRouter>)
  expect(screen.getByText(/program kemitraan/i)).toBeInTheDocument()
})

it('renders Talent Pool benefit', () => {
  render(<BrowserRouter><Partners /></BrowserRouter>)
  expect(screen.getByText(/talent pool/i)).toBeInTheDocument()
})

it('renders contact section', () => {
  render(<BrowserRouter><Partners /></BrowserRouter>)
  expect(screen.getByText(/hubungi kami/i)).toBeInTheDocument()
})
```

- [ ] **Step 2: Run — FAIL**

```bash
cd web && npx vitest run src/pages/Students.test.tsx src/pages/Partners.test.tsx
```

- [ ] **Step 3: Replace `web/src/pages/Students.tsx`**

```tsx
import { Link } from 'react-router-dom'
import { LINKS } from '../tokens'
import { CtaBand } from './Home/CtaBand'

const CLASS_FORMATS = [
  {
    icon: '👥',
    title: 'Kelas Regular',
    desc: 'Belajar dalam grup kecil bersama peserta lain. Harga lebih terjangkau, jadwal tetap setiap minggu.',
    badge: 'Populer',
  },
  {
    icon: '👤',
    title: 'Kelas Private',
    desc: 'Sesi 1-on-1 atau kelompok sangat kecil bersama instruktur pilihan. Jadwal fleksibel sesuai kebutuhan Anda.',
    badge: 'Premium',
  },
  {
    icon: '📅',
    title: 'Kelas Batch',
    desc: 'Kelas terjadwal dengan angkatan bersama. Mulai pada tanggal tertentu, belajar bersama selama beberapa minggu.',
    badge: 'Terstruktur',
  },
]

const DELIVERY_MODES = [
  { icon: '🌐', title: 'Online',  desc: 'Belajar dari mana saja melalui platform VernonEdu. Rekaman tersedia.' },
  { icon: '📍', title: 'Offline', desc: 'Hadir langsung di cabang VernonEdu terdekat di kota Anda.' },
]

export function Students() {
  return (
    <div className="pt-24 min-h-screen bg-white">
      {/* header */}
      <div className="bg-brand-900 px-12 py-20">
        <div className="max-w-[1200px] mx-auto grid grid-cols-2 gap-16 items-center">
          <div>
            <p className="text-[0.7rem] font-bold tracking-[3px] uppercase text-brand-300 mb-3">Untuk Individu</p>
            <h1 className="text-[clamp(2.25rem,5vw,3.5rem)] font-black tracking-[-2px] text-white leading-tight mb-4">
              Kursus untuk Anda.<br />
              <em className="italic text-brand-200">Sesuai Kebutuhan.</em>
            </h1>
            <p className="text-[0.9rem] text-white/45 leading-relaxed max-w-[420px]">
              Pilih format kelas, mode belajar, dan jadwal yang paling sesuai dengan gaya hidup Anda.
            </p>
          </div>
          <div className="flex gap-4">
            <a
              href={LINKS.register}
              className="inline-flex items-center gap-2 bg-brand-500 text-white text-[0.875rem] font-black px-7 py-3.5 rounded-full hover:bg-brand-400 transition-colors"
            >
              Daftar Sekarang
            </a>
            <Link
              to="/batch"
              className="inline-flex items-center border border-white/20 text-white/60 text-[0.875rem] font-semibold px-6 py-3.5 rounded-full hover:border-white/40 transition-colors"
            >
              Lihat Kelas Batch
            </Link>
          </div>
        </div>
      </div>

      {/* format cards */}
      <div className="px-12 py-20 bg-white">
        <div className="max-w-[1200px] mx-auto">
          <p className="text-[0.65rem] font-bold tracking-[3px] uppercase text-brand-500 mb-2.5">Format Belajar</p>
          <h2 className="text-3xl font-black tracking-tight text-brand-900 mb-10">Pilih cara belajar Anda.</h2>
          <div className="grid grid-cols-3 gap-5">
            {CLASS_FORMATS.map(f => (
              <div key={f.title} className="border border-brand-100 rounded-2xl p-6 hover:shadow-md transition-shadow">
                <div className="w-12 h-12 rounded-xl bg-brand-50 flex items-center justify-center text-2xl mb-4">{f.icon}</div>
                <div className="flex items-center gap-2 mb-2">
                  <h3 className="text-base font-black text-brand-900">{f.title}</h3>
                  <span className="text-[0.65rem] font-bold px-2 py-0.5 rounded-full bg-brand-50 text-brand-500">{f.badge}</span>
                </div>
                <p className="text-[0.78rem] text-slate-400 leading-relaxed">{f.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* delivery mode */}
      <div className="px-12 py-16 bg-brand-50">
        <div className="max-w-[1200px] mx-auto">
          <p className="text-[0.65rem] font-bold tracking-[3px] uppercase text-brand-500 mb-2.5">Mode Belajar</p>
          <h2 className="text-3xl font-black tracking-tight text-brand-900 mb-8">Online atau offline — pilihan Anda.</h2>
          <div className="grid grid-cols-2 gap-5">
            {DELIVERY_MODES.map(m => (
              <div key={m.title} className="bg-white border border-brand-100 rounded-2xl p-6 flex gap-4">
                <div className="w-12 h-12 rounded-xl bg-brand-50 flex items-center justify-center text-2xl shrink-0">{m.icon}</div>
                <div>
                  <h3 className="text-base font-black text-brand-900 mb-1.5">{m.title}</h3>
                  <p className="text-[0.78rem] text-slate-400 leading-relaxed">{m.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      <CtaBand />
    </div>
  )
}
```

- [ ] **Step 4: Replace `web/src/pages/Partners.tsx`**

```tsx
import { CtaBand } from './Home/CtaBand'

const PROGRAMS = [
  { icon: '📚', title: 'Kursus Standar',     desc: 'Katalog kursus existing langsung tersedia untuk siswa atau mahasiswa institusi Anda.' },
  { icon: '✏️', title: 'Program Custom',     desc: 'Kurikulum yang kami rancang khusus berdasarkan kebutuhan dan tujuan spesifik institusi Anda.' },
  { icon: '🎤', title: 'Seminar & Workshop', desc: 'Acara satu kali atau reguler dengan pembicara dan instruktur pilihan dari jaringan VernonEdu.' },
  { icon: '🎯', title: 'Akses Talent Pool',  desc: 'Perusahaan dan institusi mitra dapat mengakses database alumni terverifikasi untuk kebutuhan rekrutmen.' },
]

const PAYMENT_MODELS = [
  { model: 'Per Kunjungan', desc: 'Bayar per sesi atau kunjungan yang terlaksana.' },
  { model: 'Per Kursus',    desc: 'Biaya tetap per kursus yang diselenggarakan.' },
  { model: 'Per Siswa',     desc: 'Tarif bulk berdasarkan jumlah siswa yang terdaftar.' },
]

export function Partners() {
  return (
    <div className="pt-24 min-h-screen bg-white">
      {/* header */}
      <div className="bg-brand-900 px-12 py-20">
        <div className="max-w-[1200px] mx-auto">
          <p className="text-[0.7rem] font-bold tracking-[3px] uppercase text-brand-300 mb-3">Untuk Institusi</p>
          <h1 className="text-[clamp(2.25rem,5vw,3.5rem)] font-black tracking-[-2px] text-white leading-tight mb-4">
            Program Kemitraan<br />
            <em className="italic text-brand-200">yang Fleksibel.</em>
          </h1>
          <p className="text-[0.9rem] text-white/45 leading-relaxed max-w-[520px]">
            Kami bekerja sama dengan sekolah, universitas, dan perusahaan untuk menghadirkan pendidikan berkualitas langsung ke lingkungan Anda.
          </p>
        </div>
      </div>

      {/* programs */}
      <div className="px-12 py-20 bg-white">
        <div className="max-w-[1200px] mx-auto">
          <p className="text-[0.65rem] font-bold tracking-[3px] uppercase text-brand-500 mb-2.5">Program</p>
          <h2 className="text-3xl font-black tracking-tight text-brand-900 mb-10">Apa yang kami tawarkan.</h2>
          <div className="grid grid-cols-2 gap-5">
            {PROGRAMS.map(p => (
              <div key={p.title} className="border border-brand-100 rounded-2xl p-6 flex gap-4">
                <div className="w-12 h-12 rounded-xl bg-brand-50 flex items-center justify-center text-2xl shrink-0">{p.icon}</div>
                <div>
                  <h3 className="text-base font-black text-brand-900 mb-1.5">{p.title}</h3>
                  <p className="text-[0.78rem] text-slate-400 leading-relaxed">{p.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* payment models */}
      <div className="px-12 py-16 bg-brand-50">
        <div className="max-w-[1200px] mx-auto">
          <p className="text-[0.65rem] font-bold tracking-[3px] uppercase text-brand-500 mb-2.5">Model Pembayaran</p>
          <h2 className="text-3xl font-black tracking-tight text-brand-900 mb-8">Disesuaikan dengan kesepakatan Anda.</h2>
          <div className="grid grid-cols-3 gap-5">
            {PAYMENT_MODELS.map(m => (
              <div key={m.model} className="bg-white border border-brand-100 rounded-2xl p-6">
                <h3 className="text-base font-black text-brand-900 mb-2">{m.model}</h3>
                <p className="text-[0.78rem] text-slate-400 leading-relaxed">{m.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* contact */}
      <div id="contact" className="px-12 py-20 bg-white">
        <div className="max-w-[600px] mx-auto text-center">
          <p className="text-[0.65rem] font-bold tracking-[3px] uppercase text-brand-500 mb-3">Kontak</p>
          <h2 className="text-3xl font-black tracking-tight text-brand-900 mb-4">
            Hubungi Kami
          </h2>
          <p className="text-[0.9rem] text-slate-400 leading-relaxed mb-8">
            Tim partnership kami siap berdiskusi tentang kebutuhan spesifik institusi Anda dan merancang program yang tepat.
          </p>
          <a
            href="mailto:partnership@vernonedu.id"
            className="inline-flex items-center gap-2 bg-brand-900 text-white text-[0.875rem] font-black px-8 py-3.5 rounded-full hover:bg-brand-800 transition-colors"
          >
            partnership@vernonedu.id
          </a>
        </div>
      </div>

      <CtaBand />
    </div>
  )
}
```

- [ ] **Step 5: Run tests**

```bash
cd web && npx vitest run src/pages/Students.test.tsx src/pages/Partners.test.tsx
```
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add web/src/pages/Students.tsx web/src/pages/Students.test.tsx web/src/pages/Partners.tsx web/src/pages/Partners.test.tsx
git commit -m "feat(web): add Students and Partners audience pages"
```

---

## Task 14: Blog + BlogPost + About Pages

**Files:**
- Modify: `web/src/pages/Blog.tsx`
- Modify: `web/src/pages/BlogPost.tsx`
- Modify: `web/src/pages/About.tsx`

- [ ] **Step 1: Write failing tests**

Create `web/src/pages/Blog.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { Blog } from './Blog'
import { BLOG_POSTS } from '../data/blog-posts'

it('renders Blog heading', () => {
  render(<BrowserRouter><Blog /></BrowserRouter>)
  expect(screen.getByText(/blog/i)).toBeInTheDocument()
})

it('renders all blog post titles', () => {
  render(<BrowserRouter><Blog /></BrowserRouter>)
  BLOG_POSTS.forEach(post => {
    expect(screen.getByText(post.title)).toBeInTheDocument()
  })
})
```

Create `web/src/pages/BlogPost.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { BlogPost } from './BlogPost'

it('renders post title for valid slug', () => {
  render(
    <MemoryRouter initialEntries={['/blog/5-skill-paling-dicari-2025']}>
      <Routes>
        <Route path="/blog/:slug" element={<BlogPost />} />
      </Routes>
    </MemoryRouter>
  )
  expect(screen.getByText(/5 Skill/i)).toBeInTheDocument()
})

it('shows 404 message for invalid slug', () => {
  render(
    <MemoryRouter initialEntries={['/blog/tidak-ada']}>
      <Routes>
        <Route path="/blog/:slug" element={<BlogPost />} />
      </Routes>
    </MemoryRouter>
  )
  expect(screen.getByText(/artikel tidak ditemukan/i)).toBeInTheDocument()
})
```

Create `web/src/pages/About.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { About } from './About'

it('renders About heading', () => {
  render(<BrowserRouter><About /></BrowserRouter>)
  expect(screen.getByText(/tentang vernonedu/i)).toBeInTheDocument()
})

it('renders contact section', () => {
  render(<BrowserRouter><About /></BrowserRouter>)
  expect(screen.getByText(/kontak/i)).toBeInTheDocument()
})
```

- [ ] **Step 2: Run — FAIL**

```bash
cd web && npx vitest run src/pages/Blog.test.tsx src/pages/BlogPost.test.tsx src/pages/About.test.tsx
```

- [ ] **Step 3: Replace `web/src/pages/Blog.tsx`**

```tsx
import { BLOG_POSTS } from '../data/blog-posts'
import { BlogCard } from '../components/shared/BlogCard'

export function Blog() {
  const featured = BLOG_POSTS.find(p => p.featured)!
  const rest = BLOG_POSTS.filter(p => !p.featured)

  return (
    <div className="pt-24 min-h-screen bg-white">
      <div className="bg-brand-900 px-12 py-16">
        <div className="max-w-[1200px] mx-auto">
          <p className="text-[0.7rem] font-bold tracking-[3px] uppercase text-brand-300 mb-3">Blog</p>
          <h1 className="text-[2.5rem] font-black tracking-[-2px] text-white">
            Tips, Insight &amp; Inspirasi Belajar
          </h1>
        </div>
      </div>

      <div className="px-12 py-16">
        <div className="max-w-[1200px] mx-auto">
          <div className="grid grid-cols-[2fr_1fr_1fr] gap-5 mb-5">
            <BlogCard post={featured} featured />
            {rest.slice(0, 2).map(p => <BlogCard key={p.id} post={p} />)}
          </div>
          {rest.length > 2 && (
            <div className="grid grid-cols-3 gap-5">
              {rest.slice(2).map(p => <BlogCard key={p.id} post={p} />)}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
```

- [ ] **Step 4: Replace `web/src/pages/BlogPost.tsx`**

```tsx
import { useParams, Link } from 'react-router-dom'
import { BLOG_POSTS } from '../data/blog-posts'

export function BlogPost() {
  const { slug } = useParams<{ slug: string }>()
  const post = BLOG_POSTS.find(p => p.slug === slug)

  if (!post) {
    return (
      <div className="pt-24 min-h-screen bg-white flex items-center justify-center">
        <div className="text-center">
          <p className="text-4xl font-black text-brand-200 mb-3">404</p>
          <p className="text-brand-500 font-semibold mb-6">Artikel tidak ditemukan</p>
          <Link to="/blog" className="text-sm text-slate-400 hover:text-brand-500">
            ← Kembali ke Blog
          </Link>
        </div>
      </div>
    )
  }

  return (
    <div className="pt-24 min-h-screen bg-white">
      {/* hero */}
      <div className="bg-brand-900 px-12 py-16">
        <div className="max-w-[720px] mx-auto">
          <Link to="/blog" className="text-[0.75rem] text-brand-300 hover:text-brand-200 mb-6 inline-block">
            ← Blog
          </Link>
          <p className="text-[0.7rem] font-bold tracking-[3px] uppercase text-brand-400 mb-3">
            {post.category}
          </p>
          <h1 className="text-[clamp(1.75rem,4vw,2.75rem)] font-black tracking-tight text-white leading-tight mb-4">
            {post.title}
          </h1>
          <div className="flex gap-4 text-[0.75rem] text-white/35">
            <span>{post.date}</span>
            <span>{post.readMinutes} min baca</span>
          </div>
        </div>
      </div>

      {/* content */}
      <div className="px-12 py-16">
        <div className="max-w-[720px] mx-auto">
          <p className="text-[0.95rem] text-slate-600 leading-[1.85]">{post.content}</p>
        </div>
      </div>
    </div>
  )
}
```

- [ ] **Step 5: Replace `web/src/pages/About.tsx`**

```tsx
export function About() {
  return (
    <div className="pt-24 min-h-screen bg-white">
      <div className="bg-brand-900 px-12 py-20">
        <div className="max-w-[1200px] mx-auto">
          <h1 className="text-[clamp(2.25rem,5vw,3.5rem)] font-black tracking-[-2px] text-white leading-tight mb-4">
            Tentang VernonEdu
          </h1>
          <p className="text-[0.9rem] text-white/45 leading-relaxed max-w-[520px]">
            Lembaga pendidikan informal yang hadir untuk membuka peluang melalui kursus berkualitas, kemitraan institusi, dan program tersertifikasi.
          </p>
        </div>
      </div>

      <div className="px-12 py-20">
        <div className="max-w-[800px] mx-auto">
          <p className="text-[0.65rem] font-bold tracking-[3px] uppercase text-brand-500 mb-3">Misi</p>
          <h2 className="text-2xl font-black tracking-tight text-brand-900 mb-5">
            Pendidikan yang Relevan, Fleksibel, dan Berdampak
          </h2>
          <p className="text-[0.95rem] text-slate-500 leading-[1.85] mb-10">
            VernonEdu berdiri dengan satu keyakinan: belajar tidak harus terbatas oleh ruang kelas atau jadwal kaku. Kami hadir dengan kurikulum yang dirancang bersama praktisi, tersedia online dan offline, untuk semua kalangan — dari siswa individu hingga mitra institusi pendidikan.
          </p>

          <div id="contact" className="border-t border-brand-100 pt-12">
            <p className="text-[0.65rem] font-bold tracking-[3px] uppercase text-brand-500 mb-3">Kontak</p>
            <h2 className="text-2xl font-black tracking-tight text-brand-900 mb-6">Hubungi Kami</h2>
            <div className="flex flex-col gap-3 text-[0.9rem] text-slate-500">
              <p>Email umum: <a href="mailto:hello@vernonedu.id" className="text-brand-500 font-semibold">hello@vernonedu.id</a></p>
              <p>Partnership: <a href="mailto:partnership@vernonedu.id" className="text-brand-500 font-semibold">partnership@vernonedu.id</a></p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
```

- [ ] **Step 6: Run tests**

```bash
cd web && npx vitest run src/pages/Blog.test.tsx src/pages/BlogPost.test.tsx src/pages/About.test.tsx
```
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add web/src/pages/Blog.tsx web/src/pages/Blog.test.tsx web/src/pages/BlogPost.tsx web/src/pages/BlogPost.test.tsx web/src/pages/About.tsx web/src/pages/About.test.tsx
git commit -m "feat(web): add Blog, BlogPost, and About pages"
```

---

## Task 15: Mobile Responsive Pass

**Files:**
- Modify: `web/src/pages/Home/Hero.tsx` — stack to single col at md
- Modify: `web/src/components/layout/Nav.tsx` — hide links at mobile, show hamburger
- Modify: All grid sections — `grid-cols-1 md:grid-cols-2` / `md:grid-cols-3`

- [ ] **Step 1: Update Nav for mobile**

Replace `<ul>` and layout in `web/src/components/layout/Nav.tsx`:

```tsx
// Add state for mobile menu
import { useState } from 'react'

// Inside Nav():
const [open, setOpen] = useState(false)

// Replace nav inner:
<nav className="fixed top-0 inset-x-0 z-50 flex justify-between items-center px-6 md:px-12 py-4 bg-white/85 backdrop-blur-md border-b border-brand-100">
  <NavLink to="/" className="text-[1.1rem] font-black tracking-tight text-brand-900">
    Vernon<span className="text-brand-500">Edu</span>
  </NavLink>

  {/* desktop links */}
  <ul className="hidden md:flex gap-8 list-none">
    {NAV_LINKS.map(...)}
  </ul>

  {/* desktop CTA */}
  <a href={LINKS.register} className="hidden md:block bg-brand-500 text-white text-[0.8rem] font-bold px-5 py-2 rounded-full">
    Daftar Sekarang
  </a>

  {/* mobile hamburger */}
  <button className="md:hidden p-2 text-brand-500" onClick={() => setOpen(!open)}>
    {open ? '✕' : '☰'}
  </button>

  {/* mobile drawer */}
  {open && (
    <div className="absolute top-full inset-x-0 bg-white border-b border-brand-100 p-6 flex flex-col gap-4 md:hidden">
      {NAV_LINKS.map(link => (
        <NavLink key={link.to} to={link.to} onClick={() => setOpen(false)}
          className="text-sm font-semibold text-brand-900 hover:text-brand-500">
          {link.label}
        </NavLink>
      ))}
      <a href={LINKS.register} className="mt-2 bg-brand-500 text-white text-sm font-bold px-5 py-3 rounded-full text-center">
        Daftar Sekarang
      </a>
    </div>
  )}
</nav>
```

- [ ] **Step 2: Make Hero 2-col → 1-col on mobile**

In `web/src/pages/Home/Hero.tsx`, change:
```tsx
// Before:
className="... grid grid-cols-2 gap-16 ..."
// After:
className="... grid grid-cols-1 md:grid-cols-2 gap-8 md:gap-16 ..."
```

And stats strip:
```tsx
// Before:
className="grid grid-cols-4 divide-x ..."
// After:
className="grid grid-cols-2 md:grid-cols-4 divide-x ..."
```

- [ ] **Step 3: Make batch grid responsive**

In `web/src/pages/Home/BatchSection.tsx`:
```tsx
// Before:
className="grid grid-cols-3 gap-5"
// After:
className="grid grid-cols-1 md:grid-cols-3 gap-5"
```

In `web/src/pages/Batch.tsx`:
```tsx
// Before:
className="grid grid-cols-3 gap-5"
// After:
className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5"
```

- [ ] **Step 4: Make features section stack on mobile**

In `web/src/pages/Home/FeaturesSection.tsx`:
```tsx
// Before:
className="... grid grid-cols-[5fr_4fr] gap-20 ..."
// After:
className="... grid grid-cols-1 lg:grid-cols-[5fr_4fr] gap-10 lg:gap-20 ..."
```

- [ ] **Step 5: Make testimonial grid stack on mobile**

In `web/src/pages/Home/TestimonialSection.tsx`:
```tsx
// Before:
className="grid grid-cols-[2fr_1fr_1fr] gap-5 ..."
// After:
className="grid grid-cols-1 md:grid-cols-[2fr_1fr_1fr] gap-5 ..."
```

- [ ] **Step 6: Make B2B section stack on mobile**

In `web/src/pages/Home/B2BSection.tsx`:
```tsx
// Before:
className="... grid grid-cols-2 gap-20 ..."
// After:
className="... grid grid-cols-1 md:grid-cols-2 gap-10 md:gap-20 ..."
```

- [ ] **Step 7: Make Blog preview stack on mobile**

In `web/src/pages/Home/BlogPreviewSection.tsx`:
```tsx
// Before:
className="grid grid-cols-[2fr_1fr_1fr] gap-5"
// After:
className="grid grid-cols-1 md:grid-cols-[2fr_1fr_1fr] gap-5"
```

- [ ] **Step 8: Make Footer stack on mobile**

In `web/src/components/layout/Footer.tsx`:
```tsx
// Before:
className="... grid grid-cols-[2fr_1fr_1fr_1fr] gap-12 ..."
// After:
className="... grid grid-cols-2 md:grid-cols-[2fr_1fr_1fr_1fr] gap-8 md:gap-12 ..."
```

- [ ] **Step 9: Make CertBand stack on mobile**

In `web/src/pages/Home/CertBand.tsx`:
```tsx
// Before:
className="... flex items-center justify-center gap-12"
// After:
className="... flex flex-col md:flex-row items-center justify-center gap-6 md:gap-12"
```

- [ ] **Step 10: Run full test suite**

```bash
cd web && npx vitest run
```
Expected: all PASS

- [ ] **Step 11: Visual smoke test on mobile viewport**

```bash
cd web && npm run dev
```
Open DevTools → toggle device toolbar → iPhone SE (375px) — verify all sections stack correctly.

- [ ] **Step 12: Commit**

```bash
git add web/src/
git commit -m "feat(web): add mobile responsive breakpoints across all sections"
```

---

## Task 16: Build Verification

- [ ] **Step 1: Run production build**

```bash
cd web && npm run build
```
Expected: `dist/` generated with no TypeScript or Vite errors.

- [ ] **Step 2: Preview production build**

```bash
cd web && npm run preview
```
Visit `http://localhost:4173` — verify all routes work, no blank pages.

- [ ] **Step 3: Run final test suite**

```bash
cd web && npx vitest run
```
Expected: all PASS

- [ ] **Step 4: Final commit**

```bash
git add web/
git commit -m "feat(web): vernonedu public landing site — production ready"
```

---

## Self-Review

**Spec coverage check:**

| Spec Requirement | Covered In |
|---|---|
| Multi-page architecture (7 routes) | Task 6 App.tsx |
| Nav: 6 links + Daftar CTA | Task 5 Nav.tsx |
| Hero: headline + chooser + stats | Task 7 |
| Sertifikasi Band (BNSP + SKKNI) | Task 8 CertBand.tsx |
| Partner list chips | Task 8 PartnerList.tsx |
| Course ticker marquee | Task 8 CourseTicker.tsx |
| Kelas Batch section + BatchCard | Task 9 + Task 4 |
| Features (incl. Talent Pool) | Task 9 FeaturesSection.tsx |
| Testimoni asymmetric | Task 9 TestimonialSection.tsx |
| B2B section + Talent Pool card | Task 10 |
| Blog preview section | Task 10 |
| CTA Band | Task 10 |
| FAQ (accordion, 5 items) | Task 10 |
| Footer 4-col | Task 5 |
| `/batch` listing page + filters | Task 12 |
| `/students` page | Task 13 |
| `/partners` page + contact | Task 13 |
| `/blog` index | Task 14 |
| `/blog/:slug` post + 404 | Task 14 |
| `/about` + contact | Task 14 |
| Mobile responsive | Task 15 |
| Brand tokens from frontend | Task 2 + 3 (Tailwind config) |

**No gaps found.**
