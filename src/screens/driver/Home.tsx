import { useEffect, useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import { Menu, Bell, Wallet, User } from 'lucide-react'
import { useSession } from '@/store/session'
import { useRides, selectActiveRide, selectRideToRate } from '@/store/rides'
import MapView, { type MapPin } from '@/components/MapView'
import { FabButton } from '@/components/ui'
import OrderFeedSheet from '@/components/driver/OrderFeedSheet'
import ActiveRideSheet from '@/components/driver/ActiveRideSheet'
import { money } from '@/lib/format'
import { bearing, syntheticRoute } from '@/lib/geo'
import { bus } from '@/lib/bus'

export default function DriverHome() {
  const navigate = useNavigate()
  const user = useSession((s) => s.user)!
  const prefs = useSession((s) => s.prefs)
  const setRole = useSession((s) => s.setRole)
  const myLocation = useSession((s) => s.myLocation)

  const activeRide = useRides((s) => selectActiveRide(s, user.id, 'driver'))
  const rideToRate = useRides((s) => selectRideToRate(s, user.id, 'driver'))
  const unread = useRides((s) => s.notifications.filter((n) => !n.read).length)

  // A driver without a vehicle on file has to finish onboarding first.
  useEffect(() => {
    if (!user.driverProfile) navigate('/d/onboarding', { replace: true })
  }, [user.driverProfile, navigate])

  useEffect(() => {
    if (rideToRate) navigate(`/rate/${rideToRate.id}`)
  }, [rideToRate, navigate])

  // Broadcast our position so the passenger's tab can follow the car.
  useEffect(() => {
    if (!activeRide) return
    const id = window.setInterval(() => {
      bus.emitRemote({
        type: 'driver:location',
        driverId: user.id,
        coord: myLocation,
        bearing: bearing(myLocation, activeRide.status === 'in_progress' ? activeRide.dropoff.coord : activeRide.pickup.coord),
      })
    }, 3000)
    return () => window.clearInterval(id)
  }, [activeRide, myLocation, user.id])

  const pins = useMemo<MapPin[]>(() => {
    const result: MapPin[] = [{ id: 'me', coord: myLocation, kind: 'me' }]
    if (activeRide) {
      result.push({ id: 'pickup', coord: activeRide.pickup.coord, kind: 'pickup', label: activeRide.pickup.name })
      if (activeRide.stop) result.push({ id: 'stop', coord: activeRide.stop.coord, kind: 'stop' })
      result.push({ id: 'dropoff', coord: activeRide.dropoff.coord, kind: 'dropoff', label: activeRide.dropoff.name })
    }
    return result
  }, [activeRide, myLocation])

  const route = useMemo(() => {
    if (!activeRide) return undefined
    if (activeRide.status === 'in_progress') {
      return activeRide.routeGeometry ?? syntheticRoute(activeRide.pickup.coord, activeRide.dropoff.coord, 3)
    }
    return syntheticRoute(myLocation, activeRide.pickup.coord, 1)
  }, [activeRide, myLocation])

  const fitToken = activeRide ? `${activeRide.id}:${activeRide.status}` : undefined
  const earnedToday = user.driverProfile?.earnings ?? 0

  if (!user.driverProfile) return null

  return (
    <div className="relative h-full">
      <MapView
        center={myLocation}
        pins={pins}
        route={route}
        fitToken={fitToken}
        bottomPadding={activeRide ? 380 : 340}
      />

      <div
        className="absolute left-0 right-0 flex items-center justify-between px-3 z-10 gap-2"
        style={{ top: 'calc(var(--safe-top) + 12px)' }}
      >
        <FabButton icon={<Menu size={19} />} label="Menu" onClick={() => navigate('/menu')} />

        <button
          className="flex items-center gap-2 px-3 py-2 min-w-0"
          onClick={() => navigate('/d/earnings')}
          style={{
            background: 'var(--surface)',
            border: '1px solid var(--line)',
            borderRadius: 999,
            boxShadow: '0 4px 14px rgba(0,0,0,.35)',
          }}
        >
          <Wallet size={15} style={{ color: 'var(--brand)' }} />
          <span className="text-[14px] font-extrabold tabular">{money(earnedToday, { decimals: false })}</span>
          <span
            style={{
              width: 7, height: 7, borderRadius: 999, marginLeft: 2,
              background: prefs.driverOnline ? 'var(--ok)' : 'var(--text-mute)',
            }}
          />
        </button>

        <div className="flex gap-2">
          {!activeRide && (
            <button
              className="btn btn-sm"
              style={{
                background: 'var(--surface)',
                border: '1px solid var(--line)',
                color: 'var(--text)',
                boxShadow: '0 4px 14px rgba(0,0,0,.35)',
              }}
              onClick={() => setRole('passenger')}
            >
              <User size={15} style={{ color: 'var(--brand)' }} /> Ride
            </button>
          )}
          <FabButton
            icon={<Bell size={19} />}
            label="Notifications"
            badge={unread}
            onClick={() => navigate('/notifications')}
          />
        </div>
      </div>

      {activeRide ? (
        <ActiveRideSheet ride={activeRide} driverAt={myLocation} />
      ) : (
        <OrderFeedSheet driverAt={myLocation} />
      )}
    </div>
  )
}
