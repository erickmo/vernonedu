interface TableCardProps {
  children: React.ReactNode
}

export default function TableCard({ children }: TableCardProps) {
  return (
    <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] overflow-hidden">
      {children}
    </div>
  )
}
