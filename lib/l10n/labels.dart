import '../data/fixtures.dart';
import '../models/models.dart';
import '../services/pricing.dart';
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

// ---------------------------------------------------------------------------
// Lists of copy
//
// These were const lists in data/fixtures.dart, beside the driver names and
// vehicle makes. They do not belong there: a cancel reason or a canned chat
// line is a sentence the app says to a user, not seed data, and a const list
// cannot hold a translated string.
// ---------------------------------------------------------------------------

/// Tags a passenger can attach when rating their driver.
List<String> ratingTagsGood(AppLocalizations l) => [
  l.tagSafeDriving,
  l.tagCleanCar,
  l.tagPolite,
  l.tagGoodConversation,
  l.tagKnowsRoute,
  l.tagOnTime,
  l.tagHelpedLuggage,
  l.tagComfortableRide,
];

List<String> ratingTagsBad(AppLocalizations l) => [
  l.tagRudeBehaviour,
  l.tagDirtyCar,
  l.tagUnsafeDriving,
  l.tagLateArrival,
  l.tagWrongRoute,
  l.tagAskedForMoney,
  l.tagBadSmell,
  l.tagNoAirCon,
];

/// And the same in the other direction.
List<String> driverRatingTagsGood(AppLocalizations l) => [
  l.tagPolitePassenger,
  l.tagOnTime,
  l.tagClearPickup,
  l.tagGoodConversation,
  l.tagLeftCarClean,
];

List<String> driverRatingTagsBad(AppLocalizations l) => [
  l.tagKeptMeWaiting,
  l.tagRudeBehaviour,
  l.tagWrongPickup,
  l.tagTooManyPassengers,
  l.tagMessy,
];

/// Canned chat lines, so neither side has to type while driving.
List<String> quickPhrasesPassenger(AppLocalizations l) => [
  l.phraseAtPickup,
  l.phraseTwoMinutes,
  l.phraseBlueShirt,
  l.phraseWhichCar,
  l.phraseCallOnArrival,
  l.phraseThankYou,
];

List<String> quickPhrasesDriver(AppLocalizations l) => [
  l.phraseOnMyWay,
  l.phraseArrivedWaiting,
  l.phraseTrafficLate,
  l.phraseWhereToStop,
  l.phraseComeOut,
  l.phraseThankYou,
];

List<String> cancelReasonsPassenger(AppLocalizations l) => [
  l.cancelDriverTooLong,
  l.cancelDriverAsked,
  l.cancelNoLongerNeed,
  l.cancelWrongPickupAddress,
  l.cancelFoundAnother,
  l.cancelPriceTooHigh,
];

List<String> cancelReasonsDriver(AppLocalizations l) => [
  l.cancelPassengerSilent,
  l.cancelPassengerNoShow,
  l.cancelPickupUnreachable,
  l.cancelTooFar,
  l.cancelVehicleProblem,
  l.cancelPassengerAsked,
];

/// The demo promo codes. The code itself is an identifier the user types, so
/// it stays as it is; what it gets you is a sentence, so that is translated.
List<PromoCode> promoCodes(AppLocalizations l) => [
  PromoCode(
    code: 'TEKSI50',
    label: l.promoHalfOff,
    percentOff: 50,
    expiresAt: DateTime.now().add(const Duration(days: 14)),
  ),
  PromoCode(
    code: 'WELCOME5',
    label: l.promoFiveOff,
    amountOff: 500,
    expiresAt: DateTime.now().add(const Duration(days: 30)),
  ),
  PromoCode(
    code: 'KLIA15',
    label: l.promoAirport,
    amountOff: 1500,
    minSpend: 4000,
    expiresAt: DateTime.now().add(const Duration(days: 7)),
  ),
];

/// What to call each price verdict, and what to tell the passenger about it.
/// services/pricing.dart decides the tone; this decides how it reads.
extension PriceToneLabel on PriceTone {
  String labelIn(AppLocalizations l) => switch (this) {
    PriceTone.low => l.verdictLowLabel,
    PriceTone.fair => l.verdictFairLabel,
    PriceTone.good => l.verdictGoodLabel,
    PriceTone.high => l.verdictHighLabel,
  };

  String hintIn(AppLocalizations l) => switch (this) {
    PriceTone.low => l.verdictLowHint,
    PriceTone.fair => l.verdictFairHint,
    PriceTone.good => l.verdictGoodHint,
    PriceTone.high => l.verdictHighHint,
  };
}
