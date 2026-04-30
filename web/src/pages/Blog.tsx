import { BLOG_POSTS } from '../data/blog-posts'
import { BlogCard } from '../components/shared/BlogCard'

export function Blog() {
  const featured = BLOG_POSTS.find(p => p.featured)!
  const rest = BLOG_POSTS.filter(p => !p.featured)

  return (
    <div className="min-h-screen bg-white">
      <div className="bg-brand-900 px-12 pt-24 pb-16">
        <div className="max-w-[1200px] mx-auto">
          <p className="text-[0.7rem] font-bold tracking-[3px] uppercase text-brand-300 mb-3">Blog</p>
          <h1 className="text-[2.5rem] font-black tracking-[-2px] text-white">
            Tips, Insight &amp; Inspirasi Belajar
          </h1>
        </div>
      </div>

      <div className="px-12 py-16">
        <div className="max-w-[1200px] mx-auto">
          <div className="grid grid-cols-1 md:grid-cols-[2fr_1fr_1fr] gap-5 mb-5">
            <BlogCard post={featured} featured />
            {rest.slice(0, 2).map(p => <BlogCard key={p.id} post={p} />)}
          </div>
          {rest.length > 2 && (
            <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
              {rest.slice(2).map(p => <BlogCard key={p.id} post={p} />)}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
