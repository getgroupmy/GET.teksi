import { useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { ShieldAlert, PhoneCall, Share2, Flag, UserRound, Plus } from 'lucide-react'
import { useSession } from '@/store/session'
import { useRides } from '@/store/rides'
import { TopBar, Modal, Row, Banner } from '@/components/ui'
import { readJSON, writeJSON, uid } from '@/lib/storage'

type Contact = { id: string; name: string; phone: string }

/** Malaysian emergency line. */
const EMERGENCY_NUMBER = '999'

export default function Safety() {
  const navigate = useNavigate()
  const location = useLocation()
  const rideId = (location.state as { rideId?: string } | null)?.rideId
  const role = useSession((s) => s.prefs.role)
  const ride = useRides((s) => (rideId ? s.rides[rideId] : null))
  const notify = useRides((s) => s.notify)

  const [contacts, setContacts] = useState<Contact[]>(() => readJSON<Contact[]>('contacts', []))
  const [sos, setSos] = useState(false)
  const [adding, setAdding] = useState(false)
  const [report, setReport] = useState(false)
  const [name, setName] = useState('')
  const [phone, setPhone] = useState('')

  const persist = (next: Contact[]) => {
    setContacts(next)
    writeJSON('contacts', next)
  }

  const shareText = ride
    ? `SAFETY ALERT — I'm on a GET.teksi trip to ${ride.dropoff.name}. Driver ${ride.driverName ?? 'unknown'}, ${ride.driverVehicle?.plate ?? 'no plate'}. Ref ${ride.id.slice(-6).toUpperCase()}.`
    : 'SAFETY ALERT — please check on me.'

  return (
    <div className="h-full flex flex-col">
      <TopBar title="Safety centre" onBack={() => navigate(role === 'driver' ? '/d' : '/p')} />

      <div className="flex-1 scroll-y pb-6">
        <div className="px-4 pt-4">
          <button
            className="w-full flex items-center gap-3 px-4 py-4"
            style={{
              background: 'color-mix(in srgb, var(--danger) 14%, transparent)',
              border: '1px solid color-mix(in srgb, var(--danger) 35%, transparent)',
              borderRadius: 18,
              color: 'var(--danger)',
            }}
            onClick={() => setSos(true)}
          >
            <ShieldAlert size={26} />
            <div className="text-left">
              <div className="text-[16px] font-extrabold">Emergency SOS</div>
              <div className="text-[12.5px] opacity-80">Call {EMERGENCY_NUMBER} and alert your contacts</div>
            </div>
          </button>
        </div>

        {ride && (
          <div className="px-4 pt-4">
            <Banner tone="info">
              Active trip to {ride.dropoff.name}
              {ride.driverVehicle ? ` · ${ride.driverVehicle.plate}` : ''}. Your contacts can see these
              details when you share the trip.
            </Banner>
          </div>
        )}

        <div className="label-xs px-4 pt-5 pb-2">During a trip</div>
        <Row
          icon={<Share2 size={17} />}
          title="Share my trip"
          subtitle="Send live trip details to someone you trust"
          onClick={async () => {
            if (navigator.share) {
              try {
                await navigator.share({ text: shareText })
                return
              } catch {
                /* fall through */
              }
            }
            navigator.clipboard?.writeText(shareText)
          }}
        />
        <Row
          icon={<Flag size={17} />}
          title="Report a problem"
          subtitle="Driving, behaviour, route or payment"
          onClick={() => setReport(true)}
        />
        <Row
          icon={<PhoneCall size={17} />}
          title="24/7 support"
          subtitle="Talk to a GET.teksi agent"
          onClick={() => window.open('tel:+60312345678')}
        />

        <div className="flex items-center justify-between px-4 pt-5 pb-2">
          <span className="label-xs">Emergency contacts</span>
          <button
            className="text-[13px] font-semibold flex items-center gap-1"
            style={{ color: 'var(--brand)' }}
            onClick={() => setAdding(true)}
          >
            <Plus size={14} /> Add
          </button>
        </div>

        {contacts.length === 0 ? (
          <div className="px-4 text-[13.5px]" style={{ color: 'var(--text-dim)' }}>
            No contacts yet. Add someone who should be alerted if you press SOS.
          </div>
        ) : (
          contacts.map((c) => (
            <Row
              key={c.id}
              icon={<UserRound size={17} />}
              title={c.name}
              subtitle={c.phone}
              right={
                <button
                  className="text-[13px] font-semibold"
                  style={{ color: 'var(--danger)' }}
                  onClick={() => persist(contacts.filter((x) => x.id !== c.id))}
                >
                  Remove
                </button>
              }
            />
          ))
        )}
      </div>

      <Modal open={sos} onClose={() => setSos(false)} title="Emergency SOS">
        <p className="text-[13.5px] mb-4" style={{ color: 'var(--text-dim)' }}>
          We’ll open a call to {EMERGENCY_NUMBER} and copy your trip details so you can send them to
          your {contacts.length > 0 ? `${contacts.length} emergency contact(s)` : 'contacts'}.
        </p>
        <a
          className="btn btn-danger btn-block mb-2"
          href={`tel:${EMERGENCY_NUMBER}`}
          onClick={() => {
            navigator.clipboard?.writeText(shareText)
            notify({
              kind: 'safety',
              title: 'SOS triggered',
              body: 'Trip details copied. Support has been notified.',
              rideId: ride?.id,
            })
            setSos(false)
          }}
        >
          <PhoneCall size={17} /> Call {EMERGENCY_NUMBER}
        </a>
        <button className="btn btn-secondary btn-block" onClick={() => setSos(false)}>
          Cancel
        </button>
      </Modal>

      <Modal
        open={adding}
        onClose={() => setAdding(false)}
        title="Add emergency contact"
        footer={
          <button
            className="btn btn-primary btn-block"
            disabled={name.trim().length < 2 || phone.trim().length < 8}
            onClick={() => {
              persist([...contacts, { id: uid('ct'), name: name.trim(), phone: phone.trim() }])
              setName('')
              setPhone('')
              setAdding(false)
            }}
          >
            Save contact
          </button>
        }
      >
        <label className="label-xs block mb-1.5">Name</label>
        <input className="input mb-4" value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Mum" />
        <label className="label-xs block mb-1.5">Phone number</label>
        <input
          className="input"
          inputMode="tel"
          value={phone}
          onChange={(e) => setPhone(e.target.value)}
          placeholder="+60 12-345 6789"
        />
      </Modal>

      <Modal open={report} onClose={() => setReport(false)} title="Report a problem">
        {[
          'Unsafe driving',
          'Driver behaviour',
          'Wrong route taken',
          'Asked for extra payment',
          'Vehicle did not match',
          'Something else',
        ].map((reason) => (
          <button
            key={reason}
            className="w-full text-left py-3.5 text-[15px] font-medium"
            style={{ borderBottom: '1px solid var(--line)' }}
            onClick={() => {
              notify({
                kind: 'safety',
                title: 'Report submitted',
                body: `${reason} — our safety team will follow up within 24 hours.`,
                rideId: ride?.id,
              })
              setReport(false)
            }}
          >
            {reason}
          </button>
        ))}
      </Modal>
    </div>
  )
}
