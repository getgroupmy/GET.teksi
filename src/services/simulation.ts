import type { LatLng, NearbyDriver, Offer, Place, Ride, Vehicle } from '@/types'
import { useRides, OFFER_TTL_MS, selectOpenOrders } from '@/store/rides'
import { useSession } from '@/store/session'
import { uid } from '@/lib/storage'
import { DRIVER_NAMES, PASSENGER_NAMES, VEHICLES, pickAvatarColor } from '@/data/fixtures'
import { PLACES } from '@/data/places'
import {
  driveMinutes,
  haversineKm,
  pathLengthKm,
  pointAlongPath,
  randomPointNear,
  roadDistanceKm,
  syntheticRoute,
} from '@/lib/geo'
import { recommendedPrice } from '@/services/pricing'
import { roundFare } from '@/lib/format'

/**
 * The simulation makes the marketplace demonstrable with a single device:
 * bot drivers circulate on the map, bid on your orders and drive to you; bot
 * passengers post orders into the driver feed and respond to your bids.
 *
 * Real users in other tabs always take precedence — bots only ever act on
 * orders nobody else has claimed.
 */

const TICK_MS = 1000
const FLEET_SIZE = 9
const FLEET_RADIUS_KM = 3.5
const LEADER_KEY = 'getteksi:sim:leader'
const LEADER_TTL_MS = 5000

const TAB_ID = uid('tab')

type BotTrip = {
  path: LatLng[]
  progress: number
  /** Fraction of the path covered per tick. */
  speed: number
}

/** Where each bot is currently heading when idle (aimless city cruising). */
const wanderTrips = new Map<string, BotTrip>()
/** Bot drivers currently fulfilling a ride, keyed by driver id. */
const activeTrips = new Map<string, BotTrip>()
/** Rides a bot has already bid on, so nobody double-bids. */
const bidLog = new Map<string, Set<string>>()
/** Timestamps for staged behaviour (arrival dwell, bot decision delays). */
const timers = new Map<string, number>()

let timer: number | null = null
let fleet: NearbyDriver[] = []

function rand<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)]
}

function randBetween(min: number, max: number): number {
  return min + Math.random() * (max - min)
}

/* ------------------------------------------------------------------ */
/* Leader election — only one tab drives the bots.                     */
/* ------------------------------------------------------------------ */

/**
 * Deliberately reads and writes localStorage directly rather than going
 * through the namespaced helper: leadership is global across every tab,
 * including tabs running under a `?device=` namespace, so two simulated
 * fleets never drive the same map at once.
 */
function claimLeadership(): boolean {
  try {
    const raw = localStorage.getItem(LEADER_KEY)
    const record = raw ? (JSON.parse(raw) as { id: string; ts: number }) : null
    const now = Date.now()
    if (!record || record.id === TAB_ID || now - record.ts > LEADER_TTL_MS) {
      localStorage.setItem(LEADER_KEY, JSON.stringify({ id: TAB_ID, ts: now }))
      return true
    }
    return false
  } catch {
    // No storage access — run the bots rather than stalling the demo.
    return true
  }
}

/* ------------------------------------------------------------------ */
/* Fleet                                                               */
/* ------------------------------------------------------------------ */

function makeBotDriver(center: LatLng, index: number): NearbyDriver {
  const name = DRIVER_NAMES[index % DRIVER_NAMES.length]
  const vehicle: Vehicle = { ...rand(VEHICLES), plate: randomPlate() }
  const coord = randomPointNear(center, FLEET_RADIUS_KM)
  return {
    id: uid('bot'),
    name,
    avatarColor: pickAvatarColor(name),
    rating: Number(randBetween(4.3, 5).toFixed(2)),
    ridesGiven: Math.floor(randBetween(120, 4800)),
    vehicle,
    coord,
    bearing: Math.random() * 360,
    isBot: true,
  }
}

function randomPlate(): string {
  const letters = 'ABCDEFGHJKLMNPQRSTUVWXY'
  const l = () => letters[Math.floor(Math.random() * letters.length)]
  return `${l()}${l()}${l()} ${Math.floor(1000 + Math.random() * 8999)}`
}

