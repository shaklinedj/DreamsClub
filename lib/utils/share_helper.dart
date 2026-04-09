import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareHelper {
  // Using Firebase Hosting domain for App Links (HTTPS)
  static const String _deepLinkBase = 'https://dreams-casino-app.web.app';

  static Future<void> shareToWhatsApp(String text) async {
    final uri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }

    await SharePlus.instance.share(ShareParams(text: text));
  }

  static Future<void> sharePost(
      String id, String title, String description) async {
    final link = '$_deepLinkBase/post/$id';
    await SharePlus.instance.share(ShareParams(
      text: '$title\n$description\n\n$link',
    ));
  }

  static Future<void> shareEvent(
      String id, String title, String description, String date) async {
    final link = '$_deepLinkBase/event/$id';
    await SharePlus.instance.share(ShareParams(
      text:
          '¡Mira este evento! $title\n\n$description\n\nFecha: $date\n\n$link',
    ));
  }

  static Future<void> shareRestaurant(
      String id, String name, String cuisine, double rating) async {
    final link = '$_deepLinkBase/restaurant/$id';
    await SharePlus.instance.share(ShareParams(
      text:
          '¡Mira este restaurante! $name\n\nCocina: $cuisine\nCalificación: $rating/5\n\n$link',
    ));
  }

  static Future<void> sharePromotion(
      String id, String title, String description) async {
    final link = '$_deepLinkBase/promotion/$id';
    await SharePlus.instance.share(ShareParams(
      text: '¡Mira esta promoción! $title\n\n$description\n\n$link',
    ));
  }

  static Future<void> shareHotel(String name) async {
    await SharePlus.instance.share(ShareParams(
      text:
          '¡Mira este hotel! $name', // ID logic for hotel not requested explicitly yet
    ));
  }
}
