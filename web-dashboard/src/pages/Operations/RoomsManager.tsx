import { useState } from 'react'
import { DoorOpen, Plus, Trash2, Pencil, X } from 'lucide-react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { Field } from '@/widgets/FormPageTemplate'
import { toast } from '@/widgets/Toast/Toast'
import { locationService } from '@/services/location.service'
import formStyles from '@/widgets/FormPageTemplate/FormPageTemplate.module.css'

// ─── Types ────────────────────────────────────────────────────────────────────

export interface Room {
  id: string
  name: string
  capacity?: number
  floor?: string
  facilities?: string[]
  description?: string
}

interface RoomFormState {
  name: string
  capacity: string
  floor: string
  facilities: string[]
  facilityInput: string
  description: string
}

const EMPTY: RoomFormState = {
  name: '', capacity: '', floor: '', facilities: [], facilityInput: '', description: '',
}

// ─── RoomForm ─────────────────────────────────────────────────────────────────

function RoomForm({
  initial,
  onSave,
  onCancel,
  isSaving,
}: {
  initial?: RoomFormState
  onSave: (data: RoomFormState) => Promise<void>
  onCancel: () => void
  isSaving: boolean
}) {
  const [form, setForm] = useState<RoomFormState>(initial ?? EMPTY)
  const [errors, setErrors] = useState<Record<string, string>>({})

  function set(key: keyof RoomFormState, val: string | string[]) {
    setForm(prev => ({ ...prev, [key]: val }))
  }

  function addFacility() {
    const f = form.facilityInput.trim()
    if (!f || form.facilities.includes(f)) return
    set('facilities', [...form.facilities, f])
    set('facilityInput', '')
  }

  function removeFacility(f: string) {
    set('facilities', form.facilities.filter(x => x !== f))
  }

  function validate() {
    const e: Record<string, string> = {}
    if (!form.name.trim()) e.name = 'Nama ruangan wajib diisi'
    if (form.capacity && isNaN(Number(form.capacity))) e.capacity = 'Harus angka'
    setErrors(e)
    return Object.keys(e).length === 0
  }

  return (
    <div style={{
      border: '1px solid var(--color-border)', borderRadius: 'var(--radius-lg)',
      padding: 'var(--space-4)', background: 'var(--color-surface-elevated)',
      marginBottom: 'var(--space-3)',
    }}>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--space-3)' }}>
        <Field label="Nama Ruangan" required error={errors.name}>
          <input
            className={`${formStyles.input} ${errors.name ? formStyles.inputError : ''}`}
            value={form.name}
            onChange={e => set('name', e.target.value)}
            placeholder="cth. Ruang A1"
            autoFocus
          />
        </Field>
        <Field label="Kapasitas" hint="Jumlah orang" error={errors.capacity}>
          <input
            className={`${formStyles.input} ${errors.capacity ? formStyles.inputError : ''}`}
            type="number"
            min={1}
            value={form.capacity}
            onChange={e => set('capacity', e.target.value)}
            placeholder="cth. 30"
          />
        </Field>
        <Field label="Lantai">
          <input
            className={formStyles.input}
            value={form.floor}
            onChange={e => set('floor', e.target.value)}
            placeholder="cth. Lantai 2"
          />
        </Field>
        <Field label="Fasilitas" hint="Tekan Enter untuk tambah">
          <div style={{ display: 'flex', gap: 'var(--space-2)' }}>
            <input
              className={formStyles.input}
              value={form.facilityInput}
              onChange={e => set('facilityInput', e.target.value)}
              onKeyDown={e => { if (e.key === 'Enter') { e.preventDefault(); addFacility() } }}
              placeholder="cth. Proyektor"
              style={{ flex: 1 }}
            />
            <button
              type="button"
              onClick={addFacility}
              style={{
                padding: '0 var(--space-3)', border: '1px solid var(--color-border)',
                borderRadius: 'var(--radius-md)', background: 'var(--color-surface)',
                cursor: 'pointer', fontSize: 'var(--font-sm)',
              }}
            >
              +
            </button>
          </div>
          {form.facilities.length > 0 && (
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 'var(--space-1)', marginTop: 'var(--space-2)' }}>
              {form.facilities.map(f => (
                <span key={f} style={{
                  display: 'inline-flex', alignItems: 'center', gap: 4,
                  padding: '2px 8px', borderRadius: 'var(--radius-full)',
                  background: 'var(--color-primary-subtle)', color: 'var(--color-primary)',
                  fontSize: 'var(--font-xs)',
                }}>
                  {f}
                  <button
                    type="button"
                    onClick={() => removeFacility(f)}
                    style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0, lineHeight: 1, color: 'inherit' }}
                  >
                    <X size={11} />
                  </button>
                </span>
              ))}
            </div>
          )}
        </Field>
      </div>
      <Field label="Deskripsi" hint="Opsional">
        <textarea
          className={formStyles.textarea}
          value={form.description}
          onChange={e => set('description', e.target.value)}
          rows={2}
          placeholder="Informasi tambahan tentang ruangan..."
        />
      </Field>
      <div style={{ display: 'flex', gap: 'var(--space-2)', justifyContent: 'flex-end', marginTop: 'var(--space-3)' }}>
        <button
          type="button"
          onClick={onCancel}
          style={{
            padding: 'var(--space-2) var(--space-4)', border: '1px solid var(--color-border)',
            borderRadius: 'var(--radius-md)', background: 'var(--color-surface)',
            cursor: 'pointer', fontSize: 'var(--font-sm)',
          }}
        >
          Batal
        </button>
        <button
          type="button"
          onClick={async () => { if (validate()) await onSave(form) }}
          disabled={isSaving}
          style={{
            padding: 'var(--space-2) var(--space-4)', border: 'none',
            borderRadius: 'var(--radius-md)', background: 'var(--color-primary)',
            color: '#fff', cursor: isSaving ? 'not-allowed' : 'pointer',
            fontSize: 'var(--font-sm)', opacity: isSaving ? 0.7 : 1,
          }}
        >
          {isSaving ? 'Menyimpan...' : 'Simpan Ruangan'}
        </button>
      </div>
    </div>
  )
}

