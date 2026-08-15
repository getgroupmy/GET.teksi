import { useEffect, useMemo, useRef } from 'react'
import L from 'leaflet'
import type { LatLng, NearbyDriver } from '@/types'
import { boundsOf } from '@/lib/geo'

export type MapPin = {
  id: string
  coord: LatLng
  kind: 'pickup' | 'dropoff' | 'stop' | 'me'
  label?: string
}

type Props = {
  center: LatLng
  zoom?: number
  pins?: MapPin[]
  drivers?: NearbyDriver[]
  route?: LatLng[]
  /** Second polyline, drawn dashed — the driver's leg to the pickup. */
  approach?: LatLng[]
  /** Re-fit the viewport whenever this token changes. */
  fitToken?: string
  interactive?: boolean
  /** Extra space at the bottom so sheets don't cover the route. */
  bottomPadding?: number
  onMapMove?: (center: LatLng) => void
}

/**
 * A Leaflet instance keeps its container reference until `remove()` runs.
 * React 19's StrictMode double-mount and route changes can leave a queued
 * effect pointing at a torn-down map, so every deferred call checks this.
 */
function isLive(map: L.Map | null): map is L.Map {
  try {
    return Boolean(map && map.getContainer()?.isConnected)
  } catch {
    return false
  }
}

const TILE_URL = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
const ATTRIBUTION = '&copy; OpenStreetMap'

function carIcon(driver: NearbyDriver) {
  return L.divIcon({
    className: '',
    iconSize: [34, 34],
    iconAnchor: [17, 17],
    html: `
      <div class="marker-car" style="transform: rotate(${driver.bearing}deg); width:34px; height:34px; display:flex; align-items:center; justify-content:center;">
        <svg width="30" height="30" viewBox="0 0 24 24" fill="none" style="filter: drop-shadow(0 2px 4px rgba(0,0,0,.6))">
          <path d="M12 2.2 19 21l-7-4.1L5 21 12 2.2Z" fill="#f4f7f4" stroke="#0b0d0c" stroke-width="1.1" stroke-linejoin="round"/>
        </svg>
      </div>`,
  })
}

function pinIcon(kind: MapPin['kind'], label?: string) {
  if (kind === 'me') {
    return L.divIcon({
      className: '',
      iconSize: [22, 22],
      iconAnchor: [11, 11],
      html: `<div class="pin-pulse" style="position:relative;width:22px;height:22px;border-radius:999px;background:#38bdf8;border:3px solid #0b0d0c;box-shadow:0 0 0 2px rgba(56,189,248,.35)"></div>`,
    })
  }
  const color = kind === 'pickup' ? '#c1f11d' : kind === 'stop' ? '#ffb020' : '#ffffff'
  const inner = kind === 'pickup' ? '#0b0d0c' : kind === 'stop' ? '#0b0d0c' : '#0b0d0c'
  return L.divIcon({
    className: '',
    iconSize: [30, 38],
    iconAnchor: [15, 34],
    html: `
      <div style="position:relative;display:flex;flex-direction:column;align-items:center;filter:drop-shadow(0 3px 5px rgba(0,0,0,.55))">
        <div style="width:26px;height:26px;border-radius:999px;background:${color};display:flex;align-items:center;justify-content:center;border:2px solid rgba(0,0,0,.25)">
          <div style="width:9px;height:9px;border-radius:999px;background:${inner}"></div>
        </div>
        <div style="width:2px;height:10px;background:${color};margin-top:-1px"></div>
        ${label ? `<div style="position:absolute;top:-24px;white-space:nowrap;background:#161a18;color:#f4f7f4;font-size:11px;font-weight:600;padding:3px 8px;border-radius:8px;border:1px solid #2f3633">${label}</div>` : ''}
      </div>`,
  })
}

