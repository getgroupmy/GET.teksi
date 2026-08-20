// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get onboardTitle1 => 'Name your own fare';

  @override
  String get onboardBody1 =>
      'No fixed meter, no surge. You say what the trip is worth, drivers reply with their price.';

  @override
  String get onboardTitle2 => 'Ride and drive in one app';

  @override
  String get onboardBody2 =>
      'Switch between passenger and driver whenever you like. One profile, one wallet, one history.';

  @override
  String get onboardTitle3 => 'Safety built in';

  @override
  String get onboardBody3 =>
      'Share your trip, call for help, and see every driver’s rating before you accept a price.';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get started';

  @override
  String get phoneTitle => 'Enter your phone number';

  @override
  String get phoneSubtitle => 'We’ll send a 6-digit code to verify it’s you.';

  @override
  String get phoneTerms =>
      'By continuing you agree to the Terms of Service and Privacy Policy. Standard message rates may apply.';

  @override
  String get phoneSendFailed => 'We could not send a code to that number.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get otpTitle => 'Enter the code';

  @override
  String otpSentTo(String phone) {
    return 'Sent to $phone';
  }

  @override
  String otpResendIn(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get otpResend => 'Resend code';

  @override
  String get otpVerify => 'Verify';

  @override
  String get otpMismatch =>
      'That code doesn’t match. Check the code shown below.';

  @override
  String get otpUnverified =>
      'That code could not be verified. Request a new one.';

  @override
  String get otpWrongOrExpired => 'That code is wrong or has expired.';

  @override
  String get otpResendFailed => 'Could not send a new code.';

  @override
  String get otpDemoPrefix => 'Demo build — no SMS is sent. Your code is ';

  @override
  String get profileTitle => 'What should we call you?';

  @override
  String get profileSubtitle =>
      'Drivers and passengers will see this name and photo.';

  @override
  String get profileFullName => 'Full name';

  @override
  String get profileEmail => 'Email (optional)';

  @override
  String get profileStart => 'Start riding';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get darkTheme => 'Dark theme';

  @override
  String get preferences => 'Preferences';

  @override
  String get languageName => 'English';

  @override
  String get language => 'Language';

  @override
  String get sounds => 'Sounds and vibration';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get demo => 'Demo';

  @override
  String get simulatedMarketplace => 'Simulated marketplace';

  @override
  String get simulatedMarketplaceSubtitle =>
      'Bot drivers bid on your orders and bot passengers post rides';

  @override
  String get clearLocalData => 'Clear local data';

  @override
  String get clearLocalDataSubtitle =>
      'Erase rides, offers and messages on this device';

  @override
  String get clearLocalDataConfirmTitle => 'Clear local data?';

  @override
  String get clearEverything => 'Clear everything';

  @override
  String get cancel => 'Cancel';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get termsOfService => 'Terms of service';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get yourPrice => 'Your price';

  @override
  String recommendedFare(String amount) {
    return 'Recommended $amount';
  }

  @override
  String get chooseCarType => 'Choose a car type';

  @override
  String get carEconomy => 'Everyday cars, 4 seats';

  @override
  String get carComfort => 'Newer, roomier cars';

  @override
  String get carXl => 'Up to 6 passengers';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get cashNote =>
      'Cash is paid directly to the driver at the end of the trip.';

  @override
  String balanceIs(String amount) {
    return 'Balance $amount';
  }

  @override
  String get tripOptions => 'Trip options';

  @override
  String get extras => 'Extras';

  @override
  String get noteForDriver => 'Note for the driver';

  @override
  String get note => 'Note';

  @override
  String get noteAdded => 'Note added';

  @override
  String get saveNote => 'Save note';

  @override
  String get done => 'Done';

  @override
  String findDriverFor(String amount) {
    return 'Find a driver for $amount';
  }

  @override
  String get lookingForDrivers => 'Looking for drivers…';

  @override
  String get noOffersYet =>
      'No offers yet. Raising your price is the fastest way to get picked up.';

  @override
  String get raiseYourPrice => 'Raise your price';

  @override
  String get raiseFare => 'Raise fare';

  @override
  String get lowerFare => 'Lower fare';

  @override
  String get moreDriversWhenHigher =>
      'More drivers see your order when the fare goes up.';

  @override
  String get cancelSearch => 'Cancel search';

  @override
  String get cancelOrderTitle => 'Cancel your order?';

  @override
  String get keepSearching => 'Keep searching';

  @override
  String get declineOffer => 'Decline offer';

  @override
  String get declineReasonPrompt => 'Tell us why so we can improve matching.';

  @override
  String get accept => 'Accept';

  @override
  String balanceInsufficient(String amount) {
    return 'Balance $amount — not enough for this fare';
  }

  @override
  String get driverOnTheWay => 'Driver is on the way';

  @override
  String get driverArriving => 'Driver is arriving';

  @override
  String get driverWaiting => 'Your driver is waiting';

  @override
  String get enjoyTheRide => 'Enjoy the ride';

  @override
  String get meetAtPickup => 'Meet your driver at the pickup point';

  @override
  String get headToPickup => 'Please start heading to the pickup point';

  @override
  String get driverArrivedFreeWait =>
      'Your driver has arrived. Free waiting time applies for 3 minutes.';

  @override
  String get onTheWayToDestination => 'On the way to your destination';

  @override
  String get callLabel => 'Call';

  @override
  String get chatLabel => 'Chat';

  @override
  String get safetyLabel => 'Safety';

  @override
  String get shareLabel => 'Share';

  @override
  String get shareYourTrip => 'Share your trip';

  @override
  String get shareTripBody =>
      'Send these details to someone you trust — they’re already on your clipboard.';

  @override
  String callingName(String name) {
    return 'Calling $name…';
  }

  @override
  String get cancelRide => 'Cancel ride';

  @override
  String get cancelRideTitle => 'Cancel this ride?';

  @override
  String get cancelRideBody =>
      'Your driver is already on the way. Frequent late cancellations can affect your rating.';

  @override
  String get keepMyRide => 'Keep my ride';

  @override
  String get payInCash => 'Pay in cash';

  @override
  String get driverLabel => 'Driver';

  @override
  String get freeWaitNote => 'They can wait a few minutes free of charge';

  @override
  String get youreOffline => 'You’re offline';

  @override
  String get goOnline => 'Go online';

  @override
  String get goOffline => 'Go offline';

  @override
  String get goOnlinePrompt =>
      'Go online to see ride requests near you and send your price.';

  @override
  String get waitingForOrders => 'Waiting for orders';

  @override
  String get stayOnlinePrompt =>
      'Stay online — new requests appear here as passengers publish them.';

  @override
  String get noOrdersMatch => 'No orders match right now';

  @override
  String get offerWaitingReply => 'Your offer is waiting for a reply';

  @override
  String get filters => 'Filters';

  @override
  String get filterOrders => 'Filter orders';

  @override
  String get applyFilters => 'Apply filters';

  @override
  String get minimumFare => 'Minimum fare';

  @override
  String get maxPickupDistance => 'Maximum distance to pickup';

  @override
  String get sortNearest => 'Nearest';

  @override
  String get sortHighest => 'Highest';

  @override
  String get sortNewest => 'Newest';

  @override
  String get viewTodaysEarnings => 'View today’s earnings';

  @override
  String pickUpName(String name) {
    return 'Pick up $name';
  }

  @override
  String toDestination(String place) {
    return 'To $place';
  }

  @override
  String get waitingForPassenger => 'Waiting for the passenger';

  @override
  String get freeWaitDriverNote =>
      'Free waiting time is 3 minutes. Message the passenger if they’re not out yet.';

  @override
  String get startTheTrip => 'Start the trip';

  @override
  String finishTripFor(String amount) {
    return 'Finish trip · $amount';
  }

  @override
  String feeIs(String amount) {
    return 'Fee $amount';
  }

  @override
  String get navigate => 'Navigate';

  @override
  String navigatingTo(String place) {
    return 'Navigating to $place…';
  }

  @override
  String get cancelThisOrder => 'Cancel this order';

  @override
  String get cancelOrderConfirmTitle => 'Cancel the order?';

  @override
  String get cancelOrderBody =>
      'Cancelling accepted orders too often lowers your priority in the feed.';

  @override
  String get keepTheOrder => 'Keep the order';

  @override
  String get cash => 'Cash';

  @override
  String get card => 'Card';

  @override
  String get wallet => 'Wallet';

  @override
  String get anyAmount => 'Any';

  @override
  String youreOnlineWith(String plate) {
    return 'You’re online · $plate';
  }

  @override
  String tripDistance(String distance) {
    return 'Trip $distance';
  }

  @override
  String tripDistanceDuration(String distance, String duration) {
    return 'Trip $distance · $duration';
  }

  @override
  String shareTripMessage(
    String destination,
    String driver,
    String vehicle,
    String plate,
    String ref,
  ) {
    return 'I’m on a GET.teksi ride to $destination. Driver: $driver ($vehicle, $plate). Ref $ref.';
  }

  @override
  String get menu => 'Menu';

  @override
  String tripsGiven(int count) {
    return '$count trips given';
  }

  @override
  String tripsTaken(int count) {
    return '$count trips taken';
  }

  @override
  String get switchToPassenger => 'Switch to passenger';

  @override
  String get switchToDriver => 'Switch to driver';

  @override
  String get becomeADriver => 'Become a driver';

  @override
  String get myRides => 'My rides';

  @override
  String get myRidesSubtitle => 'Trip history and receipts';

  @override
  String get promoCodes => 'Promo codes';

  @override
  String get promoCodesSubtitle => 'Discounts and referrals';

  @override
  String get savedPlaces => 'Saved places';

  @override
  String get savedPlacesSubtitle => 'Home, work and favourites';

  @override
  String get earnings => 'Earnings';

  @override
  String get earningsSubtitle => 'Daily and weekly totals';

  @override
  String get vehicleAndDocuments => 'Vehicle & documents';

  @override
  String get safetyCentre => 'Safety centre';

  @override
  String get safetyCentreSubtitle => 'Emergency contacts and SOS';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirmTitle => 'Sign out?';

  @override
  String get signOutBody =>
      'Your rides and history stay on this device unless you clear them.';

  @override
  String get signOutAndErase => 'Sign out and erase all local data';

  @override
  String get appVersionLine => 'GET.teksi · v1.0.0';

  @override
  String get safetyAlertNoTrip => 'SAFETY ALERT — please check on me.';

  @override
  String safetyAlertTrip(
    String destination,
    String driver,
    String plate,
    String ref,
  ) {
    return 'SAFETY ALERT — I’m on a GET.teksi trip to $destination. Driver $driver, $plate. Ref $ref.';
  }

  @override
  String get unknownDriver => 'unknown';

  @override
  String get noPlate => 'no plate';

  @override
  String get emergencySos => 'Emergency SOS';

  @override
  String emergencySosSubtitle(String number) {
    return 'Call $number and alert your contacts';
  }

  @override
  String activeTripBanner(String destination, String vehicle) {
    return 'Active trip to $destination$vehicle. Your contacts can see these details when you share the trip.';
  }

  @override
  String get duringATrip => 'During a trip';

  @override
  String get shareMyTrip => 'Share my trip';

  @override
  String get shareMyTripSubtitle =>
      'Send live trip details to someone you trust';

  @override
  String get tripDetailsCopied => 'Trip details copied to clipboard';

  @override
  String get reportAProblem => 'Report a problem';

  @override
  String get reportAProblemSubtitle => 'Driving, behaviour, route or payment';

  @override
  String get supportTitle => '24/7 support';

  @override
  String get supportSubtitle => 'Talk to a GET.teksi agent';

  @override
  String get connectingToSupport => 'Connecting you to support…';

  @override
  String get emergencyContacts => 'EMERGENCY CONTACTS';

  @override
  String get add => 'Add';

  @override
  String get noEmergencyContacts =>
      'No contacts yet. Add someone who should be alerted if you press SOS.';

  @override
  String get remove => 'Remove';

  @override
  String sosBodyNoContacts(String number) {
    return 'We’ll place a call to $number and copy your trip details so you can send them to your contacts.';
  }

  @override
  String sosBodyWithContacts(String number, int count) {
    return 'We’ll place a call to $number and copy your trip details so you can send them to your $count emergency contacts.';
  }

  @override
  String get sosTriggered => 'SOS triggered';

  @override
  String get sosTriggeredBody =>
      'Trip details copied. Support has been notified.';

  @override
  String callingEmergency(String number) {
    return 'Calling $number…';
  }

  @override
  String callEmergency(String number) {
    return 'Call $number';
  }

  @override
  String get reportSubmitted => 'Report submitted';

  @override
  String reportSubmittedBody(String reason) {
    return '$reason — our safety team will follow up within 24 hours.';
  }

  @override
  String get reportUnsafeDriving => 'Unsafe driving';

  @override
  String get reportDriverBehaviour => 'Driver behaviour';

  @override
  String get reportWrongRoute => 'Wrong route taken';

  @override
  String get reportExtraPayment => 'Asked for extra payment';

  @override
  String get reportVehicleMismatch => 'Vehicle did not match';

  @override
  String get reportSomethingElse => 'Something else';

  @override
  String get addEmergencyContact => 'Add emergency contact';

  @override
  String get nameLabel => 'Name';

  @override
  String get nameHint => 'e.g. Mum';

  @override
  String get phoneNumberLabel => 'Phone number';

  @override
  String get saveContact => 'Save contact';
}
