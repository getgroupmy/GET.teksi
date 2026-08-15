import { useEffect, useMemo, useState } from 'react'
import { X, TrendingUp, Check, Car } from 'lucide-react'
import type { Offer, Ride } from '@/types'
import { useRides, selectOffersForRide } from '@/store/rides'
import { useShallow } from 'zustand/react/shallow'
import { raiseSuggestions } from '@/services/pricing'
import { money, plural, distance as fmtDistance } from '@/lib/format'
import { Sheet, Modal, Avatar, Rating, Banner, RouteStops } from '@/components/ui'
import { CANCEL_REASONS_PASSENGER } from '@/data/fixtures'

export default function OffersSheet({ ride }: { ride: Ride }) {
  const offers = useRides(useShallow((s) => selectOffersForRide(s, ride.id)))
  const acceptOffer = useRides((s) => s.acceptOffer)
  const declineOffer = useRides((s) => s.declineOffer)
  const raisePrice = useRides((s) => s.raisePrice)
  const cancelRide = useRides((s) => s.cancelRide)

  const [showRaise, setShowRaise] = useState(false)
  const [showCancel, setShowCancel] = useState(false)
  const [elapsed, setElapsed] = useState(0)

  useEffect(() => {
    const id = window.setInterval(() => setElapsed(Math.floor((Date.now() - ride.createdAt) / 1000)), 500)
    return () => window.clearInterval(id)
  }, [ride.createdAt])

  const pending = useMemo(() => offers.filter((o) => o.status === 'pending'), [offers])
  const suggestions = useMemo(() => raiseSuggestions(ride.askingPrice), [ride.askingPrice])

  const mins = Math.floor(elapsed / 60)
  const secs = elapsed % 60

  return (
    <>
      <Sheet>
        <div className="flex items-start justify-between gap-3 mb-2">
          <div className="min-w-0">
            <div className="text-[18px] font-extrabold">
              {pending.length > 0
                ? `${plural(pending.length, 'offer')} received`
                : 'Looking for drivers…'}
            </div>
            <div className="text-[13px] tabular" style={{ color: 'var(--text-dim)' }}>
              Your price {money(ride.askingPrice, { decimals: false })} · searching{' '}
              {mins > 0 ? `${mins}m ` : ''}
              {secs}s
            </div>
          </div>
          <button
            className="btn btn-ghost p-2 shrink-0"
            style={{ color: 'var(--text-dim)' }}
            onClick={() => setShowCancel(true)}
            aria-label="Cancel search"
          >
            <X size={20} />
          </button>
        </div>

        <div className="radar mb-3" />

        {pending.length === 0 && (
          <>
            <div className="px-1 py-2">
              <RouteStops pickup={ride.pickup.name} dropoff={ride.dropoff.name} stop={ride.stop?.name} compact />
            </div>
            {elapsed > 20 && (
              <div className="my-3">
                <Banner tone="warn">
                  No offers yet. Raising your price is the fastest way to get picked up.
                </Banner>
              </div>
            )}
            <div className="flex flex-col gap-2 mt-2">
              {[0, 1, 2].map((i) => (
                <div key={i} className="flex items-center gap-3 py-2">
                  <div className="skeleton" style={{ width: 44, height: 44, borderRadius: 999 }} />
                  <div className="flex-1">
                    <div className="skeleton" style={{ height: 12, width: '55%' }} />
                    <div className="skeleton mt-2" style={{ height: 10, width: '35%' }} />
                  </div>
                  <div className="skeleton" style={{ height: 30, width: 64, borderRadius: 10 }} />
                </div>
              ))}
            </div>
          </>
        )}

        <div className="flex flex-col gap-2 max-h-[46dvh] scroll-y -mx-1 px-1">
          {pending.map((offer) => (
            <OfferCard
              key={offer.id}
              offer={offer}
              askingPrice={ride.askingPrice}
              onAccept={() => acceptOffer(offer.id)}
              onDecline={() => declineOffer(offer.id)}
            />
          ))}
        </div>

        <button className="btn btn-secondary btn-block mt-3" onClick={() => setShowRaise(true)}>
          <TrendingUp size={17} /> Raise your price
        </button>
      </Sheet>

      <Modal open={showRaise} onClose={() => setShowRaise(false)} title="Raise your price">
        <p className="text-[13.5px] mb-4" style={{ color: 'var(--text-dim)' }}>
          More drivers see your order when the fare goes up. You’re currently offering{' '}
          <span className="font-bold" style={{ color: 'var(--text)' }}>
            {money(ride.askingPrice, { decimals: false })}
          </span>
          .
        </p>
        <div className="flex flex-col gap-2">
          {suggestions.map((value, i) => (
            <button
              key={value}
              className="flex items-center justify-between px-4 py-3.5"
              style={{
                background: i === 1 ? 'color-mix(in srgb, var(--brand) 14%, transparent)' : 'var(--surface-2)',
                borderRadius: 14,
                border: i === 1 ? '1px solid color-mix(in srgb, var(--brand) 35%, transparent)' : '1px solid transparent',
              }}
              onClick={() => {
                raisePrice(ride.id, value)
                setShowRaise(false)
              }}
            >
              <span className="text-[17px] font-bold tabular">{money(value, { decimals: false })}</span>
              <span className="text-[13px] font-semibold" style={{ color: 'var(--text-dim)' }}>
                +{money(value - ride.askingPrice, { decimals: false })}
                {i === 1 ? ' · recommended' : ''}
              </span>
            </button>
          ))}
        </div>
      </Modal>

      <Modal open={showCancel} onClose={() => setShowCancel(false)} title="Cancel your order?">
        <p className="text-[13.5px] mb-3" style={{ color: 'var(--text-dim)' }}>
          Tell us why so we can improve matching.
        </p>
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
          Keep searching
        </button>
      </Modal>
    </>
  )
}

