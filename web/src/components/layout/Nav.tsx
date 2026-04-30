import { useState } from 'react'
import { NavLink } from 'react-router-dom'
import { LINKS } from '../../tokens'

const NAV_LINKS = [
  { to: '/',         label: 'Beranda' },
  { to: '/batch',    label: 'Kelas Batch' },
  { to: '/partners', label: 'Mitra' },
  { to: '/blog',     label: 'Blog' },
  { to: '/about',    label: 'Tentang' },
]

export function Nav() {
  const [open, setOpen] = useState(false)

  return (
    <nav className="fixed top-0 inset-x-0 z-50 bg-white/85 backdrop-blur-md border-b border-brand-100">
      <div className="flex justify-between items-center px-6 md:px-12 py-4">
        <NavLink to="/" className="text-[1.1rem] font-black tracking-tight text-brand-900">
          Vernon<span className="text-brand-500">Edu</span>
        </NavLink>

        {/* desktop links */}
        <ul className="hidden md:flex gap-8 list-none">
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

        {/* desktop CTA */}
        <a
          href={LINKS.register}
          className="hidden md:block bg-brand-500 text-white text-[0.8rem] font-bold px-5 py-2 rounded-full hover:bg-brand-600 transition-colors"
        >
          Daftar Sekarang
        </a>

        {/* mobile hamburger */}
        <button
          className="md:hidden p-2 text-brand-500 text-xl"
          onClick={() => setOpen(!open)}
          aria-label="Toggle menu"
        >
          {open ? '✕' : '☰'}
        </button>
      </div>

      {/* mobile drawer */}
      {open && (
        <div className="md:hidden bg-white border-t border-brand-100 px-6 py-5 flex flex-col gap-4">
          {NAV_LINKS.map(link => (
            <NavLink
              key={link.to}
              to={link.to}
              end={link.to === '/'}
              onClick={() => setOpen(false)}
              className={({ isActive }) =>
                `text-sm font-semibold ${isActive ? 'text-brand-900' : 'text-slate-400'}`
              }
            >
              {link.label}
            </NavLink>
          ))}
          <a
            href={LINKS.register}
            className="mt-2 bg-brand-500 text-white text-sm font-bold px-5 py-3 rounded-full text-center"
          >
            Daftar Sekarang
          </a>
        </div>
      )}
    </nav>
  )
}
