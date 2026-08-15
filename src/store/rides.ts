import { create } from 'zustand'
import type {
  CancelledBy,
  ChatMessage,
  LatLng,
  NearbyDriver,
  Notification,
  Offer,
  Ride,
  RideRating,
  RideStatus,
  Role,
  Transaction,
} from '@/types'
import { readJSON, uid, writeJSON } from '@/lib/storage'
import { bus } from '@/lib/bus'
import { useSession } from '@/store/session'
import { driverNet } from '@/services/pricing'
import { syntheticRoute } from '@/lib/geo'

const RIDES_KEY = 'rides'
const OFFERS_KEY = 'offers'
const CHAT_KEY = 'chat'
const NOTIF_KEY = 'notifications'
const TX_KEY = 'transactions'

/** Bids stay live for 90 seconds, then grey out — same as the real product. */
export const OFFER_TTL_MS = 90_000

/** Orders nobody bids on expire so the driver feed never fills with ghosts. */
const RIDE_SEARCH_TTL_MS = 10 * 60_000

type RidesState = {
  rides: Record<string, Ride>
  offers: Record<string, Offer>
  messages: ChatMessage[]
  notifications: Notification[]
  transactions: Transaction[]
  /** Live driver positions for the map. Not persisted. */
  nearbyDrivers: Record<string, NearbyDriver>

  publishRide: (ride: Ride) => Ride
  updateRide: (id: string, patch: Partial<Ride>, opts?: { silent?: boolean }) => Ride | null
  raisePrice: (rideId: string, price: number) => void
  cancelRide: (rideId: string, by: CancelledBy, reason?: string) => void
  setRideStatus: (rideId: string, status: RideStatus) => void
  completeRide: (rideId: string) => void

  createOffer: (offer: Offer) => void
  acceptOffer: (offerId: string) => void
  declineOffer: (offerId: string) => void
  withdrawOffer: (offerId: string) => void

  setDriverLocation: (driverId: string, coord: LatLng, bearing: number) => void
  upsertNearbyDriver: (driver: NearbyDriver) => void
  removeNearbyDriver: (driverId: string) => void

  sendMessage: (rideId: string, from: Role, text: string) => void
  markChatRead: (rideId: string, viewer: Role) => void

  notify: (n: Omit<Notification, 'id' | 'createdAt' | 'read'>) => void
  markNotificationsRead: () => void
  addTransaction: (t: Omit<Transaction, 'id' | 'createdAt'>) => void

  rateRide: (rideId: string, by: Role, rating: RideRating, tip?: number) => void

  /** Applies a remote event without re-broadcasting it. */
  applyRemote: (apply: (state: RidesState) => Partial<RidesState>) => void
  /** Drops expired offers and stale searching orders. Runs on a ticker. */
  sweep: () => void
  reset: () => void
}

function persist(state: Pick<RidesState, 'rides' | 'offers' | 'messages' | 'notifications' | 'transactions'>) {
  writeJSON(RIDES_KEY, state.rides)
  writeJSON(OFFERS_KEY, state.offers)
  writeJSON(CHAT_KEY, state.messages.slice(-300))
  writeJSON(NOTIF_KEY, state.notifications.slice(0, 60))
  writeJSON(TX_KEY, state.transactions.slice(0, 120))
}

