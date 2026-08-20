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
}
