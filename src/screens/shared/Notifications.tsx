import { useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { Bell, Car, Gift, ShieldAlert, Info } from 'lucide-react'
import type { Notification } from '@/types'
import { useSession } from '@/store/session'
import { useRides } from '@/store/rides'
import { timeAgo } from '@/lib/format'
import { TopBar, EmptyState } from '@/components/ui'

const ICONS: Record<Notification['kind'], typeof Car> = {
  ride: Car,
  promo: Gift,
  safety: ShieldAlert,
  system: Info,
}

export default function Notifications() {
  const navigate = useNavigate()
  const role = useSession((s) => s.prefs.role)
  const notifications = useRides((s) => s.notifications)
  const markRead = useRides((s) => s.markNotificationsRead)

  // Opening the screen is the read receipt.
  useEffect(() => {
    const id = window.setTimeout(markRead, 400)
    return () => window.clearTimeout(id)
  }, [markRead])

  return (
    <div className="h-full flex flex-col">
      <TopBar title="Notifications" onBack={() => navigate(role === 'driver' ? '/d' : '/p')} />

      <div className="flex-1 scroll-y">
        {notifications.length === 0 ? (
          <EmptyState
            icon={<Bell size={30} />}
            title="Nothing new"
            body="Ride updates, offers and promos will show up here."
          />
        ) : (
          notifications.map((n) => {
            const Icon = ICONS[n.kind]
            return (
              <button
                key={n.id}
                onClick={() => n.rideId && navigate(`/ride/${n.rideId}`)}
                className="flex gap-3 w-full text-left px-4 py-3.5"
                style={{
                  borderBottom: '1px solid var(--line)',
                  background: n.read ? 'transparent' : 'color-mix(in srgb, var(--brand) 5%, transparent)',
                }}
              >
                <div
                  className="flex items-center justify-center shrink-0"
                  style={{
                    width: 36, height: 36, borderRadius: 999,
                    background: 'var(--surface-2)',
                    color: n.kind === 'safety' ? 'var(--danger)' : 'var(--brand)',
                  }}
                >
                  <Icon size={16} />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="text-[14.5px] font-semibold">{n.title}</div>
                  <div className="text-[13px] leading-snug" style={{ color: 'var(--text-dim)' }}>
                    {n.body}
                  </div>
                  <div className="text-[11.5px] mt-1" style={{ color: 'var(--text-mute)' }}>
                    {timeAgo(n.createdAt)}
                  </div>
                </div>
                {!n.read && (
                  <span
                    style={{ width: 8, height: 8, borderRadius: 999, background: 'var(--brand)', marginTop: 6 }}
                  />
                )}
              </button>
            )
          })
        )}
      </div>
    </div>
  )
}
