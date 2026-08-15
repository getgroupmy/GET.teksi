import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Minus, Plus, Wallet, Banknote, CreditCard, MessageSquare, Users, Sparkles,
  ChevronRight, X, Baby, Dog, Luggage, Snowflake, CigaretteOff, VolumeX, UserRound,
} from 'lucide-react'
import type { PaymentMethod, Ride, RideOption, VehicleClass } from '@/types'
import { useDraft, tripOf } from '@/store/draft'
import { useSession } from '@/store/session'
import { useRides } from '@/store/rides'
import { judgePrice, priceBounds } from '@/services/pricing'
import { money, roundFare, distance, duration } from '@/lib/format'
import { syntheticRoute } from '@/lib/geo'
import { Sheet, Modal, RouteStops, Banner } from '@/components/ui'
import { uid } from '@/lib/storage'

const CLASSES: { value: VehicleClass; label: string; hint: string }[] = [
  { value: 'economy', label: 'Economy', hint: 'Everyday cars, 4 seats' },
  { value: 'comfort', label: 'Comfort', hint: 'Newer, roomier cars' },
  { value: 'xl', label: 'XL', hint: 'Up to 6 passengers' },
]

const OPTION_META: Record<RideOption, { label: string; icon: typeof Baby }> = {
  child_seat: { label: 'Child seat', icon: Baby },
  pet: { label: 'Travelling with a pet', icon: Dog },
  luggage: { label: 'Large luggage', icon: Luggage },
  air_con: { label: 'Air conditioning', icon: Snowflake },
  no_smoking: { label: 'Non-smoking car', icon: CigaretteOff },
  silent_ride: { label: 'Silent ride', icon: VolumeX },
  female_driver: { label: 'Prefer a female driver', icon: UserRound },
}

const PAYMENTS: { value: PaymentMethod; label: string; icon: typeof Banknote }[] = [
  { value: 'cash', label: 'Cash', icon: Banknote },
  { value: 'card', label: 'Card ···4821', icon: CreditCard },
  { value: 'wallet', label: 'Wallet', icon: Wallet },
]

