import { create } from 'zustand'
import type { PaymentMethod, Place, RideOption, ServiceType, VehicleClass } from '@/types'
import { driveMinutes, roadDistanceKm } from '@/lib/geo'
import { recommendedPrice } from '@/services/pricing'

/**
 * The passenger's in-progress order. Kept apart from `rides` so an abandoned
 * composition never leaks into history.
 */

export type DraftStep = 'idle' | 'destination' | 'price'

type DraftState = {
  step: DraftStep
  service: ServiceType
  vehicleClass: VehicleClass
  pickup: Place | null
  dropoff: Place | null
  stop: Place | null
  price: number
  paymentMethod: PaymentMethod
  passengerCount: number
  comment: string
  options: RideOption[]
  promoCode: string | null
  /** Which field the destination search is editing. */
  editing: 'pickup' | 'dropoff' | 'stop'

  setStep: (step: DraftStep) => void
  setService: (service: ServiceType) => void
  setVehicleClass: (vehicleClass: VehicleClass) => void
  setPickup: (place: Place | null) => void
  setDropoff: (place: Place | null) => void
  setStop: (place: Place | null) => void
  setEditing: (field: 'pickup' | 'dropoff' | 'stop') => void
  setPrice: (price: number) => void
  setPaymentMethod: (m: PaymentMethod) => void
  setPassengerCount: (n: number) => void
  setComment: (text: string) => void
  toggleOption: (option: RideOption) => void
  setPromoCode: (code: string | null) => void
  /** Recomputes the recommendation and snaps the price to it. */
  resetPriceToRecommended: () => void
  clear: () => void
}

const initial = {
  step: 'idle' as DraftStep,
  service: 'city' as ServiceType,
  vehicleClass: 'economy' as VehicleClass,
  pickup: null as Place | null,
  dropoff: null as Place | null,
  stop: null as Place | null,
  price: 0,
  paymentMethod: 'cash' as PaymentMethod,
  passengerCount: 1,
  comment: '',
  options: [] as RideOption[],
  promoCode: null as string | null,
  editing: 'dropoff' as 'pickup' | 'dropoff' | 'stop',
}

export const useDraft = create<DraftState>((set, get) => ({
  ...initial,

  setStep: (step) => set({ step }),
  setService: (service) => {
    set({ service })
    get().resetPriceToRecommended()
  },
  setVehicleClass: (vehicleClass) => {
    set({ vehicleClass })
    get().resetPriceToRecommended()
  },
  setPickup: (pickup) => {
    set({ pickup })
    get().resetPriceToRecommended()
  },
  setDropoff: (dropoff) => {
    set({ dropoff })
    get().resetPriceToRecommended()
  },
  setStop: (stop) => {
    set({ stop })
    get().resetPriceToRecommended()
  },
  setEditing: (editing) => set({ editing }),
  setPrice: (price) => set({ price }),
  setPaymentMethod: (paymentMethod) => set({ paymentMethod }),
  setPassengerCount: (passengerCount) => set({ passengerCount }),
  setComment: (comment) => set({ comment }),
  toggleOption: (option) =>
    set((s) => ({
      options: s.options.includes(option)
        ? s.options.filter((o) => o !== option)
        : [...s.options, option],
    })),
  setPromoCode: (promoCode) => set({ promoCode }),

  resetPriceToRecommended: () => {
    const trip = tripOf(get())
    if (!trip) return
    set({ price: trip.recommended })
  },

  clear: () => set({ ...initial }),
}))

export type TripEstimate = {
  distanceKm: number
  durationMinutes: number
  recommended: number
}

/** Distance/time/anchor for the current draft, or null until both ends are set. */
export function tripOf(draft: Pick<DraftState, 'pickup' | 'dropoff' | 'stop' | 'vehicleClass' | 'service'>): TripEstimate | null {
  if (!draft.pickup || !draft.dropoff) return null
  const legs = draft.stop
    ? roadDistanceKm(draft.pickup.coord, draft.stop.coord) +
      roadDistanceKm(draft.stop.coord, draft.dropoff.coord)
    : roadDistanceKm(draft.pickup.coord, draft.dropoff.coord)
  const distanceKm = Number(legs.toFixed(2))
  // A mid-route stop costs the driver a few minutes of waiting.
  const durationMinutes = driveMinutes(distanceKm) + (draft.stop ? 4 : 0)
  return {
    distanceKm,
    durationMinutes,
    recommended: recommendedPrice({
      distanceKm,
      durationMinutes,
      vehicleClass: draft.vehicleClass,
      service: draft.service,
    }),
  }
}
