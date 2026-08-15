import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { TopBar } from '@/components/ui'

/**
 * Phone entry. There is no SMS gateway here — the OTP screen accepts any
 * six digits and shows the code it "sent", so the flow is fully walkable.
 */
export default function PhoneScreen() {
  const [digits, setDigits] = useState('')
  const navigate = useNavigate()
  const valid = digits.length >= 9 && digits.length <= 10

  const onChange = (raw: string) => setDigits(raw.replace(/\D/g, '').replace(/^0+/, '').slice(0, 10))

  return (
    <div className="h-full flex flex-col">
      <TopBar onBack={() => navigate('/intro')} />
      <div className="flex-1 px-5 flex flex-col">
        <h1 className="text-[26px] font-extrabold leading-tight mt-2">Enter your phone number</h1>
        <p className="text-[14px] mt-2" style={{ color: 'var(--text-dim)' }}>
          We’ll send a 6-digit code to verify it’s you.
        </p>

        <div
          className="flex items-center gap-2 mt-7"
          style={{
            background: 'var(--surface-2)',
            border: '1px solid var(--line)',
            borderRadius: 14,
            padding: '4px 14px',
          }}
        >
          <span className="text-[17px] font-semibold" style={{ color: 'var(--text-dim)' }}>
            🇲🇾 +60
          </span>
          <div style={{ width: 1, height: 22, background: 'var(--line)' }} />
          <input
            autoFocus
            inputMode="numeric"
            placeholder="12 345 6789"
            value={digits}
            onChange={(e) => onChange(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && valid && navigate('/auth/otp', { state: { phone: `60${digits}` } })}
            className="flex-1 bg-transparent outline-none text-[17px] font-semibold tabular py-3.5"
            style={{ color: 'var(--text)' }}
          />
        </div>

        <p className="text-[12px] mt-4 leading-relaxed" style={{ color: 'var(--text-mute)' }}>
          By continuing you agree to the Terms of Service and Privacy Policy. Standard message rates
          may apply.
        </p>

        <div className="flex-1" />
        <button
          className="btn btn-primary btn-block"
          style={{ marginBottom: 'calc(var(--safe-bottom) + 22px)' }}
          disabled={!valid}
          onClick={() => navigate('/auth/otp', { state: { phone: `60${digits}` } })}
        >
          Continue
        </button>
      </div>
    </div>
  )
}