function ensureFleet(center: LatLng) {
  const store = useRides.getState()
  if (fleet.length === 0) {
    fleet = Array.from({ length: FLEET_SIZE }, (_, i) => makeBotDriver(center, i))
    fleet.forEach((d) => store.upsertNearbyDriver(d))
    return
  }
  // Recycle bots that drifted far from the user so the map never looks empty.
  fleet.forEach((driver, i) => {
    if (activeTrips.has(driver.id)) return
    if (haversineKm(driver.coord, center) > FLEET_RADIUS_KM * 2.5) {
      store.removeNearbyDriver(driver.id)
      wanderTrips.delete(driver.id)
      const replacement = makeBotDriver(center, i)
      fleet[i] = replacement
      store.upsertNearbyDriver(replacement)
    }
  })
}

function wander(driver: NearbyDriver, center: LatLng) {
  let trip = wanderTrips.get(driver.id)
  if (!trip || trip.progress >= 1) {
    const target = randomPointNear(center, FLEET_RADIUS_KM)
    const path = syntheticRoute(driver.coord, target, Math.floor(Math.random() * 4))
    const km = pathLengthKm(path)
    // ~28 km/h of idle cruising, expressed as fraction-per-tick.
    const speed = km > 0 ? (28 / 3600) * (TICK_MS / 1000) / km : 1
    trip = { path, progress: 0, speed }
    wanderTrips.set(driver.id, trip)
  }
  trip.progress = Math.min(1, trip.progress + trip.speed)
  const at = pointAlongPath(trip.path, trip.progress)
  driver.coord = at.coord
  driver.bearing = at.bearing
  useRides.getState().upsertNearbyDriver({ ...driver })
}

/* ------------------------------------------------------------------ */
/* Bidding on the local passenger's order                              */
/* ------------------------------------------------------------------ */

function botBidsOn(ride: Ride) {
  const store = useRides.getState()
  const bidders = bidLog.get(ride.id) ?? new Set<string>()
  bidLog.set(ride.id, bidders)

  const age = Date.now() - ride.createdAt
  // Stagger arrivals: first bid ~3s in, then roughly one every 4s.
  const expected = Math.min(FLEET_SIZE, Math.floor((age - 2500) / 4000) + 1)
  if (expected <= bidders.size) return

  const candidates = fleet
    .filter((d) => !bidders.has(d.id) && !activeTrips.has(d.id))
    .filter((d) => ride.vehicleClass === 'economy' || d.vehicle.vehicleClass === ride.vehicleClass)
    .map((d) => ({ driver: d, km: haversineKm(d.coord, ride.pickup.coord) }))
    .filter((c) => c.km < FLEET_RADIUS_KM * 1.6)
    .sort((a, b) => a.km - b.km)

  const next = candidates[0]
  if (!next) return

  const { driver, km } = next
  const pickupDriveKm = km * 1.35
  const etaMinutes = driveMinutes(pickupDriveKm)

  // How the bot judges the asking price against its own expectation.
  const expectedFare = recommendedPrice({
    distanceKm: ride.distanceKm,
    durationMinutes: ride.durationMinutes,
    vehicleClass: ride.vehicleClass,
    service: ride.service,
  })
  const askRatio = ride.askingPrice / expectedFare
  // Generous offers get taken as-is; low ones get a counter-bid.
  const takesAskingPrice = askRatio >= 0.97 || (askRatio >= 0.88 && Math.random() < 0.45)
  const counterMultiplier = randBetween(1.05, 1.28)
  const price = takesAskingPrice
    ? ride.askingPrice
    : roundFare(Math.max(ride.askingPrice * 1.02, expectedFare * counterMultiplier))

  // A really low ask simply gets ignored by most drivers.
  if (askRatio < 0.7 && Math.random() < 0.75) {
    bidders.add(driver.id)
    return
  }

  const offer: Offer = {
    id: uid('ofr'),
    rideId: ride.id,
    driverId: driver.id,
    driverName: driver.name,
    driverAvatarColor: driver.avatarColor,
    driverRating: driver.rating,
    driverRidesGiven: driver.ridesGiven,
    vehicle: driver.vehicle,
    price,
    etaMinutes,
    distanceKm: Number(km.toFixed(2)),
    createdAt: Date.now(),
    expiresAt: Date.now() + OFFER_TTL_MS,
    status: 'pending',
    matchedAskingPrice: takesAskingPrice,
  }
  bidders.add(driver.id)
  store.createOffer(offer)
}


