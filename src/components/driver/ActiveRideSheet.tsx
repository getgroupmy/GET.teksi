import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { MessageSquare, Phone, Navigation, ShieldAlert, Users, StickyNote } from 'lucide-react'
import type { Ride } from '@/types'
import { useRides, selectUnreadChat } from '@/store/rides'
import { money, duration, distance as fmtDistance, plural } from '@/lib/format'
import { driveMinutes, haversineKm } from '@/lib/geo'
import { driverNet, commissionOn } from '@/services/pricing'
import { Sheet, Modal, Avatar, Rating, Banner, RouteStops } from '@/components/ui'
import { CANCEL_REASONS_DRIVER } from '@/data/fixtures'

/**
 * The driver's job card. One primary button always drives the trip forward:
 * on my way → arrived → start → finish.
 */
export default function ActiveRideSheet({ ride, driverAt }: { ride: Ride; driverAt: { lat: number; lng: number } }) {
  const navigate = useNavigate()
  const setRideStatus = useRides((s) => s.setRideStatus)
  const completeRide = useRides((s) => s.completeRide)
  const cancelRide = useRides((s) => s.cancelRide)
  const unread = useRides((s) => selectUnreadChat(s, ride.id, 'driver'))
  const [showCancel, setShowCancel] = useState(false)

  const fare = ride.finalPrice ?? ride.askingPrice
  const heading = ride.status === 'in_progress' ? ride.dropoff : ride.pickup
  const km = haversineKm(driverAt, heading.coord) * 1.35
  const eta = driveMinutes(km)

  const primary = (() => {
    switch (ride.status) {
      case 'accepted':
      case 'arriving':
        return { label: "I've arrived", action: () => setRideStatus(ride.id, 'waiting') }
      case 'waiting':
        return { label: 'Start the trip', action: () => setRideStatus(ride.id, 'in_progress') }
      case 'in_progress':
        return { label: `Finish trip · ${money(fare, { decimals: false })}`, action: () => completeRide(ride.id) }
      default:
        return null
    }
  })()

  const statusTitle =
    ride.status === 'in_progress'
      ? `To ${ride.dropoff.name}`
      : ride.status === 'waiting'
        ? 'Waiting for the passenger'
        : `Pick up ${ride.passengerName}`

  return (
    <>
      <Sheet>
        <div className="flex items-baseline justify-between mb-3">
          <h2 className="text-[17px] font-extrabold truncate">{statusTitle}</h2>
          <span className="text-[14px] font-bold tabular shrink-0" style={{ color: 'var(--brand)' }}>
            {duration(eta)} · {fmtDistance(km)}
          </span>
        </div>

        <div
          className="flex items-center gap-3 px-3 py-3 mb-2"
          style={{ background: 'var(--surface-2)', borderRadius: 16 }}
        >
          <Avatar name={ride.passengerName} color={ride.passengerAvatarColor} size={44} />
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2">
              <span className="text-[15px] font-bold truncate">{ride.passengerName}</span>
              <Rating value={ride.passengerRating} />
            </div>
            <div className="text-[12.5px] flex items-center gap-1.5" style={{ color: 'var(--text-dim)' }}>
              <Users size={13} /> {plural(ride.passengerCount, 'passenger')} ·{' '}
              {ride.paymentMethod === 'cash' ? 'Cash' : ride.paymentMethod === 'card' ? 'Card' : 'Wallet'}
            </div>
          </div>
          <div className="text-right shrink-0">
            <div className="text-[19px] font-extrabold tabular leading-none">
              {money(fare, { decimals: false })}
            </div>
            <div className="text-[11px] mt-1" style={{ color: 'var(--text-dim)' }}>
              you get {money(driverNet(fare), { decimals: false })}
            </div>
          </div>
        </div>

        {ride.comment && (
          <div
            className="flex gap-2 px-3 py-2.5 mb-2 text-[13px]"
            style={{ background: 'var(--surface-2)', borderRadius: 12, color: 'var(--text-dim)' }}
          >
            <StickyNote size={15} className="shrink-0 mt-0.5" />
            <span>{ride.comment}</span>
          </div>
        )}

        <div className="flex gap-2 mb-3">
          <SmallAction
            icon={<MessageSquare size={17} />}
            label="Chat"
            badge={unread}
            onClick={() => navigate(`/chat/${ride.id}`)}
          />
          <SmallAction icon={<Phone size={17} />} label="Call" href={`tel:+60${ride.id.slice(-9)}`} />
          <SmallAction
            icon={<Navigation size={17} />}
            label="Navigate"
            href={`https://www.google.com/maps/dir/?api=1&destination=${heading.coord.lat},${heading.coord.lng}&travelmode=driving`}
            external
          />
          <SmallAction
            icon={<ShieldAlert size={17} />}
            label="Safety"
            danger
            onClick={() => navigate('/safety', { state: { rideId: ride.id } })}
          />
        </div>

        <div className="px-3 py-3 mb-3" style={{ background: 'var(--surface-2)', borderRadius: 16 }}>
          <RouteStops pickup={ride.pickup.name} dropoff={ride.dropoff.name} stop={ride.stop?.name} compact />
          <div className="divider my-3" />
          <div className="flex items-center justify-between text-[12.5px]" style={{ color: 'var(--text-dim)' }}>
            <span className="tabular">
              Trip {fmtDistance(ride.distanceKm)} · {duration(ride.durationMinutes)}
            </span>
            <span className="tabular">Service fee {money(commissionOn(fare))}</span>
          </div>
        </div>

        {ride.status === 'waiting' && (
          <div className="mb-3">
            <Banner tone="info">
              Free waiting time is 3 minutes. Message the passenger if they’re not out yet.
            </Banner>
          </div>
        )}

        {primary && (
          <button className="btn btn-primary btn-block" onClick={primary.action}>
            {primary.label}
          </button>
        )}
        {ride.status !== 'in_progress' && (
          <button
            className="btn btn-ghost btn-block btn-sm mt-1"
            style={{ color: 'var(--danger)' }}
            onClick={() => setShowCancel(true)}
          >
            Cancel this order
          </button>
        )}
      </Sheet>

      <Modal open={showCancel} onClose={() => setShowCancel(false)} title="Cancel the order?">
        <div className="mb-3">
          <Banner tone="warn">Cancelling accepted orders too often lowers your priority in the feed.</Banner>
        </div>
        {CANCEL_REASONS_DRIVER.map((reason) => (
          <button
            key={reason}
            className="w-full text-left py-3.5 text-[15px] font-medium"
            style={{ borderBottom: '1px solid var(--line)' }}
            onClick={() => {
              cancelRide(ride.id, 'driver', reason)
              setShowCancel(false)
            }}
          >
            {reason}
          </button>
        ))}
        <button className="btn btn-secondary btn-block mt-4" onClick={() => setShowCancel(false)}>
          Keep the order
        </button>
      </Modal>
    </>
  )
}

