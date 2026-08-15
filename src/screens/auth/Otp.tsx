import { useEffect, useMemo, useRef, useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { TopBar } from '@/components/ui'
import { phoneDisplay } from '@/lib/format'

const LENGTH = 6

export default function OtpScreen() {
  const navigate = useNavigate()
  const location = useLocation()
  const phone = (location.state as { phone?: string } | null)?.phone

  const [code, setCode] = useState('')
  const [seconds, setSeconds] = useState(30)
  const [error, setError] = useState('')
  const inputRef = useRef<HTMLInputElement>(null)

  // The demo "SMS" — shown on screen instead of being sent.
  const expected = useMemo(() => {
    if (!phone) return '000000'
    const n = phone.split('').reduce((acc, c) => (acc * 31 + c.charCodeAt(0)) % 1_000_000, 7)
    return String(n).padStart(6, '0')
  }, [phone])

  useEffect(() => {
    if (!phone) navigate('/auth/phone', { replace: true })
  }, [phone, navigate])

  useEffect(() => {
    if (seconds <= 0) return
    const id = window.setTimeout(() => setSeconds((s) => s - 1), 1000)
    return () => window.clearTimeout(id)
  }, [seconds])

  const submit = (value: string) => {
    if (value.length !== LENGTH) return
    if (value !== expected) {
      setError('That code doesn’t match. Check the code shown below.')
      setCode('')
      return
    }
    navigate('/auth/profile', { state: { phone } })
  }

  return (
    <div className="h-full flex flex-col">
      <TopBar onBack={() => navigate('/auth/phone')} />
      <div className="flex-1 px-5 flex flex-col">
        <h1 className="text-[26px] font-extrabold leading-tight mt-2">Enter the code</h1>
        <p className="text-[14px] mt-2" style={{ color: 'var(--text-dim)' }}>
          Sent to {phone ? phoneDisplay(phone) : ''}
        </p>

        <div className="relative mt-8" onClick={() => inputRef.current?.focus()}>
          <input
            ref={inputRef}
            autoFocus
            inputMode="numeric"
            value={code}
            onChange={(e) => {
              const next = e.target.value.replace(/\D/g, '').slice(0, LENGTH)
              setCode(next)
              setError('')
              if (next.length === LENGTH) submit(next)
            }}
            className="absolute inset-0 opacity-0"
            style={{ caretColor: 'transparent' }}
            aria-label="Verification code"
          />
          <div className="flex gap-2 justify-between">
            {Array.from({ length: LENGTH }).map((_, i) => (
              <div
                key={i}
                className="flex-1 flex items-center justify-center text-[22px] font-bold tabular"
                style={{
                  height: 58,
                  borderRadius: 14,
                  background: 'var(--surface-2)',
                  border: `1.5px solid ${i === code.length ? 'var(--brand)' : error ? 'var(--danger)' : 'var(--line)'}`,
                }}
              >
                {code[i] ?? ''}
              </div>
            ))}
          </div>
        </div>

        {error && (
          <p className="text-[13px] mt-3" style={{ color: 'var(--danger)' }}>
            {error}
          </p>
        )}

        <div
          className="mt-6 px-4 py-3 rounded-xl text-[13px]"
          style={{
            background: 'color-mix(in srgb, var(--info) 10%, transparent)',
            border: '1px solid color-mix(in srgb, var(--info) 25%, transparent)',
            color: 'var(--info)',
          }}
        >
          Demo build — no SMS is sent. Your code is{' '}
          <button
            className="font-bold tabular underline"
            onClick={() => {
              setCode(expected)
              submit(expected)
            }}
          >
            {expected}
          </button>
        </div>

        <button
          className="mt-5 text-[14px] font-semibold self-start"
          style={{ color: seconds > 0 ? 'var(--text-mute)' : 'var(--brand)' }}
          disabled={seconds > 0}
          onClick={() => setSeconds(30)}
        >
          {seconds > 0 ? `Resend code in ${seconds}s` : 'Resend code'}
        </button>

        <div className="flex-1" />
        <button
          className="btn btn-primary btn-block"
          style={{ marginBottom: 'calc(var(--safe-bottom) + 22px)' }}
          disabled={code.length !== LENGTH}
          onClick={() => submit(code)}
        >
          Verify
        </button>
      </div>
    </div>
  )
}