/**
 * Bot trips are time-compressed: a real pickup leg of several minutes plays
 * out in well under a minute so the whole ride lifecycle stays demonstrable
 * in one sitting. Longer trips still take proportionally longer than short
 * ones — the clock is squeezed, not flattened.
 */
const clamp = (value: number, min: number, max: number) => Math.min(max, Math.max(min, value))

function pickupLegMs(km: number): number {
  return clamp(km * 12_000, 15_000, 45_000)
}

function mainLegMs(km: number): number {
  return clamp(15_000 + km * 4_000, 30_000, 75_000)
}

/* ------------------------------------------------------------------ */
/* Bot driver fulfilling an accepted ride                              */
/* ------------------------------------------------------------------ */

function driveBot(ride: Ride) {
  const store = useRides.getState()
  const driverId = ride.driverId!
  const bot = fleet.find((d) => d.id === driverId)
  const from = ride.driverCoord ?? bot?.coord ?? ride.pickup.coord

  if (ride.status === 'accepted' || ride.status === 'arriving') {
    let trip = activeTrips.get(driverId)
    if (!trip) {
      const path = syntheticRoute(from, ride.pickup.coord, 1)
      trip = { path, progress: 0, speed: TICK_MS / pickupLegMs(pathLengthKm(path)) }
      activeTrips.set(driverId, trip)
    }
    trip.progress = Math.min(1, trip.progress + trip.speed)
    const at = pointAlongPath(trip.path, trip.progress)
    store.setDriverLocation(driverId, at.coord, at.bearing)
    if (bot) {
      bot.coord = at.coord
      bot.bearing = at.bearing
      store.upsertNearbyDriver({ ...bot })
    }

    const remainingKm = haversineKm(at.coord, ride.pickup.coord)
    if (ride.status === 'accepted' && remainingKm < 0.45) {
      store.setRideStatus(ride.id, 'arriving')
    }
    if (trip.progress >= 1 || remainingKm < 0.06) {
      activeTrips.delete(driverId)
      store.setRideStatus(ride.id, 'waiting')
      store.sendMessage(ride.id, 'driver', "I've arrived and I'm waiting outside.")
      store.notify({
        kind: 'ride',
        title: 'Your driver has arrived',
        body: `${ride.driverName} is waiting at ${ride.pickup.name}.`,
        rideId: ride.id,
      })
      timers.set(`wait:${ride.id}`, Date.now())
    }
    return
  }

  if (ride.status === 'waiting') {
    // Give the passenger a beat to walk out, then pull away.
    const since = timers.get(`wait:${ride.id}`) ?? Date.now()
    if (Date.now() - since > 6000) {
      timers.delete(`wait:${ride.id}`)
      store.setRideStatus(ride.id, 'in_progress')
      store.notify({
        kind: 'ride',
        title: 'Trip started',
        body: `On the way to ${ride.dropoff.name}.`,
        rideId: ride.id,
      })
    }
    return
  }

  if (ride.status === 'in_progress') {
    let trip = activeTrips.get(driverId)
    if (!trip) {
      const path = ride.routeGeometry?.length
        ? ride.routeGeometry
        : syntheticRoute(ride.pickup.coord, ride.dropoff.coord, 3)
      trip = { path, progress: 0, speed: TICK_MS / mainLegMs(pathLengthKm(path)) }
      activeTrips.set(driverId, trip)
    }
    trip.progress = Math.min(1, trip.progress + trip.speed)
    const at = pointAlongPath(trip.path, trip.progress)
    store.setDriverLocation(driverId, at.coord, at.bearing)
    if (bot) {
      bot.coord = at.coord
      bot.bearing = at.bearing
      store.upsertNearbyDriver({ ...bot })
    }
    if (trip.progress >= 1) {
      activeTrips.delete(driverId)
      store.completeRide(ride.id)
      store.notify({
        kind: 'ride',
        title: 'Trip completed',
        body: `You arrived at ${ride.dropoff.name}. Rate your driver.`,
        rideId: ride.id,
      })
    }
  }
}

