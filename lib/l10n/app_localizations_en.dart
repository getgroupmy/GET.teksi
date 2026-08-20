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
}
