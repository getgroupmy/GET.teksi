import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Home, Briefcase, MapPin, Search, X } from 'lucide-react'
import type { Place } from '@/types'
import { useSession } from '@/store/session'
import { useDraft } from '@/store/draft'
import { ALL_PLACES, fuzzySearch } from '@/data/places'
import { TopBar, Modal, Row, EmptyState } from '@/components/ui'

export default function Places() {
  const navigate = useNavigate()
  const user = useSession((s) => s.user)!
  const saveShortcut = useSession((s) => s.saveShortcut)
  const updateUser = useSession((s) => s.updateUser)
  const draft = useDraft()

  const [picking, setPicking] = useState<null | 'home' | 'work'>(null)
  const [query, setQuery] = useState('')

  const results = useMemo(() => (query.trim() ? fuzzySearch(query, ALL_PLACES, 12) : ALL_PLACES.slice(0, 12)), [query])

  const go = (place: Place) => {
    draft.setDropoff(place)
    draft.setStep('price')
    navigate('/p')
  }

  return (
    <div className="h-full flex flex-col">
      <TopBar title="Saved places" onBack={() => navigate('/menu')} />

      <div className="flex-1 scroll-y pb-6">
        <div className="label-xs px-4 pt-4 pb-2">Shortcuts</div>

        <Row
          icon={<Home size={17} />}
          title={user.homePlace ? user.homePlace.name : 'Add home'}
          subtitle={user.homePlace?.address ?? 'Set your home address for one-tap booking'}
          onClick={() => (user.homePlace ? go(user.homePlace) : setPicking('home'))}
          right={
            user.homePlace ? (
              <button
                onClick={(e) => {
                  e.stopPropagation()
                  updateUser({ homePlace: undefined })
                }}
                style={{ color: 'var(--text-mute)' }}
                aria-label="Remove home"
              >
                <X size={16} />
              </button>
            ) : undefined
          }
        />

        <Row
          icon={<Briefcase size={17} />}
          title={user.workPlace ? user.workPlace.name : 'Add work'}
          subtitle={user.workPlace?.address ?? 'Set your work address for one-tap booking'}
          onClick={() => (user.workPlace ? go(user.workPlace) : setPicking('work'))}
          right={
            user.workPlace ? (
              <button
                onClick={(e) => {
                  e.stopPropagation()
                  updateUser({ workPlace: undefined })
                }}
                style={{ color: 'var(--text-mute)' }}
                aria-label="Remove work"
              >
                <X size={16} />
              </button>
            ) : undefined
          }
        />

        {(user.homePlace || user.workPlace) && (
          <div className="px-4 pt-3 flex gap-2">
            <button className="btn btn-secondary btn-sm flex-1" onClick={() => setPicking('home')}>
              Change home
            </button>
            <button className="btn btn-secondary btn-sm flex-1" onClick={() => setPicking('work')}>
              Change work
            </button>
          </div>
        )}

        <div className="label-xs px-4 pt-6 pb-2">Popular in Kuala Lumpur</div>
        {ALL_PLACES.slice(0, 10).map((place) => (
          <Row
            key={place.id}
            icon={<MapPin size={17} />}
            title={place.name}
            subtitle={place.address}
            onClick={() => go(place)}
          />
        ))}
      </div>

      <Modal
        open={picking != null}
        onClose={() => {
          setPicking(null)
          setQuery('')
        }}
        title={picking === 'home' ? 'Set your home' : 'Set your work'}
      >
        <div className="flex items-center gap-2 mb-3">
          <Search size={17} style={{ color: 'var(--text-dim)' }} />
          <input
            autoFocus
            className="input"
            placeholder="Search for an address"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
        </div>
        <div className="max-h-[45dvh] scroll-y">
          {results.length === 0 ? (
            <EmptyState title="No matches" body="Try another name." />
          ) : (
            results.map((place) => (
              <button
                key={place.id}
                className="flex items-center gap-3 w-full text-left py-3"
                style={{ borderBottom: '1px solid var(--line)' }}
                onClick={() => {
                  saveShortcut(picking!, { ...place, category: 'saved' })
                  setPicking(null)
                  setQuery('')
                }}
              >
                <MapPin size={16} style={{ color: 'var(--text-dim)' }} />
                <div className="min-w-0">
                  <div className="text-[14.5px] font-semibold truncate">{place.name}</div>
                  <div className="text-[12.5px] truncate" style={{ color: 'var(--text-dim)' }}>
                    {place.address}
                  </div>
                </div>
              </button>
            ))
          )}
        </div>
      </Modal>
    </div>
  )
}
