import { useNavigate } from 'react-router-dom'
import { Search, Home, Briefcase, Clock, Plus, Car, Bike, Package, Truck, Route } from 'lucide-react'
import type { Place, ServiceType } from '@/types'
import { useDraft } from '@/store/draft'
import { useSession } from '@/store/session'
import { useRides, selectHistory } from '@/store/rides'
import { useShallow } from 'zustand/react/shallow'
import { Sheet } from '@/components/ui'

const SERVICES: { value: ServiceType; label: string; icon: typeof Car }[] = [
  { value: 'city', label: 'City', icon: Car },
  { value: 'intercity', label: 'Intercity', icon: Route },
  { value: 'delivery', label: 'Delivery', icon: Package },
  { value: 'moto', label: 'Moto', icon: Bike },
  { value: 'freight', label: 'Freight', icon: Truck },
]

export default function IdleSheet() {
  const navigate = useNavigate()
  const draft = useDraft()
  const user = useSession((s) => s.user)
  const history = useRides(useShallow((s) => (user ? selectHistory(s, user.id, 'passenger') : [])))

  const recents: Place[] = []
  const seen = new Set<string>()
  for (const ride of history) {
    if (seen.has(ride.dropoff.name)) continue
    seen.add(ride.dropoff.name)
    recents.push({ ...ride.dropoff, category: 'recent' })
    if (recents.length >= 3) break
  }

  const openSearch = (field: 'pickup' | 'dropoff') => {
    draft.setEditing(field)
    navigate('/p/search')
  }

  const quickTo = (place: Place) => {
    draft.setDropoff(place)
    draft.setStep('price')
  }

  return (
    <Sheet>
      <div className="scroll-x flex gap-2 pb-3 -mx-4 px-4">
        {SERVICES.map((s) => {
          const Icon = s.icon
          const active = draft.service === s.value
          return (
            <button
              key={s.value}
              className="chip"
              data-active={active}
              onClick={() => draft.setService(s.value)}
            >
              <Icon size={15} />
              {s.label}
            </button>
          )
        })}
      </div>

      <button
        onClick={() => openSearch('dropoff')}
        className="w-full flex items-center gap-3 px-4 py-4 mb-3"
        style={{ background: 'var(--surface-2)', borderRadius: 16, border: '1px solid var(--line)' }}
      >
        <Search size={20} style={{ color: 'var(--brand)' }} />
        <span className="text-[17px] font-semibold">Where to?</span>
      </button>

      <div className="flex gap-2 mb-1">
        <ShortcutButton
          icon={<Home size={16} />}
          label={user?.homePlace ? 'Home' : 'Add home'}
          sub={user?.homePlace?.name}
          onClick={() => (user?.homePlace ? quickTo(user.homePlace) : navigate('/places'))}
        />
        <ShortcutButton
          icon={<Briefcase size={16} />}
          label={user?.workPlace ? 'Work' : 'Add work'}
          sub={user?.workPlace?.name}
          onClick={() => (user?.workPlace ? quickTo(user.workPlace) : navigate('/places'))}
        />
        <ShortcutButton icon={<Plus size={16} />} label="Saved" onClick={() => navigate('/places')} />
      </div>

      {recents.length > 0 && (
        <div className="mt-3">
          {recents.map((place) => (
            <button
              key={place.id}
              onClick={() => quickTo(place)}
              className="flex items-center gap-3 w-full text-left py-3"
            >
              <div
                className="flex items-center justify-center shrink-0"
                style={{ width: 36, height: 36, borderRadius: 999, background: 'var(--surface-2)', color: 'var(--text-dim)' }}
              >
                <Clock size={16} />
              </div>
              <div className="min-w-0 flex-1">
                <div className="text-[15px] font-semibold truncate">{place.name}</div>
                <div className="text-[13px] truncate" style={{ color: 'var(--text-dim)' }}>
                  {place.address}
                </div>
              </div>
            </button>
          ))}
        </div>
      )}
    </Sheet>
  )
}

function ShortcutButton({
  icon,
  label,
  sub,
  onClick,
}: {
  icon: React.ReactNode
  label: string
  sub?: string
  onClick: () => void
}) {
  return (
    <button
      onClick={onClick}
      className="flex-1 flex flex-col items-start gap-1 px-3 py-2.5 min-w-0"
      style={{ background: 'var(--surface-2)', borderRadius: 14 }}
    >
      <span style={{ color: 'var(--brand)' }}>{icon}</span>
      <span className="text-[13px] font-semibold truncate w-full text-left">{label}</span>
      {sub && (
        <span className="text-[11px] truncate w-full text-left" style={{ color: 'var(--text-mute)' }}>
          {sub}
        </span>
      )}
    </button>
  )
}
