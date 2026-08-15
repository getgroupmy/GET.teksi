import { useNavigate } from 'react-router-dom'
import {
  Clock, Wallet, Gift, Settings as SettingsIcon, ShieldAlert, Car, MapPin,
  User as UserIcon, TrendingUp, LogOut, CarFront,
} from 'lucide-react'
import { useSession } from '@/store/session'
import { useRides } from '@/store/rides'
import { money } from '@/lib/format'
import { TopBar, Avatar, Rating, Row, Modal } from '@/components/ui'
import { useState } from 'react'

export default function Menu() {
  const navigate = useNavigate()
  const user = useSession((s) => s.user)!
  const prefs = useSession((s) => s.prefs)
  const setRole = useSession((s) => s.setRole)
  const signOut = useSession((s) => s.signOut)
  const reset = useRides((s) => s.reset)
  const [confirmOut, setConfirmOut] = useState(false)

  const isDriver = prefs.role === 'driver'
  const home = isDriver ? '/d' : '/p'

  return (
    <div className="h-full flex flex-col">
      <TopBar title="Menu" onBack={() => navigate(home)} />

      <div className="flex-1 scroll-y pb-6">
        <button
          className="flex items-center gap-3 w-full text-left px-4 py-4"
          onClick={() => navigate('/profile')}
        >
          <Avatar name={user.name} color={user.avatarColor} size={54} />
          <div className="flex-1 min-w-0">
            <div className="text-[18px] font-extrabold truncate">{user.name}</div>
            <div className="flex items-center gap-2 text-[13px]" style={{ color: 'var(--text-dim)' }}>
              <Rating value={isDriver ? (user.driverProfile?.rating ?? 5) : user.rating} />
              <span>·</span>
              <span>
                {isDriver
                  ? `${user.driverProfile?.ridesGiven ?? 0} trips given`
                  : `${user.ridesTaken} trips taken`}
              </span>
            </div>
          </div>
        </button>

        <div className="px-4 mb-3">
          <button
            className="btn btn-secondary btn-block"
            onClick={() => {
              if (isDriver) {
                setRole('passenger')
                navigate('/p')
              } else if (user.driverProfile) {
                setRole('driver')
                navigate('/d')
              } else {
                navigate('/d/onboarding')
              }
            }}
          >
            {isDriver ? (
              <>
                <UserIcon size={17} style={{ color: 'var(--brand)' }} /> Switch to passenger
              </>
            ) : user.driverProfile ? (
              <>
                <CarFront size={17} style={{ color: 'var(--brand)' }} /> Switch to driver
              </>
            ) : (
              <>
                <CarFront size={17} style={{ color: 'var(--brand)' }} /> Become a driver
              </>
            )}
          </button>
        </div>

        <div className="divider mx-4" />

        <Row icon={<Clock size={17} />} title="My rides" subtitle="Trip history and receipts" onClick={() => navigate('/history')} />
        <Row
          icon={<Wallet size={17} />}
          title="Wallet"
          subtitle={`Balance ${money(user.walletBalance)}`}
          onClick={() => navigate('/wallet')}
        />
        <Row icon={<Gift size={17} />} title="Promo codes" subtitle="Discounts and referrals" onClick={() => navigate('/promos')} />
        <Row icon={<MapPin size={17} />} title="Saved places" subtitle="Home, work and favourites" onClick={() => navigate('/places')} />

        {user.driverProfile && (
          <>
            <div className="divider mx-4 my-2" />
            <Row icon={<TrendingUp size={17} />} title="Earnings" subtitle="Daily and weekly totals" onClick={() => navigate('/d/earnings')} />
            <Row icon={<Car size={17} />} title="Vehicle & documents" subtitle={user.driverProfile.vehicle.plate} onClick={() => navigate('/d/vehicle')} />
          </>
        )}

        <div className="divider mx-4 my-2" />
        <Row icon={<ShieldAlert size={17} />} title="Safety centre" subtitle="Emergency contacts and SOS" onClick={() => navigate('/safety')} />
        <Row icon={<SettingsIcon size={17} />} title="Settings" onClick={() => navigate('/settings')} />
        <Row icon={<LogOut size={17} />} title="Sign out" danger onClick={() => setConfirmOut(true)} />

        <div className="text-center text-[11.5px] mt-6" style={{ color: 'var(--text-mute)' }}>
          GET.teksi · v1.0.0
        </div>
      </div>

      <Modal open={confirmOut} onClose={() => setConfirmOut(false)} title="Sign out?">
        <p className="text-[13.5px] mb-4" style={{ color: 'var(--text-dim)' }}>
          Your rides and history stay on this device unless you clear them.
        </p>
        <button
          className="btn btn-danger btn-block mb-2"
          onClick={() => {
            signOut()
            navigate('/auth/phone', { replace: true })
          }}
        >
          Sign out
        </button>
        <button
          className="btn btn-ghost btn-block btn-sm"
          style={{ color: 'var(--text-mute)' }}
          onClick={() => {
            reset()
            signOut()
            navigate('/auth/phone', { replace: true })
          }}
        >
          Sign out and erase all local data
        </button>
      </Modal>
    </div>
  )
}