/* ------------------------------------------------------------------ */
/* Bot passengers — orders for the local driver's feed                 */
/* ------------------------------------------------------------------ */

function maybeSpawnBotOrder(center: LatLng) {
  const store = useRides.getState()
  const me = useSession.getState().user
  if (!me) return
  const open = selectOpenOrders(store, me.id).filter((r) => r.passengerId.startsWith('bp'))
  if (open.length >= 6) return

  const last = timers.get('spawn') ?? 0
  const gap = open.length === 0 ? 3000 : randBetween(9000, 20000)
  if (Date.now() - last < gap) return
  timers.set('spawn', Date.now())

  const pickupAt = randomPointNear(center, 4)
  const pickupAnchor = nearestPlace(pickupAt)
  const pickupPlace: Place = {
    ...pickupAnchor,
    id: uid('pin'),
    coord: pickupAt,
    category: 'area',
    address: `Near ${pickupAnchor.name}`,
  }
  // Pick a destination that is actually somewhere else — comparing ids would
  // never match, because the pickup pin carries a freshly minted one.
  const options = PLACES.filter(
    (p) => p.id !== pickupAnchor.id && haversineKm(p.coord, pickupAt) > 2.5,
  )
  const dropoffPlace = rand(options.length ? options : PLACES)

  const distanceKm = roadDistanceKm(pickupPlace.coord, dropoffPlace.coord)
  const durationMinutes = driveMinutes(distanceKm)
  const vehicleClass = Math.random() < 0.72 ? 'economy' : Math.random() < 0.7 ? 'comfort' : 'xl'
  const recommended = recommendedPrice({ distanceKm, durationMinutes, vehicleClass, service: 'city' })
  // Bot passengers ask somewhere between a lowball and a generous offer.
  const asking = roundFare(recommended * randBetween(0.78, 1.15))
  const name = rand(PASSENGER_NAMES)

  const ride: Ride = {
    id: uid('ride'),
    passengerId: uid('bp'),
    passengerName: name,
    passengerAvatarColor: pickAvatarColor(name),
    passengerRating: Number(randBetween(4.2, 5).toFixed(1)),
    service: 'city',
    vehicleClass,
    pickup: pickupPlace,
    dropoff: dropoffPlace,
    askingPrice: asking,
    recommendedPrice: recommended,
    currency: 'MYR',
    distanceKm: Number(distanceKm.toFixed(2)),
    durationMinutes,
    paymentMethod: Math.random() < 0.6 ? 'cash' : 'card',
    passengerCount: Math.random() < 0.8 ? 1 : Math.ceil(randBetween(2, 4)),
    comment: Math.random() < 0.3 ? rand(['At the lobby entrance', 'Near the guard house', 'I have one big luggage', 'Please come to level 1 drop-off']) : undefined,
    options: Math.random() < 0.2 ? ['luggage'] : [],
    status: 'searching',
    createdAt: Date.now(),
    updatedAt: Date.now(),
    priceRaises: 0,
    routeGeometry: syntheticRoute(pickupPlace.coord, dropoffPlace.coord, 3),
  }
  store.publishRide(ride)
}

/** The landmark a dropped pin should be described relative to. */
function nearestPlace(coord: LatLng): Place {
  let best = PLACES[0]
  let bestKm = Infinity
  for (const p of PLACES) {
    const km = haversineKm(p.coord, coord)
    if (km < bestKm) {
      bestKm = km
      best = p
    }
  }
  return best
}

