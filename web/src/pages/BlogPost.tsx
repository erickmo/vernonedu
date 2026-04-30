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

      <div className="px-12 py-16">
        <div className="max-w-[720px] mx-auto">
          <p className="text-[0.95rem] text-slate-600 leading-[1.85]">{post.content}</p>
        </div>
      </div>
    </div>
  )
}
