import type { Place } from '@/types'

/** Default map centre — Kuala Lumpur city centre. */
export const CITY_CENTER = { lat: 3.1478, lng: 101.6953 }
export const CITY_NAME = 'Kuala Lumpur'

/**
 * Offline place index. Search works with no network at all; when the device is
 * online the geocoder in `services/geocode.ts` layers live results on top.
 */
export const PLACES: Place[] = [
  { id: 'p_klcc', name: 'Suria KLCC', address: 'Jalan Ampang, Kuala Lumpur City Centre', coord: { lat: 3.1578, lng: 101.7123 }, category: 'mall' },
  { id: 'p_twin', name: 'Petronas Twin Towers', address: 'Kuala Lumpur City Centre', coord: { lat: 3.1579, lng: 101.7116 }, category: 'landmark' },
  { id: 'p_klia', name: 'KLIA Terminal 1', address: 'Kuala Lumpur International Airport, Sepang', coord: { lat: 2.7456, lng: 101.7099 }, category: 'airport' },
  { id: 'p_klia2', name: 'KLIA Terminal 2', address: 'KLIA2, Sepang', coord: { lat: 2.7426, lng: 101.6862 }, category: 'airport' },
  { id: 'p_subang', name: 'Sultan Abdul Aziz Shah Airport', address: 'Subang, Selangor', coord: { lat: 3.1304, lng: 101.5493 }, category: 'airport' },
  { id: 'p_sentral', name: 'KL Sentral', address: 'Jalan Stesen Sentral, Brickfields', coord: { lat: 3.1338, lng: 101.6869 }, category: 'transit' },
  { id: 'p_pavilion', name: 'Pavilion Kuala Lumpur', address: 'Jalan Bukit Bintang, Bukit Bintang', coord: { lat: 3.1490, lng: 101.7132 }, category: 'mall' },
  { id: 'p_bb', name: 'Bukit Bintang', address: 'Bukit Bintang, Kuala Lumpur', coord: { lat: 3.1466, lng: 101.7113 }, category: 'area' },
  { id: 'p_midvalley', name: 'Mid Valley Megamall', address: 'Lingkaran Syed Putra, Mid Valley City', coord: { lat: 3.1177, lng: 101.6771 }, category: 'mall' },
  { id: 'p_gardens', name: 'The Gardens Mall', address: 'Mid Valley City, Lingkaran Syed Putra', coord: { lat: 3.1183, lng: 101.6764 }, category: 'mall' },
  { id: 'p_bangsar', name: 'Bangsar Village', address: 'Jalan Telawi 1, Bangsar', coord: { lat: 3.1300, lng: 101.6700 }, category: 'mall' },
  { id: 'p_mont', name: 'Mont Kiara', address: 'Mont Kiara, Kuala Lumpur', coord: { lat: 3.1710, lng: 101.6500 }, category: 'area' },
  { id: 'p_ttdi', name: 'Taman Tun Dr Ismail', address: 'TTDI, Kuala Lumpur', coord: { lat: 3.1450, lng: 101.6300 }, category: 'area' },
  { id: 'p_damansara', name: 'The Curve, Mutiara Damansara', address: 'Jalan PJU 7/3, Petaling Jaya', coord: { lat: 3.1580, lng: 101.6110 }, category: 'mall' },
  { id: 'p_1u', name: '1 Utama Shopping Centre', address: 'Bandar Utama, Petaling Jaya', coord: { lat: 3.1502, lng: 101.6155 }, category: 'mall' },
  { id: 'p_sunway', name: 'Sunway Pyramid', address: 'Bandar Sunway, Subang Jaya', coord: { lat: 3.0726, lng: 101.6069 }, category: 'mall' },
  { id: 'p_pj', name: 'Petaling Jaya SS2', address: 'SS2, Petaling Jaya, Selangor', coord: { lat: 3.1180, lng: 101.6230 }, category: 'area' },
  { id: 'p_shah', name: 'Shah Alam i-City', address: 'Seksyen 7, Shah Alam', coord: { lat: 3.0640, lng: 101.4880 }, category: 'landmark' },
  { id: 'p_puchong', name: 'IOI Mall Puchong', address: 'Bandar Puchong Jaya, Puchong', coord: { lat: 3.0450, lng: 101.6180 }, category: 'mall' },
  { id: 'p_cheras', name: 'Cheras Leisure Mall', address: 'Taman Segar, Cheras', coord: { lat: 3.0930, lng: 101.7420 }, category: 'mall' },
  { id: 'p_ampang', name: 'Ampang Park', address: 'Jalan Ampang, Kuala Lumpur', coord: { lat: 3.1600, lng: 101.7180 }, category: 'transit' },
  { id: 'p_setapak', name: 'Wangsa Walk Mall', address: 'Wangsa Maju, Kuala Lumpur', coord: { lat: 3.2020, lng: 101.7350 }, category: 'mall' },
  { id: 'p_putrajaya', name: 'Putrajaya Sentral', address: 'Presint 7, Putrajaya', coord: { lat: 2.9310, lng: 101.6710 }, category: 'transit' },
  { id: 'p_cyber', name: 'Cyberjaya City Centre', address: 'Cyberjaya, Selangor', coord: { lat: 2.9210, lng: 101.6560 }, category: 'area' },
  { id: 'p_batu', name: 'Batu Caves', address: 'Gombak, Selangor', coord: { lat: 3.2379, lng: 101.6840 }, category: 'landmark' },
  { id: 'p_merdeka', name: 'Merdeka 118', address: 'Jalan Hang Jebat, Kuala Lumpur', coord: { lat: 3.1416, lng: 101.7009 }, category: 'landmark' },
  { id: 'p_masjid', name: 'Masjid Jamek', address: 'Jalan Tun Perak, Kuala Lumpur', coord: { lat: 3.1490, lng: 101.6960 }, category: 'transit' },
  { id: 'p_chinatown', name: 'Petaling Street', address: 'Chinatown, Kuala Lumpur', coord: { lat: 3.1436, lng: 101.6980 }, category: 'landmark' },
  { id: 'p_titiwangsa', name: 'Titiwangsa Lake Gardens', address: 'Titiwangsa, Kuala Lumpur', coord: { lat: 3.1780, lng: 101.7020 }, category: 'landmark' },
  { id: 'p_desapark', name: 'Desa ParkCity', address: 'Desa ParkCity, Kuala Lumpur', coord: { lat: 3.1870, lng: 101.6300 }, category: 'area' },
  { id: 'p_hospital', name: 'Hospital Kuala Lumpur', address: 'Jalan Pahang, Kuala Lumpur', coord: { lat: 3.1730, lng: 101.6990 }, category: 'landmark' },
  { id: 'p_um', name: 'Universiti Malaya', address: 'Jalan Universiti, Kuala Lumpur', coord: { lat: 3.1209, lng: 101.6538 }, category: 'landmark' },
  { id: 'p_ioicity', name: 'IOI City Mall', address: 'Putrajaya, Selangor', coord: { lat: 2.9690, lng: 101.7130 }, category: 'mall' },
  { id: 'p_klgateway', name: 'KL Gateway Mall', address: 'Kerinchi, Kuala Lumpur', coord: { lat: 3.1140, lng: 101.6640 }, category: 'mall' },
  { id: 'p_tbs', name: 'Terminal Bersepadu Selatan', address: 'Bandar Tasik Selatan, Kuala Lumpur', coord: { lat: 3.0760, lng: 101.7110 }, category: 'transit' },
  { id: 'p_bukitjalil', name: 'Bukit Jalil National Stadium', address: 'Bukit Jalil, Kuala Lumpur', coord: { lat: 3.0545, lng: 101.6913 }, category: 'landmark' },
  { id: 'p_pavilion2', name: 'Pavilion Bukit Jalil', address: 'Bukit Jalil, Kuala Lumpur', coord: { lat: 3.0590, lng: 101.6870 }, category: 'mall' },
  { id: 'p_setiawalk', name: 'SetiaWalk Puchong', address: 'Pusat Bandar Puchong', coord: { lat: 3.0230, lng: 101.6180 }, category: 'mall' },
  { id: 'p_klang', name: 'Klang Town Centre', address: 'Klang, Selangor', coord: { lat: 3.0450, lng: 101.4450 }, category: 'area' },
  { id: 'p_genting', name: 'Genting Highlands', address: 'Bentong, Pahang', coord: { lat: 3.4230, lng: 101.7930 }, category: 'landmark' },
]

