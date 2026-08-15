import 'package:latlong2/latlong.dart';

/// Core domain model for GET.teksi, shared by the passenger and driver sides.

LatLng _coordFromJson(Map<String, dynamic> json) =>
    LatLng((json['lat'] as num).toDouble(), (json['lng'] as num).toDouble());

Map<String, dynamic> coordToJson(LatLng c) => {
  'lat': c.latitude,
  'lng': c.longitude,
};

T _enumFrom<T extends Enum>(List<T> values, Object? raw, T fallback) {
  if (raw is! String) return fallback;
  for (final v in values) {
    if (v.name == raw) return v;
  }
  return fallback;
}

enum PlaceCategory { airport, mall, transit, landmark, area, recent, saved }

/// The service verticals the app exposes.
enum ServiceType { city, intercity, delivery, freight, moto }

enum VehicleClass { economy, comfort, xl }

enum PaymentMethod { cash, card, wallet }

enum Role { passenger, driver }

enum RideStatus {
  /// Passenger is composing the order (never persisted as an order).
  draft,

  /// Published; drivers may bid.
  searching,

  /// Passenger accepted an offer; driver is heading to pickup.
  accepted,
  arriving,
  waiting,
  inProgress,
  completed,
  cancelled,
}

enum CancelledBy { passenger, driver, system }

enum OfferStatus { pending, accepted, declined, expired, withdrawn }

enum RideOption {
  childSeat,
  pet,
  luggage,
  airCon,
  noSmoking,
  silentRide,
  femaleDriver,
}

enum DocumentKind { license, registration, insurance, psv, selfie }

enum DocumentStatus { missing, pending, approved, rejected }

enum NotificationKind { ride, promo, system, safety }

enum TransactionKind { ridePayment, rideEarning, topup, payout, tip, promo }

extension VehicleClassLabel on VehicleClass {
  String get label => switch (this) {
    VehicleClass.economy => 'Economy',
    VehicleClass.comfort => 'Comfort',
    VehicleClass.xl => 'XL',
  };
}

extension ServiceTypeLabel on ServiceType {
  String get label => switch (this) {
    ServiceType.city => 'City',
    ServiceType.intercity => 'Intercity',
    ServiceType.delivery => 'Delivery',
    ServiceType.freight => 'Freight',
    ServiceType.moto => 'Moto',
  };
}

extension PaymentMethodLabel on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.cash => 'Cash',
    PaymentMethod.card => 'Card ···4821',
    PaymentMethod.wallet => 'Wallet',
  };
}

extension RideOptionLabel on RideOption {
  String get label => switch (this) {
    RideOption.childSeat => 'Child seat',
    RideOption.pet => 'Travelling with a pet',
    RideOption.luggage => 'Large luggage',
    RideOption.airCon => 'Air conditioning',
    RideOption.noSmoking => 'Non-smoking car',
    RideOption.silentRide => 'Silent ride',
    RideOption.femaleDriver => 'Prefer a female driver',
  };
}

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.address,
    required this.coord,
    this.category = PlaceCategory.area,
  });

  final String id;
  final String name;
  final String address;
  final LatLng coord;
  final PlaceCategory category;

  Place copyWith({
    String? id,
    String? name,
    String? address,
    LatLng? coord,
    PlaceCategory? category,
  }) => Place(
    id: id ?? this.id,
    name: name ?? this.name,
    address: address ?? this.address,
    coord: coord ?? this.coord,
    category: category ?? this.category,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'coord': coordToJson(coord),
    'category': category.name,
  };

  factory Place.fromJson(Map<String, dynamic> json) => Place(
    id: json['id'] as String,
    name: json['name'] as String,
    address: json['address'] as String,
    coord: _coordFromJson(json['coord'] as Map<String, dynamic>),
    category: _enumFrom(
      PlaceCategory.values,
      json['category'],
      PlaceCategory.area,
    ),
  );
}

class Vehicle {
  const Vehicle({
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.plate,
    required this.vehicleClass,
    required this.seats,
  });

  final String make;
  final String model;
  final int year;
  final String color;
  final String plate;
  final VehicleClass vehicleClass;
  final int seats;

  String get describe => '$color $make $model';

  Vehicle copyWith({
    String? make,
    String? model,
    int? year,
    String? color,
    String? plate,
    VehicleClass? vehicleClass,
    int? seats,
  }) => Vehicle(
    make: make ?? this.make,
    model: model ?? this.model,
    year: year ?? this.year,
    color: color ?? this.color,
    plate: plate ?? this.plate,
    vehicleClass: vehicleClass ?? this.vehicleClass,
    seats: seats ?? this.seats,
  );

