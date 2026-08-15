import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { MessageSquare, Phone, ShieldAlert, Share2, Car } from 'lucide-react'
import type { Ride } from '@/types'
import { useRides, selectUnreadChat } from '@/store/rides'
import { money, duration } from '@/lib/format'
import { haversineKm, driveMinutes } from '@/lib/geo'
import { Sheet, Modal, Avatar, Rating, Banner, RouteStops } from '@/components/ui'
import { CANCEL_REASONS_PASSENGER } from '@/data/fixtures'

const STATUS_COPY: Record<string, { title: string; sub: string }> = {
  accepted: { title: 'Driver is on the way', sub: 'Meet your driver at the pickup point' },
  arriving: { title: 'Driver is arriving', sub: 'Please start heading to the pickup point' },
  waiting: { title: 'Your driver is waiting', sub: 'They can wait a few minutes free of charge' },
  in_progress: { title: 'On the way to your destination', sub: 'Enjoy the ride' },
}

export default function TrackingSheet({ ride }: { ride: Ride }) {
  const navigate = useNavigate()
  const cancelRide = useRides((s) => s.cancelRide)
  const unread = useRides((s) => selectUnreadChat(s, ride.id, 'passenger'))
  const [showCancel, setShowCancel] = useState(false)
  const [showShare, setShowShare] = useState(false)

  const copy = STATUS_COPY[ride.status] ?? STATUS_COPY.accepted
  const target = ride.status === 'in_progress' ? ride.dropoff.coord : ride.pickup.coord
  const etaMinutes = ride.driverCoord
    ? driveMinutes(haversineKm(ride.driverCoord, target) * 1.35)
    : ride.durationMinutes

  const fare = ride.finalPrice ?? ride.askingPrice

  const shareText = `I'm on a GET.teksi ride to ${ride.dropoff.name}. Driver: ${ride.driverName} (${ride.driverVehicle?.color} ${ride.driverVehicle?.make} ${ride.driverVehicle?.model}, ${ride.driverVehicle?.plate}). Ref ${ride.id.slice(-6).toUpperCase()}.`

  const share = async () => {
    if (typeof navigator !== 'undefined' && navigator.share) {
      try {
        await navigator.share({ title: 'My GET.teksi trip', text: shareText })
        return
      } catch {
        // Fall through to the copyable dialog.
      }
    }
    setShowShare(true)
  }

  return (
    <>
      <Sheet>
        <div className="flex items-baseline justify-between mb-1">
          <h2 className="text-[18px] font-extrabold">{copy.title}</h2>
          {ride.status !== 'waiting' && (
            <span className="text-[15px] font-bold tabular" style={{ color: 'var(--brand)' }}>
              {duration(etaMinutes)}
            </span>
          )}
        </div>
        <p className="text-[13px] mb-3" style={{ color: 'var(--text-dim)' }}>
          {copy.sub}
        </p>

        <div
          className="flex items-center gap-3 px-3 py-3 mb-2"
          style={{ background: 'var(--surface-2)', borderRadius: 16 }}
        >
          <Avatar name={ride.driverName ?? ''} color={ride.driverAvatarColor ?? '#ccc'} size={46} ring />
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2">
              <span className="text-[15px] font-bold truncate">{ride.driverName}</span>
              <Rating value={ride.driverRating ?? 5} />
            </div>
            {ride.driverVehicle && (
              <div className="text-[12.5px] flex items-center gap-1.5 truncate" style={{ color: 'var(--text-dim)' }}>
                <Car size={13} />
                {ride.driverVehicle.color} {ride.driverVehicle.make} {ride.driverVehicle.model}
              </div>
            )}
          </div>
          <div
            className="px-2.5 py-1.5 text-[13px] font-extrabold tabular shrink-0"
            style={{ background: 'var(--surface-3)', borderRadius: 9, letterSpacing: '0.04em' }}
          >
            {ride.driverVehicle?.plate}
          </div>
        </div>

        <div className="flex gap-2 mb-3">
          <ActionButton
            icon={<MessageSquare size={17} />}
            label="Chat"
            badge={unread}
            onClick={() => navigate(`/chat/${ride.id}`)}
          />
          <ActionButton icon={<Phone size={17} />} label="Call" onClick={() => setShowShare(false)} href={`tel:+60${ride.id.slice(-9)}`} />
          <ActionButton icon={<Share2 size={17} />} label="Share" onClick={share} />
          <ActionButton
            icon={<ShieldAlert size={17} />}
            label="Safety"
            danger
            onClick={() => navigate('/safety', { state: { rideId: ride.id } })}
          />
        </div>

        <div className="px-3 py-3 mb-3" style={{ background: 'var(--surface-2)', borderRadius: 16 }}>
          <RouteStops pickup={ride.pickup.name} dropoff={ride.dropoff.name} stop={ride.stop?.name} compact />
          <div className="divider my-3" />
          <div className="flex items-center justify-between">
            <span className="text-[13px]" style={{ color: 'var(--text-dim)' }}>
              {ride.paymentMethod === 'cash' ? 'Pay in cash' : ride.paymentMethod === 'card' ? 'Card ···4821' : 'Wallet'}
            </span>
            <span className="text-[19px] font-extrabold tabular">{money(fare, { decimals: false })}</span>
          </div>
        </div>

        {ride.status === 'waiting' && (
          <div className="mb-3">
            <Banner tone="warn">Your driver has arrived. Free waiting time applies for 3 minutes.</Banner>
          </div>
        )}

        {ride.status !== 'in_progress' && (
          <button
            className="btn btn-danger btn-block btn-sm"
            onClick={() => setShowCancel(true)}
          >
            Cancel ride
          </button>
        )}
      </Sheet>

      <Modal open={showCancel} onClose={() => setShowCancel(false)} title="Cancel this ride?">
        <div className="mb-3">
          <Banner tone="warn">
            Your driver is already on the way. Frequent late cancellations can affect your rating.
          </Banner>
        </div>
        {CANCEL_REASONS_PASSENGER.map((reason) => (
          <button
            key={reason}
            className="w-full text-left py-3.5 text-[15px] font-medium"
            style={{ borderBottom: '1px solid var(--line)' }}
            onClick={() => {
              cancelRide(ride.id, 'passenger', reason)
              setShowCancel(false)
            }}
          >
            {reason}
          </button>
        ))}
        <button className="btn btn-secondary btn-block mt-4" onClick={() => setShowCancel(false)}>
          Keep my ride
        </button>
      </Modal>

      <Modal open={showShare} onClose={() => setShowShare(false)} title="Share your trip">
        <p className="text-[13.5px] mb-3" style={{ color: 'var(--text-dim)' }}>
          Send these details to someone you trust.
        </p>
        <div
          className="text-[13.5px] leading-relaxed p-3 mb-3"
          style={{ background: 'var(--surface-2)', borderRadius: 12 }}
        >
          {shareText}
        </div>
        <button
          className="btn btn-primary btn-block"
          onClick={() => {
            navigator.clipboard?.writeText(shareText)
            setShowShare(false)
          }}
        >
          Copy details
        </button>
      </Modal>
    </>
  )
}

function ActionButton({
  icon,
  label,
  onClick,
  badge,
  danger,
  href,
}: {
  icon: React.ReactNode
  label: string
  onClick: () => void
  badge?: number
  danger?: boolean
  href?: string
}) {
  const content = (
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
  const style = {
    background: 'var(--surface-2)',
    borderRadius: 14,
    color: 'var(--text)',
  } as const
  const className = 'flex-1 flex flex-col items-center gap-1.5 py-2.5'

  const accessibleName = badge ? `${label}, ${badge} unread` : label

  if (href) {
    return (
      <a href={href} className={className} style={style} onClick={onClick} aria-label={accessibleName}>
        {content}
      </a>
    )
  }
  return (
    <button className={className} style={style} onClick={onClick} aria-label={accessibleName}>
      {content}
    </button>
  )
}
