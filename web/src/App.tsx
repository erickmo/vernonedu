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
