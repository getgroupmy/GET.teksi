import '../data/fixtures.dart';
import '../models/models.dart';
import 'app_localizations.dart';

/// Display names for the domain enums.
///
/// These used to be `String get label` extensions on the enums themselves, in
/// models.dart. They cannot stay there now that they are translated: a label
/// depends on the locale, and the locale is only known from a context. Keeping
/// a context-free `label` alongside these would be worse than moving them —
/// it would be an English string any call site could reach for by accident,
/// and nothing would report the screen that did.
///
/// So models.dart is back to being domain only, and every label goes through
/// AppLocalizations.

extension VehicleClassLabel on VehicleClass {
  String labelIn(AppLocalizations l) => switch (this) {
    VehicleClass.economy => l.carEconomy,
    VehicleClass.comfort => l.carComfort,
    VehicleClass.xl => l.carXl,
  };
}

extension ServiceTypeLabel on ServiceType {
  String labelIn(AppLocalizations l) => switch (this) {
    ServiceType.city => l.serviceCity,
    ServiceType.intercity => l.serviceIntercity,
    ServiceType.delivery => l.serviceDelivery,
    ServiceType.freight => l.serviceFreight,
    ServiceType.moto => l.serviceMoto,
  };
}

extension PaymentMethodLabel on PaymentMethod {
  String labelIn(AppLocalizations l) => switch (this) {
    PaymentMethod.cash => l.cash,
    PaymentMethod.card => l.cardEndingIn(demoCardTail),
    PaymentMethod.wallet => l.wallet,
  };
}

extension RideOptionLabel on RideOption {
  String labelIn(AppLocalizations l) => switch (this) {
    RideOption.childSeat => l.optionChildSeat,
    RideOption.pet => l.optionPet,
    RideOption.luggage => l.optionLuggage,
    RideOption.airCon => l.optionAirCon,
    RideOption.noSmoking => l.optionNoSmoking,
    RideOption.silentRide => l.optionSilentRide,
    RideOption.femaleDriver => l.optionFemaleDriver,
  };
}