export default function PriceSheet() {
  const navigate = useNavigate()
  const draft = useDraft()
  const user = useSession((s) => s.user)
  const publishRide = useRides((s) => s.publishRide)
  const [sheet, setSheet] = useState<null | 'options' | 'payment' | 'comment' | 'class'>(null)
  const [commentDraft, setCommentDraft] = useState(draft.comment)

  const trip = useMemo(() => tripOf(draft), [draft])
  const price = draft.price || trip?.recommended || 0
  const bounds = useMemo(() => priceBounds(trip?.recommended ?? 1000), [trip?.recommended])
  const verdict = useMemo(
    () => judgePrice(price, trip?.recommended ?? price),
    [price, trip?.recommended],
  )

  if (!trip || !draft.pickup || !draft.dropoff || !user) return null

  const toneColor =
    verdict.tone === 'low'
      ? 'var(--danger)'
      : verdict.tone === 'high'
        ? 'var(--info)'
        : verdict.tone === 'good'
          ? 'var(--brand)'
          : 'var(--text-dim)'

  const bump = (delta: number) =>
    draft.setPrice(Math.max(bounds.min, Math.min(bounds.max, roundFare(price + delta))))

  const publish = () => {
    const ride: Ride = {
      id: uid('ride'),
      passengerId: user.id,
      passengerName: user.name,
      passengerAvatarColor: user.avatarColor,
      passengerRating: user.rating,
      service: draft.service,
      vehicleClass: draft.vehicleClass,
      pickup: draft.pickup!,
      dropoff: draft.dropoff!,
      stop: draft.stop ?? undefined,
      askingPrice: price,
      recommendedPrice: trip.recommended,
      currency: 'MYR',
      distanceKm: trip.distanceKm,
      durationMinutes: trip.durationMinutes,
      paymentMethod: draft.paymentMethod,
      passengerCount: draft.passengerCount,
      comment: draft.comment.trim() || undefined,
      options: draft.options,
      status: 'searching',
      createdAt: Date.now(),
      updatedAt: Date.now(),
      priceRaises: 0,
      routeGeometry: syntheticRoute(draft.pickup!.coord, draft.dropoff!.coord, 3),
    }
    publishRide(ride)
    draft.setStep('idle')
  }

  const optionSummary =
    draft.options.length === 0 ? 'None' : draft.options.map((o) => OPTION_META[o].label).join(', ')

  return (
    <>
      <Sheet>
        <button
          className="w-full text-left px-3 py-3 mb-3"
          style={{ background: 'var(--surface-2)', borderRadius: 14 }}
          onClick={() => {
            draft.setEditing('dropoff')
            navigate('/p/search')
          }}
        >
          <RouteStops
            pickup={draft.pickup.name}
            dropoff={draft.dropoff.name}
            stop={draft.stop?.name}
            compact
          />
        </button>

        <div className="flex items-center justify-between text-[13px] mb-4" style={{ color: 'var(--text-dim)' }}>
          <span className="tabular">
            {distance(trip.distanceKm)} · {duration(trip.durationMinutes)}
          </span>
          <button
            className="font-semibold flex items-center gap-1"
            style={{ color: 'var(--text)' }}
            onClick={() => setSheet('class')}
          >
            {CLASSES.find((c) => c.value === draft.vehicleClass)!.label}
            <ChevronRight size={14} />
          </button>
        </div>

        {/* Fare setter — the core of the product. */}
        <div className="flex items-center justify-between gap-3 mb-1">
          <button
            aria-label="Lower fare"
            onClick={() => bump(-bounds.step)}
            disabled={price <= bounds.min}
            className="flex items-center justify-center shrink-0"
            style={{
              width: 48, height: 48, borderRadius: 999,
              background: 'var(--surface-2)', color: 'var(--text)',
              opacity: price <= bounds.min ? 0.4 : 1,
            }}
          >
            <Minus size={22} />
          </button>

          <div className="text-center flex-1">
            <div className="text-[38px] font-extrabold tabular leading-none">{money(price, { decimals: false })}</div>
            <div className="text-[12px] mt-1.5 font-semibold" style={{ color: toneColor }}>
              {verdict.label}
            </div>
          </div>

          <button
            aria-label="Raise fare"
            onClick={() => bump(bounds.step)}
            disabled={price >= bounds.max}
            className="flex items-center justify-center shrink-0"
            style={{
              width: 48, height: 48, borderRadius: 999,
              background: 'var(--surface-2)', color: 'var(--text)',
              opacity: price >= bounds.max ? 0.4 : 1,
            }}
          >
            <Plus size={22} />
          </button>
        </div>

        <input
          type="range"
          className="fare"
          min={bounds.min}
          max={bounds.max}
          step={bounds.step}
          value={price}
          onChange={(e) => draft.setPrice(Number(e.target.value))}
          aria-label="Your fare"
        />

        <div className="flex items-center justify-between text-[12px] mb-3" style={{ color: 'var(--text-mute)' }}>
          <span className="tabular">{money(bounds.min, { decimals: false })}</span>
          <button
            className="font-semibold"
            style={{ color: 'var(--text-dim)' }}
            onClick={() => draft.setPrice(trip.recommended)}
          >
            Recommended {money(trip.recommended, { decimals: false })}
          </button>
          <span className="tabular">{money(bounds.max, { decimals: false })}</span>
        </div>

        <p className="text-[12.5px] leading-snug mb-3" style={{ color: 'var(--text-dim)' }}>
          {verdict.hint}
        </p>

        <div className="flex gap-2 mb-3">
          <MetaButton
            icon={<PaymentIcon method={draft.paymentMethod} />}
            label={PAYMENTS.find((p) => p.value === draft.paymentMethod)!.label}
            onClick={() => setSheet('payment')}
          />
          <MetaButton
            icon={<Users size={15} />}
            label={String(draft.passengerCount)}
            onClick={() =>
              draft.setPassengerCount(draft.passengerCount >= (draft.vehicleClass === 'xl' ? 6 : 4) ? 1 : draft.passengerCount + 1)
            }
          />
          <MetaButton
            icon={<MessageSquare size={15} />}
            label={draft.comment ? 'Note added' : 'Note'}
            onClick={() => {
              setCommentDraft(draft.comment)
              setSheet('comment')
            }}
          />
          <MetaButton
            icon={<Sparkles size={15} />}
            label={draft.options.length ? `+${draft.options.length}` : 'Extras'}
            onClick={() => setSheet('options')}
          />
        </div>

        <button className="btn btn-primary btn-block" onClick={publish}>
          Find a driver for {money(price, { decimals: false })}
        </button>
        <button
          className="btn btn-ghost btn-block btn-sm mt-1"
          style={{ color: 'var(--text-dim)' }}
          onClick={() => {
            draft.clear()
          }}
        >
          Cancel
        </button>
      </Sheet>

      <Modal open={sheet === 'class'} onClose={() => setSheet(null)} title="Choose a car type">
        {CLASSES.map((c) => (
          <button
            key={c.value}
            className="flex items-center gap-3 w-full text-left py-3.5"
            onClick={() => {
              draft.setVehicleClass(c.value)
              setSheet(null)
            }}
          >
            <div className="flex-1">
              <div className="text-[15px] font-semibold">{c.label}</div>
              <div className="text-[13px]" style={{ color: 'var(--text-dim)' }}>
                {c.hint}
              </div>
            </div>
            <div
              style={{
                width: 20, height: 20, borderRadius: 999,
                border: `2px solid ${draft.vehicleClass === c.value ? 'var(--brand)' : 'var(--line)'}`,
                background: draft.vehicleClass === c.value ? 'var(--brand)' : 'transparent',
              }}
            />
          </button>
        ))}
      </Modal>

      <Modal open={sheet === 'payment'} onClose={() => setSheet(null)} title="Payment method">
        {PAYMENTS.map((p) => {
          const Icon = p.icon
          const insufficient = p.value === 'wallet' && user.walletBalance < price
          return (
            <button
              key={p.value}
              disabled={insufficient}
              className="flex items-center gap-3 w-full text-left py-3.5"
              style={{ opacity: insufficient ? 0.45 : 1 }}
              onClick={() => {
                draft.setPaymentMethod(p.value)
                setSheet(null)
              }}
            >
              <Icon size={19} style={{ color: 'var(--text-dim)' }} />
              <div className="flex-1">
                <div className="text-[15px] font-semibold">{p.label}</div>
                {p.value === 'wallet' && (
                  <div className="text-[12px]" style={{ color: insufficient ? 'var(--danger)' : 'var(--text-dim)' }}>
                    Balance {money(user.walletBalance)}
                    {insufficient ? ' — not enough for this fare' : ''}
                  </div>
                )}
              </div>
              <div
                style={{
                  width: 20, height: 20, borderRadius: 999,
                  border: `2px solid ${draft.paymentMethod === p.value ? 'var(--brand)' : 'var(--line)'}`,
                  background: draft.paymentMethod === p.value ? 'var(--brand)' : 'transparent',
                }}
              />
            </button>
          )
        })}
        <div className="mt-2">
          <Banner tone="info">Cash is paid directly to the driver at the end of the trip.</Banner>
        </div>
      </Modal>

      <Modal
        open={sheet === 'comment'}
        onClose={() => setSheet(null)}
        title="Note for the driver"
        footer={
          <button
            className="btn btn-primary btn-block"
            onClick={() => {
              draft.setComment(commentDraft)
              setSheet(null)
            }}
          >
            Save note
          </button>
        }
      >
        <textarea
          className="input"
          rows={3}
          maxLength={160}
          autoFocus
          placeholder="e.g. I'm at the north entrance, near the taxi stand"
          value={commentDraft}
          onChange={(e) => setCommentDraft(e.target.value)}
        />
        <div className="text-[12px] mt-2 text-right" style={{ color: 'var(--text-mute)' }}>
          {commentDraft.length}/160
        </div>
      </Modal>

      <Modal open={sheet === 'options'} onClose={() => setSheet(null)} title="Trip options">
        <div className="text-[13px] mb-3" style={{ color: 'var(--text-dim)' }}>
          Selected: {optionSummary}
        </div>
        {(Object.keys(OPTION_META) as RideOption[]).map((key) => {
          const meta = OPTION_META[key]
          const Icon = meta.icon
          const active = draft.options.includes(key)
          return (
            <button
              key={key}
              className="flex items-center gap-3 w-full text-left py-3"
              onClick={() => draft.toggleOption(key)}
            >
              <Icon size={18} style={{ color: active ? 'var(--brand)' : 'var(--text-dim)' }} />
              <span className="flex-1 text-[15px] font-medium">{meta.label}</span>
              <div
                style={{
                  width: 44, height: 26, borderRadius: 999,
                  background: active ? 'var(--brand)' : 'var(--surface-3)',
                  position: 'relative', transition: 'background .15s ease',
                }}
              >
                <div
                  style={{
                    position: 'absolute', top: 3, left: active ? 21 : 3,
                    width: 20, height: 20, borderRadius: 999, background: '#fff',
                    transition: 'left .15s ease',
                  }}
                />
              </div>
            </button>
          )
        })}
        <button className="btn btn-secondary btn-block mt-3" onClick={() => setSheet(null)}>
          <X size={16} /> Done
        </button>
      </Modal>
    </>
  )
}

function PaymentIcon({ method }: { method: PaymentMethod }) {
  const Icon = PAYMENTS.find((p) => p.value === method)!.icon
  return <Icon size={15} />
}

function MetaButton({
  icon,
  label,
  onClick,
}: {
  icon: React.ReactNode
  label: string
  onClick: () => void
}) {
  return (
    <button
      onClick={onClick}
      className="flex items-center gap-1.5 px-3 py-2.5 min-w-0 flex-1"
      style={{ background: 'var(--surface-2)', borderRadius: 12, color: 'var(--text)' }}
    >
      <span style={{ color: 'var(--text-dim)' }}>{icon}</span>
      <span className="text-[12.5px] font-semibold truncate">{label}</span>
    </button>
  )
}