export const useRides = create<RidesState>((set, get) => ({
  rides: readJSON<Record<string, Ride>>(RIDES_KEY, {}),
  offers: readJSON<Record<string, Offer>>(OFFERS_KEY, {}),
  messages: readJSON<ChatMessage[]>(CHAT_KEY, []),
  notifications: readJSON<Notification[]>(NOTIF_KEY, []),
  transactions: readJSON<Transaction[]>(TX_KEY, []),
  nearbyDrivers: {},

  publishRide: (ride) => {
    const withRoute: Ride = {
      ...ride,
      routeGeometry: ride.routeGeometry ?? syntheticRoute(ride.pickup.coord, ride.dropoff.coord, 3),
    }
    set((s) => {
      const rides = { ...s.rides, [withRoute.id]: withRoute }
      persist({ ...s, rides })
      return { rides }
    })
    bus.emitRemote({ type: 'ride:published', ride: withRoute })
    return withRoute
  },

  updateRide: (id, patch, opts) => {
    const current = get().rides[id]
    if (!current) return null
    const next: Ride = { ...current, ...patch, updatedAt: Date.now() }
    set((s) => {
      const rides = { ...s.rides, [id]: next }
      persist({ ...s, rides })
      return { rides }
    })
    if (!opts?.silent) bus.emitRemote({ type: 'ride:updated', ride: next })
    return next
  },

  raisePrice: (rideId, price) => {
    const ride = get().rides[rideId]
    if (!ride || ride.status !== 'searching') return
    get().updateRide(rideId, { askingPrice: price, priceRaises: ride.priceRaises + 1 })
    get().notify({
      kind: 'ride',
      title: 'Price raised',
      body: 'Nearby drivers have been notified of your new offer.',
      rideId,
    })
  },

  cancelRide: (rideId, by, reason) => {
    const ride = get().rides[rideId]
    if (!ride || ride.status === 'completed' || ride.status === 'cancelled') return
    get().updateRide(rideId, {
      status: 'cancelled',
      cancelledAt: Date.now(),
      cancelledBy: by,
      cancelReason: reason,
    })
    // Every pending bid on a dead order is void.
    const offers = { ...get().offers }
    Object.values(offers).forEach((o) => {
      if (o.rideId === rideId && o.status === 'pending') offers[o.id] = { ...o, status: 'declined' }
    })
    set((s) => {
      persist({ ...s, offers })
      return { offers }
    })
    bus.emitRemote({ type: 'ride:cancelled', rideId, by, reason })
    get().notify({
      kind: 'ride',
      title: by === 'driver' ? 'Driver cancelled' : 'Ride cancelled',
      body: reason ? reason : 'The order has been cancelled.',
      rideId,
    })
  },

  setRideStatus: (rideId, status) => {
    const stamps: Partial<Ride> = { status }
    const now = Date.now()
    if (status === 'accepted') stamps.acceptedAt = now
    if (status === 'waiting') stamps.arrivedAt = now
    if (status === 'in_progress') stamps.startedAt = now
    if (status === 'completed') stamps.completedAt = now
    get().updateRide(rideId, stamps)
  },

  completeRide: (rideId) => {
    const ride = get().rides[rideId]
    if (!ride || ride.status === 'completed') return
    const fare = ride.finalPrice ?? ride.askingPrice
    get().updateRide(rideId, { status: 'completed', completedAt: Date.now() })

    const session = useSession.getState()
    const me = session.user
    if (!me) return

    if (ride.passengerId === me.id) {
      session.updateUser({ ridesTaken: me.ridesTaken + 1 })
      if (ride.paymentMethod === 'wallet') session.debitWallet(fare)
      get().addTransaction({
        kind: 'ride_payment',
        amount: -fare,
        description: `Ride to ${ride.dropoff.name}`,
        rideId,
      })
    }
    if (ride.driverId === me.id) {
      const net = driverNet(fare)
      session.recordDriverEarning(net)
      get().addTransaction({
        kind: 'ride_earning',
        amount: net,
        description: `Trip from ${ride.pickup.name}`,
        rideId,
      })
    }
  },

  createOffer: (offer) => {
    const ride = get().rides[offer.rideId]
    if (!ride || ride.status !== 'searching') return
    set((s) => {
      const offers = { ...s.offers, [offer.id]: offer }
      persist({ ...s, offers })
      return { offers }
    })
    bus.emitRemote({ type: 'offer:created', offer })
    if (ride.passengerId === useSession.getState().user?.id) {
      get().notify({
        kind: 'ride',
        title: `${offer.driverName} offered a price`,
        body: `${offer.vehicle.make} ${offer.vehicle.model} · ${offer.etaMinutes} min away`,
        rideId: ride.id,
      })
    }
  },

  acceptOffer: (offerId) => {
    const offer = get().offers[offerId]
    if (!offer || offer.status !== 'pending') return
    const ride = get().rides[offer.rideId]
    if (!ride || ride.status !== 'searching') return

    const offers = { ...get().offers }
    // Accepting one bid rejects the rest — the order is off the market.
    Object.values(offers).forEach((o) => {
      if (o.rideId !== offer.rideId) return
      offers[o.id] = { ...o, status: o.id === offerId ? 'accepted' : 'declined' }
    })
    set((s) => {
      persist({ ...s, offers })
      return { offers }
    })
    bus.emitRemote({ type: 'offer:updated', offer: offers[offerId] })

    const driverStart = offer.driverId.startsWith('bot')
      ? get().nearbyDrivers[offer.driverId]?.coord
      : useSession.getState().myLocation

    get().updateRide(offer.rideId, {
      status: 'accepted',
      acceptedAt: Date.now(),
      finalPrice: offer.price,
      driverId: offer.driverId,
      driverName: offer.driverName,
      driverAvatarColor: offer.driverAvatarColor,
      driverRating: offer.driverRating,
      driverVehicle: offer.vehicle,
      driverCoord: driverStart ?? ride.pickup.coord,
    })
  },

  declineOffer: (offerId) => {
    const offer = get().offers[offerId]
    if (!offer) return
    const next: Offer = { ...offer, status: 'declined' }
    set((s) => {
      const offers = { ...s.offers, [offerId]: next }
      persist({ ...s, offers })
      return { offers }
    })
    bus.emitRemote({ type: 'offer:updated', offer: next })
  },

  withdrawOffer: (offerId) => {
    const offer = get().offers[offerId]
    if (!offer) return
    const next: Offer = { ...offer, status: 'withdrawn' }
    set((s) => {
      const offers = { ...s.offers, [offerId]: next }
      persist({ ...s, offers })
      return { offers }
    })
    bus.emitRemote({ type: 'offer:updated', offer: next })
  },

  setDriverLocation: (driverId, coord, bearing) => {
    set((s) => {
      const nearby = s.nearbyDrivers[driverId]
      const nearbyDrivers = nearby
        ? { ...s.nearbyDrivers, [driverId]: { ...nearby, coord, bearing } }
        : s.nearbyDrivers
      // Mirror onto any live ride so the passenger's map follows the car.
      const rides = { ...s.rides }
      let touched = false
      Object.values(rides).forEach((r) => {
        if (r.driverId !== driverId) return
        if (r.status === 'completed' || r.status === 'cancelled') return
        rides[r.id] = { ...r, driverCoord: coord, driverBearing: bearing }
        touched = true
      })
      return touched ? { nearbyDrivers, rides } : { nearbyDrivers }
    })
  },

  upsertNearbyDriver: (driver) =>
    set((s) => ({ nearbyDrivers: { ...s.nearbyDrivers, [driver.id]: driver } })),

  removeNearbyDriver: (driverId) =>
    set((s) => {
      const next = { ...s.nearbyDrivers }
      delete next[driverId]
      return { nearbyDrivers: next }
    }),

  sendMessage: (rideId, from, text) => {
    const message: ChatMessage = {
      id: uid('msg'),
      rideId,
      from,
      text: text.trim(),
      createdAt: Date.now(),
      read: false,
    }
    if (!message.text) return
    set((s) => {
      const messages = [...s.messages, message]
      persist({ ...s, messages })
      return { messages }
    })
    bus.emitRemote({ type: 'chat:message', message })
  },

  markChatRead: (rideId, viewer) =>
    set((s) => {
      const messages = s.messages.map((m) =>
        m.rideId === rideId && m.from !== viewer ? { ...m, read: true } : m,
      )
      persist({ ...s, messages })
      return { messages }
    }),

  notify: (n) =>
    set((s) => {
      const notifications = [
        { ...n, id: uid('ntf'), createdAt: Date.now(), read: false },
        ...s.notifications,
      ].slice(0, 60)
      persist({ ...s, notifications })
      return { notifications }
    }),

  markNotificationsRead: () =>
    set((s) => {
      const notifications = s.notifications.map((n) => ({ ...n, read: true }))
      persist({ ...s, notifications })
      return { notifications }
    }),

  addTransaction: (t) =>
    set((s) => {
      const transactions = [{ ...t, id: uid('tx'), createdAt: Date.now() }, ...s.transactions].slice(0, 120)
      persist({ ...s, transactions })
      return { transactions }
    }),

  rateRide: (rideId, by, rating, tip) => {
    const patch: Partial<Ride> =
      by === 'passenger' ? { ratingByPassenger: rating, tip } : { ratingByDriver: rating }
    get().updateRide(rideId, patch)
    if (by === 'passenger' && tip && tip > 0) {
      get().addTransaction({ kind: 'tip', amount: -tip, description: 'Tip for your driver', rideId })
    }
  },

  applyRemote: (apply) => set((s) => apply(s)),

  sweep: () => {
    const now = Date.now()
    let changed = false
    const offers = { ...get().offers }
    Object.values(offers).forEach((o) => {
      if (o.status === 'pending' && o.expiresAt <= now) {
        offers[o.id] = { ...o, status: 'expired' }
        changed = true
      }
    })
    const rides = { ...get().rides }
    Object.values(rides).forEach((r) => {
      if (r.status === 'searching' && now - r.createdAt > RIDE_SEARCH_TTL_MS) {
        rides[r.id] = {
          ...r,
          status: 'cancelled',
          cancelledAt: now,
          cancelledBy: 'system',
          cancelReason: 'No drivers responded',
          updatedAt: now,
        }
        changed = true
      }
    })
    if (changed) {
      set((s) => {
        persist({ ...s, offers, rides })
        return { offers, rides }
      })
    }
  },

  reset: () => {
    set({ rides: {}, offers: {}, messages: [], notifications: [], transactions: [], nearbyDrivers: {} })
    persist({ rides: {}, offers: {}, messages: [], notifications: [], transactions: [] })
  },
}))