function SmallAction({
  icon,
  label,
  onClick,
  href,
  badge,
  danger,
  external,
}: {
  icon: React.ReactNode
  label: string
  onClick?: () => void
  href?: string
  badge?: number
  danger?: boolean
  external?: boolean
}) {
  const inner = (
    <>
      <span className="relative" style={{ color: danger ? 'var(--danger)' : 'var(--brand)' }}>
        {icon}
        {badge != null && badge > 0 && (
          <span
            aria-hidden
            className="absolute -top-1.5 -right-2 flex items-center justify-center"
            style={{
              minWidth: 16, height: 16, padding: '0 4px', borderRadius: 999,
              background: 'var(--danger)', color: '#fff', fontSize: 9.5, fontWeight: 700,
            }}
          >
            {badge}
          </span>
        )}
      </span>
      <span className="text-[11.5px] font-semibold">{label}</span>
    </>
  )
  const className = 'flex-1 flex flex-col items-center gap-1.5 py-2.5'
  const style = { background: 'var(--surface-2)', borderRadius: 14, color: 'var(--text)' } as const
  const accessibleName = badge ? `${label}, ${badge} unread` : label

  if (href) {
    return (
      <a
        href={href}
        className={className}
        style={style}
        aria-label={accessibleName}
        target={external ? '_blank' : undefined}
        rel={external ? 'noreferrer' : undefined}
      >
        {inner}
      </a>
    )
  }
  return (
    <button className={className} style={style} onClick={onClick} aria-label={accessibleName}>
      {inner}
    </button>
  )
}
