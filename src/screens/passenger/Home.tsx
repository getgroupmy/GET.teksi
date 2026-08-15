import { useEffect, useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import { Menu, Bell, Crosshair, CarFront } from 'lucide-react'
import { useSession } from '@/store/session'
import { useRides, selectActiveRide, selectRideToRate } from '@/store/rides'
import { useDraft } from '@/store/draft'
import MapView, { type MapPin } from '@/components/MapView'
import { FabButton } from '@/components/ui'
import IdleSheet from '@/components/passenger/IdleSheet'
import PriceSheet from '@/components/passenger/PriceSheet'
import OffersSheet from '@/components/passenger/OffersSheet'
import TrackingSheet from '@/components/passenger/TrackingSheet'
import { STREETS } from '@/data/places'
import { syntheticRoute } from '@/lib/geo'
import { uid } from '@/lib/storage'

export default function PassengerHome() {
  const navigate = useNavigate()
  const user = useSession((s) => s.user)!
  const myLocation = useSession((s) => s.myLocation)
  const setRole = useSession((s) => s.setRole)
  const draft = useDraft()

  const activeRide = useRides((s) => selectActiveRide(s, user.id, 'passenger'))
  const rideToRate = useRides((s) => selectRideToRate(s, user.id, 'passenger'))
  const nearbyDrivers = useRides((s) => s.nearbyDrivers)
  const unreadNotifications = useRides((s) => s.notifications.filter((n) => !n.read).length)

  // Seed the pickup from the device location the first time we have one.
  useEffect(() => {
    if (draft.pickup) return
    draft.setPickup({
      id: uid('pin'),
      name: 'Current location',
      address: STREETS[Math.floor(Math.random() * STREETS.length)],
      coord: myLocation,
      category: 'area',
    })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [myLocation.lat, myLocation.lng])

  // A finished ride always leads to the rating screen.
  useEffect(() => {
    if (rideToRate) navigate(`/rate/${rideToRate.id}`)
  }, [rideToRate, navigate])

  // Publishing an order clears the composer.
  useEffect(() => {
    if (activeRide && draft.step !== 'idle') draft.setStep('idle')
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeRide?.id])

  const drivers = useMemo(() => {
    const list = Object.values(nearbyDrivers)
    if (!activeRide?.driverId) return list
    // Once matched, only the assigned car matters on the map.
    return list.filter((d) => d.id === activeRide.driverId)
  }, [nearbyDrivers, activeRide?.driverId])

  const pins = useMemo<MapPin[]>(() => {
    const result: MapPin[] = []
    if (activeRide) {
      result.push({ id: 'pickup', coord: activeRide.pickup.coord, kind: 'pickup', label: 'Pickup' })
      if (activeRide.stop) result.push({ id: 'stop', coord: activeRide.stop.coord, kind: 'stop' })
      result.push({ id: 'dropoff', coord: activeRide.dropoff.coord, kind: 'dropoff', label: activeRide.dropoff.name })
      return result
    }
    if (draft.pickup) result.push({ id: 'pickup', coord: draft.pickup.coord, kind: 'pickup', label: 'Pickup' })
    if (draft.stop) result.push({ id: 'stop', coord: draft.stop.coord, kind: 'stop' })
    if (draft.dropoff) result.push({ id: 'dropoff', coord: draft.dropoff.coord, kind: 'dropoff', label: draft.dropoff.name })
    if (!draft.pickup) result.push({ id: 'me', coord: myLocation, kind: 'me' })
    return result
  }, [activeRide, draft.pickup, draft.dropoff, draft.stop, myLocation])

  const route = useMemo(() => {
    if (activeRide) {
      if (activeRide.status === 'in_progress') return activeRide.routeGeometry
      return activeRide.status === 'searching' ? activeRide.routeGeometry : undefined
    }
    if (draft.pickup && draft.dropoff) return syntheticRoute(draft.pickup.coord, draft.dropoff.coord, 3)
    return undefined
  }, [activeRide, draft.pickup, draft.dropoff])

  // Dashed line from the driver's live position to wherever they're headed.
  const approach = useMemo(() => {
    if (!activeRide?.driverCoord) return undefined
    if (activeRide.status === 'accepted' || activeRide.status === 'arriving') {
      return syntheticRoute(activeRide.driverCoord, activeRide.pickup.coord, 1)
    }
    return undefined
  }, [activeRide?.driverCoord, activeRide?.status, activeRide?.pickup.coord])

  const fitToken = useMemo(() => {
    if (activeRide) return `${activeRide.id}:${activeRide.status}`
    if (draft.pickup && draft.dropoff) return `draft:${draft.pickup.id}:${draft.dropoff.id}`
    return undefined
  }, [activeRide, draft.pickup, draft.dropoff])

  const sheetHeight = activeRide ? 340 : draft.step === 'price' ? 400 : 300

  return (
    <div className="relative h-full">
      <MapView
        center={myLocation}
        pins={pins}
        drivers={drivers}
        route={route}
        approach={approach}
        fitToken={fitToken}
        bottomPadding={sheetHeight}
      />

      <div
        className="absolute left-0 right-0 flex items-center justify-between px-3 z-10"
        style={{ top: 'calc(var(--safe-top) + 12px)' }}
      >
        <FabButton icon={<Menu size={19} />} label="Menu" onClick={() => navigate('/menu')} />
        <div className="flex gap-2">
          {user.driverProfile && !activeRide && (
            <button
              className="btn btn-sm"
              style={{
                background: 'var(--surface)',
                border: '1px solid var(--line)',
                color: 'var(--text)',
                boxShadow: '0 4px 14px rgba(0,0,0,.35)',
              }}
              onClick={() => setRole('driver')}
            >
              <CarFront size={15} style={{ color: 'var(--brand)' }} /> Drive
            </button>
          )}
          <FabButton
            icon={<Bell size={19} />}
            label="Notifications"
            badge={unreadNotifications}
            onClick={() => navigate('/notifications')}
          />
        </div>
      </div>

      {!activeRide && draft.step === 'idle' && (
        <div className="absolute right-3 z-10" style={{ bottom: sheetHeight + 14 }}>
          <FabButton
            icon={<Crosshair size={19} />}
            label="Centre on me"
            onClick={() =>
              draft.setPickup({
                id: uid('pin'),
                name: 'Current location',
                address: STREETS[Math.floor(Math.random() * STREETS.length)],
                coord: myLocation,
                category: 'area',
              })
            }
          />
        </div>
      )}

      {activeRide ? (
        activeRide.status === 'searching' ? (
          <OffersSheet ride={activeRide} />
        ) : (
          <TrackingSheet ride={activeRide} />
        )
      ) : draft.step === 'price' && draft.dropoff ? (
        <PriceSheet />
      ) : (
        <IdleSheet />
      )}
    </div>
  )
}
