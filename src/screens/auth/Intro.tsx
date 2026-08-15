import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ChevronRight, HandCoins, Users, ShieldCheck } from 'lucide-react'
import { useSession } from '@/store/session'

const SLIDES = [
  {
    icon: HandCoins,
    title: 'Name your own fare',
    body: 'No fixed meter, no surge. You say what the trip is worth, drivers reply with their price.',
  },
  {
    icon: Users,
    title: 'Ride and drive in one app',
    body: 'Switch between passenger and driver whenever you like. One profile, one wallet, one history.',
  },
  {
    icon: ShieldCheck,
    title: 'Safety built in',
    body: 'Share your trip, call for help, and see every driver’s rating before you accept a price.',
  },
]

export default function Intro() {
  const [index, setIndex] = useState(0)
  const navigate = useNavigate()
  const setPrefs = useSession((s) => s.setPrefs)
  const slide = SLIDES[index]
  const Icon = slide.icon
  const last = index === SLIDES.length - 1

  const finish = () => {
    setPrefs({ hasSeenIntro: true })
    navigate('/auth/phone')
  }

  return (
    <div className="h-full flex flex-col px-6" style={{ paddingTop: 'calc(var(--safe-top) + 28px)' }}>
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <svg width="26" height="26" viewBox="0 0 24 24" aria-hidden>
            <path d="M12 2 21 21l-9-5.2L3 21 12 2Z" fill="var(--brand)" />
          </svg>
          <span className="font-extrabold text-[18px] tracking-tight">GET.teksi</span>
        </div>
        <button className="btn btn-ghost btn-sm" style={{ color: 'var(--text-dim)' }} onClick={finish}>
          Skip
        </button>
      </div>

      <div className="flex-1 flex flex-col items-center justify-center text-center gap-5 fade-in" key={index}>
        <div
          className="flex items-center justify-center"
          style={{
            width: 92,
            height: 92,
            borderRadius: 28,
            background: 'color-mix(in srgb, var(--brand) 15%, transparent)',
            color: 'var(--brand)',
          }}
        >
          <Icon size={42} />
        </div>
        <h2 className="text-[27px] font-extrabold leading-tight px-2">{slide.title}</h2>
        <p className="text-[15px] leading-relaxed px-2" style={{ color: 'var(--text-dim)' }}>
          {slide.body}
        </p>
      </div>

      <div className="flex justify-center gap-2 mb-6">
        {SLIDES.map((_, i) => (
          <div
            key={i}
            style={{
              width: i === index ? 22 : 7,
              height: 7,
              borderRadius: 999,
              background: i === index ? 'var(--brand)' : 'var(--surface-3)',
              transition: 'width .2s ease',
            }}
          />
        ))}
      </div>

      <button
        className="btn btn-primary btn-block mb-4"
        style={{ marginBottom: 'calc(var(--safe-bottom) + 20px)' }}
        onClick={() => (last ? finish() : setIndex(index + 1))}
      >
        {last ? 'Get started' : 'Next'}
        <ChevronRight size={18} />
      </button>
    </div>
  )
}
