import { useMemo, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Star } from 'lucide-react'
import { useSession } from '@/store/session'
import { useRides } from '@/store/rides'
import { useDraft } from '@/store/draft'
import { money, distance as fmtDistance, duration } from '@/lib/format'
import { TopBar, Avatar, EmptyState, RouteStops } from '@/components/ui'
import {
  RATING_TAGS_GOOD,
  RATING_TAGS_BAD,
  DRIVER_RATING_TAGS_GOOD,
  DRIVER_RATING_TAGS_BAD,
} from '@/data/fixtures'

const TIPS = [0, 200, 500, 1000]

export default function RateScreen() {
  const { rideId = '' } = useParams()
  const navigate = useNavigate()
  const user = useSession((s) => s.user)!
  const ride = useRides((s) => s.rides[rideId])
  const rateRide = useRides((s) => s.rateRide)
  const clearDraft = useDraft((s) => s.clear)

  const viewer = ride?.driverId === user.id ? 'driver' : 'passenger'
  const [stars, setStars] = useState(0)
  const [tags, setTags] = useState<string[]>([])
  const [comment, setComment] = useState('')
  const [tip, setTip] = useState(0)

  const tagPool = useMemo(() => {
    if (stars === 0) return []
    const good = stars >= 4
    if (viewer === 'driver') return good ? DRIVER_RATING_TAGS_GOOD : DRIVER_RATING_TAGS_BAD
    return good ? RATING_TAGS_GOOD : RATING_TAGS_BAD
  }, [stars, viewer])

  if (!ride) {
    return (
      <div className="h-full flex flex-col">
        <TopBar title="Rate" onBack={() => navigate('/')} />
        <EmptyState title="Ride not found" />
      </div>
    )
  }

  const other =
    viewer === 'driver'
      ? { name: ride.passengerName, color: ride.passengerAvatarColor }
      : { name: ride.driverName ?? 'Driver', color: ride.driverAvatarColor ?? '#888' }

  const fare = ride.finalPrice ?? ride.askingPrice
  const home = viewer === 'driver' ? '/d' : '/p'

  const submit = () => {
    rateRide(
      rideId,
      viewer,
      { stars: stars || 5, tags, comment: comment.trim() || undefined, createdAt: Date.now() },
      viewer === 'passenger' && tip > 0 ? tip : undefined,
    )
    if (viewer === 'passenger') clearDraft()
    navigate(home, { replace: true })
  }

  const skip = () => {
    // Skipping still records a neutral rating so the ride leaves the queue.
    rateRide(rideId, viewer, { stars: 5, tags: [], createdAt: Date.now() })
    if (viewer === 'passenger') clearDraft()
    navigate(home, { replace: true })
  }

  return (
    <div className="h-full flex flex-col">
      <TopBar
        title="Trip completed"
        right={
          <button className="btn btn-ghost btn-sm" style={{ color: 'var(--text-dim)' }} onClick={skip}>
            Skip
          </button>
        }
      />

      <div className="flex-1 scroll-y px-5 pb-4">
        <div className="card p-4 my-3">
          <RouteStops pickup={ride.pickup.name} dropoff={ride.dropoff.name} stop={ride.stop?.name} compact />
          <div className="divider my-3" />
          <div className="flex items-center justify-between">
            <span className="text-[13px] tabular" style={{ color: 'var(--text-dim)' }}>
              {fmtDistance(ride.distanceKm)} · {duration(ride.durationMinutes)}
            </span>
            <span className="text-[20px] font-extrabold tabular">{money(fare, { decimals: false })}</span>
          </div>
        </div>

        <div className="flex flex-col items-center gap-3 mt-5">
          <Avatar name={other.name} color={other.color} size={76} />
          <div className="text-center">
            <div className="text-[19px] font-extrabold">{other.name}</div>
            <div className="text-[13.5px]" style={{ color: 'var(--text-dim)' }}>
              How was your trip{viewer === 'driver' ? ' with them' : ''}?
            </div>
          </div>

          <div className="flex gap-1.5 mt-1">
            {[1, 2, 3, 4, 5].map((n) => (
              <button
                key={n}
                onClick={() => {
                  setStars(n)
                  setTags([])
                }}
                aria-label={`${n} star${n === 1 ? '' : 's'}`}
                style={{ padding: 4 }}
              >
                <Star
                  size={36}
                  fill={n <= stars ? 'var(--brand)' : 'transparent'}
                  color={n <= stars ? 'var(--brand)' : 'var(--surface-3)'}
                />
              </button>
            ))}
          </div>
        </div>

        {tagPool.length > 0 && (
          <div className="flex flex-wrap gap-2 justify-center mt-5 fade-in">
            {tagPool.map((tag) => (
              <button
                key={tag}
                className="chip"
                data-active={tags.includes(tag)}
                onClick={() =>
                  setTags((prev) => (prev.includes(tag) ? prev.filter((t) => t !== tag) : [...prev, tag]))
                }
              >
                {tag}
              </button>
            ))}
          </div>
        )}

        {stars > 0 && (
          <textarea
            className="input mt-4 fade-in"
            rows={2}
            maxLength={200}
            placeholder="Add a comment (optional)"
            value={comment}
            onChange={(e) => setComment(e.target.value)}
          />
        )}

        {viewer === 'passenger' && stars >= 4 && (
          <div className="mt-5 fade-in">
            <div className="label-xs mb-2">Add a tip for {other.name.split(' ')[0]}</div>
            <div className="flex gap-2">
              {TIPS.map((value) => (
                <button
                  key={value}
                  className="flex-1 py-3 text-[15px] font-bold tabular"
                  style={{
                    background: tip === value ? 'color-mix(in srgb, var(--brand) 16%, transparent)' : 'var(--surface-2)',
                    color: tip === value ? 'var(--brand)' : 'var(--text)',
                    borderRadius: 13,
                    border: `1px solid ${tip === value ? 'color-mix(in srgb, var(--brand) 40%, transparent)' : 'transparent'}`,
                  }}
                  onClick={() => setTip(value)}
                >
                  {value === 0 ? 'None' : money(value, { decimals: false })}
                </button>
              ))}
            </div>
          </div>
        )}
      </div>

      <div className="px-5" style={{ paddingBottom: 'calc(var(--safe-bottom) + 18px)' }}>
        <button className="btn btn-primary btn-block" disabled={stars === 0} onClick={submit}>
          {tip > 0 ? `Submit and tip ${money(tip, { decimals: false })}` : 'Submit rating'}
        </button>
      </div>
    </div>
  )
}
