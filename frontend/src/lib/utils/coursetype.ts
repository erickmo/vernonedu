export function isProgramKarir(typeName?: string | null): boolean {
  if (!typeName) return false
  return typeName.toLowerCase().includes('karir')
}
