import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Gift, Copy, Check, Share2 } from 'lucide-react'
import { useSession } from '@/store/session'
import { useDraft } from '@/store/draft'
import { PROMO_CODES } from '@/data/fixtures'
import { money } from '@/lib/format'
import { TopBar, Banner } from '@/components/ui'

export default function Promos() {
  const navigate = useNavigate()
  const user = useSession((s) => s.user)!
  const draft = useDraft()
  const [entered, setEntered] = useState('')
  const [feedback, setFeedback] = useState<{ ok: boolean; text: string } | null>(null)

  const referral = `TEKSI-${user.id.slice(-5).toUpperCase()}`

  const apply = (code: string) => {
    const match = PROMO_CODES.find((p) => p.code.toLowerCase() === code.trim().toLowerCase())
    if (!match) {
      setFeedback({ ok: false, text: 'That code isn’t valid or has expired.' })
      return
    }
    draft.setPromoCode(match.code)
    setFeedback({ ok: true, text: `${match.code} applied — ${match.label}` })
  }

  return (
    <div className="h-full flex flex-col">
      <TopBar title="Promo codes" onBack={() => navigate('/menu')} />

      <div className="flex-1 scroll-y px-4 pb-6">
        <div className="flex gap-2 my-4">
          <input
            className="input"
            placeholder="Enter a promo code"
            value={entered}
            onChange={(e) => {
              setEntered(e.target.value.toUpperCase())
              setFeedback(null)
            }}
            onKeyDown={(e) => e.key === 'Enter' && apply(entered)}
          />
          <button className="btn btn-primary shrink-0" disabled={!entered.trim()} onClick={() => apply(entered)}>
            Apply
          </button>
        </div>

        {feedback && (
          <div className="mb-4">
            <Banner tone={feedback.ok ? 'ok' : 'danger'}>{feedback.text}</Banner>
          </div>
        )}

        <div className="label-xs mb-2">Available for you</div>
        <div className="flex flex-col gap-2 mb-6">
          {PROMO_CODES.map((promo) => {
            const active = draft.promoCode === promo.code
            return (
              <div
                key={promo.code}
                className="card p-4 flex items-center gap-3"
                style={{
                  borderColor: active ? 'color-mix(in srgb, var(--brand) 45%, transparent)' : 'var(--line)',
                }}
              >
                <div
                  className="flex items-center justify-center shrink-0"
                  style={{
                    width: 44, height: 44, borderRadius: 13,
                    background: 'color-mix(in srgb, var(--brand) 14%, transparent)',
                    color: 'var(--brand)',
                  }}
                >
                  <Gift size={20} />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="text-[15px] font-extrabold tabular tracking-wide">{promo.code}</div>
                  <div className="text-[13px] leading-snug" style={{ color: 'var(--text-dim)' }}>
                    {promo.label}
                  </div>
                  {promo.minSpend && (
                    <div className="text-[11.5px] mt-0.5" style={{ color: 'var(--text-mute)' }}>
                      Minimum fare {money(promo.minSpend, { decimals: false })}
                    </div>
                  )}
                </div>
                <button
                  className="btn btn-sm shrink-0"
                  style={{
                    background: active ? 'transparent' : 'var(--surface-3)',
                    color: active ? 'var(--brand)' : 'var(--text)',
                  }}
                  onClick={() => apply(promo.code)}
                >
                  {active ? <Check size={15} /> : 'Use'}
                </button>
              </div>
            )
          })}
        </div>

        <div className="label-xs mb-2">Invite friends</div>
        <div className="card p-4">
          <p className="text-[13.5px] leading-relaxed mb-3" style={{ color: 'var(--text-dim)' }}>
            Give a friend {money(500, { decimals: false })} off their first ride and get{' '}
            {money(500, { decimals: false })} when they take it.
          </p>
          <div
            className="flex items-center justify-between px-3.5 py-3 mb-3"
            style={{ background: 'var(--surface-2)', borderRadius: 12 }}
          >
            <span className="text-[16px] font-extrabold tabular tracking-widest">{referral}</span>
            <button
              onClick={() => navigator.clipboard?.writeText(referral)}
              style={{ color: 'var(--brand)' }}
              aria-label="Copy referral code"
            >
              <Copy size={17} />
            </button>
          </div>
          <button
            className="btn btn-secondary btn-block"
            onClick={async () => {
              const text = `Use my GET.teksi code ${referral} and get RM5 off your first ride.`
              if (navigator.share) {
                try {
                  await navigator.share({ text })
                  return
                } catch {
                  /* fall through */
                }
              }
              navigator.clipboard?.writeText(text)
            }}
          >
            <Share2 size={16} /> Share invite
          </button>
        </div>
      </div>
    </div>
  )
}
