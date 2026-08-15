import { create } from 'zustand'
import type { DriverDocument, DriverProfile, Place, Role, User, Vehicle } from '@/types'
import { readJSON, writeJSON, remove, uid } from '@/lib/storage'
import { pickAvatarColor } from '@/data/fixtures'
import { CITY_CENTER } from '@/data/places'
import type { LatLng } from '@/types'

const USER_KEY = 'user'
const PREFS_KEY = 'prefs'

export type Prefs = {
  role: Role
  theme: 'dark' | 'light'
  /** Drivers go on/off duty; only online drivers receive the order feed. */
  driverOnline: boolean
  language: 'en' | 'ms'
  soundEnabled: boolean
  /** Bot drivers/passengers that make the app demonstrable solo. */
  simulationEnabled: boolean
  hasSeenIntro: boolean
}

const DEFAULT_PREFS: Prefs = {
  role: 'passenger',
  theme: 'dark',
  driverOnline: false,
  language: 'en',
  soundEnabled: true,
  simulationEnabled: true,
  hasSeenIntro: false,
}

function starterDocuments(): DriverDocument[] {
  return [
    { id: uid('doc'), kind: 'license', label: 'Driving licence', status: 'approved', expiresAt: Date.now() + 400 * 86_400_000 },
    { id: uid('doc'), kind: 'registration', label: 'Vehicle registration (Geran)', status: 'approved' },
    { id: uid('doc'), kind: 'insurance', label: 'Insurance certificate', status: 'approved', expiresAt: Date.now() + 200 * 86_400_000 },
    { id: uid('doc'), kind: 'psv', label: 'PSV / e-hailing permit', status: 'pending' },
    { id: uid('doc'), kind: 'selfie', label: 'Profile photo verification', status: 'approved' },
  ]
}

type SessionState = {
  user: User | null
  prefs: Prefs
  /** Device location; seeded to the city centre until geolocation resolves. */
  myLocation: LatLng
  locationReady: boolean

  signIn: (phone: string, name?: string) => User
  updateUser: (patch: Partial<User>) => void
  signOut: () => void
  setRole: (role: Role) => void
  setPrefs: (patch: Partial<Prefs>) => void
  becomeDriver: (vehicle: Vehicle) => void
  updateVehicle: (patch: Partial<Vehicle>) => void
  setMyLocation: (coord: LatLng) => void
  saveShortcut: (kind: 'home' | 'work', place: Place) => void
  creditWallet: (amount: number) => void
  debitWallet: (amount: number) => boolean
  recordDriverEarning: (amount: number) => void
}

export const useSession = create<SessionState>((set, get) => ({
  user: readJSON<User | null>(USER_KEY, null),
  prefs: { ...DEFAULT_PREFS, ...readJSON<Partial<Prefs>>(PREFS_KEY, {}) },
  myLocation: CITY_CENTER,
  locationReady: false,

  signIn: (phone, name) => {
    const existing = get().user
    // Returning to the same number keeps the profile, rating and history.
    if (existing && existing.phone === phone) return existing
    const user: User = {
      id: uid('usr'),
      phone,
      name: name?.trim() || 'Guest',
      avatarColor: pickAvatarColor(phone),
      createdAt: Date.now(),
      rating: 5,
      ridesTaken: 0,
      walletBalance: 2500,
    }
    writeJSON(USER_KEY, user)
    set({ user })
    return user
  },

  updateUser: (patch) => {
    const user = get().user
    if (!user) return
    const next = { ...user, ...patch }
    writeJSON(USER_KEY, next)
    set({ user: next })
  },

  signOut: () => {
    remove(USER_KEY)
    const prefs = { ...get().prefs, role: 'passenger' as Role, driverOnline: false }
    writeJSON(PREFS_KEY, prefs)
    set({ user: null, prefs })
  },

  setRole: (role) => get().setPrefs({ role }),

  setPrefs: (patch) => {
    const prefs = { ...get().prefs, ...patch }
    writeJSON(PREFS_KEY, prefs)
    set({ prefs })
  },

  becomeDriver: (vehicle) => {
    const user = get().user
    if (!user) return
    const driverProfile: DriverProfile = user.driverProfile ?? {
      vehicle,
      rating: 5,
      ridesGiven: 0,
      earnings: 0,
      verified: true,
      documents: starterDocuments(),
      joinedAt: Date.now(),
    }
    get().updateUser({ driverProfile: { ...driverProfile, vehicle } })
  },

  updateVehicle: (patch) => {
    const user = get().user
    if (!user?.driverProfile) return
    get().updateUser({
      driverProfile: { ...user.driverProfile, vehicle: { ...user.driverProfile.vehicle, ...patch } },
    })
  },

  setMyLocation: (coord) => set({ myLocation: coord, locationReady: true }),

  saveShortcut: (kind, place) =>
    get().updateUser(kind === 'home' ? { homePlace: place } : { workPlace: place }),

  creditWallet: (amount) => {
    const user = get().user
    if (!user) return
    get().updateUser({ walletBalance: user.walletBalance + amount })
  },

  debitWallet: (amount) => {
    const user = get().user
    if (!user || user.walletBalance < amount) return false
    get().updateUser({ walletBalance: user.walletBalance - amount })
    return true
  },

  recordDriverEarning: (amount) => {
    const user = get().user
    if (!user?.driverProfile) return
    get().updateUser({
      driverProfile: {
        ...user.driverProfile,
        earnings: user.driverProfile.earnings + amount,
        ridesGiven: user.driverProfile.ridesGiven + 1,
      },
      walletBalance: user.walletBalance + amount,
    })
  },
}))

/** Ask the browser for a real fix; silently keeps the city-centre default. */
export function requestGeolocation(): void {
  if (typeof navigator === 'undefined' || !navigator.geolocation) return
  navigator.geolocation.getCurrentPosition(
    (pos) => {
      useSession.getState().setMyLocation({ lat: pos.coords.latitude, lng: pos.coords.longitude })
    },
    () => {
      // Permission denied or unavailable — the seeded location stands.
      useSession.setState({ locationReady: true })
    },
    { enableHighAccuracy: true, timeout: 8000, maximumAge: 60_000 },
  )
}
