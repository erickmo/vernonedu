import { Link } from 'react-router-dom'
import { LINKS } from '../../tokens'

const LEARN_LINKS = [
  { label: 'Katalog Kursus',        to: '/students' },
  { label: 'Kelas Batch',           to: '/batch' },
  { label: 'Kelas Private',         to: '/students#private' },
  { label: 'Talent Pool',           href: LINKS.talentPool },
  { label: 'Verifikasi Sertifikat', href: LINKS.verify },
]

const PARTNER_LINKS = [
  { label: 'Program Mitra',       to: '/partners' },
  { label: 'Hubungi Partnership', to: '/partners#contact' },
  { label: 'Akses Talent Pool',   href: LINKS.talentPool },
]

const COMPANY_LINKS = [
  { label: 'Tentang Kami',      to: '/about' },
  { label: 'Blog',              to: '/blog' },
  { label: 'Kontak',            to: '/about#contact' },
  { label: 'Kebijakan Privasi', to: '/privacy' },
]

type FooterLink =
  | { label: string; to: string; href?: never }
  | { label: string; href: string; to?: never }

function FooterLinkItem({ link }: { link: FooterLink }) {
  const cls = "block text-[0.8rem] text-white/40 hover:text-brand-200 transition-colors mb-2.5"
  if ('href' in link) {
    return <a href={link.href} className={cls}>{link.label}</a>
  }
  return <Link to={link.to} className={cls}>{link.label}</Link>
}

export function Footer() {
  return (
    <footer className="bg-brand-900">
      <div className="max-w-[1200px] mx-auto px-6 md:px-12 pt-16 pb-12 grid grid-cols-2 md:grid-cols-[2fr_1fr_1fr_1fr] gap-8 md:gap-12">
        <div>
          <div className="text-[1.35rem] font-black text-white mb-3">
            Vernon<span className="text-brand-200">Edu</span>
          </div>
          <p className="text-[0.8rem] text-white/25 leading-relaxed max-w-[240px]">
            Pendidikan yang relevan, fleksibel, dan berdampak untuk semua kalangan di Indonesia.
          </p>
        </div>

        <div>
          <h5 className="text-[0.65rem] font-bold tracking-[2px] uppercase text-white/25 mb-5">Belajar</h5>
          {LEARN_LINKS.map(link => <FooterLinkItem key={link.label} link={link} />)}
        </div>

        <div>
          <h5 className="text-[0.65rem] font-bold tracking-[2px] uppercase text-white/25 mb-5">Institusi</h5>
          {PARTNER_LINKS.map(link => <FooterLinkItem key={link.label} link={link} />)}
        </div>

        <div>
          <h5 className="text-[0.65rem] font-bold tracking-[2px] uppercase text-white/25 mb-5">Perusahaan</h5>
          {COMPANY_LINKS.map(link => <FooterLinkItem key={link.label} link={link} />)}
        </div>
      </div>

      <div className="border-t border-white/5 max-w-[1200px] mx-auto px-6 md:px-12 py-5 flex flex-col md:flex-row gap-1 justify-between text-[0.72rem] text-white/20">
        <span>© 2025 VernonEdu. All rights reserved.</span>
        <span>Made in Indonesia 🇮🇩</span>
      </div>
    </footer>
  )
}
