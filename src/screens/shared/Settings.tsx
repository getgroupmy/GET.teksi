import { useNavigate } from 'react-router-dom'
import { Moon, Sun, Volume2, Languages, Bot, Trash2, FileText, Info } from 'lucide-react'
import { useSession } from '@/store/session'
import { useRides } from '@/store/rides'
import { TopBar, Row, Banner } from '@/components/ui'
import { useState } from 'react'
import { Modal } from '@/components/ui'

export default function Settings() {
  const navigate = useNavigate()
  const prefs = useSession((s) => s.prefs)
  const setPrefs = useSession((s) => s.setPrefs)
  const reset = useRides((s) => s.reset)
  const [confirmClear, setConfirmClear] = useState(false)

  return (
    <div className="h-full flex flex-col">
      <TopBar title="Settings" onBack={() => navigate('/menu')} />

      <div className="flex-1 scroll-y pb-6">
        <div className="label-xs px-4 pt-4 pb-2">Appearance</div>
        <Row
          icon={prefs.theme === 'dark' ? <Moon size={17} /> : <Sun size={17} />}
          title="Dark theme"
          subtitle={prefs.theme === 'dark' ? 'On' : 'Off'}
          right={
            <Toggle
              on={prefs.theme === 'dark'}
              onChange={(on) => setPrefs({ theme: on ? 'dark' : 'light' })}
            />
          }
        />

        <div className="label-xs px-4 pt-4 pb-2">Preferences</div>
        <Row
          icon={<Languages size={17} />}
          title="Language"
          subtitle={prefs.language === 'en' ? 'English' : 'Bahasa Melayu'}
          onClick={() => setPrefs({ language: prefs.language === 'en' ? 'ms' : 'en' })}
        />
        <Row
          icon={<Volume2 size={17} />}
          title="Sounds and vibration"
          subtitle={prefs.soundEnabled ? 'On' : 'Off'}
          right={<Toggle on={prefs.soundEnabled} onChange={(on) => setPrefs({ soundEnabled: on })} />}
        />

        <div className="label-xs px-4 pt-4 pb-2">Demo</div>
        <Row
          icon={<Bot size={17} />}
          title="Simulated marketplace"
          subtitle="Bot drivers bid on your orders and bot passengers post rides"
          right={
            <Toggle
              on={prefs.simulationEnabled}
              onChange={(on) => setPrefs({ simulationEnabled: on })}
            />
          }
        />
        <div className="px-4 pt-2 pb-3">
          <Banner tone="info">
            Turn this off to run a real two-sided test. Open{' '}
            <span className="font-bold">?device=b</span> in a second tab — it signs in as a separate
            account on the same realtime channel — then put one tab in passenger mode and the other
            in driver mode. Orders, bids and messages flow between them live.
          </Banner>
        </div>

        <div className="label-xs px-4 pt-3 pb-2">About</div>
        <Row icon={<FileText size={17} />} title="Terms of service" />
        <Row icon={<FileText size={17} />} title="Privacy policy" />
        <Row icon={<Info size={17} />} title="Version" subtitle="GET.teksi 1.0.0" />
        <Row
          icon={<Trash2 size={17} />}
          title="Clear local data"
          subtitle="Erase rides, offers and messages on this device"
          danger
          onClick={() => setConfirmClear(true)}
        />
      </div>

      <Modal open={confirmClear} onClose={() => setConfirmClear(false)} title="Clear local data?">
        <p className="text-[13.5px] mb-4" style={{ color: 'var(--text-dim)' }}>
          This removes all rides, offers, messages and transactions stored in this browser. Your
          profile stays signed in.
        </p>
        <button
          className="btn btn-danger btn-block mb-2"
          onClick={() => {
            reset()
            setConfirmClear(false)
          }}
        >
          Clear everything
        </button>
        <button className="btn btn-secondary btn-block" onClick={() => setConfirmClear(false)}>
          Cancel
        </button>
      </Modal>
    </div>
  )
}

function Toggle({ on, onChange }: { on: boolean; onChange: (on: boolean) => void }) {
  return (
    <button
      onClick={() => onChange(!on)}
      role="switch"
      aria-checked={on}
      style={{
        width: 46, height: 27, borderRadius: 999,
        background: on ? 'var(--brand)' : 'var(--surface-3)',
        position: 'relative', transition: 'background .15s ease', flexShrink: 0,
      }}
    >
      <span
        style={{
          position: 'absolute', top: 3, left: on ? 22 : 3,
          width: 21, height: 21, borderRadius: 999, background: '#fff',
          transition: 'left .15s ease',
        }}
      />
    </button>
  )
}