/** Bot passengers weigh the local driver's bid and answer after a beat. */
function resolveBotPassengerDecisions() {
  const store = useRides.getState()
  const me = useSession.getState().user
  if (!me) return
  Object.values(store.offers)
    .filter((o) => o.status === 'pending' && o.driverId === me.id)
    .forEach((offer) => {
      const ride = store.rides[offer.rideId]
      if (!ride || !ride.passengerId.startsWith('bp') || ride.status !== 'searching') return
      const key = `decide:${offer.id}`
      const first = timers.get(key)
      if (!first) {
        timers.set(key, Date.now())
        return
      }
      // Bot passengers think for 4-10 seconds before answering.
      const delay = 4000 + (offer.price / Math.max(1, ride.askingPrice)) * 4000
      if (Date.now() - first < delay) return
      timers.delete(key)

      const overAsk = offer.price / ride.askingPrice
      const acceptChance =
        overAsk <= 1.0 ? 0.92 : overAsk <= 1.12 ? 0.62 : overAsk <= 1.3 ? 0.3 : 0.08
      if (Math.random() < acceptChance) {
        store.acceptOffer(offer.id)
        store.notify({
          kind: 'ride',
          title: 'Your offer was accepted',
          body: `${ride.passengerName} accepted. Head to ${ride.pickup.name}.`,
          rideId: ride.id,
        })
      } else {
        store.declineOffer(offer.id)
        store.notify({
          kind: 'ride',
          title: 'Offer declined',
          body: `${ride.passengerName} chose another driver.`,
          rideId: ride.id,
        })
      }
    })
}

/** Bot passengers give up on orders nobody wants, and sometimes raise instead. */
function ageBotOrders() {
  const store = useRides.getState()
  Object.values(store.rides)
    .filter((r) => r.status === 'searching' && r.passengerId.startsWith('bp'))
    .forEach((ride) => {
      const age = Date.now() - ride.createdAt
      if (age > 45_000 && ride.priceRaises < 2 && Math.random() < 0.02) {
        store.updateRide(ride.id, {
          askingPrice: roundFare(ride.askingPrice * 1.12),
          priceRaises: ride.priceRaises + 1,
        })
      }
      if (age > 150_000) {
        store.cancelRide(ride.id, 'passenger', 'No longer needed')
      }
    })
}

/* ------------------------------------------------------------------ */
/* Tick                                                                */
/* ------------------------------------------------------------------ */

function tick() {
  const session = useSession.getState()
  if (!session.prefs.simulationEnabled || !session.user) return
  if (!claimLeadership()) return

  const store = useRides.getState()
  const me = session.user
  const center = session.myLocation

  store.sweep()
  ensureFleet(center)

  const myRides = Object.values(store.rides)

  // Bot drivers currently on a job.
  const botJobs = myRides.filter(
    (r) =>
      r.driverId?.startsWith('bot') &&
      ['accepted', 'arriving', 'waiting', 'in_progress'].includes(r.status),
  )
  botJobs.forEach(driveBot)
  const busyIds = new Set(botJobs.map((r) => r.driverId!))

  // Idle bots cruise around.
  fleet.forEach((driver) => {
    if (busyIds.has(driver.id)) return
    wander(driver, center)
  })

  // Bots bid on the local passenger's live order.
  myRides
    .filter((r) => r.status === 'searching' && r.passengerId === me.id)
    .forEach(botBidsOn)

  // Driver-side marketplace.
  if (session.prefs.role === 'driver' && session.prefs.driverOnline) {
    maybeSpawnBotOrder(center)
  }
  resolveBotPassengerDecisions()
  ageBotOrders()
}

export function startSimulation(): void {
  if (timer != null) return
  timer = window.setInterval(tick, TICK_MS)
}

export function stopSimulation(): void {
  if (timer == null) return
  window.clearInterval(timer)
  timer = null
  fleet.forEach((d) => useRides.getState().removeNearbyDriver(d.id))
  fleet = []
  wanderTrips.clear()
  activeTrips.clear()
  bidLog.clear()
  timers.clear()
}
