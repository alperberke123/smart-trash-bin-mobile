import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Uygulama açıkken bildirim gelirse ne yapılacak?
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Bildirim Geldi: ${message.notification?.title}');
      // Burada istersen uygulama içindeyken bir diyalog kutusu çıkarabilirsin
    });

    // Uygulama arka plandayken bildirim tıklandığında ne yapılacak?
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Bildirime tıklandı!');
    });

    // Cihazın benzersiz Token'ını al (Backend'e bu lazım olacak)
    String? token = await _messaging.getToken();
    print("Firebase Token: $token");
    // NOT: Bu token'ı kopyalayıp arkadaşına vermelisin ki
    // sunucu senin telefonunu tanıyabilsin.
  }
}