  Map<String, dynamic> toJson() => {
    'make': make,
    'model': model,
    'year': year,
    'color': color,
    'plate': plate,
    'vehicleClass': vehicleClass.name,
    'seats': seats,
  };

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
    make: json['make'] as String,
    model: json['model'] as String,
    year: json['year'] as int,
    color: json['color'] as String,
    plate: json['plate'] as String,
    vehicleClass: _enumFrom(
      VehicleClass.values,
      json['vehicleClass'],
      VehicleClass.economy,
    ),
    seats: json['seats'] as int? ?? 4,
  );
}

class DriverDocument {
  const DriverDocument({
    required this.id,
    required this.kind,
    required this.label,
    required this.status,
    this.expiresAt,
  });

  final String id;
  final DocumentKind kind;
  final String label;
  final DocumentStatus status;
  final DateTime? expiresAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'label': label,
    'status': status.name,
    'expiresAt': expiresAt?.millisecondsSinceEpoch,
  };

  factory DriverDocument.fromJson(Map<String, dynamic> json) => DriverDocument(
    id: json['id'] as String,
    kind: _enumFrom(DocumentKind.values, json['kind'], DocumentKind.license),
    label: json['label'] as String,
    status: _enumFrom(
      DocumentStatus.values,
      json['status'],
      DocumentStatus.missing,
    ),
    expiresAt: json['expiresAt'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] as int),
  );
}

class DriverProfile {
  const DriverProfile({
    required this.vehicle,
    required this.rating,
    required this.ridesGiven,
    required this.earnings,
    required this.verified,
    required this.documents,
    required this.joinedAt,
  });

  final Vehicle vehicle;
  final double rating;
  final int ridesGiven;

  /// Lifetime net earnings, in sen.
  final int earnings;
  final bool verified;
  final List<DriverDocument> documents;
  final DateTime joinedAt;

  DriverProfile copyWith({
    Vehicle? vehicle,
    double? rating,
    int? ridesGiven,
    int? earnings,
    bool? verified,
    List<DriverDocument>? documents,
  }) => DriverProfile(
    vehicle: vehicle ?? this.vehicle,
    rating: rating ?? this.rating,
    ridesGiven: ridesGiven ?? this.ridesGiven,
    earnings: earnings ?? this.earnings,
    verified: verified ?? this.verified,
    documents: documents ?? this.documents,
    joinedAt: joinedAt,
  );

  Map<String, dynamic> toJson() => {
    'vehicle': vehicle.toJson(),
    'rating': rating,
    'ridesGiven': ridesGiven,
    'earnings': earnings,
    'verified': verified,
    'documents': documents.map((d) => d.toJson()).toList(),
    'joinedAt': joinedAt.millisecondsSinceEpoch,
  };

  factory DriverProfile.fromJson(Map<String, dynamic> json) => DriverProfile(
    vehicle: Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>),
    rating: (json['rating'] as num).toDouble(),
    ridesGiven: json['ridesGiven'] as int,
    earnings: json['earnings'] as int,
    verified: json['verified'] as bool? ?? true,
    documents: (json['documents'] as List<dynamic>? ?? [])
        .map((d) => DriverDocument.fromJson(d as Map<String, dynamic>))
        .toList(),
    joinedAt: DateTime.fromMillisecondsSinceEpoch(json['joinedAt'] as int),
  );
}

class AppUser {
  const AppUser({
    required this.id,
    required this.phone,
    required this.name,
    required this.avatarColor,
    required this.createdAt,
    required this.rating,
    required this.ridesTaken,
    required this.walletBalance,
    this.email,
    this.driverProfile,
    this.homePlace,
    this.workPlace,
  });

  final String id;
  final String phone;
  final String name;
  final String? email;

  /// Stored as an ARGB int so it survives a JSON round-trip.
  final int avatarColor;
  final DateTime createdAt;
  final double rating;
  final int ridesTaken;
  final int walletBalance;
  final DriverProfile? driverProfile;
  final Place? homePlace;
  final Place? workPlace;

  bool get isDriver => driverProfile != null;

