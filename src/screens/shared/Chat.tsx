import { useEffect, useMemo, useRef, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Send, Phone } from 'lucide-react'
import { useSession } from '@/store/session'
import { useRides, selectChat } from '@/store/rides'
import { useShallow } from 'zustand/react/shallow'
import { clockTime } from '@/lib/format'
import { TopBar, Avatar, EmptyState } from '@/components/ui'
import { QUICK_PHRASES_DRIVER, QUICK_PHRASES_PASSENGER } from '@/data/fixtures'

export default function ChatScreen() {
  const { rideId = '' } = useParams()
  const navigate = useNavigate()
  const user = useSession((s) => s.user)!
  const role = useSession((s) => s.prefs.role)
  const ride = useRides((s) => s.rides[rideId])
  const messages = useRides(useShallow((s) => selectChat(s, rideId)))
  const sendMessage = useRides((s) => s.sendMessage)
  const markChatRead = useRides((s) => s.markChatRead)

  const [text, setText] = useState('')
  const endRef = useRef<HTMLDivElement>(null)

  // Whichever side of the ride I'm on decides who I'm talking to.
  const viewer = ride?.driverId === user.id ? 'driver' : ride?.passengerId === user.id ? 'passenger' : role

  useEffect(() => {
    markChatRead(rideId, viewer)
  }, [rideId, viewer, markChatRead, messages.length])

  useEffect(() => {
    endRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages.length])

  const other = useMemo(() => {
    if (!ride) return null
    return viewer === 'driver'
      ? { name: ride.passengerName, color: ride.passengerAvatarColor }
      : { name: ride.driverName ?? 'Driver', color: ride.driverAvatarColor ?? '#888' }
  }, [ride, viewer])

  if (!ride || !other) {
    return (
      <div className="h-full flex flex-col">
        <TopBar title="Chat" onBack={() => navigate(-1)} />
        <EmptyState title="Conversation unavailable" body="This ride no longer exists." />
      </div>
    )
  }

  const phrases = viewer === 'driver' ? QUICK_PHRASES_DRIVER : QUICK_PHRASES_PASSENGER

  const send = (value: string) => {
    const trimmed = value.trim()
    if (!trimmed) return
    sendMessage(rideId, viewer, trimmed)
    setText('')
  }

  return (
    <div className="h-full flex flex-col">
      <TopBar
        onBack={() => navigate(-1)}
        right={
          <a
            href={`tel:+60${ride.id.slice(-9)}`}
            className="flex items-center justify-center"
            style={{
              width: 38, height: 38, borderRadius: 999,
              background: 'var(--surface-2)', color: 'var(--brand)',
            }}
            aria-label="Call"
          >
            <Phone size={17} />
          </a>
        }
      />

      <div className="flex items-center gap-2.5 px-4 pb-3 -mt-2">
        <Avatar name={other.name} color={other.color} size={36} />
        <div className="min-w-0">
          <div className="text-[15px] font-bold truncate">{other.name}</div>
          <div className="text-[12px]" style={{ color: 'var(--text-dim)' }}>
            {viewer === 'driver' ? 'Passenger' : 'Your driver'} · trip to {ride.dropoff.name}
          </div>
        </div>
      </div>

      <div className="divider" />

      <div className="flex-1 scroll-y px-4 py-3 flex flex-col gap-2">
        {messages.length === 0 && (
          <div className="text-center text-[13px] py-6" style={{ color: 'var(--text-mute)' }}>
            Messages are only available during the trip.
          </div>
        )}
        {messages.map((m) => {
          const mine = m.from === viewer
          return (
            <div
              key={m.id}
              className="max-w-[80%] px-3.5 py-2.5 slide-in"
              style={{
                alignSelf: mine ? 'flex-end' : 'flex-start',
                background: mine ? 'var(--brand)' : 'var(--surface-2)',
                color: mine ? 'var(--brand-ink)' : 'var(--text)',
                borderRadius: 16,
                borderBottomRightRadius: mine ? 5 : 16,
                borderBottomLeftRadius: mine ? 16 : 5,
              }}
            >
              <div className="text-[14.5px] leading-snug">{m.text}</div>
              <div
                className="text-[10.5px] mt-1 tabular text-right"
                style={{ color: mine ? 'rgba(13,18,0,.55)' : 'var(--text-mute)' }}
              >
                {clockTime(m.createdAt)}
              </div>
            </div>
          )
        })}
        <div ref={endRef} />
      </div>

      <div className="scroll-x flex gap-2 px-4 pb-2">
        {phrases.map((p) => (
          <button key={p} className="chip" onClick={() => send(p)}>
            {p}
          </button>
        ))}
      </div>

      <div
        className="flex items-center gap-2 px-4 pt-2"
        style={{ borderTop: '1px solid var(--line)', paddingBottom: 'calc(var(--safe-bottom) + 12px)' }}
      >
        <input
          className="input"
          style={{ padding: '12px 16px' }}
          placeholder="Message…"
          value={text}
          onChange={(e) => setText(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && send(text)}
        />
        <button
          className="btn btn-primary shrink-0"
          style={{ width: 48, height: 48, padding: 0, borderRadius: 999 }}
          onClick={() => send(text)}
          disabled={!text.trim()}
          aria-label="Send"
        >
          <Send size={18} />
        </button>
      </div>
    </div>
  )
}
