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
