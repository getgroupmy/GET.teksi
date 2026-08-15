import { type ReactNode, useEffect } from 'react'
import { Star, X, ChevronLeft } from 'lucide-react'
import { initials } from '@/lib/format'

export function Avatar({
  name,
  color,
  size = 44,
  ring,
}: {
  name: string
  color: string
  size?: number
  ring?: boolean
}) {
  return (
    <div
      className="flex items-center justify-center font-bold shrink-0"
      style={{
        width: size,
        height: size,
        borderRadius: 999,
        background: color,
        color: '#0b0d0c',
        fontSize: size * 0.36,
        boxShadow: ring ? '0 0 0 3px var(--surface), 0 0 0 5px var(--brand)' : undefined,
      }}
    >
      {initials(name)}
    </div>
  )
}

export function Rating({ value, size = 13 }: { value: number; size?: number }) {
  return (
    <span className="inline-flex items-center gap-1 tabular" style={{ fontSize: size }}>
      <Star size={size} fill="var(--brand)" color="var(--brand)" />
      <span style={{ color: 'var(--text-dim)', fontWeight: 600 }}>{value.toFixed(1)}</span>
    </span>
  )
}

export function Sheet({
  children,
  className = '',
  padded = true,
}: {
  children: ReactNode
  className?: string
  padded?: boolean
}) {
  return (
    <div className={`sheet ${className}`}>
      <div className="sheet-grabber" />
      <div className={`${padded ? 'px-4 pb-4 pt-1' : ''} scroll-y`}>{children}</div>
    </div>
  )
}