  AppUser copyWith({
    String? name,
    String? email,
    double? rating,
    int? ridesTaken,
    int? walletBalance,
    DriverProfile? driverProfile,
    Place? homePlace,
    Place? workPlace,
    bool clearHome = false,
    bool clearWork = false,
  }) => AppUser(
    id: id,
    phone: phone,
    name: name ?? this.name,
    email: email ?? this.email,
    avatarColor: avatarColor,
    createdAt: createdAt,
    rating: rating ?? this.rating,
    ridesTaken: ridesTaken ?? this.ridesTaken,
    walletBalance: walletBalance ?? this.walletBalance,
    driverProfile: driverProfile ?? this.driverProfile,
    homePlace: clearHome ? null : (homePlace ?? this.homePlace),
    workPlace: clearWork ? null : (workPlace ?? this.workPlace),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'name': name,
    'email': email,
    'avatarColor': avatarColor,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'rating': rating,
    'ridesTaken': ridesTaken,
    'walletBalance': walletBalance,
    'driverProfile': driverProfile?.toJson(),
    'homePlace': homePlace?.toJson(),
    'workPlace': workPlace?.toJson(),
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    phone: json['phone'] as String,
    name: json['name'] as String,
    email: json['email'] as String?,
    avatarColor: json['avatarColor'] as int,
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    rating: (json['rating'] as num).toDouble(),
    ridesTaken: json['ridesTaken'] as int,
    walletBalance: json['walletBalance'] as int,
    driverProfile: json['driverProfile'] == null
        ? null
        : DriverProfile.fromJson(json['driverProfile'] as Map<String, dynamic>),
    homePlace: json['homePlace'] == null
        ? null
        : Place.fromJson(json['homePlace'] as Map<String, dynamic>),
    workPlace: json['workPlace'] == null
        ? null
        : Place.fromJson(json['workPlace'] as Map<String, dynamic>),
  );
}

/// A driver visible on the map. Bot drivers come from the simulation engine.
class NearbyDriver {
  NearbyDriver({
    required this.id,
    required this.name,
    required this.avatarColor,
    required this.rating,
    required this.ridesGiven,
    required this.vehicle,
    required this.coord,
    required this.bearing,
    this.isBot = true,
  });

  final String id;
  final String name;
  final int avatarColor;
  final double rating;
  final int ridesGiven;
  final Vehicle vehicle;
  LatLng coord;

  /// Heading in degrees, used to rotate the car marker.
  double bearing;
  final bool isBot;
}

/// A driver's bid on a ride request — the heart of the model.
class Offer {
  const Offer({
    required this.id,
    required this.rideId,
    required this.driverId,
    required this.driverName,
    required this.driverAvatarColor,
    required this.driverRating,
    required this.driverRidesGiven,
    required this.vehicle,
    required this.price,
    required this.etaMinutes,
    required this.distanceKm,
    required this.createdAt,
    required this.expiresAt,
    required this.status,
    required this.matchedAskingPrice,
  });

  final String id;
  final String rideId;
  final String driverId;
  final String driverName;
  final int driverAvatarColor;
  final double driverRating;
  final int driverRidesGiven;
  final Vehicle vehicle;

  /// Bid amount in sen.
  final int price;
  final int etaMinutes;
  final double distanceKm;
  final DateTime createdAt;

  /// Bids auto-expire so a stale list never blocks the passenger.
  final DateTime expiresAt;
  final OfferStatus status;

  /// True when the driver took the passenger's asking price unchanged.
  final bool matchedAskingPrice;

  Offer copyWith({OfferStatus? status}) => Offer(
    id: id,
    rideId: rideId,
    driverId: driverId,
    driverName: driverName,
    driverAvatarColor: driverAvatarColor,
    driverRating: driverRating,
    driverRidesGiven: driverRidesGiven,
    vehicle: vehicle,
    price: price,
    etaMinutes: etaMinutes,
    distanceKm: distanceKm,
    createdAt: createdAt,
    expiresAt: expiresAt,
    status: status ?? this.status,
    matchedAskingPrice: matchedAskingPrice,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'rideId': rideId,
    'driverId': driverId,
    'driverName': driverName,
    'driverAvatarColor': driverAvatarColor,
    'driverRating': driverRating,
    'driverRidesGiven': driverRidesGiven,
    'vehicle': vehicle.toJson(),
    'price': price,
    'etaMinutes': etaMinutes,
    'distanceKm': distanceKm,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'expiresAt': expiresAt.millisecondsSinceEpoch,
    'status': status.name,
    'matchedAskingPrice': matchedAskingPrice,
  };