function OfferCard({
  offer,
  askingPrice,
  onAccept,
  onDecline,
}: {
  offer: Offer
  askingPrice: number
  onAccept: () => void
  onDecline: () => void
}) {
  const diff = offer.price - askingPrice
  const [remaining, setRemaining] = useState(Math.max(0, offer.expiresAt - Date.now()))

  useEffect(() => {
    const id = window.setInterval(() => setRemaining(Math.max(0, offer.expiresAt - Date.now())), 500)
    return () => window.clearInterval(id)
  }, [offer.expiresAt])

  const secondsLeft = Math.ceil(remaining / 1000)

  return (
    <div
      className="slide-in px-3 py-3"
      style={{
        background: 'var(--surface-2)',
        borderRadius: 16,
        border: offer.matchedAskingPrice
          ? '1px solid color-mix(in srgb, var(--brand) 45%, transparent)'
          : '1px solid var(--line)',
      }}
    >
      <div className="flex items-center gap-3">
        <Avatar name={offer.driverName} color={offer.driverAvatarColor} size={42} />
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <span className="text-[15px] font-bold truncate">{offer.driverName}</span>
            <Rating value={offer.driverRating} />
          </div>
          <div className="text-[12.5px] truncate flex items-center gap-1.5" style={{ color: 'var(--text-dim)' }}>
            <Car size={13} />
            {offer.vehicle.color} {offer.vehicle.make} {offer.vehicle.model} · {offer.vehicle.plate}
          </div>
        </div>
        <div className="text-right shrink-0">
          <div className="text-[19px] font-extrabold tabular leading-none">
            {money(offer.price, { decimals: false })}
          </div>
          <div
            className="text-[11px] font-semibold mt-1"
            style={{ color: diff === 0 ? 'var(--brand)' : diff > 0 ? 'var(--warn)' : 'var(--ok)' }}
          >
            {diff === 0 ? 'Your price' : diff > 0 ? `+${money(diff, { decimals: false })}` : `−${money(-diff, { decimals: false })}`}
          </div>
        </div>
      </div>

      <div className="flex items-center gap-2 mt-3">
        <div className="flex-1 text-[12.5px] tabular" style={{ color: 'var(--text-dim)' }}>
          {offer.etaMinutes} min away · {fmtDistance(offer.distanceKm)} ·{' '}
          {offer.driverRidesGiven.toLocaleString('en-MY')} trips
        </div>
        <button className="btn btn-secondary btn-sm" onClick={onDecline} aria-label="Decline offer">
          <X size={15} />
        </button>
        <button className="btn btn-primary btn-sm" onClick={onAccept}>
          <Check size={15} /> Accept
          <span className="tabular" style={{ opacity: 0.6 }}>
            {secondsLeft}s
          </span>
        </button>
      </div>
    </div>
  )
}
