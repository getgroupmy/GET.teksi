// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get onboardTitle1 => 'Tetapkan tambang anda sendiri';

  @override
  String get onboardBody1 =>
      'Tiada meter tetap, tiada harga melonjak. Anda tetapkan nilai perjalanan, pemandu balas dengan harga mereka.';

  @override
  String get onboardTitle2 => 'Menumpang dan memandu dalam satu apl';

  @override
  String get onboardBody2 =>
      'Tukar antara penumpang dan pemandu bila-bila masa. Satu profil, satu dompet, satu sejarah.';

  @override
  String get onboardTitle3 => 'Keselamatan disediakan';

  @override
  String get onboardBody3 =>
      'Kongsi perjalanan anda, minta bantuan, dan lihat penarafan setiap pemandu sebelum anda menerima harga.';

  @override
  String get skip => 'Langkau';

  @override
  String get next => 'Seterusnya';

  @override
  String get getStarted => 'Mula';

  @override
  String get phoneTitle => 'Masukkan nombor telefon anda';

  @override
  String get phoneSubtitle =>
      'Kami akan hantar kod 6 digit untuk mengesahkan anda.';

  @override
  String get phoneTerms =>
      'Dengan meneruskan, anda bersetuju dengan Terma Perkhidmatan dan Dasar Privasi. Kadar mesej biasa mungkin dikenakan.';

  @override
  String get phoneSendFailed =>
      'Kami tidak dapat menghantar kod ke nombor itu.';

  @override
  String get continueLabel => 'Teruskan';

  @override
  String get otpTitle => 'Masukkan kod';

  @override
  String otpSentTo(String phone) {
    return 'Dihantar ke $phone';
  }

  @override
  String otpResendIn(int seconds) {
    return 'Hantar semula kod dalam ${seconds}s';
  }

  @override
  String get otpResend => 'Hantar semula kod';

  @override
  String get otpVerify => 'Sahkan';

  @override
  String get otpMismatch =>
      'Kod itu tidak sepadan. Semak kod yang ditunjukkan di bawah.';

  @override
  String get otpUnverified => 'Kod itu tidak dapat disahkan. Minta kod baharu.';

  @override
  String get otpWrongOrExpired => 'Kod itu salah atau telah tamat tempoh.';

  @override
  String get otpResendFailed => 'Tidak dapat menghantar kod baharu.';

  @override
  String get otpDemoPrefix =>
      'Binaan demo — tiada SMS dihantar. Kod anda ialah ';

  @override
  String get profileTitle => 'Apa nama panggilan anda?';

  @override
  String get profileSubtitle =>
      'Pemandu dan penumpang akan melihat nama dan gambar ini.';

  @override
  String get profileFullName => 'Nama penuh';

  @override
  String get profileEmail => 'E-mel (pilihan)';

  @override
  String get profileStart => 'Mula menumpang';

  @override
  String get settings => 'Tetapan';

  @override
  String get appearance => 'Paparan';

  @override
  String get darkTheme => 'Tema gelap';

  @override
  String get preferences => 'Keutamaan';

  @override
  String get languageName => 'Bahasa Melayu';

  @override
  String get language => 'Bahasa';

  @override
  String get sounds => 'Bunyi dan getaran';

  @override
  String get on => 'Hidup';

  @override
  String get off => 'Mati';

  @override
  String get demo => 'Demo';

  @override
  String get simulatedMarketplace => 'Pasaran simulasi';

  @override
  String get simulatedMarketplaceSubtitle =>
      'Pemandu bot membida pesanan anda dan penumpang bot menghantar perjalanan';

  @override
  String get clearLocalData => 'Kosongkan data setempat';

  @override
  String get clearLocalDataSubtitle =>
      'Padam perjalanan, tawaran dan mesej pada peranti ini';

  @override
  String get clearLocalDataConfirmTitle => 'Kosongkan data setempat?';

  @override
  String get clearEverything => 'Kosongkan semua';

  @override
  String get cancel => 'Batal';

  @override
  String get about => 'Perihal';

  @override
  String get version => 'Versi';

  @override
  String get termsOfService => 'Terma perkhidmatan';

  @override
  String get privacyPolicy => 'Dasar privasi';

  @override
  String get yourPrice => 'Harga anda';

  @override
  String recommendedFare(String amount) {
    return 'Disyorkan $amount';
  }

  @override
  String get chooseCarType => 'Pilih jenis kereta';

  @override
  String get carEconomy => 'Kereta harian, 4 tempat duduk';

  @override
  String get carComfort => 'Kereta lebih baharu dan lapang';

  @override
  String get carXl => 'Sehingga 6 penumpang';

  @override
  String get paymentMethod => 'Cara pembayaran';

  @override
  String get cashNote =>
      'Tunai dibayar terus kepada pemandu pada akhir perjalanan.';

  @override
  String balanceIs(String amount) {
    return 'Baki $amount';
  }

  @override
  String get tripOptions => 'Pilihan perjalanan';

  @override
  String get extras => 'Tambahan';

  @override
  String get noteForDriver => 'Nota untuk pemandu';

  @override
  String get note => 'Nota';

  @override
  String get noteAdded => 'Nota ditambah';

  @override
  String get saveNote => 'Simpan nota';

  @override
  String get done => 'Selesai';

  @override
  String findDriverFor(String amount) {
    return 'Cari pemandu untuk $amount';
  }

  @override
  String get lookingForDrivers => 'Mencari pemandu…';

  @override
  String get noOffersYet =>
      'Belum ada tawaran. Menaikkan harga anda ialah cara terpantas untuk dijemput.';

  @override
  String get raiseYourPrice => 'Naikkan harga anda';

  @override
  String get raiseFare => 'Naikkan tambang';

  @override
  String get lowerFare => 'Turunkan tambang';

  @override
  String get moreDriversWhenHigher =>
      'Lebih ramai pemandu melihat pesanan anda apabila tambang dinaikkan.';

  @override
  String get cancelSearch => 'Batal carian';

  @override
  String get cancelOrderTitle => 'Batalkan pesanan anda?';

  @override
  String get keepSearching => 'Teruskan mencari';

  @override
  String get declineOffer => 'Tolak tawaran';

  @override
  String get declineReasonPrompt =>
      'Beritahu kami sebabnya supaya kami boleh menambah baik padanan.';

  @override
  String get accept => 'Terima';

  @override
  String balanceInsufficient(String amount) {
    return 'Baki $amount — tidak mencukupi untuk tambang ini';
  }

  @override
  String get driverOnTheWay => 'Pemandu dalam perjalanan';

  @override
  String get driverArriving => 'Pemandu hampir tiba';

  @override
  String get driverWaiting => 'Pemandu anda sedang menunggu';

  @override
  String get enjoyTheRide => 'Selamat menikmati perjalanan';

  @override
  String get meetAtPickup => 'Jumpa pemandu anda di tempat menaiki';

  @override
  String get headToPickup => 'Sila mula menuju ke tempat menaiki';

  @override
  String get driverArrivedFreeWait =>
      'Pemandu anda telah tiba. Masa menunggu percuma selama 3 minit.';

  @override
  String get onTheWayToDestination => 'Dalam perjalanan ke destinasi anda';

  @override
  String get callLabel => 'Panggil';

  @override
  String get chatLabel => 'Sembang';

  @override
  String get safetyLabel => 'Keselamatan';

  @override
  String get shareLabel => 'Kongsi';

  @override
  String get shareYourTrip => 'Kongsi perjalanan anda';

  @override
  String get shareTripBody =>
      'Hantar butiran ini kepada orang yang anda percayai — ia sudah disalin ke papan keratan anda.';

  @override
  String callingName(String name) {
    return 'Menghubungi $name…';
  }

  @override
  String get cancelRide => 'Batal perjalanan';

  @override
  String get cancelRideTitle => 'Batalkan perjalanan ini?';

  @override
  String get cancelRideBody =>
      'Pemandu anda sudah dalam perjalanan. Pembatalan lewat yang kerap boleh menjejaskan penarafan anda.';

  @override
  String get keepMyRide => 'Teruskan perjalanan';

  @override
  String get payInCash => 'Bayar tunai';

  @override
  String get driverLabel => 'Pemandu';

  @override
  String get freeWaitNote => 'Mereka boleh menunggu beberapa minit tanpa caj';

  @override
  String get youreOffline => 'Anda di luar talian';

  @override
  String get goOnline => 'Mula dalam talian';

  @override
  String get goOffline => 'Keluar dari talian';

  @override
  String get goOnlinePrompt =>
      'Mulakan dalam talian untuk melihat permintaan berhampiran dan hantar harga anda.';

  @override
  String get waitingForOrders => 'Menunggu pesanan';

  @override
  String get stayOnlinePrompt =>
      'Kekal dalam talian — permintaan baharu muncul di sini apabila penumpang menghantarnya.';

  @override
  String get noOrdersMatch => 'Tiada pesanan sepadan buat masa ini';

  @override
  String get offerWaitingReply => 'Tawaran anda menunggu jawapan';

  @override
  String get filters => 'Penapis';

  @override
  String get filterOrders => 'Tapis pesanan';

  @override
  String get applyFilters => 'Guna penapis';

  @override
  String get minimumFare => 'Tambang minimum';

  @override
  String get maxPickupDistance => 'Jarak maksimum ke tempat menaiki';

  @override
  String get sortNearest => 'Terdekat';

  @override
  String get sortHighest => 'Tertinggi';

  @override
  String get sortNewest => 'Terbaharu';

  @override
  String get viewTodaysEarnings => 'Lihat pendapatan hari ini';

  @override
  String pickUpName(String name) {
    return 'Jemput $name';
  }

  @override
  String toDestination(String place) {
    return 'Ke $place';
  }

  @override
  String get waitingForPassenger => 'Menunggu penumpang';

  @override
  String get freeWaitDriverNote =>
      'Masa menunggu percuma ialah 3 minit. Hantar mesej kepada penumpang jika mereka belum keluar.';

  @override
  String get startTheTrip => 'Mulakan perjalanan';

  @override
  String finishTripFor(String amount) {
    return 'Tamatkan perjalanan · $amount';
  }

  @override
  String feeIs(String amount) {
    return 'Yuran $amount';
  }

  @override
  String get navigate => 'Navigasi';

  @override
  String navigatingTo(String place) {
    return 'Menuju ke $place…';
  }

  @override
  String get cancelThisOrder => 'Batalkan pesanan ini';

  @override
  String get cancelOrderConfirmTitle => 'Batalkan pesanan?';

  @override
  String get cancelOrderBody =>
      'Terlalu kerap membatalkan pesanan yang diterima menurunkan keutamaan anda dalam senarai.';

  @override
  String get keepTheOrder => 'Kekalkan pesanan';

  @override
  String get cash => 'Tunai';

  @override
  String get card => 'Kad';

  @override
  String get wallet => 'Dompet';

  @override
  String get anyAmount => 'Mana-mana';

  @override
  String youreOnlineWith(String plate) {
    return 'Anda dalam talian · $plate';
  }

  @override
  String tripDistance(String distance) {
    return 'Perjalanan $distance';
  }

  @override
  String tripDistanceDuration(String distance, String duration) {
    return 'Perjalanan $distance · $duration';
  }

  @override
  String shareTripMessage(
    String destination,
    String driver,
    String vehicle,
    String plate,
    String ref,
  ) {
    return 'Saya dalam perjalanan GET.teksi ke $destination. Pemandu: $driver ($vehicle, $plate). Ruj. $ref.';
  }

  @override
  String get menu => 'Menu';

  @override
  String tripsGiven(int count) {
    return '$count perjalanan diberi';
  }

  @override
  String tripsTaken(int count) {
    return '$count perjalanan diambil';
  }

  @override
  String get switchToPassenger => 'Tukar kepada penumpang';

  @override
  String get switchToDriver => 'Tukar kepada pemandu';

  @override
  String get becomeADriver => 'Jadi pemandu';

  @override
  String get myRides => 'Perjalanan saya';

  @override
  String get myRidesSubtitle => 'Sejarah perjalanan dan resit';

  @override
  String get promoCodes => 'Kod promosi';

  @override
  String get promoCodesSubtitle => 'Diskaun dan rujukan';

  @override
  String get savedPlaces => 'Tempat disimpan';

  @override
  String get savedPlacesSubtitle => 'Rumah, kerja dan kegemaran';

  @override
  String get earnings => 'Pendapatan';

  @override
  String get earningsSubtitle => 'Jumlah harian dan mingguan';

  @override
  String get vehicleAndDocuments => 'Kenderaan & dokumen';

  @override
  String get safetyCentre => 'Pusat keselamatan';

  @override
  String get safetyCentreSubtitle => 'Kenalan kecemasan dan SOS';

  @override
  String get signOut => 'Log keluar';

  @override
  String get signOutConfirmTitle => 'Log keluar?';

  @override
  String get signOutBody =>
      'Perjalanan dan sejarah anda kekal pada peranti ini melainkan anda memadamkannya.';

  @override
  String get signOutAndErase => 'Log keluar dan padam semua data tempatan';

  @override
  String get appVersionLine => 'GET.teksi · v1.0.0';

  @override
  String get safetyAlertNoTrip =>
      'AMARAN KESELAMATAN — sila periksa keadaan saya.';

  @override
  String safetyAlertTrip(
    String destination,
    String driver,
    String plate,
    String ref,
  ) {
    return 'AMARAN KESELAMATAN — saya dalam perjalanan GET.teksi ke $destination. Pemandu $driver, $plate. Ruj. $ref.';
  }

  @override
  String get unknownDriver => 'tidak diketahui';

  @override
  String get noPlate => 'tiada nombor plat';

  @override
  String get emergencySos => 'SOS kecemasan';

  @override
  String emergencySosSubtitle(String number) {
    return 'Hubungi $number dan maklumkan kenalan anda';
  }

  @override
  String activeTripBanner(String destination, String vehicle) {
    return 'Perjalanan aktif ke $destination$vehicle. Kenalan anda boleh melihat butiran ini apabila anda kongsi perjalanan.';
  }

  @override
  String get duringATrip => 'Semasa perjalanan';

  @override
  String get shareMyTrip => 'Kongsi perjalanan saya';

  @override
  String get shareMyTripSubtitle =>
      'Hantar butiran perjalanan langsung kepada orang yang anda percayai';

  @override
  String get tripDetailsCopied => 'Butiran perjalanan disalin ke papan klip';

  @override
  String get reportAProblem => 'Laporkan masalah';

  @override
  String get reportAProblemSubtitle =>
      'Pemanduan, kelakuan, laluan atau bayaran';

  @override
  String get supportTitle => 'Sokongan 24/7';

  @override
  String get supportSubtitle => 'Bercakap dengan ejen GET.teksi';

  @override
  String get connectingToSupport => 'Menghubungkan anda kepada sokongan…';

  @override
  String get emergencyContacts => 'KENALAN KECEMASAN';

  @override
  String get add => 'Tambah';

  @override
  String get noEmergencyContacts =>
      'Belum ada kenalan. Tambah seseorang yang patut dimaklumkan jika anda menekan SOS.';

  @override
  String get remove => 'Buang';

  @override
  String sosBodyNoContacts(String number) {
    return 'Kami akan membuat panggilan ke $number dan menyalin butiran perjalanan anda supaya anda boleh menghantarnya kepada kenalan anda.';
  }

  @override
  String sosBodyWithContacts(String number, int count) {
    return 'Kami akan membuat panggilan ke $number dan menyalin butiran perjalanan anda supaya anda boleh menghantarnya kepada $count kenalan kecemasan anda.';
  }

  @override
  String get sosTriggered => 'SOS diaktifkan';

  @override
  String get sosTriggeredBody =>
      'Butiran perjalanan disalin. Sokongan telah dimaklumkan.';

  @override
  String callingEmergency(String number) {
    return 'Menghubungi $number…';
  }

  @override
  String callEmergency(String number) {
    return 'Hubungi $number';
  }

  @override
  String get reportSubmitted => 'Laporan dihantar';

  @override
  String reportSubmittedBody(String reason) {
    return '$reason — pasukan keselamatan kami akan susuli dalam masa 24 jam.';
  }

  @override
  String get reportUnsafeDriving => 'Pemanduan tidak selamat';

  @override
  String get reportDriverBehaviour => 'Kelakuan pemandu';

  @override
  String get reportWrongRoute => 'Laluan yang salah diambil';

  @override
  String get reportExtraPayment => 'Meminta bayaran tambahan';

  @override
  String get reportVehicleMismatch => 'Kenderaan tidak sepadan';

  @override
  String get reportSomethingElse => 'Perkara lain';

  @override
  String get addEmergencyContact => 'Tambah kenalan kecemasan';

  @override
  String get nameLabel => 'Nama';

  @override
  String get nameHint => 'cth. Mak';

  @override
  String get phoneNumberLabel => 'Nombor telefon';

  @override
  String get saveContact => 'Simpan kenalan';

  @override
  String get balanceCaps => 'BAKI';

  @override
  String get topUp => 'Tambah nilai';

  @override
  String get promos => 'Promosi';

  @override
  String get paymentMethods => 'Kaedah pembayaran';

  @override
  String cardExpires(String date) {
    return 'Luput $date';
  }

  @override
  String get defaultLabel => 'Lalai';

  @override
  String get activity => 'Aktiviti';

  @override
  String get noTransactions => 'Belum ada transaksi';

  @override
  String get noTransactionsBody =>
      'Perjalanan, tambah nilai dan pengeluaran akan muncul di sini.';

  @override
  String get cashTripsNote =>
      'Perjalanan tunai diselesaikan terus dengan pemandu dan tidak menjejaskan baki dompet anda.';

  @override
  String get topUpTitle => 'Tambah nilai dompet anda';

  @override
  String get topUpUnavailable =>
      'Pembayaran kad belum disambungkan, jadi tiada cara untuk menambah baki anda. Baki anda berubah apabila sesuatu perjalanan diselesaikan.';

  @override
  String topUpChargedTo(String card) {
    return 'Dicaj kepada $card.';
  }

  @override
  String topUpDescription(String card) {
    return 'Tambah nilai daripada kad $card';
  }

  @override
  String get profile => 'Profil';

  @override
  String get edit => 'Sunting';

  @override
  String get passengerRating => 'Penilaian penumpang';

  @override
  String get tripsTakenLabel => 'Perjalanan diambil';

  @override
  String get driverProfile => 'Profil pemandu';

  @override
  String get verified => 'Disahkan';

  @override
  String get driverRating => 'Penilaian pemandu';

  @override
  String get tripsGivenLabel => 'Perjalanan diberi';

  @override
  String get earned => 'Diperoleh';

  @override
  String memberSince(String date) {
    return 'Ahli sejak $date';
  }

  @override
  String get ratingExplainer =>
      'Penilaian anda ialah purata 50 perjalanan terakhir anda. Penumpang dan pemandu menilai satu sama lain selepas setiap perjalanan selesai.';

  @override
  String get editProfile => 'Sunting profil';

  @override
  String get fullName => 'Nama penuh';

  @override
  String get email => 'E-mel';

  @override
  String get save => 'Simpan';

  @override
  String get shortcuts => 'Pintasan';

  @override
  String get addHome => 'Tambah rumah';

  @override
  String get addHomeSubtitle =>
      'Tetapkan alamat rumah anda untuk tempahan satu ketikan';

  @override
  String get removeHome => 'Buang rumah';

  @override
  String get addWork => 'Tambah tempat kerja';

  @override
  String get addWorkSubtitle =>
      'Tetapkan alamat tempat kerja anda untuk tempahan satu ketikan';

  @override
  String get removeWork => 'Buang tempat kerja';

  @override
  String get changeHome => 'Tukar rumah';

  @override
  String get changeWork => 'Tukar tempat kerja';

  @override
  String get popularInKl => 'Popular di Kuala Lumpur';

  @override
  String get setYourHome => 'Tetapkan rumah anda';

  @override
  String get setYourWork => 'Tetapkan tempat kerja anda';

  @override
  String get searchForAnAddress => 'Cari alamat';

  @override
  String get noMatches => 'Tiada padanan';

  @override
  String get noMatchesBody => 'Cuba nama lain.';

  @override
  String get order => 'Pesanan';

  @override
  String get orderGoneTitle => 'Pesanan ini tidak lagi tersedia';

  @override
  String get orderGoneBody => 'Ia telah diambil atau dibatalkan.';

  @override
  String get rideRequest => 'Permintaan perjalanan';

  @override
  String postedAgo(String time) {
    return 'Dihantar $time';
  }

  @override
  String raisedTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dinaikkan $count kali',
    );
    return '$_temp0';
  }

  @override
  String passengerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count penumpang',
    );
    return '$_temp0';
  }

  @override
  String get toPickup => 'Ke tempat ambil';

  @override
  String get tripLength => 'Jarak perjalanan';

  @override
  String get carType => 'Jenis kereta';

  @override
  String get payment => 'Pembayaran';

  @override
  String get orderClosedToOffers => 'Pesanan ini tidak lagi menerima tawaran.';

  @override
  String get yourOffer => 'Tawaran anda';

  @override
  String waitingForReply(String name) {
    return 'Menunggu $name membalas';
  }

  @override
  String get withdrawOffer => 'Tarik balik tawaran';

  @override
  String get passengerOffers => 'Tawaran penumpang';

  @override
  String marketPrice(String amount) {
    return 'Pasaran $amount';
  }

  @override
  String get lowerOffer => 'Turunkan tawaran';

  @override
  String get raiseOffer => 'Naikkan tawaran';

  @override
  String youKeepAfterFee(String net, String fee) {
    return 'Anda simpan $net selepas yuran $fee';
  }

  @override
  String resetTo(String amount) {
    return 'Set semula kepada $amount';
  }

  @override
  String get counterOfferWarning =>
      'Tawaran balas mengambil masa lebih lama untuk diterima berbanding menerima harga penumpang.';

  @override
  String offerAmount(String amount) {
    return 'Tawar $amount';
  }

  @override
  String acceptAmount(String amount) {
    return 'Terima $amount';
  }

  @override
  String get skipThisOrder => 'Langkau pesanan ini';

  @override
  String get vehicle => 'Kenderaan';

  @override
  String get notADriverTitle => 'Anda belum menjadi pemandu';

  @override
  String get notADriverBody =>
      'Tetapkan kenderaan anda untuk mula menerima pesanan.';

  @override
  String seatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tempat duduk',
    );
    return '$_temp0';
  }

  @override
  String get category => 'Kategori';

  @override
  String get editDetails => 'Sunting butiran';

  @override
  String get documents => 'Dokumen';

  @override
  String get documentsNote =>
      'Dokumen disahkan secara automatik dalam binaan ini. Dalam pengeluaran sebenar, dokumen ini akan disemak dengan rekod LPKP/APAD sebelum pemandu boleh dalam talian.';

  @override
  String get editVehicle => 'Sunting kenderaan';

  @override
  String get plateNumber => 'Nombor plat';

  @override
  String get colour => 'Warna';

  @override
  String get saveChanges => 'Simpan perubahan';

  @override
  String get docApproved => 'Diluluskan';

  @override
  String get docInReview => 'Dalam semakan';

  @override
  String get docRejected => 'Ditolak';

  @override
  String get docNotUploaded => 'Belum dimuat naik';

  @override
  String expiresDate(String date) {
    return 'Luput $date';
  }

  @override
  String get classHintEconomy => 'Perodua, Proton, sedan kecil';

  @override
  String get classHintComfort => 'Honda City, Toyota Vios ke atas';

  @override
  String get classHintXl => 'MPV dan kenderaan 7 tempat duduk';

  @override
  String get driverIntroTitle => 'Mula menjana pendapatan dengan kereta anda';

  @override
  String get driverIntroBody =>
      'Lihat permintaan perjalanan berhampiran anda, pilih yang berbaloi dengan masa anda, dan tetapkan harga anda sendiri bagi setiap perjalanan.';

  @override
  String perkKeepTitle(String percent) {
    return 'Simpan $percent% daripada setiap tambang';
  }

  @override
  String perkKeepBody(String percent) {
    return 'Yuran perkhidmatan kami ialah $percent% — tiada pembahagian harga lonjakan, tiada potongan tersembunyi.';
  }

  @override
  String get perkHoursTitle => 'Memandu bila anda mahu';

  @override
  String get perkHoursBody =>
      'Dalam talian dan luar talian dengan satu ketikan. Tiada syif, tiada kuota.';

  @override
  String get perkChoiceTitle => 'Anda pilih pesanan';

  @override
  String get perkChoiceBody =>
      'Lihat destinasi dan tambang sebelum anda menerima apa-apa.';

  @override
  String get driverIntroDocsNote =>
      'Binaan ini mengesahkan dokumen secara automatik supaya anda boleh mencuba bahagian pemandu dengan segera.';

  @override
  String get yourVehicle => 'Kenderaan anda';

  @override
  String get make => 'Jenama';

  @override
  String get model => 'Model';

  @override
  String get year => 'Tahun';

  @override
  String get vehicleCategory => 'Kategori kenderaan';

  @override
  String get startDriving => 'Mula memandu';

  @override
  String get colourHint => 'Putih';

  @override
  String get serviceCity => 'Bandar';

  @override
  String get serviceIntercity => 'Antara bandar';

  @override
  String get serviceDelivery => 'Penghantaran';

  @override
  String get serviceFreight => 'Kargo';

  @override
  String get serviceMoto => 'Moto';

  @override
  String cardEndingIn(String tail) {
    return 'Kad $tail';
  }

  @override
  String get optionChildSeat => 'Kerusi kanak-kanak';

  @override
  String get optionPet => 'Membawa haiwan peliharaan';

  @override
  String get optionLuggage => 'Bagasi besar';

  @override
  String get optionAirCon => 'Penyaman udara';

  @override
  String get optionNoSmoking => 'Kereta bebas rokok';

  @override
  String get optionSilentRide => 'Perjalanan senyap';

  @override
  String get optionFemaleDriver => 'Utamakan pemandu wanita';

  @override
  String get whereTo => 'Ke mana?';

  @override
  String get home => 'Rumah';

  @override
  String get work => 'Kerja';

  @override
  String get saved => 'Disimpan';

  @override
  String offersReceived(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tawaran diterima',
    );
    return '$_temp0';
  }

  @override
  String yourPriceSearching(String amount, String elapsed) {
    return 'Harga anda $amount · mencari $elapsed';
  }

  @override
  String get noOffersRaisePrompt =>
      'Belum ada tawaran. Menaikkan harga anda ialah cara terpantas untuk mendapatkan tumpangan.';

  @override
  String raiseSheetBody(String amount) {
    return 'Lebih ramai pemandu melihat pesanan anda apabila tambang dinaikkan. Anda kini menawarkan $amount.';
  }

  @override
  String get recommendedSuffix => ' · disyorkan';

  @override
  String get cancelYourOrder => 'Batalkan pesanan anda?';

  @override
  String get cancelReasonPrompt =>
      'Beritahu kami sebabnya supaya kami boleh memperbaik padanan.';

  @override
  String offerMetaLine(int eta, String distance, String trips) {
    return '$eta min jauh · $distance · $trips perjalanan';
  }
}
