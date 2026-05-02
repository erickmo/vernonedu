import { useState, useMemo } from 'react'
import { toast } from 'sonner'
import PageHeader from '@/components/shared/PageHeader'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import FormField from '@/components/shared/FormField'
import Input from '@/components/ui/Input'
import Textarea from '@/components/ui/Textarea'
import Button from '@/components/ui/Button'
import { CMS_PAGE_TYPES } from '@/types/cmspage'
import { useCmsPages, useUpdateCmsPage } from '@/lib/api/cms'
import RoleGate from '@/components/shared/RoleGate'

const ALL = ''

export default function CmsPages() {
  const [type, setType] = useState<string>(ALL)
  const [selectedSlug, setSelectedSlug] = useState<string | null>(null)
  const { data: pages, isLoading } = useCmsPages({ type: type || undefined })

  const filtered = pages ?? []
  const selected = useMemo(
    () => filtered.find((p) => p.slug === selectedSlug) ?? null,
    [filtered, selectedSlug],
  )

  return (
    <div className="space-y-5">
      <PageHeader title="CMS Pages" subtitle="Manage website page content" />

      <div className="flex gap-2">
        <select
          value={type}
          onChange={(e) => setType(e.target.value)}
          className="px-3 py-2 text-sm border border-neutral-200 rounded-lg bg-white"
        >
          <option value="">All types</option>
          {CMS_PAGE_TYPES.map((t) => (
            <option key={t} value={t}>{t}</option>
          ))}
        </select>
      </div>

      {isLoading ? (
        <LoadingSpinner size="lg" />
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          <div className="bg-white rounded-xl border border-neutral-100 p-3 space-y-1 lg:col-span-1">
            {filtered.length === 0 && (
              <div className="text-sm text-neutral-500 p-3">No pages</div>
            )}
            {filtered.map((p) => (
              <button
                key={p.slug}
                onClick={() => setSelectedSlug(p.slug)}
                className={`w-full text-left px-3 py-2 rounded-lg text-sm ${
                  selectedSlug === p.slug
                    ? 'bg-brand-50 text-brand-700'
                    : 'hover:bg-neutral-50 text-neutral-700'
                }`}
              >
                <div className="font-medium">{p.title || p.slug}</div>
                <div className="text-xs text-neutral-500">{p.type} · /{p.slug}</div>
              </button>
            ))}
          </div>
          <div className="lg:col-span-2">
            {selected ? (
              <PageEditor key={selected.slug} page={selected} />
            ) : (
              <div className="bg-white rounded-xl border border-neutral-100 p-6 text-sm text-neutral-500">
                Select a page to edit
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  )
}

interface PageEditorProps {
  page: { slug: string; title: string; subtitle: string; content: Record<string, unknown> | null; hero_image_url: string; seo: Record<string, unknown> | null }
}

function PageEditor({ page }: PageEditorProps) {
  const update = useUpdateCmsPage(page.slug)
  const [title, setTitle] = useState(page.title)
  const [subtitle, setSubtitle] = useState(page.subtitle)
  const [hero, setHero] = useState(page.hero_image_url)
  const [contentJson, setContentJson] = useState(
    JSON.stringify(page.content ?? {}, null, 2),
  )
  const [seoJson, setSeoJson] = useState(JSON.stringify(page.seo ?? {}, null, 2))
  const [saving, setSaving] = useState(false)

  async function onSave() {
    let content: Record<string, unknown> = {}
    let seo: Record<string, unknown> = {}
    try {
      content = JSON.parse(contentJson || '{}')
      seo = JSON.parse(seoJson || '{}')
    } catch {
      toast.error('Invalid JSON in content or SEO')
      return
    }
    setSaving(true)
    try {
      await update.mutateAsync({ title, subtitle, hero_image_url: hero, content, seo })
      toast.success('Page updated')
    } catch (e: any) {
      toast.error(e?.response?.data?.message ?? 'Failed to update page')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="bg-white rounded-xl border border-neutral-100 p-6 space-y-4">
      <div className="text-xs text-neutral-500">/{page.slug}</div>
      <FormField label="Title" required>
        <Input value={title} onChange={(e) => setTitle(e.target.value)} />
      </FormField>
      <FormField label="Subtitle">
        <Input value={subtitle} onChange={(e) => setSubtitle(e.target.value)} />
      </FormField>
      <FormField label="Hero Image URL">
        <Input value={hero} onChange={(e) => setHero(e.target.value)} />
      </FormField>
      <FormField label="Content (JSON)">
        <Textarea value={contentJson} onChange={(e) => setContentJson(e.target.value)} rows={8} />
      </FormField>
      <FormField label="SEO (JSON)">
        <Textarea value={seoJson} onChange={(e) => setSeoJson(e.target.value)} rows={4} />
      </FormField>
      <div className="flex gap-2 pt-2 border-t border-neutral-100">
        <RoleGate action="update" resource="cms_page">
          <Button onClick={onSave} loading={saving} disabled={saving}>
            Save
          </Button>
        </RoleGate>
      </div>
    </div>
  )
}
