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
          seeAll={{ label: 'Semua Artikel', to: '/blog' }}
        />
        <div className="grid grid-cols-1 md:grid-cols-[2fr_1fr_1fr] gap-5">
          <BlogCard post={featured} featured />
          {compact.map(post => <BlogCard key={post.id} post={post} />)}
        </div>
      </div>
    </section>
  )
}
