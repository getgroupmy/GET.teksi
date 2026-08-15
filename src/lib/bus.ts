import type { BusEvent } from '@/types'

/**
 * Realtime fan-out between tabs. Open the app twice — passenger in one tab,
 * driver in the other — and orders, bids and location pings flow between them
 * with no server. Falls back to a same-tab emitter where BroadcastChannel is
 * unavailable.
 */

type Handler = (event: BusEvent) => void

const CHANNEL = 'getteksi:bus'

class Bus {
  private channel: BroadcastChannel | null = null
  private handlers = new Set<Handler>()

  constructor() {
    if (typeof BroadcastChannel !== 'undefined') {
      this.channel = new BroadcastChannel(CHANNEL)
      this.channel.onmessage = (e: MessageEvent<BusEvent>) => this.dispatch(e.data)
    }
  }

  /** Publishes to other tabs *and* to local subscribers. */
  emit(event: BusEvent): void {
    this.channel?.postMessage(event)
    this.dispatch(event)
  }

  /** Publishes to other tabs only — used when the sender already applied it. */
  emitRemote(event: BusEvent): void {
    this.channel?.postMessage(event)
  }

  subscribe(handler: Handler): () => void {
    this.handlers.add(handler)
    return () => {
      this.handlers.delete(handler)
    }
  }

  private dispatch(event: BusEvent) {
    this.handlers.forEach((h) => {
      try {
        h(event)
      } catch (err) {
        console.error('[bus] handler failed', err)
      }
    })
  }
}

export const bus = new Bus()
