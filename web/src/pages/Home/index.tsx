import { Hero } from './Hero'
import { AudienceChooser } from './AudienceChooser'
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
      <AudienceChooser />
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
