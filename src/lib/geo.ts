import type { LatLng } from '@/types'

const EARTH_RADIUS_KM = 6371

const toRad = (deg: number) => (deg * Math.PI) / 180
const toDeg = (rad: number) => (rad * 180) / Math.PI

/** Great-circle distance in kilometres. */
export function haversineKm(a: LatLng, b: LatLng): number {
  const dLat = toRad(b.lat - a.lat)
  const dLng = toRad(b.lng - a.lng)
  const lat1 = toRad(a.lat)
  const lat2 = toRad(b.lat)
  const h =
    Math.sin(dLat / 2) ** 2 + Math.sin(dLng / 2) ** 2 * Math.cos(lat1) * Math.cos(lat2)
  return 2 * EARTH_RADIUS_KM * Math.asin(Math.sqrt(h))
}

/** Compass bearing from `a` to `b`, in degrees clockwise from north. */
export function bearing(a: LatLng, b: LatLng): number {
  const lat1 = toRad(a.lat)
  const lat2 = toRad(b.lat)
  const dLng = toRad(b.lng - a.lng)
  const y = Math.sin(dLng) * Math.cos(lat2)
  const x = Math.cos(lat1) * Math.sin(lat2) - Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLng)
  return (toDeg(Math.atan2(y, x)) + 360) % 360
}

/** Linear interpolation between two coordinates — good enough at city scale. */
export function lerpCoord(a: LatLng, b: LatLng, t: number): LatLng {
  return { lat: a.lat + (b.lat - a.lat) * t, lng: a.lng + (b.lng - a.lng) * t }
}

/** Random point within `radiusKm` of `center`, uniformly distributed by area. */
export function randomPointNear(center: LatLng, radiusKm: number): LatLng {
  const r = radiusKm * Math.sqrt(Math.random())
  const theta = Math.random() * 2 * Math.PI
  const dLat = (r / EARTH_RADIUS_KM) * (180 / Math.PI)
  const dLng = dLat / Math.cos(toRad(center.lat))
  return { lat: center.lat + dLat * Math.sin(theta), lng: center.lng + dLng * Math.cos(theta) }
}

/** Total length of a polyline in kilometres. */
export function pathLengthKm(path: LatLng[]): number {
  let total = 0
  for (let i = 1; i < path.length; i++) total += haversineKm(path[i - 1], path[i])
  return total
}

/**
 * Position at `fraction` (0..1) along a polyline, plus the heading at that
 * point. Used to animate a car along its route.
 */
export function pointAlongPath(path: LatLng[], fraction: number): { coord: LatLng; bearing: number } {
  if (path.length === 0) return { coord: { lat: 0, lng: 0 }, bearing: 0 }
  if (path.length === 1) return { coord: path[0], bearing: 0 }
  const clamped = Math.max(0, Math.min(1, fraction))
  const target = pathLengthKm(path) * clamped
  let travelled = 0
  for (let i = 1; i < path.length; i++) {
    const segment = haversineKm(path[i - 1], path[i])
    if (travelled + segment >= target || i === path.length - 1) {
      const t = segment === 0 ? 0 : (target - travelled) / segment
      return {
        coord: lerpCoord(path[i - 1], path[i], Math.max(0, Math.min(1, t))),
        bearing: bearing(path[i - 1], path[i]),
      }
    }
    travelled += segment
  }
  return { coord: path[path.length - 1], bearing: 0 }
}

/**
 * Build a plausible road-like path between two points without a routing
 * server: bend the straight line with a couple of perpendicular offsets and
 * add small jitter so it reads as streets rather than a ruler line.
 */
export function syntheticRoute(from: LatLng, to: LatLng, seed = 1): LatLng[] {
  const steps = 24
  const dist = haversineKm(from, to)
  // Bend more on long trips, but never so much that it looks like a detour.
  const amplitude = Math.min(0.12, dist * 0.02)
  const path: LatLng[] = []
  const wobble = (i: number) => Math.sin((i / steps) * Math.PI) * amplitude
  const dLat = to.lat - from.lat
  const dLng = to.lng - from.lng
  // Unit perpendicular to the direct line.
  const len = Math.hypot(dLat, dLng) || 1
  const pLat = -dLng / len
  const pLng = dLat / len
  const dir = seed % 2 === 0 ? 1 : -1
  for (let i = 0; i <= steps; i++) {
    const t = i / steps
    const base = lerpCoord(from, to, t)
    const off = wobble(i) * dir * 0.01
    // A little stair-stepping to suggest a grid of streets.
    const jitter = Math.sin(t * Math.PI * 6 + seed) * amplitude * 0.0015
    path.push({ lat: base.lat + pLat * off + jitter, lng: base.lng + pLng * off })
  }
  return path
}

/** Bounding box for a set of points, padded by `padRatio`. */
export function boundsOf(points: LatLng[], padRatio = 0.18) {
  const lats = points.map((p) => p.lat)
  const lngs = points.map((p) => p.lng)
  let south = Math.min(...lats)
  let north = Math.max(...lats)
  let west = Math.min(...lngs)
  let east = Math.max(...lngs)
  const padLat = Math.max((north - south) * padRatio, 0.004)
  const padLng = Math.max((east - west) * padRatio, 0.004)
  south -= padLat
  north += padLat
  west -= padLng
  east += padLng
  return { south, west, north, east }
}

/**
 * Road distance estimate. Real road networks are longer than the crow flies;
 * 1.35 is a reasonable urban detour factor.
 */
export function roadDistanceKm(from: LatLng, to: LatLng): number {
  return haversineKm(from, to) * 1.35
}

/** Rough driving time given a distance, assuming mixed urban traffic. */
export function driveMinutes(km: number): number {
  const avgSpeedKmh = km > 25 ? 65 : km > 8 ? 38 : 24
  return Math.max(2, Math.round((km / avgSpeedKmh) * 60))
}
