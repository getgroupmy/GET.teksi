import { useMemo, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Minus, Plus, Users, StickyNote, Check, Clock3, Sparkles } from 'lucide-react'
import type { Offer } from '@/types'
import { useSession } from '@/store/session'
import { useRides, selectMyOfferFor, OFFER_TTL_MS } from '@/store/rides'
import { driverNet, commissionOn } from '@/services/pricing'
import { money, roundFare, distance as fmtDistance, duration, timeAgo, plural } from '@/lib/format'
import { driveMinutes, haversineKm } from '@/lib/geo'
import { TopBar, Avatar, Rating, Banner, RouteStops, EmptyState } from '@/components/ui'
import { uid } from '@/lib/storage'

export default function DriverOrderDetail() {
  const { rideId = '' } = useParams()
  const navigate = useNavigate()
  const user = useSession((s) => s.user)!
  const myLocation = useSession((s) => s.myLocation)
  const ride = useRides((s) => s.rides[rideId])
  const myOffer = useRides((s) => selectMyOfferFor(s, rideId, user.id))
  const createOffer = useRides((s) => s.createOffer)
  const withdrawOffer = useRides((s) => s.withdrawOffer)

  const [counter, setCounter] = useState<number | null>(null)

  const pickupKm = ride ? haversineKm(myLocation, ride.pickup.coord) * 1.35 : 0
  const pickupEta = driveMinutes(pickupKm)

  const bidPrice = counter ?? ride?.askingPrice ?? 0
  const isCounter = counter != null && counter !== ride?.askingPrice

  const bounds = useMemo(() => {
    if (!ride) return { min: 0, max: 0 }
    return { min: ride.askingPrice, max: roundFare(ride.askingPrice * 2) }
  }, [ride])

  if (!ride) {
    return (
      <div className="h-full flex flex-col">
        <TopBar title="Order" onBack={() => navigate('/d')} />
        <EmptyState title="This order is no longer available" body="It was taken or cancelled." />
      </div>
    )
  }

  const gone = ride.status !== 'searching'

  const send = () => {
    if (!user.driverProfile) return
    const offer: Offer = {
      id: uid('ofr'),
      rideId: ride.id,
      driverId: user.id,
      driverName: user.name,
      driverAvatarColor: user.avatarColor,
      driverRating: user.driverProfile.rating,
      driverRidesGiven: user.driverProfile.ridesGiven,
      vehicle: user.driverProfile.vehicle,
      price: bidPrice,
      etaMinutes: pickupEta,
      distanceKm: Number(pickupKm.toFixed(2)),
      createdAt: Date.now(),
      expiresAt: Date.now() + OFFER_TTL_MS,
      status: 'pending',
      matchedAskingPrice: !isCounter,
    }
    createOffer(offer)
    navigate('/d')
  }

  const bump = (delta: number) =>
    setCounter(Math.max(bounds.min, Math.min(bounds.max, roundFare(bidPrice + delta))))

  return (
    <div className="h-full flex flex-col">
      <TopBar title="Ride request" onBack={() => navigate('/d')} />

      <div className="flex-1 scroll-y px-4 pb-4">
        <div className="flex items-center gap-3 py-3">
          <Avatar name={ride.passengerName} color={ride.passengerAvatarColor} size={46} />
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2">
              <span className="text-[16px] font-bold truncate">{ride.passengerName}</span>
              <Rating value={ride.passengerRating} />
            </div>
            <div className="text-[12.5px] flex items-center gap-1.5" style={{ color: 'var(--text-dim)' }}>
              <Clock3 size={12} /> Posted {timeAgo(ride.createdAt)}
              {ride.priceRaises > 0 && ` · raised ${plural(ride.priceRaises, 'time')}`}
            </div>
          </div>
        </div>

        <div className="card p-3.5 mb-3">
          <RouteStops pickup={ride.pickup.address || ride.pickup.name} dropoff={ride.dropoff.name} stop={ride.stop?.name} />
          <div className="divider my-3" />
          <div className="grid grid-cols-2 gap-y-2 text-[13px]">
            <Meta label="To pickup" value={`${fmtDistance(pickupKm)} · ${duration(pickupEta)}`} />
            <Meta label="Trip length" value={`${fmtDistance(ride.distanceKm)} · ${duration(ride.durationMinutes)}`} />
            <Meta label="Car type" value={ride.vehicleClass === 'xl' ? 'XL' : ride.vehicleClass === 'comfort' ? 'Comfort' : 'Economy'} />
            <Meta
              label="Payment"
              value={ride.paymentMethod === 'cash' ? 'Cash' : ride.paymentMethod === 'card' ? 'Card' : 'Wallet'}
            />
          </div>
        </div>

        {(ride.comment || ride.options.length > 0 || ride.passengerCount > 1) && (
          <div className="card p-3.5 mb-3 flex flex-col gap-2.5">
            {ride.passengerCount > 1 && (
              <div className="flex items-center gap-2 text-[13.5px]">
                <Users size={15} style={{ color: 'var(--text-dim)' }} />
                {plural(ride.passengerCount, 'passenger')}
              </div>
            )}
            {ride.options.length > 0 && (
              <div className="flex items-start gap-2 text-[13.5px]">
                <Sparkles size={15} style={{ color: 'var(--text-dim)', marginTop: 2 }} />
                <span>{ride.options.map((o) => o.replace(/_/g, ' ')).join(', ')}</span>
              </div>
            )}
            {ride.comment && (
              <div className="flex items-start gap-2 text-[13.5px]">
                <StickyNote size={15} style={{ color: 'var(--text-dim)', marginTop: 2 }} />
                <span>{ride.comment}</span>
              </div>
            )}
          </div>
        )}

        {gone ? (
          <Banner tone="warn">This order is no longer accepting offers.</Banner>
        ) : myOffer ? (
          <>
            <div className="card p-4 text-center mb-3">
              <div className="label-xs mb-2">Your offer</div>
              <div className="text-[32px] font-extrabold tabular leading-none">
                {money(myOffer.price, { decimals: false })}
              </div>
              <div className="text-[13px] mt-2" style={{ color: 'var(--text-dim)' }}>
                Waiting for {ride.passengerName} to reply
              </div>
              <div className="radar mt-3" />
            </div>
            <button
              className="btn btn-danger btn-block"
              onClick={() => {
                withdrawOffer(myOffer.id)
                navigate('/d')
              }}
            >
              Withdraw offer
            </button>
          </>
        ) : (
          <>
            <div className="card p-4 mb-3">
              <div className="flex items-center justify-between mb-2">
                <span className="label-xs">Passenger offers</span>
                <span className="text-[12px]" style={{ color: 'var(--text-dim)' }}>
                  Market {money(ride.recommendedPrice, { decimals: false })}
                </span>
              </div>

              <div className="flex items-center justify-between gap-3">
                <button
                  aria-label="Lower offer"
                  onClick={() => bump(-50)}
                  disabled={bidPrice <= bounds.min}
                  className="flex items-center justify-center shrink-0"
                  style={{
                    width: 44, height: 44, borderRadius: 999,
                    background: 'var(--surface-2)',
                    opacity: bidPrice <= bounds.min ? 0.4 : 1,
                    color: 'var(--text)',
                  }}
                >
                  <Minus size={20} />
                </button>
                <div className="text-center flex-1">
                  <div className="text-[34px] font-extrabold tabular leading-none">
                    {money(bidPrice, { decimals: false })}
                  </div>
                  <div className="text-[12px] mt-1.5" style={{ color: 'var(--text-dim)' }}>
                    You keep {money(driverNet(bidPrice))} after {money(commissionOn(bidPrice))} fee
                  </div>
                </div>
                <button
                  aria-label="Raise offer"
                  onClick={() => bump(50)}
                  disabled={bidPrice >= bounds.max}
                  className="flex items-center justify-center shrink-0"
                  style={{
                    width: 44, height: 44, borderRadius: 999,
                    background: 'var(--surface-2)',
                    opacity: bidPrice >= bounds.max ? 0.4 : 1,
                    color: 'var(--text)',
                  }}
                >
                  <Plus size={20} />
                </button>
              </div>

              {isCounter && (
                <button
                  className="btn btn-ghost btn-sm mt-2 mx-auto block"
                  style={{ color: 'var(--brand)' }}
                  onClick={() => setCounter(null)}
                >
                  Reset to {money(ride.askingPrice, { decimals: false })}
                </button>
              )}
            </div>

            {isCounter && (
              <div className="mb-3">
                <Banner tone="warn">
                  Counter-offers take longer to be accepted than taking the passenger’s price.
                </Banner>
              </div>
            )}

            <button className="btn btn-primary btn-block" onClick={send}>
              <Check size={17} />
              {isCounter
                ? `Offer ${money(bidPrice, { decimals: false })}`
                : `Accept ${money(ride.askingPrice, { decimals: false })}`}
            </button>
            <button
              className="btn btn-ghost btn-block btn-sm mt-1"
              style={{ color: 'var(--text-dim)' }}
              onClick={() => navigate('/d')}
            >
              Skip this order
            </button>
          </>
        )}
      </div>
    </div>
  )
}

function Meta({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <div className="text-[11.5px]" style={{ color: 'var(--text-mute)' }}>
        {label}
      </div>
      <div className="font-semibold tabular">{value}</div>
    </div>
  )
}
