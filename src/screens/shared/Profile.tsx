import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Star, Car, Calendar, BadgeCheck } from 'lucide-react'
import { useSession } from '@/store/session'
import { useRides, selectHistory } from '@/store/rides'
import { useShallow } from 'zustand/react/shallow'
import { money, phoneDisplay, plural } from '@/lib/format'
import { TopBar, Avatar, Modal, StatBox, Banner } from '@/components/ui'

export default function Profile() {
  const navigate = useNavigate()
  const user = useSession((s) => s.user)!
  const updateUser = useSession((s) => s.updateUser)
  const passengerRides = useRides(useShallow((s) => selectHistory(s, user.id, 'passenger')))
  const driverRides = useRides(useShallow((s) => selectHistory(s, user.id, 'driver')))

  const [editing, setEditing] = useState(false)
  const [name, setName] = useState(user.name)
  const [email, setEmail] = useState(user.email ?? '')

  const completedAsPassenger = passengerRides.filter((r) => r.status === 'completed').length
  const completedAsDriver = driverRides.filter((r) => r.status === 'completed').length
  const memberSince = new Date(user.createdAt).toLocaleDateString('en-MY', {
    month: 'long',
    year: 'numeric',
  })

  return (
    <div className="h-full flex flex-col">
      <TopBar
        title="Profile"
        onBack={() => navigate('/menu')}
        right={
          <button
            className="btn btn-ghost btn-sm"
            style={{ color: 'var(--brand)' }}
            onClick={() => setEditing(true)}
          >
            Edit
          </button>
        }
      />

      <div className="flex-1 scroll-y px-4 pb-6">
        <div className="flex flex-col items-center gap-3 py-6">
          <Avatar name={user.name} color={user.avatarColor} size={92} />
          <div className="text-center">
            <div className="text-[22px] font-extrabold">{user.name}</div>
            <div className="text-[13.5px]" style={{ color: 'var(--text-dim)' }}>
              {phoneDisplay(user.phone)}
            </div>
            {user.email && (
              <div className="text-[13px]" style={{ color: 'var(--text-mute)' }}>
                {user.email}
              </div>
            )}
          </div>
        </div>

        <div className="flex gap-2 mb-3">
          <StatBox label="Passenger rating" value={user.rating.toFixed(1)} tone="var(--brand)" />
          <StatBox label="Trips taken" value={String(completedAsPassenger)} />
          <StatBox label="Wallet" value={money(user.walletBalance, { decimals: false })} />
        </div>

        {user.driverProfile && (
          <>
            <div className="label-xs mb-2 mt-5">Driver profile</div>
            <div className="card p-4 mb-3">
              <div className="flex items-center gap-3 mb-3">
                <div
                  className="flex items-center justify-center shrink-0"
                  style={{
                    width: 44, height: 44, borderRadius: 13,
                    background: 'color-mix(in srgb, var(--brand) 14%, transparent)',
                    color: 'var(--brand)',
                  }}
                >
                  <Car size={20} />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="text-[15px] font-bold truncate">
                    {user.driverProfile.vehicle.make} {user.driverProfile.vehicle.model}
                  </div>
                  <div className="text-[12.5px]" style={{ color: 'var(--text-dim)' }}>
                    {user.driverProfile.vehicle.plate} · {user.driverProfile.vehicle.color}
                  </div>
                </div>
                {user.driverProfile.verified && (
                  <span
                    className="flex items-center gap-1 text-[12px] font-semibold shrink-0"
                    style={{ color: 'var(--ok)' }}
                  >
                    <BadgeCheck size={14} /> Verified
                  </span>
                )}
              </div>

              <div className="flex gap-2">
                <StatBox label="Driver rating" value={user.driverProfile.rating.toFixed(2)} tone="var(--brand)" />
                <StatBox label="Trips given" value={String(completedAsDriver || user.driverProfile.ridesGiven)} />
                <StatBox label="Earned" value={money(user.driverProfile.earnings, { decimals: false })} />
              </div>
            </div>
          </>
        )}

        <div className="card p-4 mt-3 flex items-center gap-3">
          <Calendar size={18} style={{ color: 'var(--text-dim)' }} />
          <div className="flex-1 text-[14px]">Member since {memberSince}</div>
          <Star size={15} fill="var(--brand)" color="var(--brand)" />
        </div>

        <div className="mt-4">
          <Banner tone="info">
            Your rating is the average of the last {plural(50, 'trip')}. Passengers and drivers rate
            each other after every completed ride.
          </Banner>
        </div>
      </div>

      <Modal
        open={editing}
        onClose={() => setEditing(false)}
        title="Edit profile"
        footer={
          <button
            className="btn btn-primary btn-block"
            disabled={name.trim().length < 2}
            onClick={() => {
              updateUser({ name: name.trim(), email: email.trim() || undefined })
              setEditing(false)
            }}
          >
            Save
          </button>
        }
      >
        <label className="label-xs block mb-1.5">Full name</label>
        <input className="input mb-4" value={name} onChange={(e) => setName(e.target.value)} />
        <label className="label-xs block mb-1.5">Email</label>
        <input className="input" type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
      </Modal>
    </div>
  )
}