export default function MapView({
  center,
  zoom = 14,
  pins = [],
  drivers = [],
  route,
  approach,
  fitToken,
  interactive = true,
  bottomPadding = 0,
  onMapMove,
}: Props) {
  const containerRef = useRef<HTMLDivElement>(null)
  const mapRef = useRef<L.Map | null>(null)
  const driverLayer = useRef<Map<string, L.Marker>>(new Map())
  const pinLayer = useRef<Map<string, L.Marker>>(new Map())
  const routeLine = useRef<L.Polyline | null>(null)
  const routeCasing = useRef<L.Polyline | null>(null)
  const approachLine = useRef<L.Polyline | null>(null)
  const lastFit = useRef<string | undefined>(undefined)

  // Create the map once; React never re-renders Leaflet's DOM.
  useEffect(() => {
    if (!containerRef.current || mapRef.current) return
    const map = L.map(containerRef.current, {
      center: [center.lat, center.lng],
      zoom,
      zoomControl: false,
      attributionControl: true,
      dragging: interactive,
      scrollWheelZoom: interactive,
      doubleClickZoom: interactive,
      touchZoom: interactive,
      keyboard: interactive,
      preferCanvas: true,
    })
    L.tileLayer(TILE_URL, { maxZoom: 19, attribution: ATTRIBUTION, crossOrigin: true }).addTo(map)
    mapRef.current = map
    let alive = true
    if (onMapMove) {
      map.on('moveend', () => {
        const c = map.getCenter()
        onMapMove({ lat: c.lat, lng: c.lng })
      })
    }
    // Leaflet mis-measures inside animating sheets; settle it after mount.
    const settle = window.setTimeout(() => {
      if (alive) map.invalidateSize()
    }, 60)
    return () => {
      alive = false
      window.clearTimeout(settle)
      map.remove()
      mapRef.current = null
      driverLayer.current.clear()
      pinLayer.current.clear()
      routeLine.current = null
      routeCasing.current = null
      approachLine.current = null
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const paddingBottom = bottomPadding

  // Pins: reuse markers by id so they glide rather than flicker.
  useEffect(() => {
    const map = mapRef.current
    if (!map) return
    const seen = new Set<string>()
    pins.forEach((pin) => {
      seen.add(pin.id)
      const existing = pinLayer.current.get(pin.id)
      if (existing) {
        existing.setLatLng([pin.coord.lat, pin.coord.lng])
        existing.setIcon(pinIcon(pin.kind, pin.label))
      } else {
        const marker = L.marker([pin.coord.lat, pin.coord.lng], {
          icon: pinIcon(pin.kind, pin.label),
          interactive: false,
          zIndexOffset: pin.kind === 'me' ? 100 : 400,
        }).addTo(map)
        pinLayer.current.set(pin.id, marker)
      }
    })
    pinLayer.current.forEach((marker, id) => {
      if (!seen.has(id)) {
        marker.remove()
        pinLayer.current.delete(id)
      }
    })
  }, [pins])

  useEffect(() => {
    const map = mapRef.current
    if (!map) return
    const seen = new Set<string>()
    drivers.forEach((driver) => {
      seen.add(driver.id)
      const existing = driverLayer.current.get(driver.id)
      if (existing) {
        existing.setLatLng([driver.coord.lat, driver.coord.lng])
        existing.setIcon(carIcon(driver))
      } else {
        const marker = L.marker([driver.coord.lat, driver.coord.lng], {
          icon: carIcon(driver),
          interactive: false,
          zIndexOffset: 200,
        }).addTo(map)
        driverLayer.current.set(driver.id, marker)
      }
    })
    driverLayer.current.forEach((marker, id) => {
      if (!seen.has(id)) {
        marker.remove()
        driverLayer.current.delete(id)
      }
    })
  }, [drivers])

  useEffect(() => {
    const map = mapRef.current
    if (!map) return
    routeCasing.current?.remove()
    routeLine.current?.remove()
    routeCasing.current = null
    routeLine.current = null
    if (!route || route.length < 2) return
    const latlngs = route.map((p) => [p.lat, p.lng]) as [number, number][]
    // Draw a dark casing under the brand-coloured line for contrast on tiles.
    routeCasing.current = L.polyline(latlngs, {
      color: '#0b0d0c',
      weight: 9,
      opacity: 0.85,
      lineJoin: 'round',
      lineCap: 'round',
    }).addTo(map)
    routeLine.current = L.polyline(latlngs, {
      color: '#c1f11d',
      weight: 5,
      opacity: 1,
      lineJoin: 'round',
      lineCap: 'round',
    }).addTo(map)
  }, [route])

  useEffect(() => {
    const map = mapRef.current
    if (!map) return
    approachLine.current?.remove()
    approachLine.current = null
    if (!approach || approach.length < 2) return
    approachLine.current = L.polyline(
      approach.map((p) => [p.lat, p.lng]) as [number, number][],
      { color: '#9aa39d', weight: 4, opacity: 0.9, dashArray: '2 9', lineCap: 'round' },
    ).addTo(map)
  }, [approach])

  const fitPoints = useMemo(() => {
    const points: LatLng[] = []
    if (route && route.length > 1) points.push(...route)
    if (approach && approach.length > 1) points.push(...approach)
    pins.forEach((p) => points.push(p.coord))
    return points
  }, [route, approach, pins])

  // Re-frame only when the caller bumps the token — never on every tick.
  useEffect(() => {
    const map = mapRef.current
    if (!isLive(map) || !fitToken || fitToken === lastFit.current) return
    lastFit.current = fitToken
    if (fitPoints.length >= 2) {
      const b = boundsOf(fitPoints)
      map.fitBounds(
        [
          [b.south, b.west],
          [b.north, b.east],
        ],
        { paddingTopLeft: [28, 90], paddingBottomRight: [28, paddingBottom + 28], animate: true },
      )
    } else if (fitPoints.length === 1) {
      map.setView([fitPoints[0].lat, fitPoints[0].lng], 15, { animate: true })
    }
  }, [fitToken, fitPoints, paddingBottom])

  // Follow the device when there is nothing else framing the view.
  useEffect(() => {
    const map = mapRef.current
    if (!isLive(map) || fitToken) return
    map.setView([center.lat, center.lng], map.getZoom(), { animate: true })
  }, [center.lat, center.lng, fitToken])

  useEffect(() => {
    const map = mapRef.current
    if (!map) return
    const onResize = () => {
      if (isLive(mapRef.current)) map.invalidateSize()
    }
    window.addEventListener('resize', onResize)
    return () => window.removeEventListener('resize', onResize)
  }, [])

  return <div ref={containerRef} className="map-root" />
}