/* ------------------------------------------------------------------ */
/* Realtime: apply events other tabs broadcast.                        */
/* ------------------------------------------------------------------ */

bus.subscribe((event) => {
  const store = useRides.getState()
  switch (event.type) {
    case 'ride:published':
    case 'ride:updated': {
      const incoming = event.ride
      const existing = store.rides[incoming.id]
      // Last-write-wins on the update stamp keeps tabs convergent.
      if (existing && existing.updatedAt > incoming.updatedAt) return
      store.applyRemote((s) => {
        const rides = { ...s.rides, [incoming.id]: incoming }
        persist({ ...s, rides })
        return { rides }
      })
      break
    }
    case 'ride:cancelled': {
      const ride = store.rides[event.rideId]
      if (!ride || ride.status === 'cancelled') return
      store.applyRemote((s) => {
        const rides = {
          ...s.rides,
          [event.rideId]: {
            ...ride,
            status: 'cancelled' as RideStatus,
            cancelledAt: Date.now(),
            cancelledBy: event.by,
            cancelReason: event.reason,
            updatedAt: Date.now(),
          },
        }
        persist({ ...s, rides })
        return { rides }
      })
      break
    }
    case 'offer:created':
    case 'offer:updated': {
      const offer = event.offer
      store.applyRemote((s) => {
        const offers = { ...s.offers, [offer.id]: offer }
        persist({ ...s, offers })
        return { offers }
      })
      break
    }
    case 'chat:message': {
      const message = event.message
      if (store.messages.some((m) => m.id === message.id)) return
      store.applyRemote((s) => {
        const messages = [...s.messages, message]
        persist({ ...s, messages })
        return { messages }
      })
      break
    }
    case 'driver:location': {
      store.setDriverLocation(event.driverId, event.coord, event.bearing)
      break
    }
  }
})

