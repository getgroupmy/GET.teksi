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

// Rating tags, quick chat phrases, cancel reasons and promo copy used to sit
// here as const lists. They are user-visible sentences, not fixtures, so they
// live in lib/l10n/labels.dart now and are built from AppLocalizations.

const pickupNotes = [
  'At the lobby entrance',
  'Near the guard house',
  'I have one big luggage',
  'Please come to level 1 drop-off',
];
