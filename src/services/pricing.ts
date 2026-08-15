import type { ServiceType, VehicleClass } from '@/types'
import { roundFare } from '@/lib/format'

/**
 * Fare recommendation. Unlike a metered service the number here is only an
 * anchor — the passenger is free to offer above or below it, and drivers are
 * free to counter. We surface how far an offer sits from the anchor so both
 * sides can judge whether a bid is realistic.
 */

type Tariff = { base: number; perKm: number; perMin: number; minimum: number }

/** Minor units (sen). Loosely calibrated to Klang Valley street pricing. */
const TARIFFS: Record<VehicleClass, Tariff> = {
  economy: { base: 300, perKm: 110, perMin: 18, minimum: 500 },
  comfort: { base: 450, perKm: 155, perMin: 25, minimum: 800 },
  xl: { base: 600, perKm: 200, perMin: 32, minimum: 1100 },
}

const SERVICE_MULTIPLIER: Record<ServiceType, number> = {
  city: 1,
  intercity: 0.85, // Cheaper per km — long highway legs, less stop-start.
  delivery: 0.75,
  freight: 1.6,
  moto: 0.5,
}

/** Peak-hour pressure. Not a surge charge — it just moves the anchor. */
export function demandFactor(at = new Date()): number {
  const hour = at.getHours()
  const day = at.getDay()
  const weekend = day === 0 || day === 6
  if (!weekend && ((hour >= 7 && hour < 10) || (hour >= 17 && hour < 20))) return 1.22
  if (hour >= 23 || hour < 5) return 1.15
  if (weekend && hour >= 18 && hour < 23) return 1.12
  return 1
}

export function recommendedPrice(input: {
  distanceKm: number
  durationMinutes: number
  vehicleClass: VehicleClass
  service: ServiceType
  at?: Date
}): number {
  const tariff = TARIFFS[input.vehicleClass]
  const raw =
    tariff.base + tariff.perKm * input.distanceKm + tariff.perMin * input.durationMinutes
  const adjusted = raw * SERVICE_MULTIPLIER[input.service] * demandFactor(input.at)
  return roundFare(Math.max(tariff.minimum, adjusted))
}

/** The slider range a passenger can pick from, centred on the recommendation. */
export function priceBounds(recommended: number) {
  return {
    min: roundFare(recommended * 0.6),
    max: roundFare(recommended * 2.2),
    step: 50,
  }
}

export type PriceVerdict = {
  /** -1 well below anchor … 0 at anchor … +1 well above. */
  ratio: number
  tone: 'low' | 'fair' | 'good' | 'high'
  label: string
  hint: string
}

/** Feedback shown live as the passenger drags the fare slider. */
export function judgePrice(price: number, recommended: number): PriceVerdict {
  const ratio = price / recommended - 1
  if (ratio < -0.18)
    return {
      ratio,
      tone: 'low',
      label: 'Below market',
      hint: 'Drivers may skip this. Expect a longer wait.',
    }
  if (ratio < 0.06)
    return {
      ratio,
      tone: 'fair',
      label: 'Fair price',
      hint: 'Around what drivers usually accept on this route.',
    }
  if (ratio < 0.3)
    return {
      ratio,
      tone: 'good',
      label: 'Great price',
      hint: 'Drivers respond quickly to offers like this.',
    }
  return {
    ratio,
    tone: 'high',
    label: 'Above market',
    hint: "You're offering more than this trip usually costs.",
  }
}

/** Suggested bumps shown when nobody has bid yet. */
export function raiseSuggestions(current: number): number[] {
  return [roundFare(current * 1.1), roundFare(current * 1.2), roundFare(current * 1.35)].filter(
    (v, i, arr) => v > current && arr.indexOf(v) === i,
  )
}

/**
 * The platform's cut. inDrive famously charges drivers a low commission
 * rather than taking a spread on the fare.
 */
export const COMMISSION_RATE = 0.099

export function driverNet(fare: number): number {
  return Math.round(fare * (1 - COMMISSION_RATE))
}

export function commissionOn(fare: number): number {
  return fare - driverNet(fare)
}
