import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Power, Filter, Inbox, Clock3 } from 'lucide-react'
import type { LatLng, Ride } from '@/types'
import { useSession } from '@/store/session'
import { useRides, selectOpenOrders } from '@/store/rides'
import { useShallow } from 'zustand/react/shallow'
import { money, distance as fmtDistance, duration, timeAgo } from '@/lib/format'
import { driveMinutes, haversineKm } from '@/lib/geo'
import { driverNet } from '@/services/pricing'
import { Sheet, Modal, Avatar, Rating, EmptyState, RouteStops, Segmented } from '@/components/ui'

type SortMode = 'nearest' | 'highest' | 'newest'

export default function OrderFeedSheet({ driverAt }: { driverAt: LatLng }) {
  const navigate = useNavigate()
  const user = useSession((s) => s.user)!
  const prefs = useSession((s) => s.prefs)
  const setPrefs = useSession((s) => s.setPrefs)
  const orders = useRides(useShallow((s) => selectOpenOrders(s, user.id)))
  const offers = useRides((s) => s.offers)

  const myPendingRideIds = useMemo(
    () =>
      new Set(
        Object.values(offers)
          .filter((o) => o.driverId === user.id && o.status === 'pending')
          .map((o) => o.rideId),
      ),
    [offers, user.id],
  )

  const [sort, setSort] = useState<SortMode>('nearest')
  const [showFilter, setShowFilter] = useState(false)
  const [minFare, setMinFare] = useState(0)
  const [maxPickupKm, setMaxPickupKm] = useState(12)

  const decorated = useMemo(() => {
    return orders
      .map((ride) => {
        const pickupKm = haversineKm(driverAt, ride.pickup.coord) * 1.35
        return { ride, pickupKm, pickupEta: driveMinutes(pickupKm) }
      })
      .filter((o) => o.pickupKm <= maxPickupKm && o.ride.askingPrice >= minFare)
      .sort((a, b) => {
        if (sort === 'nearest') return a.pickupKm - b.pickupKm
        if (sort === 'highest') return b.ride.askingPrice - a.ride.askingPrice
        return b.ride.createdAt - a.ride.createdAt
      })
  }, [orders, driverAt, sort, minFare, maxPickupKm])

  if (!prefs.driverOnline) {
    return (
      <Sheet>
        <div className="flex flex-col items-center text-center py-4 gap-3">
          <div
            className="flex items-center justify-center"
            style={{
              width: 64, height: 64, borderRadius: 999,
              background: 'var(--surface-2)', color: 'var(--text-dim)',
            }}
          >
            <Power size={28} />
          </div>
          <div>
            <div className="text-[18px] font-extrabold">You’re offline</div>
            <div className="text-[13.5px] mt-1" style={{ color: 'var(--text-dim)' }}>
              Go online to see ride requests near you and send your price.
            </div>
          </div>
          <button
            className="btn btn-primary btn-block mt-1"
            onClick={() => setPrefs({ driverOnline: true })}
          >
            Go online
          </button>
          <button
            className="btn btn-ghost btn-block btn-sm"
            style={{ color: 'var(--text-dim)' }}
            onClick={() => navigate('/d/earnings')}
          >
            View today’s earnings
          </button>
        </div>
      </Sheet>
    )
  }

  return (
    <>
      <Sheet>
        <div className="flex items-center justify-between mb-3">
          <div>
            <div className="text-[17px] font-extrabold">
              {decorated.length > 0 ? `${decorated.length} order${decorated.length === 1 ? '' : 's'} nearby` : 'Waiting for orders'}
            </div>
            <div className="text-[12.5px]" style={{ color: 'var(--text-dim)' }}>
              You’re online · {user.driverProfile?.vehicle.plate}
            </div>
          </div>
          <button
            className="btn btn-secondary btn-sm"
            onClick={() => setShowFilter(true)}
            aria-label="Filters"
          >
            <Filter size={15} />
          </button>
        </div>

        <div className="mb-3">
          <Segmented
            value={sort}
            onChange={setSort}
            options={[
              { value: 'nearest', label: 'Nearest' },
              { value: 'highest', label: 'Highest' },
              { value: 'newest', label: 'Newest' },
            ]}
          />
        </div>

        <div className="max-h-[48dvh] scroll-y -mx-1 px-1 flex flex-col gap-2">
          {decorated.length === 0 ? (
            <>
              <div className="radar mb-2" />
              <EmptyState
                icon={<Inbox size={30} />}
                title="No orders match right now"
                body="Stay online — new requests appear here as passengers publish them."
              />
            </>
          ) : (
            decorated.map(({ ride, pickupKm, pickupEta }) => (
              <OrderCard
                key={ride.id}
                ride={ride}
                pickupKm={pickupKm}
                pickupEta={pickupEta}
                pending={myPendingRideIds.has(ride.id)}
                onOpen={() => navigate(`/d/order/${ride.id}`)}
              />
            ))
          )}
        </div>

        <button
          className="btn btn-outline btn-block mt-3"
          onClick={() => setPrefs({ driverOnline: false })}
        >
          <Power size={16} /> Go offline
        </button>
      </Sheet>

      <Modal open={showFilter} onClose={() => setShowFilter(false)} title="Filter orders">
        <label className="label-xs block mb-2">Minimum fare</label>
        <div className="flex gap-2 mb-5">
          {[0, 1000, 1500, 2500].map((v) => (
            <button key={v} className="chip" data-active={minFare === v} onClick={() => setMinFare(v)}>
              {v === 0 ? 'Any' : money(v, { decimals: false })}
            </button>
          ))}
        </div>
        <label className="label-xs block mb-2">Maximum distance to pickup</label>
        <div className="flex gap-2 mb-5">
          {[3, 6, 12, 30].map((v) => (
            <button key={v} className="chip" data-active={maxPickupKm === v} onClick={() => setMaxPickupKm(v)}>
              {v} km
            </button>
          ))}
        </div>
        <button className="btn btn-primary btn-block" onClick={() => setShowFilter(false)}>
          Show {decorated.length} order{decorated.length === 1 ? '' : 's'}
        </button>
      </Modal>
    </>
  )
}

