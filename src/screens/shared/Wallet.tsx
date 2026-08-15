import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ArrowUpRight, ArrowDownRight, CreditCard, Plus, Receipt } from 'lucide-react'
import type { Transaction } from '@/types'
import { useSession } from '@/store/session'
import { useRides } from '@/store/rides'
import { money, timeAgo } from '@/lib/format'
import { TopBar, Modal, EmptyState, Banner } from '@/components/ui'

const TOPUPS = [1000, 2000, 5000, 10000]

export default function Wallet() {
  const navigate = useNavigate()
  const user = useSession((s) => s.user)!
  const creditWallet = useSession((s) => s.creditWallet)
  const transactions = useRides((s) => s.transactions)
  const addTransaction = useRides((s) => s.addTransaction)
  const [topup, setTopup] = useState(false)

  const doTopup = (amount: number) => {
    creditWallet(amount)
    addTransaction({ kind: 'topup', amount, description: 'Top-up from card ···4821' })
    setTopup(false)
  }

  return (
    <div className="h-full flex flex-col">
      <TopBar title="Wallet" onBack={() => navigate('/menu')} />

      <div className="flex-1 scroll-y px-4 pb-6">
        <div
          className="p-5 my-3"
          style={{
            borderRadius: 20,
            background: 'linear-gradient(135deg, var(--brand) 0%, #8fc400 100%)',
            color: 'var(--brand-ink)',
          }}
        >
          <div className="text-[12px] font-bold uppercase tracking-wider opacity-70">Balance</div>
          <div className="text-[36px] font-extrabold tabular leading-none mt-1.5">
            {money(user.walletBalance)}
          </div>
          <div className="text-[13px] mt-2 opacity-75">{user.name}</div>
        </div>

        <div className="flex gap-2 mb-5">
          <button className="btn btn-secondary flex-1" onClick={() => setTopup(true)}>
            <Plus size={17} /> Top up
          </button>
          <button className="btn btn-secondary flex-1" onClick={() => navigate('/promos')}>
            <Receipt size={17} /> Promos
          </button>
        </div>

        <div className="label-xs mb-2">Payment methods</div>
        <div className="card overflow-hidden mb-5">
          <div className="flex items-center gap-3 px-4 py-3.5">
            <CreditCard size={18} style={{ color: 'var(--text-dim)' }} />
            <div className="flex-1">
              <div className="text-[14.5px] font-semibold">Visa ···4821</div>
              <div className="text-[12px]" style={{ color: 'var(--text-mute)' }}>
                Expires 09/28
              </div>
            </div>
            <span className="text-[12px] font-semibold" style={{ color: 'var(--brand)' }}>
              Default
            </span>
          </div>
        </div>

        <div className="label-xs mb-2">Activity</div>
        {transactions.length === 0 ? (
          <EmptyState title="No transactions yet" body="Rides, top-ups and payouts appear here." />
        ) : (
          <div className="card overflow-hidden">
            {transactions.map((tx, i) => (
              <TransactionRow key={tx.id} tx={tx} first={i === 0} />
            ))}
          </div>
        )}

        <div className="mt-4">
          <Banner tone="info">
            Cash trips are settled directly with the driver and don’t move your wallet balance.
          </Banner>
        </div>
      </div>

      <Modal open={topup} onClose={() => setTopup(false)} title="Top up your wallet">
        <p className="text-[13.5px] mb-4" style={{ color: 'var(--text-dim)' }}>
          Charged to Visa ···4821.
        </p>
        <div className="grid grid-cols-2 gap-2">
          {TOPUPS.map((amount) => (
            <button
              key={amount}
              className="py-4 text-[17px] font-extrabold tabular"
              style={{ background: 'var(--surface-2)', borderRadius: 14 }}
              onClick={() => doTopup(amount)}
            >
              {money(amount, { decimals: false })}
            </button>
          ))}
        </div>
      </Modal>
    </div>
  )
}

function TransactionRow({ tx, first }: { tx: Transaction; first: boolean }) {
  const positive = tx.amount > 0
  return (
    <div
      className="flex items-center gap-3 px-4 py-3.5"
      style={{ borderTop: first ? 'none' : '1px solid var(--line)' }}
    >
      <div
        className="flex items-center justify-center shrink-0"
        style={{
          width: 34, height: 34, borderRadius: 999,
          background: 'var(--surface-2)',
          color: positive ? 'var(--ok)' : 'var(--text-dim)',
        }}
      >
        {positive ? <ArrowDownRight size={16} /> : <ArrowUpRight size={16} />}
      </div>
      <div className="flex-1 min-w-0">
        <div className="text-[14px] font-semibold truncate">{tx.description}</div>
        <div className="text-[12px]" style={{ color: 'var(--text-mute)' }}>
          {timeAgo(tx.createdAt)}
        </div>
      </div>
      <div
        className="text-[14.5px] font-bold tabular shrink-0"
        style={{ color: positive ? 'var(--ok)' : 'var(--text)' }}
      >
        {positive ? '+' : '−'}
        {money(Math.abs(tx.amount))}
      </div>
    </div>
  )
}
