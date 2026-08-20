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

  @override
  String get tagSafeDriving => 'Pemanduan selamat';

  @override
  String get tagCleanCar => 'Kereta bersih';

  @override
  String get tagPolite => 'Sopan';

  @override
  String get tagGoodConversation => 'Perbualan menyenangkan';

  @override
  String get tagKnowsRoute => 'Tahu jalan';

  @override
  String get tagOnTime => 'Tepat masa';

  @override
  String get tagHelpedLuggage => 'Membantu dengan bagasi';

  @override
  String get tagComfortableRide => 'Perjalanan selesa';

  @override
  String get tagRudeBehaviour => 'Kelakuan biadab';

  @override
  String get tagDirtyCar => 'Kereta kotor';

  @override
  String get tagUnsafeDriving => 'Pemanduan tidak selamat';

  @override
  String get tagLateArrival => 'Tiba lewat';

  @override
  String get tagWrongRoute => 'Jalan yang salah';

  @override
  String get tagAskedForMoney => 'Meminta wang tambahan';

  @override
  String get tagBadSmell => 'Bau tidak menyenangkan';

  @override
  String get tagNoAirCon => 'Tiada penyaman udara';

  @override
  String get tagPolitePassenger => 'Penumpang sopan';

  @override
  String get tagClearPickup => 'Tempat ambil yang jelas';

  @override
  String get tagLeftCarClean => 'Meninggalkan kereta bersih';

  @override
  String get tagKeptMeWaiting => 'Membuat saya menunggu';

  @override
  String get tagWrongPickup => 'Tempat ambil yang salah';

  @override
  String get tagTooManyPassengers => 'Terlalu ramai penumpang';

  @override
  String get tagMessy => 'Bersepah';

  @override
  String get phraseAtPickup => 'Saya di tempat ambil';

  @override
  String get phraseTwoMinutes => 'Beri saya 2 minit ya';

  @override
  String get phraseBlueShirt => 'Saya pakai baju biru';

  @override
  String get phraseWhichCar => 'Kereta yang mana satu?';

  @override
  String get phraseCallOnArrival => 'Sila telefon saya apabila tiba';

  @override
  String get phraseThankYou => 'Terima kasih!';

  @override
  String get phraseOnMyWay => 'Saya dalam perjalanan';

  @override
  String get phraseArrivedWaiting => 'Saya sudah tiba, menunggu di luar';

  @override
  String get phraseTrafficLate => 'Jalan sesak, lewat 5 minit';

  @override
  String get phraseWhereToStop => 'Di mana tepatnya saya patut berhenti?';

  @override
  String get phraseComeOut => 'Sila keluar, saya tidak boleh menunggu di sini';

  @override
  String get cancelDriverTooLong => 'Pemandu mengambil masa terlalu lama';

  @override
  String get cancelDriverAsked => 'Pemandu minta saya batalkan';

  @override
  String get cancelNoLongerNeed => 'Saya tidak lagi memerlukan perjalanan ini';

  @override
  String get cancelWrongPickupAddress => 'Alamat ambil yang salah';

  @override
  String get cancelFoundAnother => 'Sudah dapat tumpangan lain';

  @override
  String get cancelPriceTooHigh => 'Harga terlalu tinggi';

  @override
  String get cancelPassengerSilent => 'Penumpang tidak menjawab';

  @override
  String get cancelPassengerNoShow => 'Penumpang tidak muncul';

  @override
  String get cancelPickupUnreachable => 'Tempat ambil tidak dapat dihubungi';

  @override
  String get cancelTooFar => 'Terlalu jauh dari lokasi saya';

  @override
  String get cancelVehicleProblem => 'Masalah kenderaan';

  @override
  String get cancelPassengerAsked => 'Penumpang minta dibatalkan';

  @override
  String get promoHalfOff =>
      'Diskaun 50% untuk perjalanan seterusnya, sehingga RM10';

  @override
  String get promoFiveOff => 'Potongan RM5 untuk mana-mana perjalanan';

  @override
  String get promoAirport => 'Potongan RM15 untuk pemindahan lapangan terbang';

  @override
  String get chat => 'Sembang';

  @override
  String get chatUnavailableTitle => 'Perbualan tidak tersedia';

  @override
  String get chatUnavailableBody => 'Perjalanan ini tidak lagi wujud.';

  @override
  String get passengerLabel => 'Penumpang';

  @override
  String get yourDriver => 'Pemandu anda';

  @override
  String chatSubtitle(String who, String destination) {
    return '$who · perjalanan ke $destination';
  }

  @override
  String get chatOnlyDuringTrip => 'Mesej hanya tersedia semasa perjalanan.';

  @override
  String get messageHint => 'Mesej…';

  @override
  String get send => 'Hantar';

  @override
  String get rate => 'Nilai';

  @override
  String get rideNotFound => 'Perjalanan tidak dijumpai';

  @override
  String get tripCompleted => 'Perjalanan selesai';

  @override
  String get howWasYourTrip => 'Bagaimana perjalanan anda?';

  @override
  String get howWasYourTripDriver =>
      'Bagaimana perjalanan anda bersama mereka?';

  @override
  String get addACommentOptional => 'Tambah komen (pilihan)';

  @override
  String addATipFor(String name) {
    return 'Tambah tip untuk $name';
  }

  @override
  String get none => 'Tiada';

  @override
  String submitAndTip(String amount) {
    return 'Hantar dan beri tip $amount';
  }

  @override
  String get submitRating => 'Hantar penilaian';

  @override
  String get promoInvalid => 'Kod itu tidak sah atau telah luput.';

  @override
  String promoApplied(String code, String label) {
    return '$code digunakan — $label';
  }

  @override
  String get enterAPromoCode => 'Masukkan kod promosi';

  @override
  String get apply => 'Guna';

  @override
  String get availableForYou => 'Tersedia untuk anda';

  @override
  String minimumFareIs(String amount) {
    return 'Tambang minimum $amount';
  }

  @override
  String get use => 'Guna';

  @override
  String get inviteFriends => 'Jemput rakan';

  @override
  String referralBody(String amount) {
    return 'Beri rakan anda potongan $amount untuk perjalanan pertama mereka dan dapat $amount apabila mereka menggunakannya.';
  }

  @override
  String get copyReferralCode => 'Salin kod rujukan';

  @override
  String get referralCodeCopied => 'Kod rujukan disalin';

  @override
  String inviteText(String code, String amount) {
    return 'Guna kod GET.teksi saya $code dan dapat potongan $amount untuk perjalanan pertama anda.';
  }

  @override
  String get inviteCopied => 'Jemputan disalin ke papan klip';

  @override
  String get shareInvite => 'Kongsi jemputan';

  @override
  String get setYourRoute => 'Tetapkan laluan anda';

  @override
  String get pickupLocation => 'Lokasi ambil';

  @override
  String get stopAlongTheWay => 'Perhentian di sepanjang jalan';

  @override
  String get addAStop => 'Tambah perhentian';

  @override
  String get noMatchingPlaces => 'Tiada tempat yang sepadan';

  @override
  String get noMatchingPlacesBody =>
      'Cuba nama pusat beli-belah, stesen, atau kawasan kejiranan.';

  @override
  String get today => 'Hari ini';

  @override
  String get thisWeek => 'Minggu ini';

  @override
  String get allTime => 'Sepanjang masa';

  @override
  String get netEarnings => 'Pendapatan bersih';

  @override
  String get trips => 'Perjalanan';

  @override
  String get distance => 'Jarak';

  @override
  String get time => 'Masa';

  @override
  String get averageFare => 'Purata tambang';

  @override
  String get rating => 'Penilaian';

  @override
  String get perHour => 'Sejam';

  @override
  String get noCompletedTrips => 'Belum ada perjalanan selesai';

  @override
  String get noCompletedTripsBody =>
      'Pergi dalam talian dan terima pesanan — pendapatan anda akan muncul di sini.';

  @override
  String get asPassenger => 'Sebagai penumpang';

  @override
  String get asDriver => 'Sebagai pemandu';

  @override
  String get noRidesYet => 'Belum ada perjalanan';

  @override
  String get noRidesDriverBody =>
      'Perjalanan yang anda pandu dan selesai akan muncul di sini.';

  @override
  String get noRidesPassengerBody =>
      'Tempah perjalanan pertama anda dan ia akan muncul di sini.';

  @override
  String get cancelled => 'Dibatalkan';

  @override
  String youRated(int stars) {
    return 'Anda menilai $stars';
  }

  @override
  String get verdictLowLabel => 'Bawah harga pasaran';

  @override
  String get verdictLowHint =>
      'Pemandu mungkin melangkaunya. Jangkakan menunggu lebih lama.';

  @override
  String get verdictFairLabel => 'Harga berpatutan';

  @override
  String get verdictFairHint =>
      'Lebih kurang apa yang pemandu biasanya terima untuk laluan ini.';

  @override
  String get verdictGoodLabel => 'Harga menarik';

  @override
  String get verdictGoodHint => 'Pemandu cepat membalas tawaran seperti ini.';

  @override
  String get verdictHighLabel => 'Atas harga pasaran';

  @override
  String get verdictHighHint =>
      'Anda menawarkan lebih daripada kos biasa perjalanan ini.';

  @override
  String get simulatedMarketplaceRowSubtitle =>
      'Pemandu bot membida pesanan anda dan penumpang bot menghantar perjalanan';

  @override
  String get simulationBanner =>
      'Dengan ini dihidupkan, anda boleh mencuba kedua-dua belah pasaran pada satu peranti: bot membida pesanan anda sebagai penumpang, dan menghantar pesanan ke dalam suapan anda sebagai pemandu.';

  @override
  String get appNameVersion => 'GET.teksi 1.0.0';

  @override
  String get builtWith =>
      'Dibina dengan Flutter · Android, iOS, Web, HarmonyOS';

  @override
  String get tripDetails => 'Butiran perjalanan';

  @override
  String refIs(String reference) {
    return 'Ruj. $reference';
  }

  @override
  String get fareBreakdown => 'Perincian tambang';

  @override
  String get agreedPrice => 'Harga dipersetujui';

  @override
  String get yourOriginalOffer => 'Tawaran asal anda';

  @override
  String priceRaisedTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Harga dinaikkan $count×',
    );
    return '$_temp0';
  }

  @override
  String get serviceFee => 'Yuran perkhidmatan';

  @override
  String get youEarned => 'Anda peroleh';

  @override
  String get tip => 'Tip';

  @override
  String get totalPaid => 'Jumlah dibayar';

  @override
  String paidBy(String method) {
    return 'Dibayar dengan $method';
  }

  @override
  String get paidByCash => 'tunai';

  @override
  String paidByCard(String tail) {
    return 'kad $tail';
  }

  @override
  String get paidByWallet => 'dompet';

  @override
  String get yourRating => 'Penilaian anda';

  @override
  String get tripReferenceCopied => 'Rujukan perjalanan disalin';

  @override
  String get copyTripReference => 'Salin rujukan perjalanan';

  @override
  String get currentLocation => 'Lokasi semasa';

  @override
  String get pickup => 'Tempat ambil';

  @override
  String get drive => 'Memandu';

  @override
  String get notifications => 'Pemberitahuan';

  @override
  String get switchToPassengerTooltip => 'Tukar kepada penumpang';

  @override
  String earningsSemantics(String amount, String status) {
    return 'Pendapatan, $amount, $status';
  }

  @override
  String get onlineWord => 'dalam talian';

  @override
  String get offlineWord => 'luar talian';

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String durationHours(int hours) {
    return '$hours j';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours j $minutes min';
  }

  @override
  String get justNow => 'sebentar tadi';

  @override
  String secondsAgo(int seconds) {
    return '${seconds}s lalu';
  }

  @override
  String minutesAgo(int minutes) {
    return '$minutes min lalu';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours j lalu';
  }

  @override
  String daysAgo(int days) {
    return '$days h lalu';
  }

  @override
  String get yesterday => 'Semalam';

  @override
  String ordersNearby(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pesanan berhampiran',
    );
    return '$_temp0';
  }

  @override
  String distanceToPickup(String distance, String duration) {
    return '$distance ke tempat ambil · $duration';
  }

  @override
  String get clearLocalDataConfirmBody =>
      'Ini memadamkan semua perjalanan, tawaran, mesej dan transaksi yang disimpan pada peranti ini. Profil anda kekal dilog masuk.';

  @override
  String get nothingNew => 'Tiada yang baharu';

  @override
  String get nothingNewBody =>
      'Kemas kini perjalanan, tawaran dan promosi akan muncul di sini.';

  @override
  String get lowerFareTooltip => 'Turunkan tambang';

  @override
  String get raiseFareTooltip => 'Naikkan tambang';

  @override
  String get close => 'Tutup';
}
