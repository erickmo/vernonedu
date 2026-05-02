import { useState, KeyboardEvent } from 'react'
import { X } from 'lucide-react'
import Input from '@/components/ui/Input'

interface Props {
  value: string[]
  onChange: (next: string[]) => void
  placeholder?: string
  disabled?: boolean
}

export default function MultiInput({ value, onChange, placeholder, disabled }: Props) {
  const [draft, setDraft] = useState('')

  function addChip() {
    const trimmed = draft.trim()
    if (!trimmed) return
    if (value.includes(trimmed)) {
      setDraft('')
      return
    }
    onChange([...value, trimmed])
    setDraft('')
  }

  function removeChip(idx: number) {
    onChange(value.filter((_, i) => i !== idx))
  }

  function onKey(e: KeyboardEvent<HTMLInputElement>) {
    if (e.key === 'Enter') {
      e.preventDefault()
      addChip()
    } else if (e.key === 'Backspace' && draft === '' && value.length > 0) {
      removeChip(value.length - 1)
    }
  }

  return (
    <div className="space-y-2">
      <div className="flex flex-wrap gap-1.5">
        {value.map((chip, i) => (
          <span
            key={`${chip}-${i}`}
            className="inline-flex items-center gap-1 px-2 py-0.5 text-xs bg-neutral-100 text-neutral-700 rounded-full"
          >
            {chip}
            {!disabled && (
              <button
                type="button"
                onClick={() => removeChip(i)}
                className="hover:text-red-600"
                aria-label={`Remove ${chip}`}
              >
                <X className="w-3 h-3" />
              </button>
            )}
          </span>
        ))}
      </div>
      <Input
        value={draft}
        onChange={(e) => setDraft(e.target.value)}
        onKeyDown={onKey}
        onBlur={addChip}
        placeholder={placeholder ?? 'Type and press Enter'}
        disabled={disabled}
      />
    </div>
  )
}
