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

  @override
  String get balanceCaps => 'BALANCE';

  @override
  String get topUp => 'Top up';

  @override
  String get promos => 'Promos';

  @override
  String get paymentMethods => 'Payment methods';

  @override
  String cardExpires(String date) {
    return 'Expires $date';
  }

  @override
  String get defaultLabel => 'Default';

  @override
  String get activity => 'Activity';

  @override
  String get noTransactions => 'No transactions yet';

  @override
  String get noTransactionsBody => 'Rides, top-ups and payouts appear here.';

  @override
  String get cashTripsNote =>
      'Cash trips are settled directly with the driver and don’t move your wallet balance.';

  @override
  String get topUpTitle => 'Top up your wallet';

  @override
  String get topUpUnavailable =>
      'Card payments are not connected yet, so there is no way to add to your balance. Your balance changes when a trip settles.';

  @override
  String topUpChargedTo(String card) {
    return 'Charged to $card.';
  }

  @override
  String topUpDescription(String card) {
    return 'Top-up from card $card';
  }

  @override
  String get profile => 'Profile';

  @override
  String get edit => 'Edit';

  @override
  String get passengerRating => 'Passenger rating';

  @override
  String get tripsTakenLabel => 'Trips taken';

  @override
  String get driverProfile => 'Driver profile';

  @override
  String get verified => 'Verified';

  @override
  String get driverRating => 'Driver rating';

  @override
  String get tripsGivenLabel => 'Trips given';

  @override
  String get earned => 'Earned';

  @override
  String memberSince(String date) {
    return 'Member since $date';
  }

  @override
  String get ratingExplainer =>
      'Your rating is the average of your last 50 trips. Passengers and drivers rate each other after every completed ride.';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get fullName => 'Full name';

  @override
  String get email => 'Email';

  @override
  String get save => 'Save';

  @override
  String get shortcuts => 'Shortcuts';

  @override
  String get addHome => 'Add home';

  @override
  String get addHomeSubtitle => 'Set your home address for one-tap booking';

  @override
  String get removeHome => 'Remove home';

  @override
  String get addWork => 'Add work';

  @override
  String get addWorkSubtitle => 'Set your work address for one-tap booking';

  @override
  String get removeWork => 'Remove work';

  @override
  String get changeHome => 'Change home';

  @override
  String get changeWork => 'Change work';

  @override
  String get popularInKl => 'Popular in Kuala Lumpur';

  @override
  String get setYourHome => 'Set your home';

  @override
  String get setYourWork => 'Set your work';

  @override
  String get searchForAnAddress => 'Search for an address';

  @override
  String get noMatches => 'No matches';

  @override
  String get noMatchesBody => 'Try another name.';

  @override
  String get order => 'Order';

  @override
  String get orderGoneTitle => 'This order is no longer available';

  @override
  String get orderGoneBody => 'It was taken or cancelled.';

  @override
  String get rideRequest => 'Ride request';

  @override
  String postedAgo(String time) {
    return 'Posted $time';
  }

  @override
  String raisedTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'raised $count times',
      one: 'raised $count time',
    );
    return '$_temp0';
  }

  @override
  String passengerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count passengers',
      one: '$count passenger',
    );
    return '$_temp0';
  }

  @override
  String get toPickup => 'To pickup';

  @override
  String get tripLength => 'Trip length';

  @override
  String get carType => 'Car type';

  @override
  String get payment => 'Payment';

  @override
  String get orderClosedToOffers => 'This order is no longer accepting offers.';

  @override
  String get yourOffer => 'Your offer';

  @override
  String waitingForReply(String name) {
    return 'Waiting for $name to reply';
  }

  @override
  String get withdrawOffer => 'Withdraw offer';

  @override
  String get passengerOffers => 'Passenger offers';

  @override
  String marketPrice(String amount) {
    return 'Market $amount';
  }

  @override
  String get lowerOffer => 'Lower offer';

  @override
  String get raiseOffer => 'Raise offer';

  @override
  String youKeepAfterFee(String net, String fee) {
    return 'You keep $net after $fee fee';
  }

  @override
  String resetTo(String amount) {
    return 'Reset to $amount';
  }

  @override
  String get counterOfferWarning =>
      'Counter-offers take longer to be accepted than taking the passenger’s price.';

  @override
  String offerAmount(String amount) {
    return 'Offer $amount';
  }

  @override
  String acceptAmount(String amount) {
    return 'Accept $amount';
  }

  @override
  String get skipThisOrder => 'Skip this order';

  @override
  String get vehicle => 'Vehicle';

  @override
  String get notADriverTitle => 'You’re not a driver yet';

  @override
  String get notADriverBody => 'Set up your vehicle to start receiving orders.';

  @override
  String seatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seats',
      one: '$count seat',
    );
    return '$_temp0';
  }

  @override
  String get category => 'Category';

  @override
  String get editDetails => 'Edit details';

  @override
  String get documents => 'Documents';

  @override
  String get documentsNote =>
      'Documents are verified automatically in this build. In production these would be reviewed against LPKP/APAD records before a driver can go online.';

  @override
  String get editVehicle => 'Edit vehicle';

  @override
  String get plateNumber => 'Plate number';

  @override
  String get colour => 'Colour';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get docApproved => 'Approved';

  @override
  String get docInReview => 'In review';

  @override
  String get docRejected => 'Rejected';

  @override
  String get docNotUploaded => 'Not uploaded';

  @override
  String expiresDate(String date) {
    return 'Expires $date';
  }

  @override
  String get classHintEconomy => 'Perodua, Proton, small sedans';

  @override
  String get classHintComfort => 'Honda City, Toyota Vios and up';

  @override
  String get classHintXl => 'MPVs and 7-seaters';

  @override
  String get driverIntroTitle => 'Start earning with your car';

  @override
  String get driverIntroBody =>
      'See ride requests near you, choose the ones worth your time, and set your own price on every trip.';

  @override
  String perkKeepTitle(String percent) {
    return 'Keep $percent% of every fare';
  }

  @override
  String perkKeepBody(String percent) {
    return 'Our service fee is $percent% — no surge splits, no hidden cuts.';
  }

  @override
  String get perkHoursTitle => 'Drive when you want';

  @override
  String get perkHoursBody =>
      'Go online and offline in one tap. No shifts, no quotas.';

  @override
  String get perkChoiceTitle => 'You choose the order';

  @override
  String get perkChoiceBody =>
      'See the destination and the fare before you accept anything.';

  @override
  String get driverIntroDocsNote =>
      'This build verifies documents automatically so you can try the driver side right away.';

  @override
  String get yourVehicle => 'Your vehicle';

  @override
  String get make => 'Make';

  @override
  String get model => 'Model';

  @override
  String get year => 'Year';

  @override
  String get vehicleCategory => 'Vehicle category';

  @override
  String get startDriving => 'Start driving';

  @override
  String get colourHint => 'White';

  @override
  String get serviceCity => 'City';

  @override
  String get serviceIntercity => 'Intercity';

  @override
  String get serviceDelivery => 'Delivery';

  @override
  String get serviceFreight => 'Freight';

  @override
  String get serviceMoto => 'Moto';

  @override
  String cardEndingIn(String tail) {
    return 'Card $tail';
  }

  @override
  String get optionChildSeat => 'Child seat';

  @override
  String get optionPet => 'Travelling with a pet';

  @override
  String get optionLuggage => 'Large luggage';

  @override
  String get optionAirCon => 'Air conditioning';

  @override
  String get optionNoSmoking => 'Non-smoking car';

  @override
  String get optionSilentRide => 'Silent ride';

  @override
  String get optionFemaleDriver => 'Prefer a female driver';

  @override
  String get whereTo => 'Where to?';

  @override
  String get home => 'Home';

  @override
  String get work => 'Work';

  @override
  String get saved => 'Saved';

  @override
  String offersReceived(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count offers received',
      one: '$count offer received',
    );
    return '$_temp0';
  }

  @override
  String yourPriceSearching(String amount, String elapsed) {
    return 'Your price $amount · searching $elapsed';
  }

  @override
  String get noOffersRaisePrompt =>
      'No offers yet. Raising your price is the fastest way to get picked up.';

  @override
  String raiseSheetBody(String amount) {
    return 'More drivers see your order when the fare goes up. You’re currently offering $amount.';
  }

  @override
  String get recommendedSuffix => ' · recommended';

  @override
  String get cancelYourOrder => 'Cancel your order?';

  @override
  String get cancelReasonPrompt => 'Tell us why so we can improve matching.';

  @override
  String offerMetaLine(int eta, String distance, String trips) {
    return '$eta min away · $distance · $trips trips';
  }
}
