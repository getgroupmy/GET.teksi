import { useEffect, useMemo, useRef, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { MapPin, Plus, X, Search, Clock, Star, Building2, Plane, TrainFront } from 'lucide-react'
import type { Place } from '@/types'
import { useDraft } from '@/store/draft'
import { useSession } from '@/store/session'
import { useRides, selectHistory } from '@/store/rides'
import { useShallow } from 'zustand/react/shallow'
import { ALL_PLACES, INTERCITY_PLACES, PLACES, fuzzySearch } from '@/data/places'
import { TopBar, EmptyState } from '@/components/ui'
import { haversineKm } from '@/lib/geo'
import { distance as fmtDistance } from '@/lib/format'

export default function DestinationSearch() {
  const navigate = useNavigate()
  const draft = useDraft()
  const user = useSession((s) => s.user)!
  const myLocation = useSession((s) => s.myLocation)
  const history = useRides(useShallow((s) => selectHistory(s, user.id, 'passenger')))
  const [query, setQuery] = useState('')
  /** The stop field only exists once the passenger asks for one. */
  const [wantStop, setWantStop] = useState(Boolean(draft.stop))
  const pickupRef = useRef<HTMLInputElement>(null)
  const dropoffRef = useRef<HTMLInputElement>(null)

  const field = draft.editing
  const pool = draft.service === 'intercity' ? INTERCITY_PLACES : ALL_PLACES

  useEffect(() => {
    const el = field === 'pickup' ? pickupRef.current : dropoffRef.current
    el?.focus()
  }, [field])

  const results = useMemo(() => {
    if (query.trim()) return fuzzySearch(query, pool)
    return []
  }, [query, pool])

  const recents = useMemo(() => {
    const seen = new Set<string>()
    const list: Place[] = []
    for (const ride of history) {
      for (const place of [ride.dropoff, ride.pickup]) {
        if (seen.has(place.name)) continue
        seen.add(place.name)
        list.push({ ...place, category: 'recent' })
      }
      if (list.length >= 6) break
    }
    return list
  }, [history])

  const suggestions = useMemo(() => {
    const base = draft.service === 'intercity' ? INTERCITY_PLACES : PLACES
    return [...base]
      .map((p) => ({ p, km: haversineKm(p.coord, myLocation) }))
      .sort((a, b) => a.km - b.km)
      .slice(0, 10)
      .map(({ p }) => p)
  }, [draft.service, myLocation])

  const choose = (place: Place) => {
    if (field === 'pickup') draft.setPickup(place)
    else if (field === 'stop') draft.setStop(place)
    else draft.setDropoff(place)

    // Once both ends are known, jump straight to setting the fare.
    const nextPickup = field === 'pickup' ? place : draft.pickup
    const nextDropoff = field === 'dropoff' ? place : draft.dropoff
    if (nextPickup && nextDropoff) {
      draft.setStep('price')
      navigate('/p')
    } else {
      draft.setEditing(nextDropoff ? 'pickup' : 'dropoff')
      setQuery('')
    }
  }

  const iconFor = (place: Place) => {
    switch (place.category) {
      case 'airport':
        return <Plane size={16} />
      case 'transit':
        return <TrainFront size={16} />
      case 'mall':
        return <Building2 size={16} />
      case 'recent':
        return <Clock size={16} />
      case 'saved':
        return <Star size={16} />
      default:
        return <MapPin size={16} />
    }
  }

  const list = query.trim() ? results : recents.length ? [...recents, ...suggestions] : suggestions

  return (
    <div className="h-full flex flex-col">
      <TopBar title="Set your route" onBack={() => navigate('/p')} />

      <div className="px-4 pt-1 pb-3">
        <div className="flex gap-3">
          <div className="flex flex-col items-center pt-4" style={{ width: 10 }}>
            <div style={{ width: 10, height: 10, borderRadius: 999, background: 'var(--brand)' }} />
            <div style={{ flex: 1, width: 2, background: 'var(--surface-3)', margin: '4px 0' }} />
            <div style={{ width: 9, height: 9, borderRadius: 2, background: 'var(--text)' }} />
          </div>

          <div className="flex-1 flex flex-col gap-2">
            <FieldInput
              ref={pickupRef}
              placeholder="Pickup location"
              value={field === 'pickup' ? query : (draft.pickup?.name ?? '')}
              active={field === 'pickup'}
              onFocus={() => {
                draft.setEditing('pickup')
                setQuery('')
              }}
              onChange={setQuery}
              onClear={() => setQuery('')}
            />
            {wantStop && (
              <FieldInput
                placeholder="Stop along the way"
                value={field === 'stop' ? query : (draft.stop?.name ?? '')}
                active={field === 'stop'}
                onFocus={() => {
                  draft.setEditing('stop')
                  setQuery('')
                }}
                onChange={setQuery}
                onClear={() => {
                  draft.setStop(null)
                  setWantStop(false)
                  draft.setEditing('dropoff')
                }}
              />
            )}
            <FieldInput
              ref={dropoffRef}
              placeholder="Where to?"
              value={field === 'dropoff' ? query : (draft.dropoff?.name ?? '')}
              active={field === 'dropoff'}
              onFocus={() => {
                draft.setEditing('dropoff')
                setQuery('')
              }}
              onChange={setQuery}
              onClear={() => setQuery('')}
            />
          </div>
        </div>

        {!wantStop && (
          <button
            className="btn btn-ghost btn-sm mt-2"
            style={{ color: 'var(--brand)', paddingLeft: 0 }}
            onClick={() => {
              setWantStop(true)
              draft.setEditing('stop')
              setQuery('')
            }}
          >
            <Plus size={16} /> Add a stop
          </button>
        )}
      </div>

      <div className="divider" />

      <div className="flex-1 scroll-y">
        {list.length === 0 ? (
          <EmptyState
            icon={<Search size={30} />}
            title="No matching places"
            body="Try a mall, a station, or a neighbourhood name."
          />
        ) : (
          list.map((place, i) => (
            <button
              key={`${place.id}_${i}`}
              onClick={() => choose(place)}
              className="flex items-center gap-3 w-full text-left px-4 py-3.5"
              style={{ borderBottom: '1px solid var(--line)' }}
            >
              <div
                className="flex items-center justify-center shrink-0"
                style={{
                  width: 36, height: 36, borderRadius: 999,
                  background: 'var(--surface-2)', color: 'var(--text-dim)',
                }}
              >
                {iconFor(place)}
              </div>
              <div className="flex-1 min-w-0">
                <div className="text-[15px] font-semibold truncate">{place.name}</div>
                <div className="text-[13px] truncate" style={{ color: 'var(--text-dim)' }}>
                  {place.address}
                </div>
              </div>
              <span className="text-[12px] tabular shrink-0" style={{ color: 'var(--text-mute)' }}>
                {fmtDistance(haversineKm(place.coord, myLocation))}
              </span>
            </button>
          ))
        )}
      </div>
    </div>
  )
}

const FieldInput = ({
  ref,
  placeholder,
  value,
  active,
  onFocus,
  onChange,
  onClear,
}: {
  ref?: React.Ref<HTMLInputElement>
  placeholder: string
  value: string
  active: boolean
  onFocus: () => void
  onChange: (v: string) => void
  onClear: () => void
}) => (
  <div
    className="flex items-center gap-2 px-3.5"
    style={{
      background: 'var(--surface-2)',
      borderRadius: 12,
      border: `1.5px solid ${active ? 'var(--brand)' : 'transparent'}`,
    }}
  >
    <input
      ref={ref}
      className="flex-1 bg-transparent outline-none text-[15px] font-medium py-3"
      style={{ color: 'var(--text)' }}
      placeholder={placeholder}
      value={value}
      onFocus={onFocus}
      onChange={(e) => onChange(e.target.value)}
    />
    {value && (
      <button onClick={onClear} aria-label="Clear" style={{ color: 'var(--text-mute)' }}>
        <X size={16} />
      </button>
    )}
  </div>
)
