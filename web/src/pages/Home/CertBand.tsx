const CERTS = [
  { icon: '🏛️', name: 'Terakreditasi BNSP', sub: 'Badan Nasional Sertifikasi Profesi' },
  { icon: '📜', name: 'Berbasis SKKNI',    sub: 'Standar Kompetensi Kerja Nasional Indonesia' },
  { icon: '✅', name: 'Sertifikat Terverifikasi Digital', sub: 'Dapat dicek online kapan saja' },
]

export function CertBand() {
  return (
    <div className="bg-brand-900 py-6 px-12">
      <div className="max-w-[1200px] mx-auto flex flex-col md:flex-row items-center justify-center gap-6 md:gap-0">
        {CERTS.map((cert, i) => (
          <div key={cert.name} className="flex items-center gap-3">
            {i > 0 && <div className="hidden md:block w-px h-9 bg-white/10 mx-9" />}
            <div className="w-11 h-11 rounded-xl bg-white/10 border border-white/15 flex items-center justify-center text-xl shrink-0">
              {cert.icon}
            </div>
            <div>
              <p className="text-[0.875rem] font-black text-white">{cert.name}</p>
              <p className="text-[0.7rem] text-white/40 mt-0.5">{cert.sub}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
