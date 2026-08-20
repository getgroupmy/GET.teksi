import '../models/models.dart';

/// The demo card on file. One constant so the wallet screen, the payment
/// picker and the receipt all name the same card.
const demoCardTail = '···4821';
const demoCardName = 'Visa ···4821';

const avatarColors = <int>[
  0xFFC1F11D,
  0xFF22D3EE,
  0xFFF472B6,
  0xFFFBBF24,
  0xFFA78BFA,
  0xFF34D399,
  0xFFFB923C,
  0xFF60A5FA,
  0xFFF87171,
  0xFF2DD4BF,
];

int pickAvatarColor(String seed) {
  var hash = 0;
  for (final unit in seed.codeUnits) {
    hash = (hash * 31 + unit) & 0x7FFFFFFF;
  }
  return avatarColors[hash % avatarColors.length];
}

const driverNames = [
  'Ahmad Faizal',
  'Siti Nurhaliza',
  'Rajesh Kumar',
  'Lim Wei Sheng',
  'Nurul Aina',
  'Mohd Hafiz',
  'Tan Mei Ling',
  'Suresh Pillai',
  'Zulkifli Hassan',
  'Chong Kah Wai',
  'Farah Adila',
  'Ganesh Raj',
  'Aziz Rahman',
  'Wong Li Ying',
  'Kamarul Ariffin',
  'Priya Devi',
  'Shahrul Nizam',
  'Lee Chin Hock',
  'Rosnah Ibrahim',
  'Vijay Anand',
  'Amir Hamzah',
  'Ng Sook Yee',
  'Hafizah Yusof',
  'Danish Iskandar',
  'Meena Krishnan',
];

const passengerNames = [
  'Aiman',
  'Jia Hui',
  'Kavitha',
  'Haziq',
  'Sarah',
  'Wei Jie',
  'Nabila',
  'Ramesh',
  'Yusof',
  'Michelle',
  'Adam',
  'Hui Min',
  'Farid',
  'Anitha',
  'Zahra',
];

const vehicles = <Vehicle>[
  Vehicle(
    make: 'Perodua',
    model: 'Bezza',
    year: 2021,
    color: 'Silver',
    plate: 'WXY 4412',
    vehicleClass: VehicleClass.economy,
    seats: 4,
  ),
  Vehicle(
    make: 'Perodua',
    model: 'Myvi',
    year: 2022,
    color: 'White',
    plate: 'VBA 7781',
    vehicleClass: VehicleClass.economy,
    seats: 4,
  ),
  Vehicle(
    make: 'Proton',
    model: 'Saga',
    year: 2020,
    color: 'Blue',
    plate: 'WPK 2290',
    vehicleClass: VehicleClass.economy,
    seats: 4,
  ),
  Vehicle(
    make: 'Proton',
    model: 'Persona',
    year: 2022,
    color: 'Grey',
    plate: 'BQT 5530',
    vehicleClass: VehicleClass.economy,
    seats: 4,
  ),
  Vehicle(
    make: 'Honda',
    model: 'City',
    year: 2021,
    color: 'Black',
    plate: 'WA 8812 C',
    vehicleClass: VehicleClass.comfort,
    seats: 4,
  ),
  Vehicle(
    make: 'Toyota',
    model: 'Vios',
    year: 2023,
    color: 'White',
    plate: 'VGT 1188',
    vehicleClass: VehicleClass.comfort,
    seats: 4,
  ),
  Vehicle(
    make: 'Honda',
    model: 'Civic',
    year: 2022,
    color: 'Red',
    plate: 'WNC 3344',
    vehicleClass: VehicleClass.comfort,
    seats: 4,
  ),
  Vehicle(
    make: 'Toyota',
    model: 'Camry',
    year: 2023,
    color: 'Black',
    plate: 'WWW 9001',
    vehicleClass: VehicleClass.comfort,
    seats: 4,
  ),
  Vehicle(
    make: 'Toyota',
    model: 'Innova',
    year: 2021,
    color: 'Silver',
    plate: 'BMD 6677',
    vehicleClass: VehicleClass.xl,
    seats: 7,
  ),
  Vehicle(
    make: 'Perodua',
    model: 'Alza',
    year: 2023,
    color: 'Grey',
    plate: 'VFR 2255',
    vehicleClass: VehicleClass.xl,
    seats: 7,
  ),
  Vehicle(
    make: 'Nissan',
    model: 'Serena',
    year: 2020,
    color: 'White',
    plate: 'WSN 4040',
    vehicleClass: VehicleClass.xl,
    seats: 7,
  ),
];

List<PromoCode> promoCodes() => [
  PromoCode(
    code: 'TEKSI50',
    label: '50% off your next ride, up to RM10',
    percentOff: 50,
    expiresAt: DateTime.now().add(const Duration(days: 14)),
  ),
  PromoCode(
    code: 'WELCOME5',
    label: 'RM5 off any trip',
    amountOff: 500,
    expiresAt: DateTime.now().add(const Duration(days: 30)),
  ),
  PromoCode(
    code: 'KLIA15',
    label: 'RM15 off an airport transfer',
    amountOff: 1500,
    minSpend: 4000,
    expiresAt: DateTime.now().add(const Duration(days: 7)),
  ),
];

/// Tags offered after a ride.
const ratingTagsGood = [
  'Safe driving',
  'Clean car',
  'Polite',
  'Good conversation',
  'Knows the route',
  'On time',
  'Helped with luggage',
  'Comfortable ride',
];

const ratingTagsBad = [
  'Rude behaviour',
  'Dirty car',
  'Unsafe driving',
  'Late arrival',
  'Wrong route',
  'Asked for more money',
  'Bad smell',
  'No air conditioning',
];

const driverRatingTagsGood = [
  'Polite passenger',
  'On time',
  'Clear pickup point',
  'Good conversation',
  'Left car clean',
];

const driverRatingTagsBad = [
  'Kept me waiting',
  'Rude behaviour',
  'Wrong pickup point',
  'Too many passengers',
  'Messy',
];

/// Canned chat lines, so neither side has to type while driving.
const quickPhrasesPassenger = [
  "I'm at the pickup point",
  'Give me 2 minutes please',
  "I'm wearing a blue shirt",
  'Which car are you in?',
  'Please call me when you arrive',
  'Thank you!',
];

const quickPhrasesDriver = [
  "I'm on my way",
  "I've arrived, waiting outside",
  'Traffic is heavy, running 5 min late',
  'Where exactly should I stop?',
  'Please come out, I cannot wait here',
  'Thank you!',
];

const cancelReasonsPassenger = [
  'Driver is taking too long',
  'Driver asked me to cancel',
  'I no longer need the ride',
  'Wrong pickup address',
  'Found another ride',
  'Price is too high',
];

const cancelReasonsDriver = [
  'Passenger is not responding',
  'Passenger did not show up',
  'Pickup point is unreachable',
  'Too far from my location',
  'Vehicle problem',
  'Passenger asked to cancel',
];

const pickupNotes = [
  'At the lobby entrance',
  'Near the guard house',
  'I have one big luggage',
  'Please come to level 1 drop-off',
];