function OrderCard({
  ride,
  pickupKm,
  pickupEta,
  pending,
  onOpen,
}: {
  ride: Ride
  pickupKm: number
  pickupEta: number
  pending: boolean
  onOpen: () => void
}) {
  const generous = ride.askingPrice >= ride.recommendedPrice
  return (
    <button
      onClick={onOpen}
      className="slide-in text-left px-3 py-3 w-full"
      style={{
        background: 'var(--surface-2)',
        borderRadius: 16,
        border: pending
          ? '1px solid color-mix(in srgb, var(--warn) 45%, transparent)'
          : generous
            ? '1px solid color-mix(in srgb, var(--brand) 35%, transparent)'
            : '1px solid var(--line)',
      }}
    >
      <div className="flex items-center gap-2.5 mb-2.5">
        <Avatar name={ride.passengerName} color={ride.passengerAvatarColor} size={34} />
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <span className="text-[14px] font-bold truncate">{ride.passengerName}</span>
            <Rating value={ride.passengerRating} size={12} />
          </div>
          <div className="text-[11.5px] flex items-center gap-1" style={{ color: 'var(--text-mute)' }}>
            <Clock3 size={11} /> {timeAgo(ride.createdAt)}
          </div>
        </div>
        <div className="text-right shrink-0">
          <div className="text-[19px] font-extrabold tabular leading-none">
            {money(ride.askingPrice, { decimals: false })}
          </div>
          <div className="text-[11px] mt-1" style={{ color: 'var(--text-dim)' }}>
            net {money(driverNet(ride.askingPrice), { decimals: false })}
          </div>
        </div>
      </div>

      <RouteStops pickup={ride.pickup.name} dropoff={ride.dropoff.name} stop={ride.stop?.name} compact />

      <div
        className="flex items-center justify-between mt-2.5 text-[12px] tabular"
        style={{ color: 'var(--text-dim)' }}
      >
        <span>
          {fmtDistance(pickupKm)} to pickup · {duration(pickupEta)}
        </span>
        <span>
          Trip {fmtDistance(ride.distanceKm)} · {duration(ride.durationMinutes)}
        </span>
      </div>

      {pending && (
        <div className="text-[12px] font-semibold mt-2" style={{ color: 'var(--warn)' }}>
          Your offer is waiting for a reply
        </div>
      )}
    </button>
  )
}
