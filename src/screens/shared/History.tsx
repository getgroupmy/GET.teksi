import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Clock, CircleAlert, Star } from 'lucide-react'
import { useSession } from '@/store/session'
import { useRides, selectHistory } from '@/store/rides'
import { useShallow } from 'zustand/react/shallow'
import { money, dateLabel, clockTime, distance as fmtDistance } from '@/lib/format'
import { driverNet } from '@/services/pricing'
import { TopBar, EmptyState, Segmented, RouteStops } from '@/components/ui'

export default function History() {
  const navigate = useNavigate()
  const user = useSession((s) => s.user)!
  const prefs = useSession((s) => s.prefs)
  const [role, setRole] = useState<'passenger' | 'driver'>(prefs.role)
  const rides = useRides(useShallow((s) => selectHistory(s, user.id, role)))

  const grouped = useMemo(() => {
    const map = new Map<string, typeof rides>()
    rides.forEach((ride) => {
      const key = dateLabel(ride.completedAt ?? ride.cancelledAt ?? ride.createdAt)
      map.set(key, [...(map.get(key) ?? []), ride])
    })
    return [...map.entries()]
  }, [rides])

  return (
    <div className="h-full flex flex-col">
      <TopBar title="My rides" onBack={() => navigate('/menu')} />

      {user.driverProfile && (
        <div className="px-4 py-3">
          <Segmented
            value={role}
            onChange={setRole}
            options={[
              { value: 'passenger', label: 'As passenger' },
              { value: 'driver', label: 'As driver' },
            ]}
          />
        </div>
      )}

      <div className="flex-1 scroll-y px-4 pb-6">
        {grouped.length === 0 ? (
          <EmptyState
            icon={<Clock size={30} />}
            title="No rides yet"
            body={
              role === 'driver'
                ? 'Completed trips you drive will appear here.'
                : 'Book your first ride and it will show up here.'
            }
          />
        ) : (
          grouped.map(([label, list]) => (
            <div key={label} className="mb-4">
              <div className="label-xs mb-2 mt-3">{label}</div>
              <div className="flex flex-col gap-2">
                {list.map((ride) => {
                  const cancelled = ride.status === 'cancelled'
                  const fare = ride.finalPrice ?? ride.askingPrice
                  const amount = role === 'driver' ? driverNet(fare) : fare
                  return (
                    <button
                      key={ride.id}
                      onClick={() => navigate(`/ride/${ride.id}`)}
                      className="card p-3.5 text-left"
                    >
                      <div className="flex items-start justify-between gap-3 mb-2">
                        <div className="text-[12.5px] tabular flex items-center gap-1.5" style={{ color: 'var(--text-dim)' }}>
                          {cancelled ? (
                            <>
                              <CircleAlert size={13} style={{ color: 'var(--danger)' }} />
                              <span style={{ color: 'var(--danger)' }}>Cancelled</span>
                            </>
                          ) : (
                            <>
                              <Clock size={13} />
                              {clockTime(ride.completedAt ?? ride.createdAt)} · {fmtDistance(ride.distanceKm)}
                            </>
                          )}
                        </div>
                        <div
                          className="text-[16px] font-extrabold tabular shrink-0"
                          style={{
                            color: cancelled ? 'var(--text-mute)' : 'var(--text)',
                            textDecoration: cancelled ? 'line-through' : undefined,
                          }}
                        >
                          {money(amount, { decimals: false })}
                        </div>
                      </div>
                      <RouteStops pickup={ride.pickup.name} dropoff={ride.dropoff.name} stop={ride.stop?.name} compact />
                      {ride.ratingByPassenger && role === 'passenger' && (
                        <div className="flex items-center gap-1 mt-2 text-[12px]" style={{ color: 'var(--text-mute)' }}>
                          <Star size={12} fill="var(--brand)" color="var(--brand)" />
                          You rated {ride.ratingByPassenger.stars}
                        </div>
                      )}
                    </button>
                  )
                })}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  )
}
