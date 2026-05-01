import { Link } from 'react-router-dom'

const CHOOSER_ITEMS = [
  {
    icon: '🎓',
    name: 'Siswa / Pelajar',
    sub: 'Daftar kursus regular, private, atau kelas batch',
    to: '/students',
  },
  {
    icon: '🏫',
    name: 'Mitra Institusi',
    sub: 'Sekolah, kampus, atau perusahaan',
    to: '/partners',
  },
]

export function AudienceChooser() {
  return (
    <section className="bg-white py-16 px-12">
      <div className="max-w-[1200px] mx-auto">
        <p className="text-xs font-bold tracking-[2px] uppercase text-brand-500 mb-4">
          Saya adalah...
        </p>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {CHOOSER_ITEMS.map(item => (
            <Link
              key={item.to}
              to={item.to}
              className="flex items-center gap-5 p-6 bg-white border-[1.5px] border-brand-100 rounded-2xl hover:border-brand-300 hover:shadow-md hover:translate-x-1 transition-all group"
            >
              <div className="w-12 h-12 rounded-xl bg-brand-50 flex items-center justify-center text-2xl shrink-0">
                {item.icon}
              </div>
              <div className="flex-1">
                <h3 className="text-lg font-black text-brand-900 mb-1">
                  {item.name}
                </h3>
                <p className="text-sm text-slate-500 leading-relaxed">
                  {item.sub}
                </p>
              </div>
              <span className="text-brand-500 font-bold text-xl group-hover:translate-x-0.5 transition-transform">
                →
              </span>
            </Link>
          ))}
        </div>
      </div>
    </section>
  )
}
