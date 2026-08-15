import { useNavigate, useParams } from 'react-router-dom'
import { Star, Copy, TrendingUp } from 'lucide-react'
import { useSession } from '@/store/session'
import { useRides } from '@/store/rides'
import { money, distance as fmtDistance, duration, clockTime, dateLabel } from '@/lib/format'
import { driverNet, commissionOn } from '@/services/pricing'
import { TopBar, Avatar, Rating, EmptyState, RouteStops, Banner } from '@/components/ui'
import MapView, { type MapPin } from '@/components/MapView'

export default function RideDetail() {
  const { rideId = '' } = useParams()
  const navigate = useNavigate()
  const user = useSession((s) => s.user)!
  const ride = useRides((s) => s.rides[rideId])

  if (!ride) {
    return (
      <div className="h-full flex flex-col">
        <TopBar title="Ride" onBack={() => navigate('/history')} />
        <EmptyState title="Ride not found" />
      </div>
    )
  }

  const asDriver = ride.driverId === user.id
  const fare = ride.finalPrice ?? ride.askingPrice
  const net = driverNet(fare)
  const cancelled = ride.status === 'cancelled'
  const other = asDriver
    ? { name: ride.passengerName, color: ride.passengerAvatarColor, rating: ride.passengerRating }
    : { name: ride.driverName ?? 'Driver', color: ride.driverAvatarColor ?? '#888', rating: ride.driverRating ?? 5 }

  const pins: MapPin[] = [
    { id: 'pickup', coord: ride.pickup.coord, kind: 'pickup' },
    { id: 'dropoff', coord: ride.dropoff.coord, kind: 'dropoff' },
  ]
  if (ride.stop) pins.splice(1, 0, { id: 'stop', coord: ride.stop.coord, kind: 'stop' })

  const reference = ride.id.slice(-8).toUpperCase()

  return (
    <div className="h-full flex flex-col">
      <TopBar title="Trip details" onBack={() => navigate(-1)} />

      <div className="flex-1 scroll-y pb-6">
        <div style={{ position: 'relative', height: 190 }}>
          <MapView
            center={ride.pickup.coord}
            pins={pins}
            route={ride.routeGeometry}
            fitToken={`detail:${ride.id}`}
            interactive={false}
          />
        </div>

        <div className="px-4">
          <div className="flex items-baseline justify-between mt-4 mb-1">
            <h2 className="text-[22px] font-extrabold tabular">
              {money(asDriver ? net : fare)}
            </h2>
            <span className="text-[13px]" style={{ color: 'var(--text-dim)' }}>
              {dateLabel(ride.completedAt ?? ride.createdAt)} · {clockTime(ride.completedAt ?? ride.createdAt)}
            </span>
          </div>

          {cancelled && (
            <div className="my-3">
              <Banner tone="danger">
                Cancelled by {ride.cancelledBy === 'driver' ? 'the driver' : ride.cancelledBy === 'system' ? 'the system' : 'you'}
                {ride.cancelReason ? ` — ${ride.cancelReason}` : ''}.
              </Banner>
            </div>
          )}

          <div className="card p-3.5 my-3">
            <RouteStops pickup={ride.pickup.name} dropoff={ride.dropoff.name} stop={ride.stop?.name} />
            <div className="divider my-3" />
            <div className="flex items-center justify-between text-[13px] tabular" style={{ color: 'var(--text-dim)' }}>
              <span>{fmtDistance(ride.distanceKm)}</span>
              <span>{duration(ride.durationMinutes)}</span>
              <span>Ref {reference}</span>
            </div>
          </div>

          {!cancelled && (
            <div className="card p-3.5 my-3">
              <div className="label-xs mb-3">Fare breakdown</div>
              <LineItem label="Agreed price" value={money(fare)} />
              {ride.askingPrice !== fare && (
                <LineItem
                  label="Your original offer"
                  value={money(ride.askingPrice)}
                  muted
                />
              )}
              {ride.priceRaises > 0 && (
                <LineItem
                  label={`Price raised ${ride.priceRaises}×`}
                  value=""
                  muted
                  icon={<TrendingUp size={13} />}
                />
              )}
              {asDriver && (
                <>
                  <LineItem label="Service fee" value={`−${money(commissionOn(fare))}`} muted />
                  <div className="divider my-2.5" />
                  <LineItem label="You earned" value={money(net)} bold />
                </>
              )}
              {!asDriver && (
                <>
                  {ride.tip ? <LineItem label="Tip" value={money(ride.tip)} /> : null}
                  <div className="divider my-2.5" />
                  <LineItem label="Total paid" value={money(fare + (ride.tip ?? 0))} bold />
                  <div className="text-[12px] mt-2" style={{ color: 'var(--text-mute)' }}>
                    Paid by {ride.paymentMethod === 'cash' ? 'cash' : ride.paymentMethod === 'card' ? 'card ···4821' : 'wallet'}
                  </div>
                </>
              )}
            </div>
          )}

          <div className="card p-3.5 my-3 flex items-center gap-3">
            <Avatar name={other.name} color={other.color} size={44} />
            <div className="flex-1 min-w-0">
              <div className="text-[15px] font-bold truncate">{other.name}</div>
              <div className="flex items-center gap-2">
                <Rating value={other.rating} />
                {ride.driverVehicle && !asDriver && (
                  <span className="text-[12.5px] truncate" style={{ color: 'var(--text-dim)' }}>
                    {ride.driverVehicle.plate}
                  </span>
                )}
              </div>
            </div>
          </div>

          {(asDriver ? ride.ratingByDriver : ride.ratingByPassenger) && (
            <div className="card p-3.5 my-3">
              <div className="label-xs mb-2">Your rating</div>
              <div className="flex gap-1 mb-2">
                {[1, 2, 3, 4, 5].map((n) => {
                  const value = (asDriver ? ride.ratingByDriver : ride.ratingByPassenger)!.stars
                  return (
                    <Star
                      key={n}
                      size={17}
                      fill={n <= value ? 'var(--brand)' : 'transparent'}
                      color={n <= value ? 'var(--brand)' : 'var(--surface-3)'}
                    />
                  )
                })}
              </div>
              {(asDriver ? ride.ratingByDriver : ride.ratingByPassenger)!.tags.length > 0 && (
                <div className="flex flex-wrap gap-1.5">
                  {(asDriver ? ride.ratingByDriver : ride.ratingByPassenger)!.tags.map((t) => (
                    <span key={t} className="chip" style={{ cursor: 'default' }}>
                      {t}
                    </span>
                  ))}
                </div>
              )}
            </div>
          )}

          <button
            className="btn btn-secondary btn-block mt-2"
            onClick={() => navigator.clipboard?.writeText(reference)}
          >
            <Copy size={16} /> Copy trip reference
          </button>
        </div>
      </div>
    </div>
  )
}

function LineItem({
  label,
  value,
  muted,
  bold,
  icon,
}: {
  label: string
  value: string
  muted?: boolean
  bold?: boolean
  icon?: React.ReactNode
}) {
  return (
    <div className="flex items-center justify-between py-1">
      <span
        className="text-[13.5px] flex items-center gap-1.5"
        style={{ color: muted ? 'var(--text-dim)' : 'var(--text)', fontWeight: bold ? 700 : 400 }}
      >
        {icon}
        {label}
      </span>
      <span
        className="text-[13.5px] tabular"
        style={{ color: muted ? 'var(--text-dim)' : 'var(--text)', fontWeight: bold ? 800 : 600 }}
      >
        {value}
      </span>
    </div>
  )
}