  factory Offer.fromJson(Map<String, dynamic> json) => Offer(
    id: json['id'] as String,
    rideId: json['rideId'] as String,
    driverId: json['driverId'] as String,
    driverName: json['driverName'] as String,
    driverAvatarColor: json['driverAvatarColor'] as int,
    driverRating: (json['driverRating'] as num).toDouble(),
    driverRidesGiven: json['driverRidesGiven'] as int,
    vehicle: Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>),
    price: json['price'] as int,
    etaMinutes: json['etaMinutes'] as int,
    distanceKm: (json['distanceKm'] as num).toDouble(),
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] as int),
    status: _enumFrom(OfferStatus.values, json['status'], OfferStatus.pending),
    matchedAskingPrice: json['matchedAskingPrice'] as bool? ?? false,
  );
}

class RideRating {
  const RideRating({
    required this.stars,
    required this.tags,
    required this.createdAt,
    this.comment,
  });

  final int stars;
  final List<String> tags;
  final String? comment;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'stars': stars,
    'tags': tags,
    'comment': comment,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory RideRating.fromJson(Map<String, dynamic> json) => RideRating(
    stars: json['stars'] as int,
    tags: (json['tags'] as List<dynamic>? ?? []).cast<String>(),
    comment: json['comment'] as String?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
  );
}

class Ride {
  Ride({
    required this.id,
    required this.passengerId,
    required this.passengerName,
    required this.passengerAvatarColor,
    required this.passengerRating,
    required this.service,
    required this.vehicleClass,
    required this.pickup,
    required this.dropoff,
    required this.askingPrice,
    required this.recommendedPrice,
    required this.distanceKm,
    required this.durationMinutes,
    required this.paymentMethod,
    required this.passengerCount,
    required this.options,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.priceRaises,
    this.stop,
    this.finalPrice,
    this.comment,
    this.driverId,
    this.driverName,
    this.driverAvatarColor,
    this.driverRating,
    this.driverVehicle,
    this.driverCoord,
    this.driverBearing,
    this.acceptedAt,
    this.arrivedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancelledBy,
    this.cancelReason,
    this.routeGeometry,
    this.ratingByPassenger,
    this.ratingByDriver,
    this.tip,
  });

  final String id;
  final String passengerId;
  final String passengerName;
  final int passengerAvatarColor;
  final double passengerRating;
  final ServiceType service;
  final VehicleClass vehicleClass;
  final Place pickup;
  final Place dropoff;
  final Place? stop;

  /// Passenger's asking fare in sen; rises with "raise price".
  final int askingPrice;

  /// What the ride settled at — the accepted offer's price.
  final int? finalPrice;
  final int recommendedPrice;
  final double distanceKm;
  final int durationMinutes;
  final PaymentMethod paymentMethod;
  final int passengerCount;
  final String? comment;
  final List<RideOption> options;
  final RideStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int priceRaises;

  final String? driverId;
  final String? driverName;
  final int? driverAvatarColor;
  final double? driverRating;
  final Vehicle? driverVehicle;
  final LatLng? driverCoord;
  final double? driverBearing;

  final DateTime? acceptedAt;
  final DateTime? arrivedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final CancelledBy? cancelledBy;
  final String? cancelReason;

  /// Route geometry from pickup to dropoff, for the map polyline.
  final List<LatLng>? routeGeometry;
  final RideRating? ratingByPassenger;
  final RideRating? ratingByDriver;
  final int? tip;

  int get fare => finalPrice ?? askingPrice;

  bool get isLive => const {
    RideStatus.searching,
    RideStatus.accepted,
    RideStatus.arriving,
    RideStatus.waiting,
    RideStatus.inProgress,
  }.contains(status);

  bool get isFinished =>
      status == RideStatus.completed || status == RideStatus.cancelled;

