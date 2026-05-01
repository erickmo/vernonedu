# Hero Section Redesign — Professional & Elegant

**Date:** 2026-05-01  
**Status:** Approved  
**Goal:** Modernize hero section for better visual appeal and conversion focus

## Overview

Redesign the homepage hero section from current gradient-blob aesthetic to a premium, professional look with education-focused photography. Layout remains 2-column structure but integrates photo as full-screen background with dark overlay, eliminating stats strip and moving audience chooser below for cleaner focus.

## Design Decisions

### 1. Layout: Full-Screen Photo + Overlay

- **What:** Hero background = full-width education photo with dark gradient overlay
- **Why:** Premium, modern feel; establishes brand authority; education context visible without clutter
- **Implementation:** 
  - Background: education-focused photography (students, learning, classroom moments)
  - Overlay: dark gradient `rgba(46, 26, 55, 0.82)` to `rgba(149, 97, 171, 0.70)` for readability
  - Content layer: headline, description, CTAs positioned left-aligned within overlay
  - No additional decorative elements (blobs, shapes, etc.)

### 2. Content on Overlay

- **Left-aligned text:** Maximum width ~600px, ensures legibility and balanced composition
- **Eyebrow label:** "● LEMBAGA PENDIDIKAN INFORMAL" 
  - Style: `text-xs` (0.8rem), uppercase, `font-bold`, semi-transparent white
  - Background: `rgba(255,255,255,0.12)` with `backdrop-filter: blur(8px)` for frosted glass effect
  - Spacing: `mb-7` below label
  
- **Headline:** "Belajar Lebih. Raih Lebih."
  - Style: `text-4xl` (3.5rem), `font-black`, `leading-1.05`, `tracking-tight`
  - Color: White text, italic "Raih Lebih" in light accent color
  - Spacing: `mb-6` below headline
  
- **Description:** 1–2 sentence value proposition
  - Style: `text-lg` (1.125rem), medium weight, white with `opacity-80`
  - Length: ~80 words max
  - Spacing: `mb-8` below description
  
- **CTAs:** Two buttons, horizontal layout
  - Primary: White background, brand-color text, solid button
    - Padding: `px-8 py-4`, `rounded-full`, `font-bold`
    - Shadow: subtle box-shadow for depth
  - Secondary: Outline button, white text, transparent background
    - Border: 2px white/30% opacity
    - Padding: `px-8 py-4`, `rounded-full`, `font-semibold`
  - Gap: `gap-5` between buttons
  - Hover states: White button darkens, outline button border brightens

### 3. Remove Stats Strip

- **What:** Delete the bottom stats section (12K+ students, 500+ courses, etc.)
- **Why:** Keeps hero focused, reduces visual clutter, premium/elegant aesthetic
- **Impact:** Hero section becomes more purposeful, cleaner scroll experience

### 4. Move Audience Chooser Below Hero

- **Location:** Separate section immediately below hero
- **Layout:** Two-column grid on desktop, cards side-by-side
  - Card style: Light border (`border-1.5px #edd5f8`), white background, `rounded-2xl`
  - Content: Icon (emoji) + title + subtitle + arrow
  - Hover state: Border color intensifies, shadow appears, slight translate-x
  
- **Section spacing:**
  - Background: White
  - Padding: `py-16` (`4rem`), `px-12`
  - Max-width: 1200px, centered
  
- **Cards:**
  - Grid: `grid-cols-1 md:grid-cols-2`, `gap-6`
  - Card content:
    - Icon container: 48×48px, `rounded-xl`, light background
    - Title: `text-lg` (1.125rem), `font-black`, brand-color
    - Subtitle: `text-sm` (1rem), gray text, 1.5 line-height
    - Arrow: right-aligned, brand-color, scale on hover

### 5. Typography Scale (from tailwind config)

```
xs:   0.8rem   (labels, meta)
sm:   1rem     (body text, descriptions)
base: 1.13rem  (main content)
lg:   1.38rem  (subheadings)
xl:   1.69rem  (prominent text)
```

## Visual Hierarchy

1. **Headline** — Most prominent, establishes core message
2. **Description** — Secondary, clarifies value
3. **Primary CTA** — Visual weight via color, highest conversion action
4. **Secondary CTA** — Lower emphasis, alternative path
5. **Audience chooser** — Tertiary layer below, guides routing

## Accessibility

- **Color contrast:** White text on overlay meets WCAG AA (4.5:1 ratio)
- **Interactive elements:** Buttons have sufficient padding for touch targets (min 44×44px)
- **Alternative text:** Hero photo gets descriptive alt text ("students collaborating in classroom")
- **Focus states:** Buttons have visible outline on focus

## Success Criteria

- ✅ Modern, professional aesthetic vs. current gradient-blob design
- ✅ Cleaner hero without stats strip (less cognitive load)
- ✅ Education photo establishes credibility and context
- ✅ CTAs remain prominent and accessible
- ✅ Audience chooser logically separated below
- ✅ Full-width design feels intentional, not empty
- ✅ Overlay readability maintained across photo variations

## Browser & Device Support

- Desktop: Full-screen photo + content
- Tablet: Responsive scaling, photo still visible
- Mobile: 
  - Single-column layout (content stack vertically over photo)
  - Text sizes scale responsively (`clamp()` for headlines)
  - CTAs remain accessible (touch-friendly padding)

## Dependencies

- Education-focused placeholder image (Unsplash or stock library)
- No new packages; uses existing Tailwind utilities
- Existing color palette extended with overlay transparency

## Future Iterations

- Swap placeholder with actual branded photography
- A/B test CTA button placement / copy
- Monitor conversion metrics vs. current design