export function Modal({
  open,
  onClose,
  title,
  children,
  footer,
}: {
  open: boolean
  onClose: () => void
  title?: string
  children: ReactNode
  footer?: ReactNode
}) {
  useEffect(() => {
    if (!open) return
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && onClose()
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [open, onClose])

  if (!open) return null
  return (
    <>
      <div className="scrim" onClick={onClose} />
      <div className="sheet" style={{ zIndex: 30 }}>
        <div className="sheet-grabber" />
        <div className="px-4 pb-5 pt-1 scroll-y">
          {title && (
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-lg font-bold">{title}</h3>
              <button className="btn btn-ghost p-2" onClick={onClose} aria-label="Close">
                <X size={20} />
              </button>
            </div>
          )}
          {children}
          {footer && <div className="mt-4">{footer}</div>}
        </div>
      </div>
    </>
  )
}

export function TopBar({
  title,
  onBack,
  right,
  transparent,
}: {
  title?: string
  onBack?: () => void
  right?: ReactNode
  transparent?: boolean
}) {
  return (
    <div
      className="flex items-center gap-2 px-3 h-14 shrink-0"
      style={{
        background: transparent ? 'transparent' : 'var(--bg)',
        borderBottom: transparent ? 'none' : '1px solid var(--line)',
        paddingTop: 'var(--safe-top)',
      }}
    >
      {onBack && (
        <button
          onClick={onBack}
          aria-label="Back"
          className="flex items-center justify-center shrink-0"
          style={{
            width: 38,
            height: 38,
            borderRadius: 999,
            background: 'var(--surface-2)',
            border: '1px solid var(--line)',
            color: 'var(--text)',
          }}
        >
          <ChevronLeft size={20} />
        </button>
      )}
      {title && <h1 className="text-[17px] font-bold truncate flex-1">{title}</h1>}
      {!title && <div className="flex-1" />}
      {right}
    </div>
  )
}

/** Round floating button used for map controls. */
export function FabButton({
  icon,
  onClick,
  label,
  badge,
}: {
  icon: ReactNode
  onClick: () => void
  label: string
  badge?: number
}) {
  return (
    <button
      onClick={onClick}
      aria-label={badge ? `${label}, ${badge} unread` : label}
      className="relative flex items-center justify-center"
      style={{
        width: 42,
        height: 42,
        borderRadius: 999,
        background: 'var(--surface)',
        border: '1px solid var(--line)',
        color: 'var(--text)',
        boxShadow: '0 4px 14px rgba(0,0,0,.35)',
      }}
    >
      {icon}
      {badge != null && badge > 0 && (
        <span
          aria-hidden
          className="absolute -top-1 -right-1 flex items-center justify-center tabular"
          style={{
            minWidth: 18,
            height: 18,
            padding: '0 5px',
            borderRadius: 999,
            background: 'var(--danger)',
            color: '#fff',
            fontSize: 10,
            fontWeight: 700,
          }}
        >
          {badge > 9 ? '9+' : badge}
        </span>
      )}
    </button>
  )
}

export function EmptyState({
  icon,
  title,
  body,
  action,
}: {
  icon?: ReactNode
  title: string
  body?: string
  action?: ReactNode
}) {
  return (
    <div className="flex flex-col items-center text-center py-14 px-8 gap-2">
      {icon && <div style={{ color: 'var(--text-mute)' }}>{icon}</div>}
      <div className="font-bold text-[16px]">{title}</div>
      {body && (
        <div className="text-[14px]" style={{ color: 'var(--text-dim)' }}>
          {body}
        </div>
      )}
      {action && <div className="mt-3">{action}</div>}
    </div>
  )
}

export function Row({
  icon,
  title,
  subtitle,
  right,
  onClick,
  danger,
}: {
  icon?: ReactNode
  title: string
  subtitle?: string
  right?: ReactNode
  onClick?: () => void
  danger?: boolean
}) {
  const Tag = onClick ? 'button' : 'div'
  return (
    <Tag
      onClick={onClick}
      className="flex items-center gap-3 w-full text-left px-4 py-3.5"
      style={{ color: danger ? 'var(--danger)' : 'var(--text)' }}
    >
      {icon && (
        <div
          className="flex items-center justify-center shrink-0"
          style={{
            width: 36,
            height: 36,
            borderRadius: 11,
            background: 'var(--surface-2)',
            color: danger ? 'var(--danger)' : 'var(--text-dim)',
          }}
        >
          {icon}
        </div>
      )}
      <div className="flex-1 min-w-0">
        <div className="text-[15px] font-semibold truncate">{title}</div>
        {subtitle && (
          <div className="text-[13px] truncate" style={{ color: 'var(--text-dim)' }}>
            {subtitle}
          </div>
        )}
      </div>
      {right}
    </Tag>
  )
}

/** Pickup → dropoff timeline used on order cards. */
export function RouteStops({
  pickup,
  dropoff,
  stop,
  compact,
}: {
  pickup: string
  dropoff: string
  stop?: string
  compact?: boolean
}) {
  const dot = (color: string, square = false) => (
    <div
      style={{
        width: square ? 9 : 10,
        height: square ? 9 : 10,
        borderRadius: square ? 2 : 999,
        background: color,
        flexShrink: 0,
      }}
    />
  )
  return (
    <div className="flex gap-3">
      <div className="flex flex-col items-center pt-1.5" style={{ width: 10 }}>
        {dot('var(--brand)')}
        <div style={{ flex: 1, width: 2, background: 'var(--surface-3)', margin: '3px 0' }} />
        {stop && (
          <>
            {dot('var(--warn)', true)}
            <div style={{ flex: 1, width: 2, background: 'var(--surface-3)', margin: '3px 0' }} />
          </>
        )}
        {dot('var(--text)', true)}
      </div>
      <div className="flex-1 min-w-0 flex flex-col justify-between gap-2">
        <div className={`${compact ? 'text-[13px]' : 'text-[14px]'} font-semibold truncate`}>
          {pickup}
        </div>
        {stop && (
          <div className={`${compact ? 'text-[13px]' : 'text-[14px]'} truncate`} style={{ color: 'var(--text-dim)' }}>
            {stop}
          </div>
        )}
        <div className={`${compact ? 'text-[13px]' : 'text-[14px]'} font-semibold truncate`}>
          {dropoff}
        </div>
      </div>
    </div>
  )
}

export function Segmented<T extends string>({
  options,
  value,
  onChange,
}: {
  options: { value: T; label: string }[]
  value: T
  onChange: (v: T) => void
}) {
  return (
    <div
      className="flex p-1 gap-1"
      style={{ background: 'var(--surface-2)', borderRadius: 14 }}
    >
      {options.map((o) => (
        <button
          key={o.value}
          onClick={() => onChange(o.value)}
          className="flex-1 py-2.5 text-[14px] font-semibold"
          style={{
            borderRadius: 11,
            background: value === o.value ? 'var(--surface)' : 'transparent',
            color: value === o.value ? 'var(--text)' : 'var(--text-dim)',
            boxShadow: value === o.value ? '0 1px 4px rgba(0,0,0,.3)' : undefined,
          }}
        >
          {o.label}
        </button>
      ))}
    </div>
  )
}

export function StatBox({ label, value, tone }: { label: string; value: string; tone?: string }) {
  return (
    <div className="card p-3 flex-1">
      <div className="text-[19px] font-extrabold tabular" style={{ color: tone ?? 'var(--text)' }}>
        {value}
      </div>
      <div className="text-[12px] mt-0.5" style={{ color: 'var(--text-dim)' }}>
        {label}
      </div>
    </div>
  )
}

export function Banner({
  tone = 'info',
  children,
}: {
  tone?: 'info' | 'warn' | 'danger' | 'ok'
  children: ReactNode
}) {
  const color =
    tone === 'warn' ? 'var(--warn)' : tone === 'danger' ? 'var(--danger)' : tone === 'ok' ? 'var(--ok)' : 'var(--info)'
  return (
    <div
      className="text-[13px] px-3.5 py-3 rounded-xl leading-snug"
      style={{
        background: `color-mix(in srgb, ${color} 12%, transparent)`,
        color,
        border: `1px solid color-mix(in srgb, ${color} 28%, transparent)`,
      }}
    >
      {children}
    </div>
  )
}
