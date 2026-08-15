import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Car, FileText, BadgeCheck, TriangleAlert, Clock } from 'lucide-react'
import type { DriverDocument } from '@/types'
import { useSession } from '@/store/session'
import { TopBar, Modal, EmptyState, Banner } from '@/components/ui'

const STATUS_META: Record<DriverDocument['status'], { label: string; color: string; icon: typeof BadgeCheck }> = {
  approved: { label: 'Approved', color: 'var(--ok)', icon: BadgeCheck },
  pending: { label: 'In review', color: 'var(--warn)', icon: Clock },
  rejected: { label: 'Rejected', color: 'var(--danger)', icon: TriangleAlert },
  missing: { label: 'Not uploaded', color: 'var(--text-mute)', icon: FileText },
}

export default function DriverVehicle() {
  const navigate = useNavigate()
  const user = useSession((s) => s.user)!
  const updateVehicle = useSession((s) => s.updateVehicle)
  const profile = user.driverProfile

  const [editing, setEditing] = useState(false)
  const [plate, setPlate] = useState(profile?.vehicle.plate ?? '')
  const [color, setColor] = useState(profile?.vehicle.color ?? '')

  if (!profile) {
    return (
      <div className="h-full flex flex-col">
        <TopBar title="Vehicle" onBack={() => navigate('/menu')} />
        <EmptyState
          title="You’re not a driver yet"
          body="Set up your vehicle to start receiving orders."
          action={
            <button className="btn btn-primary" onClick={() => navigate('/d/onboarding')}>
              Become a driver
            </button>
          }
        />
      </div>
    )
  }

  const { vehicle } = profile

  return (
    <div className="h-full flex flex-col">
      <TopBar title="Vehicle & documents" onBack={() => navigate('/menu')} />
      <div className="flex-1 scroll-y px-4 pb-6">
        <div className="card p-4 my-3">
          <div className="flex items-center gap-3">
            <div
              className="flex items-center justify-center shrink-0"
              style={{
                width: 52, height: 52, borderRadius: 15,
                background: 'color-mix(in srgb, var(--brand) 14%, transparent)',
                color: 'var(--brand)',
              }}
            >
              <Car size={24} />
            </div>
            <div className="flex-1 min-w-0">
              <div className="text-[17px] font-bold truncate">
                {vehicle.make} {vehicle.model}
              </div>
              <div className="text-[13px]" style={{ color: 'var(--text-dim)' }}>
                {vehicle.color} · {vehicle.year} · {vehicle.seats} seats
              </div>
            </div>
          </div>

          <div
            className="mt-3 py-2.5 text-center text-[17px] font-extrabold tabular"
            style={{ background: 'var(--surface-2)', borderRadius: 12, letterSpacing: '0.08em' }}
          >
            {vehicle.plate}
          </div>

          <div className="flex items-center justify-between mt-3 text-[13px]">
            <span style={{ color: 'var(--text-dim)' }}>Category</span>
            <span className="font-semibold">
              {vehicle.vehicleClass === 'xl' ? 'XL' : vehicle.vehicleClass === 'comfort' ? 'Comfort' : 'Economy'}
            </span>
          </div>

          <button className="btn btn-secondary btn-block btn-sm mt-3" onClick={() => setEditing(true)}>
            Edit details
          </button>
        </div>

        <div className="label-xs mb-2">Documents</div>
        <div className="card overflow-hidden mb-4">
          {profile.documents.map((doc, i) => {
            const meta = STATUS_META[doc.status]
            const Icon = meta.icon
            return (
              <div
                key={doc.id}
                className="flex items-center gap-3 px-4 py-3.5"
                style={{ borderTop: i === 0 ? 'none' : '1px solid var(--line)' }}
              >
                <FileText size={17} style={{ color: 'var(--text-dim)' }} />
                <div className="flex-1 min-w-0">
                  <div className="text-[14.5px] font-semibold truncate">{doc.label}</div>
                  {doc.expiresAt && (
                    <div className="text-[12px]" style={{ color: 'var(--text-mute)' }}>
                      Expires {new Date(doc.expiresAt).toLocaleDateString('en-MY', { month: 'short', year: 'numeric' })}
                    </div>
                  )}
                </div>
                <span
                  className="flex items-center gap-1 text-[12px] font-semibold shrink-0"
                  style={{ color: meta.color }}
                >
                  <Icon size={14} />
                  {meta.label}
                </span>
              </div>
            )
          })}
        </div>

        <Banner tone="info">
          Documents are verified automatically in this build. In production these would be reviewed
          against LPKP/APAD records before a driver can go online.
        </Banner>
      </div>

      <Modal
        open={editing}
        onClose={() => setEditing(false)}
        title="Edit vehicle"
        footer={
          <button
            className="btn btn-primary btn-block"
            onClick={() => {
              updateVehicle({ plate: plate.toUpperCase().trim(), color: color.trim() })
              setEditing(false)
            }}
          >
            Save changes
          </button>
        }
      >
        <label className="label-xs block mb-1.5">Plate number</label>
        <input className="input mb-4" value={plate} onChange={(e) => setPlate(e.target.value.toUpperCase())} />
        <label className="label-xs block mb-1.5">Colour</label>
        <input className="input" value={color} onChange={(e) => setColor(e.target.value)} />
      </Modal>
    </div>
  )
}
