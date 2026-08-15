/** Namespaced, crash-safe wrapper over localStorage. */

/**
 * `?device=b` gives a tab its own storage namespace, so it signs in as a
 * separate account while still sharing the realtime bus with the default
 * tab. That is what makes a genuine two-sided test possible in one browser:
 * order published in tab A, bid sent from tab B.
 */
const DEVICE_KEY = 'getteksi:device'

function devicePrefix(): string {
  try {
    const fromUrl = new URLSearchParams(window.location.search).get('device')
    // sessionStorage is per-tab, so the namespace survives reloads and the
    // router dropping the query string on the first navigation.
    const id = fromUrl ?? sessionStorage.getItem(DEVICE_KEY)
    if (!id) return ''
    const safe = id.replace(/[^a-z0-9]/gi, '').slice(0, 8)
    if (!safe) return ''
    sessionStorage.setItem(DEVICE_KEY, safe)
    return `${safe}:`
  } catch {
    return ''
  }
}

const PREFIX = `getteksi:${devicePrefix()}`

export function readJSON<T>(key: string, fallback: T): T {
  try {
    const raw = localStorage.getItem(PREFIX + key)
    if (raw == null) return fallback
    return JSON.parse(raw) as T
  } catch {
    return fallback
  }
}

export function writeJSON(key: string, value: unknown): void {
  try {
    localStorage.setItem(PREFIX + key, JSON.stringify(value))
  } catch {
    // Quota exceeded or private mode — the app stays usable in memory.
  }
}

export function remove(key: string): void {
  try {
    localStorage.removeItem(PREFIX + key)
  } catch {
    /* ignore */
  }
}

export function clearAll(): void {
  try {
    Object.keys(localStorage)
      .filter((k) => k.startsWith(PREFIX))
      .forEach((k) => localStorage.removeItem(k))
  } catch {
    /* ignore */
  }
}

export function uid(prefix = ''): string {
  const rand =
    typeof crypto !== 'undefined' && 'randomUUID' in crypto
      ? crypto.randomUUID().replace(/-/g, '').slice(0, 12)
      : Math.random().toString(36).slice(2, 14)
  return prefix ? `${prefix}_${rand}` : rand
}