  Ride copyWith({
    int? askingPrice,
    int? finalPrice,
    RideStatus? status,
    DateTime? updatedAt,
    int? priceRaises,
    String? driverId,
    String? driverName,
    int? driverAvatarColor,
    double? driverRating,
    Vehicle? driverVehicle,
    LatLng? driverCoord,
    double? driverBearing,
    DateTime? acceptedAt,
    DateTime? arrivedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    CancelledBy? cancelledBy,
    String? cancelReason,
    List<LatLng>? routeGeometry,
    RideRating? ratingByPassenger,
    RideRating? ratingByDriver,
    int? tip,
  }) => Ride(
    id: id,
    passengerId: passengerId,
    passengerName: passengerName,
    passengerAvatarColor: passengerAvatarColor,
    passengerRating: passengerRating,
    service: service,
    vehicleClass: vehicleClass,
    pickup: pickup,
    dropoff: dropoff,
    stop: stop,
    askingPrice: askingPrice ?? this.askingPrice,
    finalPrice: finalPrice ?? this.finalPrice,
    recommendedPrice: recommendedPrice,
    distanceKm: distanceKm,
    durationMinutes: durationMinutes,
    paymentMethod: paymentMethod,
    passengerCount: passengerCount,
    comment: comment,
    options: options,
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
    priceRaises: priceRaises ?? this.priceRaises,
    driverId: driverId ?? this.driverId,
    driverName: driverName ?? this.driverName,
    driverAvatarColor: driverAvatarColor ?? this.driverAvatarColor,
    driverRating: driverRating ?? this.driverRating,
    driverVehicle: driverVehicle ?? this.driverVehicle,
    driverCoord: driverCoord ?? this.driverCoord,
    driverBearing: driverBearing ?? this.driverBearing,
    acceptedAt: acceptedAt ?? this.acceptedAt,
    arrivedAt: arrivedAt ?? this.arrivedAt,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt ?? this.completedAt,
    cancelledAt: cancelledAt ?? this.cancelledAt,
    cancelledBy: cancelledBy ?? this.cancelledBy,
    cancelReason: cancelReason ?? this.cancelReason,
    routeGeometry: routeGeometry ?? this.routeGeometry,
    ratingByPassenger: ratingByPassenger ?? this.ratingByPassenger,
    ratingByDriver: ratingByDriver ?? this.ratingByDriver,
    tip: tip ?? this.tip,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'passengerId': passengerId,
    'passengerName': passengerName,
    'passengerAvatarColor': passengerAvatarColor,
    'passengerRating': passengerRating,
    'service': service.name,
    'vehicleClass': vehicleClass.name,
    'pickup': pickup.toJson(),
    'dropoff': dropoff.toJson(),
    'stop': stop?.toJson(),
    'askingPrice': askingPrice,
    'finalPrice': finalPrice,
    'recommendedPrice': recommendedPrice,
    'distanceKm': distanceKm,
    'durationMinutes': durationMinutes,
    'paymentMethod': paymentMethod.name,
    'passengerCount': passengerCount,
    'comment': comment,
    'options': options.map((o) => o.name).toList(),
    'status': status.name,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'priceRaises': priceRaises,
    'driverId': driverId,
    'driverName': driverName,
    'driverAvatarColor': driverAvatarColor,
    'driverRating': driverRating,
    'driverVehicle': driverVehicle?.toJson(),
    'driverCoord': driverCoord == null ? null : coordToJson(driverCoord!),
    'driverBearing': driverBearing,
    'acceptedAt': acceptedAt?.millisecondsSinceEpoch,
    'arrivedAt': arrivedAt?.millisecondsSinceEpoch,
    'startedAt': startedAt?.millisecondsSinceEpoch,
    'completedAt': completedAt?.millisecondsSinceEpoch,
    'cancelledAt': cancelledAt?.millisecondsSinceEpoch,
    'cancelledBy': cancelledBy?.name,
    'cancelReason': cancelReason,
    'routeGeometry': routeGeometry?.map(coordToJson).toList(),
    'ratingByPassenger': ratingByPassenger?.toJson(),
    'ratingByDriver': ratingByDriver?.toJson(),
    'tip': tip,
  };

