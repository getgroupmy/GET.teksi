import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { TrendingUp, Car, Star, Clock } from 'lucide-react'
import { useSession } from '@/store/session'
import { useRides, selectHistory } from '@/store/rides'
import { useShallow } from 'zustand/react/shallow'
import { money, duration, dateLabel, clockTime, distance as fmtDistance } from '@/lib/format'
import { driverNet } from '@/services/pricing'
import { TopBar, StatBox, EmptyState, Segmented } from '@/components/ui'

type Period = 'today' | 'week' | 'all'

const PERIOD_MS: Record<Period, number> = {
  today: 24 * 3600_000,
  week: 7 * 24 * 3600_000,
  all: Number.MAX_SAFE_INTEGER,
}

export default function DriverEarnings() {
  const navigate = useNavigate()
  const user = useSession((s) => s.user)!
  const rides = useRides(useShallow((s) => selectHistory(s, user.id, 'driver')))
  const [period, setPeriod] = useState<Period>('today')

  const startOfToday = useMemo(() => {
    const d = new Date()
    d.setHours(0, 0, 0, 0)
    return d.getTime()
  }, [])

  const filtered = useMemo(() => {
    const cutoff = period === 'today' ? startOfToday : Date.now() - PERIOD_MS[period]
    return rides.filter((r) => r.status === 'completed' && (r.completedAt ?? 0) >= cutoff)
  }, [rides, period, startOfToday])

  const stats = useMemo(() => {
    const gross = filtered.reduce((sum, r) => sum + (r.finalPrice ?? r.askingPrice), 0)
    const net = filtered.reduce((sum, r) => sum + driverNet(r.finalPrice ?? r.askingPrice), 0)
    const km = filtered.reduce((sum, r) => sum + r.distanceKm, 0)
    const minutes = filtered.reduce((sum, r) => sum + r.durationMinutes, 0)
    const rated = filtered.filter((r) => r.ratingByPassenger)
    const avgRating =
      rated.length > 0
        ? rated.reduce((sum, r) => sum + (r.ratingByPassenger?.stars ?? 5), 0) / rated.length
        : (user.driverProfile?.rating ?? 5)
    return { gross, net, km, minutes, trips: filtered.length, avgRating }
  }, [filtered, user.driverProfile?.rating])

  const grouped = useMemo(() => {
    const map = new Map<string, typeof filtered>()
    filtered.forEach((ride) => {
      const key = dateLabel(ride.completedAt ?? ride.createdAt)
      map.set(key, [...(map.get(key) ?? []), ride])
    })
    return [...map.entries()]
  }, [filtered])

  return (
    <div className="h-full flex flex-col">
      <TopBar title="Earnings" onBack={() => navigate('/d')} />

      <div className="flex-1 scroll-y px-4 pb-6">
        <div className="my-3">
          <Segmented
            value={period}
            onChange={setPeriod}
            options={[
              { value: 'today', label: 'Today' },
              { value: 'week', label: 'This week' },
              { value: 'all', label: 'All time' },
            ]}
          />
        </div>

        <div className="card p-5 text-center mb-3">
          <div className="label-xs mb-2">Net earnings</div>
          <div className="text-[38px] font-extrabold tabular leading-none">{money(stats.net)}</div>
          <div className="text-[13px] mt-2" style={{ color: 'var(--text-dim)' }}>
            {money(stats.gross)} in fares · {money(stats.gross - stats.net)} service fee
          </div>
        </div>

        <div className="flex gap-2 mb-3">
          <StatBox label="Trips" value={String(stats.trips)} />
          <StatBox label="Distance" value={fmtDistance(stats.km)} />
          <StatBox label="Time" value={duration(stats.minutes)} />
        </div>

        <div className="flex gap-2 mb-5">
          <StatBox
            label="Average fare"
            value={stats.trips ? money(Math.round(stats.net / stats.trips), { decimals: false }) : '—'}
          />
          <StatBox label="Rating" value={stats.avgRating.toFixed(2)} tone="var(--brand)" />
          <StatBox
            label="Per hour"
            value={
              stats.minutes > 0
                ? money(Math.round((stats.net / stats.minutes) * 60), { decimals: false })
                : '—'
            }
            tone="var(--brand)"
          />
        </div>

        {grouped.length === 0 ? (
          <EmptyState
            icon={<TrendingUp size={30} />}
            title="No completed trips yet"
            body="Go online and accept an order — your earnings will show up here."
          />
        ) : (
          grouped.map(([label, list]) => (
            <div key={label} className="mb-4">
              <div className="label-xs mb-2">{label}</div>
              <div className="card overflow-hidden">
                {list.map((ride, i) => (
                  <button
                    key={ride.id}
                    onClick={() => navigate(`/ride/${ride.id}`)}
                    className="flex items-center gap-3 w-full text-left px-3.5 py-3"
                    style={{ borderTop: i === 0 ? 'none' : '1px solid var(--line)' }}
                  >
                    <div
                      className="flex items-center justify-center shrink-0"
                      style={{ width: 34, height: 34, borderRadius: 999, background: 'var(--surface-2)', color: 'var(--text-dim)' }}
                    >
                      <Car size={15} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="text-[14px] font-semibold truncate">{ride.dropoff.name}</div>
                      <div className="text-[12px] flex items-center gap-2 tabular" style={{ color: 'var(--text-dim)' }}>
                        <Clock size={11} /> {clockTime(ride.completedAt ?? ride.createdAt)} ·{' '}
                        {fmtDistance(ride.distanceKm)}
                        {ride.ratingByPassenger && (
                          <>
                            <Star size={11} fill="var(--brand)" color="var(--brand)" />
                            {ride.ratingByPassenger.stars}
                          </>
                        )}
                      </div>
                    </div>
                    <div className="text-[15px] font-bold tabular shrink-0">
                      {money(driverNet(ride.finalPrice ?? ride.askingPrice), { decimals: false })}
                    </div>
                  </button>
                ))}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  )
}