// ─── RoomsManager ─────────────────────────────────────────────────────────────

export function RoomsManager({ buildingId }: { buildingId: string }) {
  const queryClient = useQueryClient()
  const [addingRoom, setAddingRoom] = useState(false)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [savingId, setSavingId] = useState<string | null>(null)
  const [deletingId, setDeletingId] = useState<string | null>(null)

  const { data: rooms = [], isLoading } = useQuery<Room[]>({
    queryKey: ['rooms', buildingId],
    queryFn: async () => {
      const data = await locationService.listRooms(buildingId)
      return Array.isArray(data) ? data : (data as any)?.items ?? []
    },
  })

  async function handleAdd(form: RoomFormState) {
    setSavingId('new')
    try {
      await locationService.createRoom({
        building_id: buildingId,
        name: form.name.trim(),
        capacity: form.capacity ? Number(form.capacity) : undefined,
        floor: form.floor.trim() || undefined,
        facilities: form.facilities.length ? form.facilities : undefined,
        description: form.description.trim() || undefined,
      })
      toast.success('Ruangan berhasil ditambahkan')
      await queryClient.invalidateQueries({ queryKey: ['rooms', buildingId] })
      setAddingRoom(false)
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Gagal menambah ruangan')
    } finally {
      setSavingId(null)
    }
  }

  async function handleEdit(room: Room, form: RoomFormState) {
    setSavingId(room.id)
    try {
      await locationService.updateRoom(room.id, {
        name: form.name.trim(),
        capacity: form.capacity ? Number(form.capacity) : undefined,
        floor: form.floor.trim() || undefined,
        facilities: form.facilities.length ? form.facilities : undefined,
        description: form.description.trim() || undefined,
      })
      toast.success('Ruangan berhasil diperbarui')
      await queryClient.invalidateQueries({ queryKey: ['rooms', buildingId] })
      setEditingId(null)
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Gagal memperbarui ruangan')
    } finally {
      setSavingId(null)
    }
  }

  async function handleDelete(room: Room) {
    if (!window.confirm(`Hapus ruangan "${room.name}"?`)) return
    setDeletingId(room.id)
    try {
      await locationService.deleteRoom(room.id)
      toast.success('Ruangan dihapus')
      await queryClient.invalidateQueries({ queryKey: ['rooms', buildingId] })
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Gagal menghapus ruangan')
    } finally {
      setDeletingId(null)
    }
  }

  if (isLoading) {
    return <p style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)' }}>Memuat ruangan...</p>
  }

  return (
    <div>
      {addingRoom && (
        <RoomForm
          onSave={handleAdd}
          onCancel={() => setAddingRoom(false)}
          isSaving={savingId === 'new'}
        />
      )}

      {rooms.length === 0 && !addingRoom && (
        <div style={{
          textAlign: 'center', padding: 'var(--space-8)',
          border: '2px dashed var(--color-border)', borderRadius: 'var(--radius-lg)',
          marginBottom: 'var(--space-4)',
        }}>
          <DoorOpen size={32} style={{ color: 'var(--color-text-tertiary)', marginBottom: 'var(--space-2)' }} />
          <p style={{ color: 'var(--color-text-tertiary)', fontSize: 'var(--font-sm)', margin: 0 }}>
            Belum ada ruangan. Tambahkan ruangan untuk gedung ini.
          </p>
        </div>
      )}

      {rooms.map(room => (
        <div key={room.id}>
          {editingId === room.id ? (
            <RoomForm
              initial={{
                name: room.name,
                capacity: room.capacity?.toString() ?? '',
                floor: room.floor ?? '',
                facilities: room.facilities ?? [],
                facilityInput: '',
                description: room.description ?? '',
              }}
              onSave={form => handleEdit(room, form)}
              onCancel={() => setEditingId(null)}
              isSaving={savingId === room.id}
            />
          ) : (
            <div style={{
              display: 'flex', alignItems: 'center', gap: 'var(--space-3)',
              padding: 'var(--space-3) var(--space-4)',
              border: '1px solid var(--color-border)', borderRadius: 'var(--radius-lg)',
              background: 'var(--color-surface-elevated)', marginBottom: 'var(--space-2)',
            }}>
              <DoorOpen size={18} style={{ color: 'var(--color-text-tertiary)', flexShrink: 0 }} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>{room.name}</div>
                <div style={{
                  display: 'flex', flexWrap: 'wrap', gap: 'var(--space-3)', marginTop: 2,
                  fontSize: 'var(--font-sm)', color: 'var(--color-text-secondary)',
                }}>
                  {room.capacity && <span>Kapasitas: {room.capacity} orang</span>}
                  {room.floor && <span>{room.floor}</span>}
                  {room.facilities?.length ? <span>{room.facilities.join(', ')}</span> : null}
                </div>
              </div>
              <div style={{ display: 'flex', gap: 'var(--space-2)', flexShrink: 0 }}>
                <button
                  type="button"
                  onClick={() => { setEditingId(room.id); setAddingRoom(false) }}
                  style={{
                    padding: 'var(--space-1) var(--space-2)', border: '1px solid var(--color-border)',
                    borderRadius: 'var(--radius-md)', background: 'var(--color-surface)',
                    cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 4,
                    fontSize: 'var(--font-xs)',
                  }}
                >
                  <Pencil size={12} /> Edit
                </button>
                <button
                  type="button"
                  onClick={() => handleDelete(room)}
                  disabled={deletingId === room.id}
                  style={{
                    padding: 'var(--space-1) var(--space-2)', border: '1px solid var(--color-border)',
                    borderRadius: 'var(--radius-md)', background: 'var(--color-surface)',
                    cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 4,
                    fontSize: 'var(--font-xs)', color: 'var(--color-danger)',
                    opacity: deletingId === room.id ? 0.5 : 1,
                  }}
                >
                  <Trash2 size={12} /> Hapus
                </button>
              </div>
            </div>
          )}
        </div>
      ))}

      {!addingRoom && (
        <button
          type="button"
          onClick={() => { setAddingRoom(true); setEditingId(null) }}
          style={{
            display: 'flex', alignItems: 'center', gap: 'var(--space-2)',
            padding: 'var(--space-2) var(--space-4)',
            border: '1px dashed var(--color-primary)', borderRadius: 'var(--radius-md)',
            background: 'var(--color-primary-subtle)', color: 'var(--color-primary)',
            cursor: 'pointer', fontSize: 'var(--font-sm)', fontWeight: 500,
          }}
        >
          <Plus size={14} /> Tambah Ruangan
        </button>
      )}
    </div>
  )
}
