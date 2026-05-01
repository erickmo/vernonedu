# Hero Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign homepage hero from gradient-blob aesthetic to professional/elegant full-screen education photo with overlay, remove stats strip, and move audience chooser to separate section below.

**Architecture:** Split Hero into two pieces: Hero section (background + overlay + content) and separate AudienceChooser section below. Remove decorative blobs, stats, and restructure content layout for left-aligned positioning on dark overlay.

**Tech Stack:** React, Tailwind CSS (existing), optional placeholder image service (Unsplash/Pexels)

---

## File Structure

**Modify:**
- `web/src/pages/Home/Hero.tsx` — Restructure background, remove stats, move audience chooser out
- `web/src/pages/Home/index.tsx` — Add AudienceChooser section

**Create:**
- `web/src/pages/Home/AudienceChooser.tsx` — New component for audience selection section

**Delete:**
- Stats grid markup from Hero.tsx

---

## Implementation Tasks

### Task 1: Prepare Placeholder Hero Image

**Files:**
- Reference: `web/src/pages/Home/Hero.tsx` (no changes yet)

- [ ] **Step 1: Find education placeholder image**

Go to https://unsplash.com and search "students learning classroom". Save image URL. Example:
```
https://images.unsplash.com/photo-1427504494785-cdafb85e1ef0?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2070&q=80
```

