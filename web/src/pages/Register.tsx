import { Link } from 'react-router-dom'

export function Register() {
  return (
    <div className="min-h-screen bg-white">
      <div className="bg-brand-900 px-12 pt-24 pb-16">
        <div className="max-w-[1200px] mx-auto">
          <p className="text-[0.7rem] font-bold tracking-[3px] uppercase text-brand-300 mb-3">
            Pendaftaran
          </p>
          <h1 className="text-[2.5rem] font-black tracking-[-2px] text-white leading-tight">
            Daftar Kelas Batch
          </h1>
          <p className="text-[1rem] text-white/50 mt-3 max-w-[480px] leading-relaxed">
            Isi formulir di bawah atau hubungi kami langsung untuk mendaftar.
          </p>
        </div>
      </div>

      <div className="px-12 py-16">
        <div className="max-w-[640px] mx-auto">
          <div className="border border-brand-100 rounded-2xl p-8 space-y-5">
            <div>
              <label className="text-sm font-bold text-brand-900 block mb-1.5">Nama Lengkap</label>
              <input
                type="text"
                placeholder="Nama kamu"
                className="w-full border border-brand-100 rounded-xl px-4 py-3 text-sm text-slate-700 focus:outline-none focus:border-brand-400 transition-colors"
              />
            </div>
            <div>
              <label className="text-sm font-bold text-brand-900 block mb-1.5">Email</label>
              <input
                type="email"
                placeholder="email@kamu.com"
                className="w-full border border-brand-100 rounded-xl px-4 py-3 text-sm text-slate-700 focus:outline-none focus:border-brand-400 transition-colors"
              />
            </div>
            <div>
              <label className="text-sm font-bold text-brand-900 block mb-1.5">No. WhatsApp</label>
              <input
                type="tel"
                placeholder="08xxxxxxxxxx"
                className="w-full border border-brand-100 rounded-xl px-4 py-3 text-sm text-slate-700 focus:outline-none focus:border-brand-400 transition-colors"
              />
            </div>
            <div>
              <label className="text-sm font-bold text-brand-900 block mb-1.5">Kelas yang diminati</label>
              <select className="w-full border border-brand-100 rounded-xl px-4 py-3 text-sm text-slate-700 focus:outline-none focus:border-brand-400 transition-colors bg-white">
                <option value="">Pilih kelas...</option>
                <option>English for Professionals</option>
                <option>UI/UX Design Fundamentals</option>
                <option>Python for Data Analysis</option>
              </select>
            </div>
            <button
              type="button"
              className="w-full py-3 bg-brand-500 text-white text-sm font-bold rounded-xl hover:bg-brand-600 transition-colors"
            >
              Kirim Pendaftaran
            </button>
          </div>

          <p className="text-sm text-center text-slate-400 mt-8">
            Atau{' '}
            <Link to="/batch" className="text-brand-500 font-semibold hover:text-brand-700">
              kembali lihat jadwal batch
            </Link>
          </p>
        </div>
      </div>
    </div>
  )
}