/** Intercity destinations offered in the Intercity vertical. */
export const INTERCITY_PLACES: Place[] = [
  { id: 'ic_ipoh', name: 'Ipoh', address: 'Perak', coord: { lat: 4.5975, lng: 101.0901 }, category: 'area' },
  { id: 'ic_penang', name: 'George Town, Penang', address: 'Pulau Pinang', coord: { lat: 5.4141, lng: 100.3288 }, category: 'area' },
  { id: 'ic_melaka', name: 'Melaka', address: 'Melaka', coord: { lat: 2.1896, lng: 102.2501 }, category: 'area' },
  { id: 'ic_jb', name: 'Johor Bahru', address: 'Johor', coord: { lat: 1.4927, lng: 103.7414 }, category: 'area' },
  { id: 'ic_seremban', name: 'Seremban', address: 'Negeri Sembilan', coord: { lat: 2.7297, lng: 101.9381 }, category: 'area' },
  { id: 'ic_kuantan', name: 'Kuantan', address: 'Pahang', coord: { lat: 3.8077, lng: 103.3260 }, category: 'area' },
  { id: 'ic_cameron', name: 'Cameron Highlands', address: 'Pahang', coord: { lat: 4.4711, lng: 101.3776 }, category: 'area' },
]

export const ALL_PLACES = [...PLACES, ...INTERCITY_PLACES]

/** Street names used to synthesise "dropped pin" addresses. */
export const STREETS = [
  'Jalan Ampang', 'Jalan Sultan Ismail', 'Jalan Raja Chulan', 'Jalan Tun Razak',
  'Jalan Bukit Bintang', 'Jalan Imbi', 'Jalan Pudu', 'Jalan Kuching',
  'Jalan Ipoh', 'Jalan Cheras', 'Jalan Klang Lama', 'Jalan Duta',
  'Persiaran KLCC', 'Lebuh Ampang', 'Jalan Sultan Hishamuddin', 'Jalan Damansara',
]

export function fuzzySearch(query: string, pool: Place[] = ALL_PLACES, limit = 8): Place[] {
  const q = query.trim().toLowerCase()
  if (!q) return []
  const scored = pool
    .map((place) => {
      const name = place.name.toLowerCase()
      const address = place.address.toLowerCase()
      let score = 0
      if (name.startsWith(q)) score += 100
      else if (name.includes(q)) score += 60
      if (address.includes(q)) score += 25
      // Match on individual words so "mid valley" finds "Mid Valley Megamall".
      const words = q.split(/\s+/)
      if (words.length > 1 && words.every((w) => name.includes(w) || address.includes(w))) score += 40
      return { place, score }
    })
    .filter((s) => s.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, limit)
  return scored.map((s) => s.place)
}