/* ------------------------------------------------------------------ */
/* Selectors                                                           */
/*                                                                     */
/* Anything below that builds a NEW array must be read through         */
/* `useRides(useShallow(...))`. Zustand v5 compares snapshots by        */
/* identity, so a freshly-allocated array on every render loops        */
/* forever. Selectors returning a primitive or an existing object       */
/* reference are safe to call directly.                                */
/* ------------------------------------------------------------------ */

const LIVE: RideStatus[] = ['searching', 'accepted', 'arriving', 'waiting', 'in_progress']

export function selectActiveRide(state: RidesState, userId: string, role: Role): Ride | null {
  const mine = Object.values(state.rides).filter((r) =>
    role === 'passenger' ? r.passengerId === userId : r.driverId === userId,
  )
  const live = mine.filter((r) => LIVE.includes(r.status)).sort((a, b) => b.createdAt - a.createdAt)
  return live[0] ?? null
}

/** The most recent finished ride awaiting a rating from this side. */
export function selectRideToRate(state: RidesState, userId: string, role: Role): Ride | null {
  return (
    Object.values(state.rides)
      .filter((r) => r.status === 'completed')
      .filter((r) => (role === 'passenger' ? r.passengerId === userId : r.driverId === userId))
      .filter((r) => (role === 'passenger' ? !r.ratingByPassenger : !r.ratingByDriver))
      .sort((a, b) => (b.completedAt ?? 0) - (a.completedAt ?? 0))[0] ?? null
  )
}

export function selectOffersForRide(state: RidesState, rideId: string): Offer[] {
  return Object.values(state.offers)
    .filter((o) => o.rideId === rideId)
    .sort((a, b) => a.price - b.price || a.etaMinutes - b.etaMinutes)
}

/** Open orders a driver may bid on, nearest first. */
export function selectOpenOrders(state: RidesState, driverId: string): Ride[] {
  return Object.values(state.rides)
    .filter((r) => r.status === 'searching' && r.passengerId !== driverId)
    .sort((a, b) => b.createdAt - a.createdAt)
}

export function selectMyOfferFor(state: RidesState, rideId: string, driverId: string): Offer | null {
  return (
    Object.values(state.offers).find(
      (o) => o.rideId === rideId && o.driverId === driverId && o.status === 'pending',
    ) ?? null
  )
}

export function selectHistory(state: RidesState, userId: string, role: Role): Ride[] {
  return Object.values(state.rides)
    .filter((r) => (role === 'passenger' ? r.passengerId === userId : r.driverId === userId))
    .filter((r) => r.status === 'completed' || r.status === 'cancelled')
    .sort((a, b) => (b.completedAt ?? b.cancelledAt ?? b.createdAt) - (a.completedAt ?? a.cancelledAt ?? a.createdAt))
}

export function selectChat(state: RidesState, rideId: string): ChatMessage[] {
  return state.messages.filter((m) => m.rideId === rideId).sort((a, b) => a.createdAt - b.createdAt)
}

export function selectUnreadChat(state: RidesState, rideId: string, viewer: Role): number {
  return state.messages.filter((m) => m.rideId === rideId && m.from !== viewer && !m.read).length
}
