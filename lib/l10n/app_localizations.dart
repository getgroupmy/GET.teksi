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

  /// No description provided for @dutyNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'You’re online'**
  String get dutyNotificationTitle;

  /// No description provided for @dutyNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Keeping you reachable for new orders. Go offline in the app to stop.'**
  String get dutyNotificationBody;

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

  /// No description provided for @balanceCaps.
  ///
  /// In en, this message translates to:
  /// **'BALANCE'**
  String get balanceCaps;

  /// No description provided for @topUp.
  ///
  /// In en, this message translates to:
  /// **'Top up'**
  String get topUp;

  /// No description provided for @promos.
  ///
  /// In en, this message translates to:
  /// **'Promos'**
  String get promos;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment methods'**
  String get paymentMethods;

  /// No description provided for @cardExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String cardExpires(String date);

  /// No description provided for @defaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultLabel;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// No description provided for @noTransactionsBody.
  ///
  /// In en, this message translates to:
  /// **'Rides, top-ups and payouts appear here.'**
  String get noTransactionsBody;

  /// No description provided for @cashTripsNote.
  ///
  /// In en, this message translates to:
  /// **'Cash trips are settled directly with the driver and don’t move your wallet balance.'**
  String get cashTripsNote;

  /// No description provided for @topUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Top up your wallet'**
  String get topUpTitle;

  /// No description provided for @topUpUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Card payments are not connected yet, so there is no way to add to your balance. Your balance changes when a trip settles.'**
  String get topUpUnavailable;

  /// No description provided for @topUpChargedTo.
  ///
  /// In en, this message translates to:
  /// **'Charged to {card}.'**
  String topUpChargedTo(String card);

  /// No description provided for @topUpDescription.
  ///
  /// In en, this message translates to:
  /// **'Top-up from card {card}'**
  String topUpDescription(String card);

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @passengerRating.
  ///
  /// In en, this message translates to:
  /// **'Passenger rating'**
  String get passengerRating;

  /// No description provided for @tripsTakenLabel.
  ///
  /// In en, this message translates to:
  /// **'Trips taken'**
  String get tripsTakenLabel;

  /// No description provided for @driverProfile.
  ///
  /// In en, this message translates to:
  /// **'Driver profile'**
  String get driverProfile;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @driverRating.
  ///
  /// In en, this message translates to:
  /// **'Driver rating'**
  String get driverRating;

  /// No description provided for @tripsGivenLabel.
  ///
  /// In en, this message translates to:
  /// **'Trips given'**
  String get tripsGivenLabel;

  /// No description provided for @earned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get earned;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String memberSince(String date);

  /// No description provided for @ratingExplainer.
  ///
  /// In en, this message translates to:
  /// **'Your rating is the average of your last 50 trips. Passengers and drivers rate each other after every completed ride.'**
  String get ratingExplainer;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @shortcuts.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get shortcuts;

  /// No description provided for @addHome.
  ///
  /// In en, this message translates to:
  /// **'Add home'**
  String get addHome;

  /// No description provided for @addHomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your home address for one-tap booking'**
  String get addHomeSubtitle;

  /// No description provided for @removeHome.
  ///
  /// In en, this message translates to:
  /// **'Remove home'**
  String get removeHome;

  /// No description provided for @addWork.
  ///
  /// In en, this message translates to:
  /// **'Add work'**
  String get addWork;

  /// No description provided for @addWorkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your work address for one-tap booking'**
  String get addWorkSubtitle;

  /// No description provided for @removeWork.
  ///
  /// In en, this message translates to:
  /// **'Remove work'**
  String get removeWork;

  /// No description provided for @changeHome.
  ///
  /// In en, this message translates to:
  /// **'Change home'**
  String get changeHome;

  /// No description provided for @changeWork.
  ///
  /// In en, this message translates to:
  /// **'Change work'**
  String get changeWork;

  /// No description provided for @popularInKl.
  ///
  /// In en, this message translates to:
  /// **'Popular in Kuala Lumpur'**
  String get popularInKl;

  /// No description provided for @setYourHome.
  ///
  /// In en, this message translates to:
  /// **'Set your home'**
  String get setYourHome;

  /// No description provided for @setYourWork.
  ///
  /// In en, this message translates to:
  /// **'Set your work'**
  String get setYourWork;

  /// No description provided for @searchForAnAddress.
  ///
  /// In en, this message translates to:
  /// **'Search for an address'**
  String get searchForAnAddress;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get noMatches;

  /// No description provided for @noMatchesBody.
  ///
  /// In en, this message translates to:
  /// **'Try another name.'**
  String get noMatchesBody;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// No description provided for @orderGoneTitle.
  ///
  /// In en, this message translates to:
  /// **'This order is no longer available'**
  String get orderGoneTitle;

  /// No description provided for @orderGoneBody.
  ///
  /// In en, this message translates to:
  /// **'It was taken or cancelled.'**
  String get orderGoneBody;

  /// No description provided for @rideRequest.
  ///
  /// In en, this message translates to:
  /// **'Ride request'**
  String get rideRequest;

  /// No description provided for @postedAgo.
  ///
  /// In en, this message translates to:
  /// **'Posted {time}'**
  String postedAgo(String time);

  /// How many times the passenger raised their asking price. Malay does not inflect for number, so its plural has a single 'other' case.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{raised {count} time} other{raised {count} times}}'**
  String raisedTimes(int count);

  /// How many people are riding.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} passenger} other{{count} passengers}}'**
  String passengerCount(int count);

  /// No description provided for @toPickup.
  ///
  /// In en, this message translates to:
  /// **'To pickup'**
  String get toPickup;

  /// No description provided for @tripLength.
  ///
  /// In en, this message translates to:
  /// **'Trip length'**
  String get tripLength;

  /// No description provided for @carType.
  ///
  /// In en, this message translates to:
  /// **'Car type'**
  String get carType;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @orderClosedToOffers.
  ///
  /// In en, this message translates to:
  /// **'This order is no longer accepting offers.'**
  String get orderClosedToOffers;

  /// No description provided for @yourOffer.
  ///
  /// In en, this message translates to:
  /// **'Your offer'**
  String get yourOffer;

  /// No description provided for @waitingForReply.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to reply'**
  String waitingForReply(String name);

  /// No description provided for @withdrawOffer.
  ///
  /// In en, this message translates to:
  /// **'Withdraw offer'**
  String get withdrawOffer;

  /// No description provided for @passengerOffers.
  ///
  /// In en, this message translates to:
  /// **'Passenger offers'**
  String get passengerOffers;

  /// No description provided for @marketPrice.
  ///
  /// In en, this message translates to:
  /// **'Market {amount}'**
  String marketPrice(String amount);

  /// No description provided for @lowerOffer.
  ///
  /// In en, this message translates to:
  /// **'Lower offer'**
  String get lowerOffer;

  /// No description provided for @raiseOffer.
  ///
  /// In en, this message translates to:
  /// **'Raise offer'**
  String get raiseOffer;

  /// The driver's take-home on a bid, and the commission deducted from it.
  ///
  /// In en, this message translates to:
  /// **'You keep {net} after {fee} fee'**
  String youKeepAfterFee(String net, String fee);

  /// No description provided for @resetTo.
  ///
  /// In en, this message translates to:
  /// **'Reset to {amount}'**
  String resetTo(String amount);

  /// No description provided for @counterOfferWarning.
  ///
  /// In en, this message translates to:
  /// **'Counter-offers take longer to be accepted than taking the passenger’s price.'**
  String get counterOfferWarning;

  /// No description provided for @offerAmount.
  ///
  /// In en, this message translates to:
  /// **'Offer {amount}'**
  String offerAmount(String amount);

  /// No description provided for @acceptAmount.
  ///
  /// In en, this message translates to:
  /// **'Accept {amount}'**
  String acceptAmount(String amount);

  /// No description provided for @skipThisOrder.
  ///
  /// In en, this message translates to:
  /// **'Skip this order'**
  String get skipThisOrder;

  /// No description provided for @vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicle;

  /// No description provided for @notADriverTitle.
  ///
  /// In en, this message translates to:
  /// **'You’re not a driver yet'**
  String get notADriverTitle;

  /// No description provided for @notADriverBody.
  ///
  /// In en, this message translates to:
  /// **'Set up your vehicle to start receiving orders.'**
  String get notADriverBody;

  /// How many seats a vehicle has.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} seat} other{{count} seats}}'**
  String seatCount(int count);

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @editDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get editDetails;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @documentsNote.
  ///
  /// In en, this message translates to:
  /// **'Documents are verified automatically in this build. In production these would be reviewed against LPKP/APAD records before a driver can go online.'**
  String get documentsNote;

  /// No description provided for @editVehicle.
  ///
  /// In en, this message translates to:
  /// **'Edit vehicle'**
  String get editVehicle;

  /// No description provided for @plateNumber.
  ///
  /// In en, this message translates to:
  /// **'Plate number'**
  String get plateNumber;

  /// No description provided for @colour.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get colour;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @docApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get docApproved;

  /// No description provided for @docInReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get docInReview;

  /// No description provided for @docRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get docRejected;

  /// No description provided for @docNotUploaded.
  ///
  /// In en, this message translates to:
  /// **'Not uploaded'**
  String get docNotUploaded;

  /// No description provided for @expiresDate.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String expiresDate(String date);

  /// No description provided for @classHintEconomy.
  ///
  /// In en, this message translates to:
  /// **'Perodua, Proton, small sedans'**
  String get classHintEconomy;

  /// No description provided for @classHintComfort.
  ///
  /// In en, this message translates to:
  /// **'Honda City, Toyota Vios and up'**
  String get classHintComfort;

  /// No description provided for @classHintXl.
  ///
  /// In en, this message translates to:
  /// **'MPVs and 7-seaters'**
  String get classHintXl;

  /// No description provided for @driverIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Start earning with your car'**
  String get driverIntroTitle;

  /// No description provided for @driverIntroBody.
  ///
  /// In en, this message translates to:
  /// **'See ride requests near you, choose the ones worth your time, and set your own price on every trip.'**
  String get driverIntroBody;

  /// The driver's share of a fare, as a whole percentage.
  ///
  /// In en, this message translates to:
  /// **'Keep {percent}% of every fare'**
  String perkKeepTitle(String percent);

  /// The platform's commission, to one decimal place.
  ///
  /// In en, this message translates to:
  /// **'Our service fee is {percent}% — no surge splits, no hidden cuts.'**
  String perkKeepBody(String percent);

  /// No description provided for @perkHoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Drive when you want'**
  String get perkHoursTitle;

  /// No description provided for @perkHoursBody.
  ///
  /// In en, this message translates to:
  /// **'Go online and offline in one tap. No shifts, no quotas.'**
  String get perkHoursBody;

  /// No description provided for @perkChoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'You choose the order'**
  String get perkChoiceTitle;

  /// No description provided for @perkChoiceBody.
  ///
  /// In en, this message translates to:
  /// **'See the destination and the fare before you accept anything.'**
  String get perkChoiceBody;

  /// No description provided for @driverIntroDocsNote.
  ///
  /// In en, this message translates to:
  /// **'This build verifies documents automatically so you can try the driver side right away.'**
  String get driverIntroDocsNote;

  /// No description provided for @yourVehicle.
  ///
  /// In en, this message translates to:
  /// **'Your vehicle'**
  String get yourVehicle;

  /// No description provided for @make.
  ///
  /// In en, this message translates to:
  /// **'Make'**
  String get make;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @vehicleCategory.
  ///
  /// In en, this message translates to:
  /// **'Vehicle category'**
  String get vehicleCategory;

  /// No description provided for @startDriving.
  ///
  /// In en, this message translates to:
  /// **'Start driving'**
  String get startDriving;

  /// Placeholder in the vehicle colour field, and the value stored when the driver leaves it blank.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get colourHint;

  /// No description provided for @serviceCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get serviceCity;

  /// No description provided for @serviceIntercity.
  ///
  /// In en, this message translates to:
  /// **'Intercity'**
  String get serviceIntercity;

  /// No description provided for @serviceDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get serviceDelivery;

  /// No description provided for @serviceFreight.
  ///
  /// In en, this message translates to:
  /// **'Freight'**
  String get serviceFreight;

  /// No description provided for @serviceMoto.
  ///
  /// In en, this message translates to:
  /// **'Moto'**
  String get serviceMoto;

  /// The card on file, named by its last four digits.
  ///
  /// In en, this message translates to:
  /// **'Card {tail}'**
  String cardEndingIn(String tail);

  /// No description provided for @optionChildSeat.
  ///
  /// In en, this message translates to:
  /// **'Child seat'**
  String get optionChildSeat;

  /// No description provided for @optionPet.
  ///
  /// In en, this message translates to:
  /// **'Travelling with a pet'**
  String get optionPet;

  /// No description provided for @optionLuggage.
  ///
  /// In en, this message translates to:
  /// **'Large luggage'**
  String get optionLuggage;

  /// No description provided for @optionAirCon.
  ///
  /// In en, this message translates to:
  /// **'Air conditioning'**
  String get optionAirCon;

  /// No description provided for @optionNoSmoking.
  ///
  /// In en, this message translates to:
  /// **'Non-smoking car'**
  String get optionNoSmoking;

  /// No description provided for @optionSilentRide.
  ///
  /// In en, this message translates to:
  /// **'Silent ride'**
  String get optionSilentRide;

  /// No description provided for @optionFemaleDriver.
  ///
  /// In en, this message translates to:
  /// **'Prefer a female driver'**
  String get optionFemaleDriver;

  /// No description provided for @whereTo.
  ///
  /// In en, this message translates to:
  /// **'Where to?'**
  String get whereTo;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get work;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @offersReceived.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} offer received} other{{count} offers received}}'**
  String offersReceived(int count);

  /// elapsed is an already-formatted duration such as "1m 20s".
  ///
  /// In en, this message translates to:
  /// **'Your price {amount} · searching {elapsed}'**
  String yourPriceSearching(String amount, String elapsed);

  /// No description provided for @noOffersRaisePrompt.
  ///
  /// In en, this message translates to:
  /// **'No offers yet. Raising your price is the fastest way to get picked up.'**
  String get noOffersRaisePrompt;

  /// No description provided for @raiseSheetBody.
  ///
  /// In en, this message translates to:
  /// **'More drivers see your order when the fare goes up. You’re currently offering {amount}.'**
  String raiseSheetBody(String amount);

  /// Appended to the middle raise suggestion. Leading separator included so a language can drop it.
  ///
  /// In en, this message translates to:
  /// **' · recommended'**
  String get recommendedSuffix;

  /// No description provided for @cancelYourOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel your order?'**
  String get cancelYourOrder;

  /// No description provided for @cancelReasonPrompt.
  ///
  /// In en, this message translates to:
  /// **'Tell us why so we can improve matching.'**
  String get cancelReasonPrompt;

  /// No description provided for @offerMetaLine.
  ///
  /// In en, this message translates to:
  /// **'{eta} min away · {distance} · {trips} trips'**
  String offerMetaLine(int eta, String distance, String trips);

  /// No description provided for @tagSafeDriving.
  ///
  /// In en, this message translates to:
  /// **'Safe driving'**
  String get tagSafeDriving;

  /// No description provided for @tagCleanCar.
  ///
  /// In en, this message translates to:
  /// **'Clean car'**
  String get tagCleanCar;

  /// No description provided for @tagPolite.
  ///
  /// In en, this message translates to:
  /// **'Polite'**
  String get tagPolite;

  /// No description provided for @tagGoodConversation.
  ///
  /// In en, this message translates to:
  /// **'Good conversation'**
  String get tagGoodConversation;

  /// No description provided for @tagKnowsRoute.
  ///
  /// In en, this message translates to:
  /// **'Knows the route'**
  String get tagKnowsRoute;

  /// No description provided for @tagOnTime.
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get tagOnTime;

  /// No description provided for @tagHelpedLuggage.
  ///
  /// In en, this message translates to:
  /// **'Helped with luggage'**
  String get tagHelpedLuggage;

  /// No description provided for @tagComfortableRide.
  ///
  /// In en, this message translates to:
  /// **'Comfortable ride'**
  String get tagComfortableRide;

  /// No description provided for @tagRudeBehaviour.
  ///
  /// In en, this message translates to:
  /// **'Rude behaviour'**
  String get tagRudeBehaviour;

  /// No description provided for @tagDirtyCar.
  ///
  /// In en, this message translates to:
  /// **'Dirty car'**
  String get tagDirtyCar;

  /// No description provided for @tagUnsafeDriving.
  ///
  /// In en, this message translates to:
  /// **'Unsafe driving'**
  String get tagUnsafeDriving;

  /// No description provided for @tagLateArrival.
  ///
  /// In en, this message translates to:
  /// **'Late arrival'**
  String get tagLateArrival;

  /// No description provided for @tagWrongRoute.
  ///
  /// In en, this message translates to:
  /// **'Wrong route'**
  String get tagWrongRoute;

  /// No description provided for @tagAskedForMoney.
  ///
  /// In en, this message translates to:
  /// **'Asked for more money'**
  String get tagAskedForMoney;

  /// No description provided for @tagBadSmell.
  ///
  /// In en, this message translates to:
  /// **'Bad smell'**
  String get tagBadSmell;

  /// No description provided for @tagNoAirCon.
  ///
  /// In en, this message translates to:
  /// **'No air conditioning'**
  String get tagNoAirCon;

  /// No description provided for @tagPolitePassenger.
  ///
  /// In en, this message translates to:
  /// **'Polite passenger'**
  String get tagPolitePassenger;

  /// No description provided for @tagClearPickup.
  ///
  /// In en, this message translates to:
  /// **'Clear pickup point'**
  String get tagClearPickup;

  /// No description provided for @tagLeftCarClean.
  ///
  /// In en, this message translates to:
  /// **'Left car clean'**
  String get tagLeftCarClean;

  /// No description provided for @tagKeptMeWaiting.
  ///
  /// In en, this message translates to:
  /// **'Kept me waiting'**
  String get tagKeptMeWaiting;

  /// No description provided for @tagWrongPickup.
  ///
  /// In en, this message translates to:
  /// **'Wrong pickup point'**
  String get tagWrongPickup;

  /// No description provided for @tagTooManyPassengers.
  ///
  /// In en, this message translates to:
  /// **'Too many passengers'**
  String get tagTooManyPassengers;

  /// No description provided for @tagMessy.
  ///
  /// In en, this message translates to:
  /// **'Messy'**
  String get tagMessy;

  /// No description provided for @phraseAtPickup.
  ///
  /// In en, this message translates to:
  /// **'I’m at the pickup point'**
  String get phraseAtPickup;

  /// No description provided for @phraseTwoMinutes.
  ///
  /// In en, this message translates to:
  /// **'Give me 2 minutes please'**
  String get phraseTwoMinutes;

  /// No description provided for @phraseBlueShirt.
  ///
  /// In en, this message translates to:
  /// **'I’m wearing a blue shirt'**
  String get phraseBlueShirt;

  /// No description provided for @phraseWhichCar.
  ///
  /// In en, this message translates to:
  /// **'Which car are you in?'**
  String get phraseWhichCar;

  /// No description provided for @phraseCallOnArrival.
  ///
  /// In en, this message translates to:
  /// **'Please call me when you arrive'**
  String get phraseCallOnArrival;

  /// No description provided for @phraseThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you!'**
  String get phraseThankYou;

  /// No description provided for @phraseOnMyWay.
  ///
  /// In en, this message translates to:
  /// **'I’m on my way'**
  String get phraseOnMyWay;

  /// No description provided for @phraseArrivedWaiting.
  ///
  /// In en, this message translates to:
  /// **'I’ve arrived, waiting outside'**
  String get phraseArrivedWaiting;

  /// No description provided for @phraseTrafficLate.
  ///
  /// In en, this message translates to:
  /// **'Traffic is heavy, running 5 min late'**
  String get phraseTrafficLate;

  /// No description provided for @phraseWhereToStop.
  ///
  /// In en, this message translates to:
  /// **'Where exactly should I stop?'**
  String get phraseWhereToStop;

  /// No description provided for @phraseComeOut.
  ///
  /// In en, this message translates to:
  /// **'Please come out, I cannot wait here'**
  String get phraseComeOut;

  /// No description provided for @cancelDriverTooLong.
  ///
  /// In en, this message translates to:
  /// **'Driver is taking too long'**
  String get cancelDriverTooLong;

  /// No description provided for @cancelDriverAsked.
  ///
  /// In en, this message translates to:
  /// **'Driver asked me to cancel'**
  String get cancelDriverAsked;

  /// No description provided for @cancelNoLongerNeed.
  ///
  /// In en, this message translates to:
  /// **'I no longer need the ride'**
  String get cancelNoLongerNeed;

  /// No description provided for @cancelWrongPickupAddress.
  ///
  /// In en, this message translates to:
  /// **'Wrong pickup address'**
  String get cancelWrongPickupAddress;

  /// No description provided for @cancelFoundAnother.
  ///
  /// In en, this message translates to:
  /// **'Found another ride'**
  String get cancelFoundAnother;

  /// No description provided for @cancelPriceTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Price is too high'**
  String get cancelPriceTooHigh;

  /// No description provided for @cancelPassengerSilent.
  ///
  /// In en, this message translates to:
  /// **'Passenger is not responding'**
  String get cancelPassengerSilent;

  /// No description provided for @cancelPassengerNoShow.
  ///
  /// In en, this message translates to:
  /// **'Passenger did not show up'**
  String get cancelPassengerNoShow;

  /// No description provided for @cancelPickupUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Pickup point is unreachable'**
  String get cancelPickupUnreachable;

  /// No description provided for @cancelTooFar.
  ///
  /// In en, this message translates to:
  /// **'Too far from my location'**
  String get cancelTooFar;

  /// No description provided for @cancelVehicleProblem.
  ///
  /// In en, this message translates to:
  /// **'Vehicle problem'**
  String get cancelVehicleProblem;

  /// No description provided for @cancelPassengerAsked.
  ///
  /// In en, this message translates to:
  /// **'Passenger asked to cancel'**
  String get cancelPassengerAsked;

  /// No description provided for @promoHalfOff.
  ///
  /// In en, this message translates to:
  /// **'50% off your next ride, up to RM10'**
  String get promoHalfOff;

  /// No description provided for @promoFiveOff.
  ///
  /// In en, this message translates to:
  /// **'RM5 off any trip'**
  String get promoFiveOff;

  /// No description provided for @promoAirport.
  ///
  /// In en, this message translates to:
  /// **'RM15 off an airport transfer'**
  String get promoAirport;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @chatUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversation unavailable'**
  String get chatUnavailableTitle;

  /// No description provided for @chatUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'This ride no longer exists.'**
  String get chatUnavailableBody;

  /// No description provided for @passengerLabel.
  ///
  /// In en, this message translates to:
  /// **'Passenger'**
  String get passengerLabel;

  /// No description provided for @yourDriver.
  ///
  /// In en, this message translates to:
  /// **'Your driver'**
  String get yourDriver;

  /// No description provided for @chatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{who} · trip to {destination}'**
  String chatSubtitle(String who, String destination);

  /// No description provided for @chatOnlyDuringTrip.
  ///
  /// In en, this message translates to:
  /// **'Messages are only available during the trip.'**
  String get chatOnlyDuringTrip;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Message…'**
  String get messageHint;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @rideNotFound.
  ///
  /// In en, this message translates to:
  /// **'Ride not found'**
  String get rideNotFound;

  /// No description provided for @tripCompleted.
  ///
  /// In en, this message translates to:
  /// **'Trip completed'**
  String get tripCompleted;

  /// No description provided for @howWasYourTrip.
  ///
  /// In en, this message translates to:
  /// **'How was your trip?'**
  String get howWasYourTrip;

  /// No description provided for @howWasYourTripDriver.
  ///
  /// In en, this message translates to:
  /// **'How was your trip with them?'**
  String get howWasYourTripDriver;

  /// No description provided for @addACommentOptional.
  ///
  /// In en, this message translates to:
  /// **'Add a comment (optional)'**
  String get addACommentOptional;

  /// No description provided for @addATipFor.
  ///
  /// In en, this message translates to:
  /// **'Add a tip for {name}'**
  String addATipFor(String name);

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @submitAndTip.
  ///
  /// In en, this message translates to:
  /// **'Submit and tip {amount}'**
  String submitAndTip(String amount);

  /// No description provided for @submitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit rating'**
  String get submitRating;

  /// No description provided for @promoInvalid.
  ///
  /// In en, this message translates to:
  /// **'That code isn’t valid or has expired.'**
  String get promoInvalid;

  /// No description provided for @promoApplied.
  ///
  /// In en, this message translates to:
  /// **'{code} applied — {label}'**
  String promoApplied(String code, String label);

  /// No description provided for @enterAPromoCode.
  ///
  /// In en, this message translates to:
  /// **'Enter a promo code'**
  String get enterAPromoCode;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @availableForYou.
  ///
  /// In en, this message translates to:
  /// **'Available for you'**
  String get availableForYou;

  /// The spend a promo code requires. Distinct from minimumFare, which labels the driver's filter.
  ///
  /// In en, this message translates to:
  /// **'Minimum fare {amount}'**
  String minimumFareIs(String amount);

  /// No description provided for @use.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get use;

  /// No description provided for @inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite friends'**
  String get inviteFriends;

  /// No description provided for @referralBody.
  ///
  /// In en, this message translates to:
  /// **'Give a friend {amount} off their first ride and get {amount} when they take it.'**
  String referralBody(String amount);

  /// No description provided for @copyReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Copy referral code'**
  String get copyReferralCode;

  /// No description provided for @referralCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Referral code copied'**
  String get referralCodeCopied;

  /// No description provided for @inviteText.
  ///
  /// In en, this message translates to:
  /// **'Use my GET.teksi code {code} and get {amount} off your first ride.'**
  String inviteText(String code, String amount);

  /// No description provided for @inviteCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite copied to clipboard'**
  String get inviteCopied;

  /// No description provided for @shareInvite.
  ///
  /// In en, this message translates to:
  /// **'Share invite'**
  String get shareInvite;

  /// No description provided for @setYourRoute.
  ///
  /// In en, this message translates to:
  /// **'Set your route'**
  String get setYourRoute;

  /// No description provided for @pickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Pickup location'**
  String get pickupLocation;

  /// No description provided for @stopAlongTheWay.
  ///
  /// In en, this message translates to:
  /// **'Stop along the way'**
  String get stopAlongTheWay;

  /// No description provided for @addAStop.
  ///
  /// In en, this message translates to:
  /// **'Add a stop'**
  String get addAStop;

  /// No description provided for @noMatchingPlaces.
  ///
  /// In en, this message translates to:
  /// **'No matching places'**
  String get noMatchingPlaces;

  /// No description provided for @noMatchingPlacesBody.
  ///
  /// In en, this message translates to:
  /// **'Try a mall, a station, or a neighbourhood name.'**
  String get noMatchingPlacesBody;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// No description provided for @netEarnings.
  ///
  /// In en, this message translates to:
  /// **'Net earnings'**
  String get netEarnings;

  /// No description provided for @trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get trips;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @averageFare.
  ///
  /// In en, this message translates to:
  /// **'Average fare'**
  String get averageFare;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @perHour.
  ///
  /// In en, this message translates to:
  /// **'Per hour'**
  String get perHour;

  /// No description provided for @noCompletedTrips.
  ///
  /// In en, this message translates to:
  /// **'No completed trips yet'**
  String get noCompletedTrips;

  /// No description provided for @noCompletedTripsBody.
  ///
  /// In en, this message translates to:
  /// **'Go online and accept an order — your earnings will show up here.'**
  String get noCompletedTripsBody;

  /// No description provided for @asPassenger.
  ///
  /// In en, this message translates to:
  /// **'As passenger'**
  String get asPassenger;

  /// No description provided for @asDriver.
  ///
  /// In en, this message translates to:
  /// **'As driver'**
  String get asDriver;

  /// No description provided for @noRidesYet.
  ///
  /// In en, this message translates to:
  /// **'No rides yet'**
  String get noRidesYet;

  /// No description provided for @noRidesDriverBody.
  ///
  /// In en, this message translates to:
  /// **'Completed trips you drive will appear here.'**
  String get noRidesDriverBody;

  /// No description provided for @noRidesPassengerBody.
  ///
  /// In en, this message translates to:
  /// **'Book your first ride and it will show up here.'**
  String get noRidesPassengerBody;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @youRated.
  ///
  /// In en, this message translates to:
  /// **'You rated {stars}'**
  String youRated(int stars);

  /// No description provided for @verdictLowLabel.
  ///
  /// In en, this message translates to:
  /// **'Below market'**
  String get verdictLowLabel;

  /// No description provided for @verdictLowHint.
  ///
  /// In en, this message translates to:
  /// **'Drivers may skip this. Expect a longer wait.'**
  String get verdictLowHint;

  /// No description provided for @verdictFairLabel.
  ///
  /// In en, this message translates to:
  /// **'Fair price'**
  String get verdictFairLabel;

  /// No description provided for @verdictFairHint.
  ///
  /// In en, this message translates to:
  /// **'Around what drivers usually accept on this route.'**
  String get verdictFairHint;

  /// No description provided for @verdictGoodLabel.
  ///
  /// In en, this message translates to:
  /// **'Great price'**
  String get verdictGoodLabel;

  /// No description provided for @verdictGoodHint.
  ///
  /// In en, this message translates to:
  /// **'Drivers respond quickly to offers like this.'**
  String get verdictGoodHint;

  /// No description provided for @verdictHighLabel.
  ///
  /// In en, this message translates to:
  /// **'Above market'**
  String get verdictHighLabel;

  /// No description provided for @verdictHighHint.
  ///
  /// In en, this message translates to:
  /// **'You’re offering more than this trip usually costs.'**
  String get verdictHighHint;

  /// No description provided for @simulatedMarketplaceRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bot drivers bid on your orders and bot passengers post rides'**
  String get simulatedMarketplaceRowSubtitle;

  /// No description provided for @simulationBanner.
  ///
  /// In en, this message translates to:
  /// **'With this on you can walk both sides of the marketplace on one device: bots bid on your orders as a passenger, and post orders into your feed as a driver.'**
  String get simulationBanner;

  /// No description provided for @appNameVersion.
  ///
  /// In en, this message translates to:
  /// **'GET.teksi 1.0.0'**
  String get appNameVersion;

  /// No description provided for @builtWith.
  ///
  /// In en, this message translates to:
  /// **'Built with Flutter · Android, iOS, Web, HarmonyOS'**
  String get builtWith;

  /// No description provided for @tripDetails.
  ///
  /// In en, this message translates to:
  /// **'Trip details'**
  String get tripDetails;

  /// No description provided for @refIs.
  ///
  /// In en, this message translates to:
  /// **'Ref {reference}'**
  String refIs(String reference);

  /// No description provided for @fareBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Fare breakdown'**
  String get fareBreakdown;

  /// No description provided for @agreedPrice.
  ///
  /// In en, this message translates to:
  /// **'Agreed price'**
  String get agreedPrice;

  /// No description provided for @yourOriginalOffer.
  ///
  /// In en, this message translates to:
  /// **'Your original offer'**
  String get yourOriginalOffer;

  /// No description provided for @priceRaisedTimes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Price raised {count}×} other{Price raised {count}×}}'**
  String priceRaisedTimes(int count);

  /// No description provided for @serviceFee.
  ///
  /// In en, this message translates to:
  /// **'Service fee'**
  String get serviceFee;

  /// No description provided for @youEarned.
  ///
  /// In en, this message translates to:
  /// **'You earned'**
  String get youEarned;

  /// No description provided for @tip.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get tip;

  /// No description provided for @totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total paid'**
  String get totalPaid;

  /// method is one of paidByCash / paidByCard / paidByWallet.
  ///
  /// In en, this message translates to:
  /// **'Paid by {method}'**
  String paidBy(String method);

  /// No description provided for @paidByCash.
  ///
  /// In en, this message translates to:
  /// **'cash'**
  String get paidByCash;

  /// No description provided for @paidByCard.
  ///
  /// In en, this message translates to:
  /// **'card {tail}'**
  String paidByCard(String tail);

  /// No description provided for @paidByWallet.
  ///
  /// In en, this message translates to:
  /// **'wallet'**
  String get paidByWallet;

  /// No description provided for @yourRating.
  ///
  /// In en, this message translates to:
  /// **'Your rating'**
  String get yourRating;

  /// No description provided for @tripReferenceCopied.
  ///
  /// In en, this message translates to:
  /// **'Trip reference copied'**
  String get tripReferenceCopied;

  /// No description provided for @copyTripReference.
  ///
  /// In en, this message translates to:
  /// **'Copy trip reference'**
  String get copyTripReference;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get currentLocation;

  /// No description provided for @pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// No description provided for @drive.
  ///
  /// In en, this message translates to:
  /// **'Drive'**
  String get drive;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @switchToPassengerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch to passenger'**
  String get switchToPassengerTooltip;

  /// Screen-reader label for the driver's earnings pill.
  ///
  /// In en, this message translates to:
  /// **'Earnings, {amount}, {status}'**
  String earningsSemantics(String amount, String status);

  /// No description provided for @onlineWord.
  ///
  /// In en, this message translates to:
  /// **'online'**
  String get onlineWord;

  /// No description provided for @offlineWord.
  ///
  /// In en, this message translates to:
  /// **'offline'**
  String get offlineWord;

  /// A duration under an hour.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// A whole number of hours. Malay abbreviates jam as j.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String durationHours(int hours);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @secondsAgo.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s ago'**
  String secondsAgo(int seconds);

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String minutesAgo(int minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} h ago'**
  String hoursAgo(int hours);

  /// Malay abbreviates hari as h.
  ///
  /// In en, this message translates to:
  /// **'{days} d ago'**
  String daysAgo(int days);

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @ordersNearby.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} order nearby} other{{count} orders nearby}}'**
  String ordersNearby(int count);

  /// No description provided for @distanceToPickup.
  ///
  /// In en, this message translates to:
  /// **'{distance} to pickup · {duration}'**
  String distanceToPickup(String distance, String duration);

  /// No description provided for @clearLocalDataConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This removes all rides, offers, messages and transactions stored on this device. Your profile stays signed in.'**
  String get clearLocalDataConfirmBody;

  /// No description provided for @nothingNew.
  ///
  /// In en, this message translates to:
  /// **'Nothing new'**
  String get nothingNew;

  /// No description provided for @nothingNewBody.
  ///
  /// In en, this message translates to:
  /// **'Ride updates, offers and promos will show up here.'**
  String get nothingNewBody;

  /// No description provided for @lowerFareTooltip.
  ///
  /// In en, this message translates to:
  /// **'Lower fare'**
  String get lowerFareTooltip;

  /// No description provided for @raiseFareTooltip.
  ///
  /// In en, this message translates to:
  /// **'Raise fare'**
  String get raiseFareTooltip;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;
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
