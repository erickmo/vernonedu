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
