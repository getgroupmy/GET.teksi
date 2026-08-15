import { useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { TopBar, Avatar } from '@/components/ui'
import { useSession } from '@/store/session'
import { pickAvatarColor } from '@/data/fixtures'

export default function ProfileSetup() {
  const navigate = useNavigate()
  const location = useLocation()
  const phone = (location.state as { phone?: string } | null)?.phone ?? ''
  const signIn = useSession((s) => s.signIn)
  const updateUser = useSession((s) => s.updateUser)

  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const valid = name.trim().length >= 2

  const finish = () => {
    if (!valid) return
    signIn(phone, name.trim())
    updateUser({ name: name.trim(), email: email.trim() || undefined })
    navigate('/p', { replace: true })
  }

  return (
    <div className="h-full flex flex-col">
      <TopBar onBack={() => navigate('/auth/phone')} />
      <div className="flex-1 px-5 flex flex-col">
        <h1 className="text-[26px] font-extrabold leading-tight mt-2">What should we call you?</h1>
        <p className="text-[14px] mt-2" style={{ color: 'var(--text-dim)' }}>
          Drivers and passengers will see this name and photo.
        </p>

        <div className="flex justify-center my-7">
          <Avatar
            name={name || '?'}
            color={pickAvatarColor(name || phone)}
            size={92}
          />
        </div>

        <label className="label-xs mb-2 block">Full name</label>
        <input
          autoFocus
          className="input"
          placeholder="e.g. Aiman Rahman"
          value={name}
          onChange={(e) => setName(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && finish()}
        />

        <label className="label-xs mb-2 mt-5 block">Email (optional)</label>
        <input
          className="input"
          type="email"
          placeholder="you@example.com"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && finish()}
        />

        <div className="flex-1" />
        <button
          className="btn btn-primary btn-block"
          style={{ marginBottom: 'calc(var(--safe-bottom) + 22px)' }}
          disabled={!valid}
          onClick={finish}
        >
          Start riding
        </button>
      </div>
    </div>
  )
}
