import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ms.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ms'),
  ];

  /// No description provided for @onboardTitle1.
  ///
  /// In en, this message translates to:
  /// **'Name your own fare'**
  String get onboardTitle1;

  /// No description provided for @onboardBody1.
  ///
  /// In en, this message translates to:
  /// **'No fixed meter, no surge. You say what the trip is worth, drivers reply with their price.'**
  String get onboardBody1;

  /// No description provided for @onboardTitle2.
  ///
  /// In en, this message translates to:
  /// **'Ride and drive in one app'**
  String get onboardTitle2;

  /// No description provided for @onboardBody2.
  ///
  /// In en, this message translates to:
  /// **'Switch between passenger and driver whenever you like. One profile, one wallet, one history.'**
  String get onboardBody2;

  /// No description provided for @onboardTitle3.
  ///
  /// In en, this message translates to:
  /// **'Safety built in'**
  String get onboardTitle3;

  /// No description provided for @onboardBody3.
  ///
  /// In en, this message translates to:
  /// **'Share your trip, call for help, and see every driver’s rating before you accept a price.'**
  String get onboardBody3;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @phoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get phoneTitle;

  /// No description provided for @phoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We’ll send a 6-digit code to verify it’s you.'**
  String get phoneSubtitle;

  /// No description provided for @phoneTerms.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to the Terms of Service and Privacy Policy. Standard message rates may apply.'**
  String get phoneTerms;

  /// No description provided for @phoneSendFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not send a code to that number.'**
  String get phoneSendFailed;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code'**
  String get otpTitle;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'Sent to {phone}'**
  String otpSentTo(String phone);

  /// No description provided for @otpResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String otpResendIn(int seconds);

  /// No description provided for @otpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get otpResend;

  /// No description provided for @otpVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get otpVerify;

  /// No description provided for @otpMismatch.
  ///
  /// In en, this message translates to:
  /// **'That code doesn’t match. Check the code shown below.'**
  String get otpMismatch;

  /// No description provided for @otpUnverified.
  ///
  /// In en, this message translates to:
  /// **'That code could not be verified. Request a new one.'**
  String get otpUnverified;

  /// No description provided for @otpWrongOrExpired.
  ///
  /// In en, this message translates to:
  /// **'That code is wrong or has expired.'**
  String get otpWrongOrExpired;

  /// No description provided for @otpResendFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send a new code.'**
  String get otpResendFailed;

  /// No description provided for @otpDemoPrefix.
  ///
  /// In en, this message translates to:
  /// **'Demo build — no SMS is sent. Your code is '**
  String get otpDemoPrefix;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get profileTitle;

  /// No description provided for @profileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Drivers and passengers will see this name and photo.'**
  String get profileSubtitle;

  /// No description provided for @profileFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get profileFullName;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get profileEmail;

  /// No description provided for @profileStart.
  ///
  /// In en, this message translates to:
  /// **'Start riding'**
  String get profileStart;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get darkTheme;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @languageName.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @sounds.
  ///
  /// In en, this message translates to:
  /// **'Sounds and vibration'**
  String get sounds;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @demo.
  ///
  /// In en, this message translates to:
  /// **'Demo'**
  String get demo;

  /// No description provided for @simulatedMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Simulated marketplace'**
  String get simulatedMarketplace;

  /// No description provided for @simulatedMarketplaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bot drivers bid on your orders and bot passengers post rides'**
  String get simulatedMarketplaceSubtitle;

  /// No description provided for @clearLocalData.
  ///
  /// In en, this message translates to:
  /// **'Clear local data'**
  String get clearLocalData;

  /// No description provided for @clearLocalDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Erase rides, offers and messages on this device'**
  String get clearLocalDataSubtitle;

  /// No description provided for @clearLocalDataConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear local data?'**
  String get clearLocalDataConfirmTitle;

  /// No description provided for @clearEverything.
  ///
  /// In en, this message translates to:
  /// **'Clear everything'**
  String get clearEverything;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @yourPrice.
  ///
  /// In en, this message translates to:
  /// **'Your price'**
  String get yourPrice;

  /// No description provided for @recommendedFare.
  ///
  /// In en, this message translates to:
  /// **'Recommended {amount}'**
  String recommendedFare(String amount);

  /// No description provided for @chooseCarType.
  ///
  /// In en, this message translates to:
  /// **'Choose a car type'**
  String get chooseCarType;

  /// No description provided for @carEconomy.
  ///
  /// In en, this message translates to:
  /// **'Everyday cars, 4 seats'**
  String get carEconomy;

  /// No description provided for @carComfort.
  ///
  /// In en, this message translates to:
  /// **'Newer, roomier cars'**
  String get carComfort;

  /// No description provided for @carXl.
  ///
  /// In en, this message translates to:
  /// **'Up to 6 passengers'**
  String get carXl;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// No description provided for @cashNote.
  ///
  /// In en, this message translates to:
  /// **'Cash is paid directly to the driver at the end of the trip.'**
  String get cashNote;

  /// No description provided for @balanceIs.
  ///
  /// In en, this message translates to:
  /// **'Balance {amount}'**
  String balanceIs(String amount);

  /// No description provided for @tripOptions.
  ///
  /// In en, this message translates to:
  /// **'Trip options'**
  String get tripOptions;

  /// No description provided for @extras.
  ///
  /// In en, this message translates to:
  /// **'Extras'**
  String get extras;

  /// No description provided for @noteForDriver.
  ///
  /// In en, this message translates to:
  /// **'Note for the driver'**
  String get noteForDriver;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @noteAdded.
  ///
  /// In en, this message translates to:
  /// **'Note added'**
  String get noteAdded;

  /// No description provided for @saveNote.
  ///
  /// In en, this message translates to:
  /// **'Save note'**
  String get saveNote;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @findDriverFor.
  ///
  /// In en, this message translates to:
  /// **'Find a driver for {amount}'**
  String findDriverFor(String amount);

  /// No description provided for @lookingForDrivers.
  ///
  /// In en, this message translates to:
  /// **'Looking for drivers…'**
  String get lookingForDrivers;

  /// No description provided for @noOffersYet.
  ///
  /// In en, this message translates to:
  /// **'No offers yet. Raising your price is the fastest way to get picked up.'**
  String get noOffersYet;

  /// No description provided for @raiseYourPrice.
  ///
  /// In en, this message translates to:
  /// **'Raise your price'**
  String get raiseYourPrice;

  /// No description provided for @raiseFare.
  ///
  /// In en, this message translates to:
  /// **'Raise fare'**
  String get raiseFare;

  /// No description provided for @lowerFare.
  ///
  /// In en, this message translates to:
  /// **'Lower fare'**
  String get lowerFare;

  /// No description provided for @moreDriversWhenHigher.
  ///
  /// In en, this message translates to:
  /// **'More drivers see your order when the fare goes up.'**
  String get moreDriversWhenHigher;

  /// No description provided for @cancelSearch.
  ///
  /// In en, this message translates to:
  /// **'Cancel search'**
  String get cancelSearch;

  /// No description provided for @cancelOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel your order?'**
  String get cancelOrderTitle;

  /// No description provided for @keepSearching.
  ///
  /// In en, this message translates to:
  /// **'Keep searching'**
  String get keepSearching;

  /// No description provided for @declineOffer.
  ///
  /// In en, this message translates to:
  /// **'Decline offer'**
  String get declineOffer;

  /// No description provided for @declineReasonPrompt.
  ///
  /// In en, this message translates to:
  /// **'Tell us why so we can improve matching.'**
  String get declineReasonPrompt;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @balanceInsufficient.
  ///
  /// In en, this message translates to:
  /// **'Balance {amount} — not enough for this fare'**
  String balanceInsufficient(String amount);

  /// No description provided for @driverOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'Driver is on the way'**
  String get driverOnTheWay;

  /// No description provided for @driverArriving.
  ///
  /// In en, this message translates to:
  /// **'Driver is arriving'**
  String get driverArriving;

  /// No description provided for @driverWaiting.
  ///
  /// In en, this message translates to:
  /// **'Your driver is waiting'**
  String get driverWaiting;

  /// No description provided for @enjoyTheRide.
  ///
  /// In en, this message translates to:
  /// **'Enjoy the ride'**
  String get enjoyTheRide;

  /// No description provided for @meetAtPickup.
  ///
  /// In en, this message translates to:
  /// **'Meet your driver at the pickup point'**
  String get meetAtPickup;

  /// No description provided for @headToPickup.
  ///
  /// In en, this message translates to:
  /// **'Please start heading to the pickup point'**
  String get headToPickup;

  /// No description provided for @driverArrivedFreeWait.
  ///
  /// In en, this message translates to:
  /// **'Your driver has arrived. Free waiting time applies for 3 minutes.'**
  String get driverArrivedFreeWait;

  /// No description provided for @onTheWayToDestination.
  ///
  /// In en, this message translates to:
  /// **'On the way to your destination'**
  String get onTheWayToDestination;

  /// No description provided for @callLabel.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callLabel;

  /// No description provided for @chatLabel.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatLabel;

  /// No description provided for @safetyLabel.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get safetyLabel;

  /// No description provided for @shareLabel.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareLabel;

  /// No description provided for @shareYourTrip.
  ///
  /// In en, this message translates to:
  /// **'Share your trip'**
  String get shareYourTrip;

  /// No description provided for @shareTripBody.
  ///
  /// In en, this message translates to:
  /// **'Send these details to someone you trust — they’re already on your clipboard.'**
  String get shareTripBody;

  /// No description provided for @callingName.
  ///
  /// In en, this message translates to:
  /// **'Calling {name}…'**
  String callingName(String name);

  /// No description provided for @cancelRide.
  ///
  /// In en, this message translates to:
  /// **'Cancel ride'**
  String get cancelRide;

  /// No description provided for @cancelRideTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this ride?'**
  String get cancelRideTitle;

  /// No description provided for @cancelRideBody.
  ///
  /// In en, this message translates to:
  /// **'Your driver is already on the way. Frequent late cancellations can affect your rating.'**
  String get cancelRideBody;

  /// No description provided for @keepMyRide.
  ///
  /// In en, this message translates to:
  /// **'Keep my ride'**
  String get keepMyRide;

  /// No description provided for @payInCash.
  ///
  /// In en, this message translates to:
  /// **'Pay in cash'**
  String get payInCash;

  /// No description provided for @driverLabel.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driverLabel;

  /// No description provided for @freeWaitNote.
  ///
  /// In en, this message translates to:
  /// **'They can wait a few minutes free of charge'**
  String get freeWaitNote;

  /// No description provided for @youreOffline.
  ///
  /// In en, this message translates to:
  /// **'You’re offline'**
  String get youreOffline;

  /// No description provided for @goOnline.
  ///
  /// In en, this message translates to:
  /// **'Go online'**
  String get goOnline;

  /// No description provided for @goOffline.
  ///
  /// In en, this message translates to:
  /// **'Go offline'**
  String get goOffline;

  /// No description provided for @goOnlinePrompt.
  ///
  /// In en, this message translates to:
  /// **'Go online to see ride requests near you and send your price.'**
  String get goOnlinePrompt;

  /// No description provided for @waitingForOrders.
  ///
  /// In en, this message translates to:
  /// **'Waiting for orders'**
  String get waitingForOrders;

  /// No description provided for @stayOnlinePrompt.
  ///
  /// In en, this message translates to:
  /// **'Stay online — new requests appear here as passengers publish them.'**
  String get stayOnlinePrompt;

  /// No description provided for @noOrdersMatch.
  ///
  /// In en, this message translates to:
  /// **'No orders match right now'**
  String get noOrdersMatch;

  /// No description provided for @offerWaitingReply.
  ///
  /// In en, this message translates to:
  /// **'Your offer is waiting for a reply'**
  String get offerWaitingReply;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @filterOrders.
  ///
  /// In en, this message translates to:
  /// **'Filter orders'**
  String get filterOrders;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get applyFilters;

  /// No description provided for @minimumFare.
  ///
  /// In en, this message translates to:
  /// **'Minimum fare'**
  String get minimumFare;

  /// No description provided for @maxPickupDistance.
  ///
  /// In en, this message translates to:
  /// **'Maximum distance to pickup'**
  String get maxPickupDistance;

  /// No description provided for @sortNearest.
  ///
  /// In en, this message translates to:
  /// **'Nearest'**
  String get sortNearest;

  /// No description provided for @sortHighest.
  ///
  /// In en, this message translates to:
  /// **'Highest'**
  String get sortHighest;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// No description provided for @viewTodaysEarnings.
  ///
  /// In en, this message translates to:
  /// **'View today’s earnings'**
  String get viewTodaysEarnings;

  /// No description provided for @pickUpName.
  ///
  /// In en, this message translates to:
  /// **'Pick up {name}'**
  String pickUpName(String name);

  /// No description provided for @toDestination.
  ///
  /// In en, this message translates to:
  /// **'To {place}'**
  String toDestination(String place);

  /// No description provided for @waitingForPassenger.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the passenger'**
  String get waitingForPassenger;

  /// No description provided for @freeWaitDriverNote.
  ///
  /// In en, this message translates to:
  /// **'Free waiting time is 3 minutes. Message the passenger if they’re not out yet.'**
  String get freeWaitDriverNote;

  /// No description provided for @startTheTrip.
  ///
  /// In en, this message translates to:
  /// **'Start the trip'**
  String get startTheTrip;

  /// No description provided for @finishTripFor.
  ///
  /// In en, this message translates to:
  /// **'Finish trip · {amount}'**
  String finishTripFor(String amount);

  /// No description provided for @feeIs.
  ///
  /// In en, this message translates to:
  /// **'Fee {amount}'**
  String feeIs(String amount);

  /// No description provided for @navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @navigatingTo.
  ///
  /// In en, this message translates to:
  /// **'Navigating to {place}…'**
  String navigatingTo(String place);

  /// No description provided for @cancelThisOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel this order'**
  String get cancelThisOrder;

  /// No description provided for @cancelOrderConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel the order?'**
  String get cancelOrderConfirmTitle;

  /// No description provided for @cancelOrderBody.
  ///
  /// In en, this message translates to:
  /// **'Cancelling accepted orders too often lowers your priority in the feed.'**
  String get cancelOrderBody;

  /// No description provided for @keepTheOrder.
  ///
  /// In en, this message translates to:
  /// **'Keep the order'**
  String get keepTheOrder;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// Filter option meaning no minimum fare is required.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get anyAmount;

  /// Driver status line, with the vehicle's plate.
  ///
  /// In en, this message translates to:
  /// **'You’re online · {plate}'**
  String youreOnlineWith(String plate);

  /// Distance of the trip leg on an order card.
  ///
  /// In en, this message translates to:
  /// **'Trip {distance}'**
  String tripDistance(String distance);

  /// Distance and duration of the trip leg.
  ///
  /// In en, this message translates to:
  /// **'Trip {distance} · {duration}'**
  String tripDistanceDuration(String distance, String duration);

  /// The message a passenger shares to let someone follow their trip.
  ///
  /// In en, this message translates to:
  /// **'I’m on a GET.teksi ride to {destination}. Driver: {driver} ({vehicle}, {plate}). Ref {ref}.'**
  String shareTripMessage(
    String destination,
    String driver,
    String vehicle,
    String plate,
    String ref,
  );

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// Trip count on a driver's profile row.
  ///
  /// In en, this message translates to:
  /// **'{count} trips given'**
  String tripsGiven(int count);

  /// Trip count on a passenger's profile row.
  ///
  /// In en, this message translates to:
  /// **'{count} trips taken'**
  String tripsTaken(int count);

  /// No description provided for @switchToPassenger.
  ///
  /// In en, this message translates to:
  /// **'Switch to passenger'**
  String get switchToPassenger;

  /// No description provided for @switchToDriver.
  ///
  /// In en, this message translates to:
  /// **'Switch to driver'**
  String get switchToDriver;

  /// No description provided for @becomeADriver.
  ///
  /// In en, this message translates to:
  /// **'Become a driver'**
  String get becomeADriver;

  /// No description provided for @myRides.
  ///
  /// In en, this message translates to:
  /// **'My rides'**
  String get myRides;

  /// No description provided for @myRidesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Trip history and receipts'**
  String get myRidesSubtitle;

  /// No description provided for @promoCodes.
  ///
  /// In en, this message translates to:
  /// **'Promo codes'**
  String get promoCodes;

  /// No description provided for @promoCodesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discounts and referrals'**
  String get promoCodesSubtitle;

  /// No description provided for @savedPlaces.
  ///
  /// In en, this message translates to:
  /// **'Saved places'**
  String get savedPlaces;

  /// No description provided for @savedPlacesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Home, work and favourites'**
  String get savedPlacesSubtitle;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @earningsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily and weekly totals'**
  String get earningsSubtitle;

  /// No description provided for @vehicleAndDocuments.
  ///
  /// In en, this message translates to:
  /// **'Vehicle & documents'**
  String get vehicleAndDocuments;

  /// No description provided for @safetyCentre.
  ///
  /// In en, this message translates to:
  /// **'Safety centre'**
  String get safetyCentre;

  /// No description provided for @safetyCentreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency contacts and SOS'**
  String get safetyCentreSubtitle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutBody.
  ///
  /// In en, this message translates to:
  /// **'Your rides and history stay on this device unless you clear them.'**
  String get signOutBody;

  /// No description provided for @signOutAndErase.
  ///
  /// In en, this message translates to:
  /// **'Sign out and erase all local data'**
  String get signOutAndErase;

  /// App name and version at the foot of the menu.
  ///
  /// In en, this message translates to:
  /// **'GET.teksi · v1.0.0'**
  String get appVersionLine;

  /// No description provided for @safetyAlertNoTrip.
  ///
  /// In en, this message translates to:
  /// **'SAFETY ALERT — please check on me.'**
  String get safetyAlertNoTrip;

  /// The message SOS copies when a trip is in progress.
  ///
  /// In en, this message translates to:
  /// **'SAFETY ALERT — I’m on a GET.teksi trip to {destination}. Driver {driver}, {plate}. Ref {ref}.'**
  String safetyAlertTrip(
    String destination,
    String driver,
    String plate,
    String ref,
  );

  /// No description provided for @unknownDriver.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get unknownDriver;

  /// No description provided for @noPlate.
  ///
  /// In en, this message translates to:
  /// **'no plate'**
  String get noPlate;

  /// No description provided for @emergencySos.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS'**
  String get emergencySos;

  /// No description provided for @emergencySosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Call {number} and alert your contacts'**
  String emergencySosSubtitle(String number);

  /// vehicle is an already-formatted fragment, empty when no vehicle is assigned.
  ///
  /// In en, this message translates to:
  /// **'Active trip to {destination}{vehicle}. Your contacts can see these details when you share the trip.'**
  String activeTripBanner(String destination, String vehicle);

  /// No description provided for @duringATrip.
  ///
  /// In en, this message translates to:
  /// **'During a trip'**
  String get duringATrip;

  /// No description provided for @shareMyTrip.
  ///
  /// In en, this message translates to:
  /// **'Share my trip'**
  String get shareMyTrip;

  /// No description provided for @shareMyTripSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send live trip details to someone you trust'**
  String get shareMyTripSubtitle;

  /// No description provided for @tripDetailsCopied.
  ///
  /// In en, this message translates to:
  /// **'Trip details copied to clipboard'**
  String get tripDetailsCopied;

  /// No description provided for @reportAProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportAProblem;

  /// No description provided for @reportAProblemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Driving, behaviour, route or payment'**
  String get reportAProblemSubtitle;

  /// No description provided for @supportTitle.
  ///
  /// In en, this message translates to:
  /// **'24/7 support'**
  String get supportTitle;

  /// No description provided for @supportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Talk to a GET.teksi agent'**
  String get supportSubtitle;

  /// No description provided for @connectingToSupport.
  ///
  /// In en, this message translates to:
  /// **'Connecting you to support…'**
  String get connectingToSupport;

  /// No description provided for @emergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'EMERGENCY CONTACTS'**
  String get emergencyContacts;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @noEmergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet. Add someone who should be alerted if you press SOS.'**
  String get noEmergencyContacts;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @sosBodyNoContacts.
  ///
  /// In en, this message translates to:
  /// **'We’ll place a call to {number} and copy your trip details so you can send them to your contacts.'**
  String sosBodyNoContacts(String number);

  /// No description provided for @sosBodyWithContacts.
  ///
  /// In en, this message translates to:
  /// **'We’ll place a call to {number} and copy your trip details so you can send them to your {count} emergency contacts.'**
  String sosBodyWithContacts(String number, int count);

  /// No description provided for @sosTriggered.
  ///
  /// In en, this message translates to:
  /// **'SOS triggered'**
  String get sosTriggered;

  /// No description provided for @sosTriggeredBody.
  ///
  /// In en, this message translates to:
  /// **'Trip details copied. Support has been notified.'**
  String get sosTriggeredBody;

  /// No description provided for @callingEmergency.
  ///
  /// In en, this message translates to:
  /// **'Calling {number}…'**
  String callingEmergency(String number);

  /// No description provided for @callEmergency.
  ///
  /// In en, this message translates to:
  /// **'Call {number}'**
  String callEmergency(String number);

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted'**
  String get reportSubmitted;

  /// No description provided for @reportSubmittedBody.
  ///
  /// In en, this message translates to:
  /// **'{reason} — our safety team will follow up within 24 hours.'**
  String reportSubmittedBody(String reason);

  /// No description provided for @reportUnsafeDriving.
  ///
  /// In en, this message translates to:
  /// **'Unsafe driving'**
  String get reportUnsafeDriving;

  /// No description provided for @reportDriverBehaviour.
  ///
  /// In en, this message translates to:
  /// **'Driver behaviour'**
  String get reportDriverBehaviour;

  /// No description provided for @reportWrongRoute.
  ///
  /// In en, this message translates to:
  /// **'Wrong route taken'**
  String get reportWrongRoute;

  /// No description provided for @reportExtraPayment.
  ///
  /// In en, this message translates to:
  /// **'Asked for extra payment'**
  String get reportExtraPayment;

  /// No description provided for @reportVehicleMismatch.
  ///
  /// In en, this message translates to:
  /// **'Vehicle did not match'**
  String get reportVehicleMismatch;

  /// No description provided for @reportSomethingElse.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get reportSomethingElse;

  /// No description provided for @addEmergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Add emergency contact'**
  String get addEmergencyContact;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Mum'**
  String get nameHint;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberLabel;

  /// No description provided for @saveContact.
  ///
  /// In en, this message translates to:
  /// **'Save contact'**
  String get saveContact;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ms'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ms':
      return AppLocalizationsMs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