  factory Ride.fromJson(Map<String, dynamic> json) {
    DateTime? at(String key) => json[key] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(json[key] as int);
    return Ride(
      id: json['id'] as String,
      passengerId: json['passengerId'] as String,
      passengerName: json['passengerName'] as String,
      passengerAvatarColor: json['passengerAvatarColor'] as int,
      passengerRating: (json['passengerRating'] as num).toDouble(),
      service: _enumFrom(ServiceType.values, json['service'], ServiceType.city),
      vehicleClass: _enumFrom(
        VehicleClass.values,
        json['vehicleClass'],
        VehicleClass.economy,
      ),
      pickup: Place.fromJson(json['pickup'] as Map<String, dynamic>),
      dropoff: Place.fromJson(json['dropoff'] as Map<String, dynamic>),
      stop: json['stop'] == null
          ? null
          : Place.fromJson(json['stop'] as Map<String, dynamic>),
      askingPrice: json['askingPrice'] as int,
      finalPrice: json['finalPrice'] as int?,
      recommendedPrice: json['recommendedPrice'] as int,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      durationMinutes: json['durationMinutes'] as int,
      paymentMethod: _enumFrom(
        PaymentMethod.values,
        json['paymentMethod'],
        PaymentMethod.cash,
      ),
      passengerCount: json['passengerCount'] as int? ?? 1,
      comment: json['comment'] as String?,
      options: (json['options'] as List<dynamic>? ?? [])
          .map((o) => _enumFrom(RideOption.values, o, RideOption.luggage))
          .toList(),
      status: _enumFrom(
        RideStatus.values,
        json['status'],
        RideStatus.searching,
      ),
      createdAt: at('createdAt')!,
      updatedAt: at('updatedAt')!,
      priceRaises: json['priceRaises'] as int? ?? 0,
      driverId: json['driverId'] as String?,
      driverName: json['driverName'] as String?,
      driverAvatarColor: json['driverAvatarColor'] as int?,
      driverRating: (json['driverRating'] as num?)?.toDouble(),
      driverVehicle: json['driverVehicle'] == null
          ? null
          : Vehicle.fromJson(json['driverVehicle'] as Map<String, dynamic>),
      driverCoord: json['driverCoord'] == null
          ? null
          : _coordFromJson(json['driverCoord'] as Map<String, dynamic>),
      driverBearing: (json['driverBearing'] as num?)?.toDouble(),
      acceptedAt: at('acceptedAt'),
      arrivedAt: at('arrivedAt'),
      startedAt: at('startedAt'),
      completedAt: at('completedAt'),
      cancelledAt: at('cancelledAt'),
      cancelledBy: json['cancelledBy'] == null
          ? null
          : _enumFrom(
              CancelledBy.values,
              json['cancelledBy'],
              CancelledBy.system,
            ),
      cancelReason: json['cancelReason'] as String?,
      routeGeometry: (json['routeGeometry'] as List<dynamic>?)
          ?.map((c) => _coordFromJson(c as Map<String, dynamic>))
          .toList(),
      ratingByPassenger: json['ratingByPassenger'] == null
          ? null
          : RideRating.fromJson(
              json['ratingByPassenger'] as Map<String, dynamic>,
            ),
      ratingByDriver: json['ratingByDriver'] == null
          ? null
          : RideRating.fromJson(json['ratingByDriver'] as Map<String, dynamic>),
      tip: json['tip'] as int?,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.rideId,
    required this.from,
    required this.text,
    required this.createdAt,
    required this.read,
  });

  final String id;
  final String rideId;
  final Role from;
  final String text;
  final DateTime createdAt;
  final bool read;

  ChatMessage copyWith({bool? read}) => ChatMessage(
    id: id,
    rideId: rideId,
    from: from,
    text: text,
    createdAt: createdAt,
    read: read ?? this.read,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'rideId': rideId,
    'from': from.name,
    'text': text,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'read': read,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    rideId: json['rideId'] as String,
    from: _enumFrom(Role.values, json['from'], Role.passenger),
    text: json['text'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    read: json['read'] as bool? ?? false,
  );
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
    required this.kind,
    this.rideId,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final NotificationKind kind;
  final String? rideId;

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    title: title,
    body: body,
    createdAt: createdAt,
    read: read ?? this.read,
    kind: kind,
    rideId: rideId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'read': read,
    'kind': kind.name,
    'rideId': rideId,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          json['createdAt'] as int,
        ),
        read: json['read'] as bool? ?? false,
        kind: _enumFrom(
          NotificationKind.values,
          json['kind'],
          NotificationKind.system,
        ),
        rideId: json['rideId'] as String?,
      );
}

class PromoCode {
  const PromoCode({
    required this.code,
    required this.label,
    required this.expiresAt,
    this.percentOff,
    this.amountOff,
    this.minSpend,
  });

  final String code;
  final String label;
  final int? percentOff;
  final int? amountOff;
  final int? minSpend;
  final DateTime expiresAt;
}

class Txn {
  const Txn({
    required this.id,
    required this.kind,
    required this.amount,
    required this.description,
    required this.createdAt,
    this.rideId,
  });

  final String id;
  final TransactionKind kind;

  /// Signed, in sen: positive is money in, negative is money out.
  final int amount;
  final String description;
  final DateTime createdAt;
  final String? rideId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'amount': amount,
    'description': description,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'rideId': rideId,
  };

  factory Txn.fromJson(Map<String, dynamic> json) => Txn(
    id: json['id'] as String,
    kind: _enumFrom(
      TransactionKind.values,
      json['kind'],
      TransactionKind.ridePayment,
    ),
    amount: json['amount'] as int,
    description: json['description'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    rideId: json['rideId'] as String?,
  );
}
