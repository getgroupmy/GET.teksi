import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Check, ShieldCheck, Wallet, Clock } from 'lucide-react'
import type { VehicleClass } from '@/types'
import { useSession } from '@/store/session'
import { TopBar, Banner } from '@/components/ui'
import { COMMISSION_RATE } from '@/services/pricing'

const CLASS_OPTIONS: { value: VehicleClass; label: string; hint: string; seats: number }[] = [
  { value: 'economy', label: 'Economy', hint: 'Perodua, Proton, small sedans', seats: 4 },
  { value: 'comfort', label: 'Comfort', hint: 'Honda City, Toyota Vios and up', seats: 4 },
  { value: 'xl', label: 'XL', hint: 'MPVs and 7-seaters', seats: 7 },
]

export default function DriverOnboarding() {
  const navigate = useNavigate()
  const becomeDriver = useSession((s) => s.becomeDriver)
  const setPrefs = useSession((s) => s.setPrefs)

  const [step, setStep] = useState<'intro' | 'vehicle'>('intro')
  const [make, setMake] = useState('')
  const [model, setModel] = useState('')
  const [year, setYear] = useState('')
  const [color, setColor] = useState('')
  const [plate, setPlate] = useState('')
  const [vehicleClass, setVehicleClass] = useState<VehicleClass>('economy')

  const valid =
    make.trim().length >= 2 &&
    model.trim().length >= 1 &&
    plate.trim().length >= 4 &&
    Number(year) >= 2000 &&
    Number(year) <= new Date().getFullYear() + 1

  const finish = () => {
    if (!valid) return
    becomeDriver({
      make: make.trim(),
      model: model.trim(),
      year: Number(year),
      color: color.trim() || 'Silver',
      plate: plate.trim().toUpperCase(),
      vehicleClass,
      seats: CLASS_OPTIONS.find((c) => c.value === vehicleClass)!.seats,
    })
    setPrefs({ role: 'driver', driverOnline: true })
    navigate('/d', { replace: true })
  }

  if (step === 'intro') {
    return (
      <div className="h-full flex flex-col">
        <TopBar onBack={() => navigate('/p')} />
        <div className="flex-1 scroll-y px-5">
          <h1 className="text-[27px] font-extrabold leading-tight">Start earning with your car</h1>
          <p className="text-[14.5px] mt-2.5 leading-relaxed" style={{ color: 'var(--text-dim)' }}>
            See ride requests near you, choose the ones worth your time, and set your own price on
            every trip.
          </p>

          <div className="flex flex-col gap-3 mt-6">
            <Perk
              icon={<Wallet size={20} />}
              title={`Keep ${Math.round((1 - COMMISSION_RATE) * 100)}% of every fare`}
              body={`Our service fee is ${(COMMISSION_RATE * 100).toFixed(1)}% — no surge splits, no hidden cuts.`}
            />
            <Perk
              icon={<Clock size={20} />}
              title="Drive when you want"
              body="Go online and offline in one tap. There are no shifts and no quotas."
            />
            <Perk
              icon={<ShieldCheck size={20} />}
              title="You choose the order"
              body="See the destination and the fare before you accept anything."
            />
          </div>

          <div className="mt-6">
            <Banner tone="info">
              This build verifies documents automatically so you can try the driver side right away.
            </Banner>
          </div>
        </div>
        <div className="px-5" style={{ paddingBottom: 'calc(var(--safe-bottom) + 20px)' }}>
          <button className="btn btn-primary btn-block" onClick={() => setStep('vehicle')}>
            Continue
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="h-full flex flex-col">
      <TopBar title="Your vehicle" onBack={() => setStep('intro')} />
      <div className="flex-1 scroll-y px-5 pb-4">
        <div className="grid grid-cols-2 gap-3">
          <Field label="Make" value={make} onChange={setMake} placeholder="Perodua" autoFocus />
          <Field label="Model" value={model} onChange={setModel} placeholder="Myvi" />
          <Field label="Year" value={year} onChange={(v) => setYear(v.replace(/\D/g, '').slice(0, 4))} placeholder="2022" numeric />
          <Field label="Colour" value={color} onChange={setColor} placeholder="White" />
        </div>
        <div className="mt-3">
          <Field label="Plate number" value={plate} onChange={(v) => setPlate(v.toUpperCase())} placeholder="WXY 1234" />
        </div>

        <label className="label-xs block mt-6 mb-2">Vehicle category</label>
        <div className="flex flex-col gap-2">
          {CLASS_OPTIONS.map((c) => (
            <button
              key={c.value}
              className="flex items-center gap-3 px-4 py-3.5 text-left"
              style={{
                background: 'var(--surface-2)',
                borderRadius: 14,
                border: `1.5px solid ${vehicleClass === c.value ? 'var(--brand)' : 'transparent'}`,
              }}
              onClick={() => setVehicleClass(c.value)}
            >
              <div className="flex-1">
                <div className="text-[15px] font-semibold">{c.label}</div>
                <div className="text-[12.5px]" style={{ color: 'var(--text-dim)' }}>
                  {c.hint} · {c.seats} seats
                </div>
              </div>
              {vehicleClass === c.value && <Check size={18} style={{ color: 'var(--brand)' }} />}
            </button>
          ))}
        </div>
      </div>
      <div className="px-5" style={{ paddingBottom: 'calc(var(--safe-bottom) + 20px)' }}>
        <button className="btn btn-primary btn-block" disabled={!valid} onClick={finish}>
          Start driving
        </button>
      </div>
    </div>
  )
}

function Perk({ icon, title, body }: { icon: React.ReactNode; title: string; body: string }) {
  return (
    <div className="flex gap-3">
      <div
        className="flex items-center justify-center shrink-0"
        style={{
          width: 42, height: 42, borderRadius: 13,
          background: 'color-mix(in srgb, var(--brand) 14%, transparent)',
          color: 'var(--brand)',
        }}
      >
        {icon}
      </div>
      <div>
        <div className="text-[15px] font-bold">{title}</div>
        <div className="text-[13px] leading-snug" style={{ color: 'var(--text-dim)' }}>
          {body}
        </div>
      </div>
    </div>
  )
}

function Field({
  label,
  value,
  onChange,
  placeholder,
  numeric,
  autoFocus,
}: {
  label: string
  value: string
  onChange: (v: string) => void
  placeholder: string
  numeric?: boolean
  autoFocus?: boolean
}) {
  return (
    <div>
      <label className="label-xs block mb-1.5">{label}</label>
      <input
        className="input"
        style={{ padding: '12px 14px', fontSize: 15 }}
        value={value}
        autoFocus={autoFocus}
        inputMode={numeric ? 'numeric' : undefined}
        placeholder={placeholder}
        onChange={(e) => onChange(e.target.value)}
      />
    </div>
  )
}
