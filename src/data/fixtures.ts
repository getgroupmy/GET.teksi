import type { PromoCode, Vehicle } from '@/types'

export const AVATAR_COLORS = [
  '#C1F11D', '#22D3EE', '#F472B6', '#FBBF24', '#A78BFA',
  '#34D399', '#FB923C', '#60A5FA', '#F87171', '#2DD4BF',
]

export function pickAvatarColor(seed: string): string {
  let hash = 0
  for (let i = 0; i < seed.length; i++) hash = (hash * 31 + seed.charCodeAt(i)) >>> 0
  return AVATAR_COLORS[hash % AVATAR_COLORS.length]
}

/** Names used for simulated drivers and passengers. */
export const DRIVER_NAMES = [
  'Ahmad Faizal', 'Siti Nurhaliza', 'Rajesh Kumar', 'Lim Wei Sheng', 'Nurul Aina',
  'Mohd Hafiz', 'Tan Mei Ling', 'Suresh Pillai', 'Zulkifli Hassan', 'Chong Kah Wai',
  'Farah Adila', 'Ganesh Raj', 'Aziz Rahman', 'Wong Li Ying', 'Kamarul Ariffin',
  'Priya Devi', 'Shahrul Nizam', 'Lee Chin Hock', 'Rosnah Ibrahim', 'Vijay Anand',
  'Amir Hamzah', 'Ng Sook Yee', 'Hafizah Yusof', 'Danish Iskandar', 'Meena Krishnan',
]

export const PASSENGER_NAMES = [
  'Aiman', 'Jia Hui', 'Kavitha', 'Haziq', 'Sarah', 'Wei Jie', 'Nabila',
  'Ramesh', 'Yusof', 'Michelle', 'Adam', 'Hui Min', 'Farid', 'Anitha', 'Zahra',
]

export const VEHICLES: Vehicle[] = [
  { make: 'Perodua', model: 'Bezza', year: 2021, color: 'Silver', plate: 'WXY 4412', vehicleClass: 'economy', seats: 4 },
  { make: 'Perodua', model: 'Myvi', year: 2022, color: 'White', plate: 'VBA 7781', vehicleClass: 'economy', seats: 4 },
  { make: 'Proton', model: 'Saga', year: 2020, color: 'Blue', plate: 'WPK 2290', vehicleClass: 'economy', seats: 4 },
  { make: 'Proton', model: 'Persona', year: 2022, color: 'Grey', plate: 'BQT 5530', vehicleClass: 'economy', seats: 4 },
  { make: 'Honda', model: 'City', year: 2021, color: 'Black', plate: 'WA 8812 C', vehicleClass: 'comfort', seats: 4 },
  { make: 'Toyota', model: 'Vios', year: 2023, color: 'White', plate: 'VGT 1188', vehicleClass: 'comfort', seats: 4 },
  { make: 'Honda', model: 'Civic', year: 2022, color: 'Red', plate: 'WNC 3344', vehicleClass: 'comfort', seats: 4 },
  { make: 'Toyota', model: 'Camry', year: 2023, color: 'Black', plate: 'WWW 9001', vehicleClass: 'comfort', seats: 4 },
  { make: 'Toyota', model: 'Innova', year: 2021, color: 'Silver', plate: 'BMD 6677', vehicleClass: 'xl', seats: 7 },
  { make: 'Perodua', model: 'Alza', year: 2023, color: 'Grey', plate: 'VFR 2255', vehicleClass: 'xl', seats: 7 },
  { make: 'Nissan', model: 'Serena', year: 2020, color: 'White', plate: 'WSN 4040', vehicleClass: 'xl', seats: 7 },
]

export const PROMO_CODES: PromoCode[] = [
  { code: 'TEKSI50', label: '50% off your next ride, up to RM10', percentOff: 50, expiresAt: Date.now() + 14 * 86_400_000 },
  { code: 'WELCOME5', label: 'RM5 off any trip', amountOff: 500, expiresAt: Date.now() + 30 * 86_400_000 },
  { code: 'KLIA15', label: 'RM15 off an airport transfer', amountOff: 1500, minSpend: 4000, expiresAt: Date.now() + 7 * 86_400_000 },
]

/** Tags offered after a ride, mirroring inDrive's post-trip rating sheet. */
export const RATING_TAGS_GOOD = [
  'Safe driving', 'Clean car', 'Polite', 'Good conversation', 'Knows the route',
  'On time', 'Helped with luggage', 'Comfortable ride',
]

export const RATING_TAGS_BAD = [
  'Rude behaviour', 'Dirty car', 'Unsafe driving', 'Late arrival',
  'Wrong route', 'Asked for more money', 'Bad smell', 'No air conditioning',
]

export const DRIVER_RATING_TAGS_GOOD = [
  'Polite passenger', 'On time', 'Clear pickup point', 'Good conversation', 'Left car clean',
]

export const DRIVER_RATING_TAGS_BAD = [
  'Kept me waiting', 'Rude behaviour', 'Wrong pickup point', 'Too many passengers', 'Messy',
]

/** Canned chat lines, so neither side has to type while driving. */
export const QUICK_PHRASES_PASSENGER = [
  "I'm at the pickup point",
  'Give me 2 minutes please',
  "I'm wearing a blue shirt",
  'Which car are you in?',
  'Please call me when you arrive',
  'Thank you!',
]

export const QUICK_PHRASES_DRIVER = [
  "I'm on my way",
  "I've arrived, waiting outside",
  'Traffic is heavy, running 5 min late',
  'Where exactly should I stop?',
  'Please come out, I cannot wait here',
  'Thank you!',
]

export const CANCEL_REASONS_PASSENGER = [
  'Driver is taking too long',
  'Driver asked me to cancel',
  'I no longer need the ride',
  'Wrong pickup address',
  'Found another ride',
  'Price is too high',
]

export const CANCEL_REASONS_DRIVER = [
  'Passenger is not responding',
  'Passenger did not show up',
  'Pickup point is unreachable',
  'Too far from my location',
  'Vehicle problem',
  'Passenger asked to cancel',
]