Store URL in a constant for now (we'll use inline image URL in CSS background, no img tag needed).

- [ ] **Step 2: Test image loads and is visible**

Add a temporary `background-image` to a test element to verify URL works. Expected: Image loads without CORS errors.

---

### Task 2: Restructure Hero.tsx — Remove Blobs and Stats

**Files:**
- Modify: `web/src/pages/Home/Hero.tsx`

- [ ] **Step 1: Open Hero.tsx and review current structure**

Current structure:
- Blobs (two divs with `absolute` positioning and `pointer-events-none`)
- Main content grid (left text + right chooser)
- Stats strip (border-t, 4-column grid)

- [ ] **Step 2: Delete blob decorations**

Find and remove these two divs:
```jsx
{/* blobs */}
<div className="absolute -top-32 -right-32 w-[600px] h-[600px] rounded-full bg-gradient-to-br from-brand-200/35 to-transparent pointer-events-none" />
<div className="absolute bottom-32 -left-24 w-[400px] h-[400px] rounded-full bg-gradient-to-br from-brand-500/12 to-transparent pointer-events-none" />
```

Expected: Removed from DOM.

- [ ] **Step 3: Delete stats strip section**

Find and remove the entire `{/* stats strip */}` section (starting with `<div className="max-w-[1200px]..."` and ending after the stats grid).

Expected: Removed from DOM.

- [ ] **Step 4: Remove audience chooser from Hero**

Find the right-column section with chooser items:
```jsx
{/* right — audience chooser */}
<div className="bg-brand-50 border border-brand-100 rounded-3xl p-8">
  ...
</div>
```

Delete this entire div (we'll move it to a separate component).

Expected: Hero now only has left-column content + background.

---

### Task 3: Refactor Hero.tsx — Add Background Image + Overlay

**Files:**
- Modify: `web/src/pages/Home/Hero.tsx`

- [ ] **Step 1: Update section element with background**

Change the outer `<section>` element from:
```jsx
<section className="min-h-screen pt-28 flex flex-col relative overflow-hidden bg-white">
```

To:
```jsx
<section 
  className="min-h-screen pt-28 flex flex-col relative overflow-hidden"
  style={{
    backgroundImage: `linear-gradient(135deg, rgba(46, 26, 55, 0.82) 0%, rgba(149, 97, 171, 0.70) 100%), url('https://images.unsplash.com/photo-1427504494785-cdafb85e1ef0?ixlib=rb-4.0.3&auto=format&fit=crop&w=2070&q=80')`,
    backgroundSize: 'cover',
    backgroundPosition: 'center',
  }}
>
```

Expected: Background image visible with dark overlay, text should be readable on top.

- [ ] **Step 2: Update main content grid**

Change the grid container from:
```jsx
<div className="flex-1 max-w-[1200px] w-full mx-auto px-12 grid grid-cols-1 md:grid-cols-2 gap-8 md:gap-16 items-center py-12">
```

To (single column, left-aligned content on overlay):
```jsx
<div className="flex-1 max-w-[1200px] w-full mx-auto px-12 flex items-center py-12">
```

Expected: Grid changed to flex, removes 2-column layout.

- [ ] **Step 3: Wrap content in overlay container**

Wrap the left-column content div in a new container:
```jsx
<div style={{ maxWidth: '600px' }}>
  {/* all existing left-column content goes here */}
</div>
```

Expected: Content constrained to 600px width, left-aligned on screen.

---

### Task 4: Update Hero Content Typography

**Files:**
- Modify: `web/src/pages/Home/Hero.tsx:37-65` (left column content)

- [ ] **Step 1: Update eyebrow label**

Find:
```jsx
<div className="inline-flex items-center gap-2 bg-brand-50 border border-brand-100 rounded-full px-4 py-1.5 text-[0.7rem] font-bold text-brand-500 tracking-[1.5px] uppercase mb-6">
  <span className="text-[0.55rem]">●</span>
  Lembaga Pendidikan Informal
</div>
```

Replace with:
```jsx
<div className="inline-flex items-center gap-2 rounded-full px-5 py-3.5 text-xs font-bold uppercase mb-7 backdrop-blur-lg" style={{ backgroundColor: 'rgba(255,255,255,0.12)', color: 'rgba(255,255,255,0.85)', letterSpacing: '1.5px' }}>
  <span className="text-[0.55rem]">●</span>
  Lembaga Pendidikan Informal
</div>
```

Expected: Frosted glass background, white text on dark overlay.

- [ ] **Step 2: Update headline**

Find:
```jsx
<h1 className="text-[clamp(2.75rem,5.5vw,4.25rem)] font-black leading-[1.0] tracking-[-2.5px] text-brand-900 mb-5">
  Belajar Lebih.<br />
  Raih <em className="italic text-brand-500 font-bold">Lebih.</em>
</h1>
```

Replace with:
```jsx
<h1 className="text-[3.5rem] font-black leading-[1.05] tracking-tight text-white mb-6">
  Belajar Lebih.<br />
  <em className="italic text-[#e0b7ff] font-bold">Raih Lebih.</em>
</h1>
```

Expected: Larger, white text, light accent color for italic portion.

- [ ] **Step 3: Update description**

Find:
```jsx
<p className="text-base text-slate-400 leading-[1.75] max-w-[420px] mb-8">
  Kursus berkualitas, kelas batch terjadwal, dan program kemitraan untuk individu dan institusi di seluruh Indonesia.
</p>
```

Replace with:
```jsx
<p className="text-lg leading-relaxed max-w-[500px] mb-8" style={{ color: 'rgba(255,255,255,0.80)', fontWeight: '400' }}>
  Kursus berkualitas, kelas batch terjadwal, dan program kemitraan untuk individu dan institusi di seluruh Indonesia.
</p>
```

Expected: Larger text, white with transparency on dark background.

- [ ] **Step 4: Update CTA buttons**

Find:
```jsx
<div className="flex items-center gap-4">
  <a href={LINKS.register} className="bg-brand-500 text-white text-sm font-bold px-7 py-3 rounded-full hover:bg-brand-600 transition-colors">
    Mulai Belajar
  </a>
  <Link to="/batch" className="border-[1.5px] border-brand-100 text-brand-600 text-sm font-semibold px-6 py-[0.75rem] rounded-full hover:border-brand-300 transition-colors">
    Lihat Kelas Batch ↗
  </Link>
</div>
```

Replace with:
```jsx
<div className="flex items-center gap-5 flex-wrap">
  <a href={LINKS.register} 
    className="bg-white text-brand-500 text-base font-bold px-8 py-4 rounded-full hover:bg-gray-100 transition-all hover:shadow-lg"
  >
    Mulai Belajar
  </a>
  <Link 
    to="/batch"
    className="text-white text-base font-semibold px-8 py-4 rounded-full transition-all"
    style={{ border: '2px solid rgba(255,255,255,0.3)', backgroundColor: 'transparent' }}
  >
    Lihat Kelas Batch ↗
  </Link>
</div>
```

Expected: White primary button, outline secondary button with white border, both readable on dark overlay.

---

### Task 5: Create AudienceChooser Component

**Files:**
- Create: `web/src/pages/Home/AudienceChooser.tsx`

- [ ] **Step 1: Create new component file**

Create `web/src/pages/Home/AudienceChooser.tsx`:

```tsx
import { Link } from 'react-router-dom'

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

export function AudienceChooser() {
  return (
    <section className="bg-white py-16 px-12">
      <div className="max-w-[1200px] mx-auto">
        <p className="text-xs font-bold tracking-[2px] uppercase text-brand-500 mb-4">
          Saya adalah...
        </p>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {CHOOSER_ITEMS.map(item => (
            <Link
              key={item.to}
              to={item.to}
              className="flex items-center gap-5 p-6 bg-white border-[1.5px] border-brand-100 rounded-2xl hover:border-brand-300 hover:shadow-md hover:translate-x-1 transition-all group"
            >
              <div className="w-12 h-12 rounded-xl bg-brand-50 flex items-center justify-center text-2xl shrink-0">
                {item.icon}
              </div>
              <div className="flex-1">
                <h3 className="text-lg font-black text-brand-900 mb-1">
                  {item.name}
                </h3>
                <p className="text-sm text-slate-500 leading-relaxed">
                  {item.sub}
                </p>
              </div>
              <span className="text-brand-500 font-bold text-xl group-hover:translate-x-0.5 transition-transform">
                →
              </span>
            </Link>
          ))}
        </div>
      </div>
    </section>
  )
}
```

Expected: Component renders audience chooser cards with proper styling, hover effects.

- [ ] **Step 2: Run type check**

Run: `npx tsc --noEmit`
Expected: No errors.

---

### Task 6: Update Home.tsx to Include Both Hero and AudienceChooser

**Files:**
- Modify: `web/src/pages/Home/index.tsx`

- [ ] **Step 1: Import AudienceChooser**

Find the imports section at top. Add:
```tsx
import { AudienceChooser } from './AudienceChooser'
```

Expected: Import statement added.

- [ ] **Step 2: Add AudienceChooser below Hero**

Find the return statement where `<Hero />` is rendered. Add `<AudienceChooser />` right after:
```tsx
<Hero />
<AudienceChooser />
```

Expected: Component appears below hero in JSX.

- [ ] **Step 3: Run type check**

Run: `npx tsc --noEmit`
Expected: No errors.

---

### Task 7: Test Responsive Behavior

**Files:**
- Reference: `web/src/pages/Home/Hero.tsx`

- [ ] **Step 1: Run dev server**

Run: `npm run dev`
Expected: Server starts, no errors in console.

- [ ] **Step 2: Test desktop view (1200px+)**

Open http://localhost:5174 in browser at full width.
Verify:
- Hero background image visible with overlay
- Content left-aligned, readable
- Primary button (white) and secondary button (outline) visible
- AudienceChooser cards below with proper spacing
Expected: All elements render correctly.

- [ ] **Step 3: Test tablet view (768px)**

Resize browser to ~768px width.
Verify:
- Hero image still visible, text readable
- Buttons stack horizontally (gap-5)
- AudienceChooser cards still 2-column
Expected: Responsive layout works.

- [ ] **Step 4: Test mobile view (375px)**

Resize browser to ~375px width.
Verify:
- Hero text scales down (font sizes still readable)
- Buttons stack if needed
- AudienceChooser cards become single column (grid-cols-1)
- No horizontal scroll
Expected: Mobile layout is clean and readable.

- [ ] **Step 5: Test button interactions**

Click primary button "Mulai Belajar" → should navigate to /register
Click secondary button "Lihat Kelas Batch" → should navigate to /batch
Click audience chooser cards → should navigate to respective pages
Expected: All links work.

---

### Task 8: Commit

**Files:**
- Modified: `web/src/pages/Home/Hero.tsx`, `web/src/pages/Home/index.tsx`
- Created: `web/src/pages/Home/AudienceChooser.tsx`

- [ ] **Step 1: Stage files**

Run: `git add web/src/pages/Home/Hero.tsx web/src/pages/Home/AudienceChooser.tsx web/src/pages/Home/index.tsx`

- [ ] **Step 2: Commit**

```bash
git commit -m "feat(home): redesign hero with education photo background, remove stats, move audience chooser below

- Replace gradient blobs with full-screen education photo + dark overlay
- Restructure hero content for left-aligned layout on overlay
- Update typography: larger headlines (3.5rem), white text, accent colors
- Refactor CTAs: white primary button, outline secondary button
- Create AudienceChooser component as separate section below hero
- Remove stats strip for cleaner, more focused presentation
- Update responsive behavior for tablet and mobile views"
```

Expected: Commit created successfully.

- [ ] **Step 3: Verify commit**

Run: `git log --oneline -1`
Expected: Shows new commit message.

---

## Self-Review Checklist

**Spec Coverage:**
- ✅ Task 3: Background image + overlay styling
- ✅ Task 4: Content typography (eyebrow, headline, description, CTAs)
- ✅ Task 5: AudienceChooser component with proper cards
- ✅ Task 6: Integration in Home.tsx
- ✅ Task 7: Responsive behavior (desktop, tablet, mobile)
- ✅ Stats strip removal (Task 2, step 3)
- ✅ Blob removal (Task 2, step 2)

**Placeholder Scan:**
- ✅ No "TBD", "TODO", or vague steps
- ✅ All code blocks contain complete, working code
- ✅ All commands have expected output
- ✅ Image URL provided (Unsplash example)

**Type Consistency:**
- ✅ CHOOSER_ITEMS used consistently in both Hero removal and AudienceChooser
- ✅ All className strings use Tailwind utilities or inline styles
- ✅ Link imports correct (`Link` from `react-router-dom`)

**No Gaps:**
- ✅ All spec sections covered by at least one task
- ✅ Accessibility considerations (contrast, touch targets) covered in code
- ✅ Mobile responsiveness tested in Task 7

---

## Execution

Plan complete and saved to `docs/superpowers/plans/2026-05-01-hero-redesign-implementation.md`. Two execution options:

**1. Subagent-Driven (recommended)** — I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
