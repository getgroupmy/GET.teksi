/** Money is stored in minor units (sen) everywhere; format at the edges only. */

export const CURRENCY = 'MYR'
export const CURRENCY_SYMBOL = 'RM'

export function money(minor: number, opts: { decimals?: boolean; symbol?: boolean } = {}): string {
  const { decimals = true, symbol = true } = opts
  const major = minor / 100
  const text = decimals
    ? major.toFixed(2)
    : Math.round(major).toLocaleString('en-MY')
  return symbol ? `${CURRENCY_SYMBOL}${text}` : text
}

/** Rounds to the nearest 50 sen — riders think in half-ringgit steps. */
export function roundFare(minor: number): number {
  return Math.max(100, Math.round(minor / 50) * 50)
}

export function distance(km: number): string {
  return km < 1 ? `${Math.round(km * 1000)} m` : `${km.toFixed(1)} km`
}

export function duration(minutes: number): string {
  if (minutes < 60) return `${Math.round(minutes)} min`
  const h = Math.floor(minutes / 60)
  const m = Math.round(minutes % 60)
  return m === 0 ? `${h} h` : `${h} h ${m} min`
}

export function timeAgo(ts: number): string {
  const secs = Math.max(0, Math.floor((Date.now() - ts) / 1000))
  if (secs < 10) return 'just now'
  if (secs < 60) return `${secs}s ago`
  const mins = Math.floor(secs / 60)
  if (mins < 60) return `${mins} min ago`
  const hours = Math.floor(mins / 60)
  if (hours < 24) return `${hours} h ago`
  const days = Math.floor(hours / 24)
  if (days < 7) return `${days} d ago`
  return new Date(ts).toLocaleDateString('en-MY', { day: 'numeric', month: 'short' })
}

export function clockTime(ts: number): string {
  return new Date(ts).toLocaleTimeString('en-MY', { hour: '2-digit', minute: '2-digit', hour12: false })
}

export function dateLabel(ts: number): string {
  const d = new Date(ts)
  const today = new Date()
  const yesterday = new Date(Date.now() - 86_400_000)
  const same = (a: Date, b: Date) => a.toDateString() === b.toDateString()
  if (same(d, today)) return 'Today'
  if (same(d, yesterday)) return 'Yesterday'
  return d.toLocaleDateString('en-MY', { day: 'numeric', month: 'long', year: d.getFullYear() === today.getFullYear() ? undefined : 'numeric' })
}

/** "+60 12-345 6789" from a raw Malaysian number. */
export function phoneDisplay(raw: string): string {
  const digits = raw.replace(/\D/g, '').replace(/^60/, '')
  if (digits.length < 9) return `+60 ${digits}`
  const head = digits.slice(0, 2)
  const mid = digits.slice(2, digits.length - 4)
  const tail = digits.slice(-4)
  return `+60 ${head}-${mid} ${tail}`
}

export function initials(name: string): string {
  return name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0]!.toUpperCase())
    .join('')
}

export function plural(n: number, one: string, many = `${one}s`): string {
  return `${n} ${n === 1 ? one : many}`
}
