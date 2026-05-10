import 'dart:async'; // Timer için eklendi
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Bildirim paketi
import '../models/trash_reading.dart';
import '../services/api_service.dart';
import 'stats_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // --- TASARIM SABİTLERİ ---
  final Color _bgColor = const Color(0xFFF5F3EF);
  final Color _cardColor = Colors.white;
  final Color _textColor = const Color(0xFF3E3A36);
  final Color _subTextColor = const Color(0xFF9E9A96);
  final Color _successColor = const Color(0xFF4CAF50);
  final Color _alertColor = const Color(0xFFE53935);

  // --- CANLI VERİ VE BİLDİRİM YÖNETİMİ ---
  TrashReading? _currentData;
  bool _isLoading = true;

  // Bildirim değişkenleri
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _notificationSent = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _initializeNotifications(); // Bildirim altyapısını hazırla
    _fetchData(); // İlk veriyi çek
    _startPolling(); // Otomatik yenilemeyi başlat
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); // Sayfa kapanırsa timer'ı durdur (Hafıza sızıntısını önler)
    super.dispose();
  }

  // --- 1. BİLDİRİM KURULUMU ---
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(settings: initSettings);

    // Android 13+ için izin isteme penceresi
    await _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  // --- 2. OTOMATİK KONTROL (POLLING) ---
  void _startPolling() {
    // Uygulama açık kaldığı sürece her 10 saniyede bir veriyi gizlice günceller
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchData(isBackground: true);
    });
  }

  // --- 3. VERİ ÇEKME VE BİLDİRİM KONTROLÜ (SENİN FONKSİYONUN MODİFİYE HALİ) ---
  Future<void> _fetchData({bool isBackground = false}) async {
    // Sadece manuel yenilemelerde loading animasyonu göster
    if (!isBackground) {
      setState(() { _isLoading = true; });
    }

    try {
      final data = await ApiService.getLatestReading();

      setState(() {
        _currentData = data;
        _isLoading = false;
      });

      // BİLDİRİM MANTIĞI BURADA ÇALIŞIYOR
      int guncelDoluluk = _currentData?.fillPercent.toInt() ?? 0;

      if (guncelDoluluk >= 80 && !_notificationSent) {
        _showLocalNotification(guncelDoluluk);
        _notificationSent = true; // Bildirimi kilitledik
      } else if (guncelDoluluk < 20) {
        _notificationSent = false; // Çöp boşaldı, kilidi açtık
      }

    } catch (e) {
      debugPrint("Veri çekme hatası: $e");
      setState(() { _isLoading = false; });
    }
  }

  // --- 4. BİLDİRİMİ EKRANA DÜŞÜRME ---
  Future<void> _showLocalNotification(int oran) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'trash_bin_channel',
      'Çöp Kutusu Uyarıları',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: 0,
      title: 'Kutu Doldu!',
      body: 'Çöp kutusu %$oran doluluğa ulaştı. Lütfen boşaltın.',
      notificationDetails: platformDetails,
    );
  }

  // Güvenli değerler (Fallback)
  int get fillPercent => _currentData?.fillPercent.toInt() ?? 0;
  double get airQualityRaw => _currentData?.gasRaw ?? 0.0;
  int get distanceCm => _currentData?.distanceCm.toInt() ?? 0;
  bool get odorAlert => _currentData?.odorAlert ?? false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: _isLoading && _currentData == null
            ? Center(child: CircularProgressIndicator(color: _successColor))
            : RefreshIndicator(
          onRefresh: () => _fetchData(isBackground: false),
          color: _successColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                const SizedBox(height: 25),
                Text(
                  'IoT tabanlı akıllı kova sistemi üzerinden gelen verilerin anlık analiz ve izleme paneli.',
                  style: TextStyle(color: _textColor, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 35),

                if (_currentData == null)
                  Container(
                    padding: const EdgeInsets.all(15),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.wifi_off, color: Colors.red),
                        SizedBox(width: 10),
                        Expanded(child: Text('Sunucuya bağlanılamadı veya veri yok. Lütfen sayfayı aşağı kaydırarak yenileyin.', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ),

                _buildMainContent(),
                const SizedBox(height: 35),
                Text(
                  'GÜNLÜK VERİM',
                  style: TextStyle(color: _subTextColor, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StatsScreen()),
                    );
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: _buildCardDecoration(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stacked_line_chart, color: _successColor, size: 48),
                        const SizedBox(height: 15),
                        Text(
                          'Detaylı Grafikleri Görüntüle',
                          style: TextStyle(color: _textColor, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Geçmiş kullanımları analiz et',
                          style: TextStyle(color: _subTextColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(),
        Row(
          children: [
            _buildIconButton(Icons.refresh, onPressed: () => _fetchData(isBackground: false)),
            const SizedBox(width: 15),
            _buildIconButton(Icons.person_outline, onPressed: (){}),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, {required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 1, blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: IconButton(icon: Icon(icon, color: _textColor), onPressed: onPressed),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildFillStatusCard(),
        const SizedBox(height: 25),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('ANLIK METRİKLER', style: TextStyle(color: _textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _buildMetricCard(Icons.air, '${airQualityRaw.toInt()} RAW', 'HAVA KALİTESİ', odorAlert ? 'Kritik' : 'Normal Seviye', odorAlert)),
            const SizedBox(width: 15),
            Expanded(child: _buildMetricCard(Icons.speed, '$distanceCm CM', 'MESAFE', 'Anlık Mesafe', false)),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _buildMetricCard(Icons.access_time, 'Canlı', 'DURUM', 'Senkronizasyon', false)),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildFillStatusCard() {
    Color statusColor = fillPercent > 80 ? _alertColor : _successColor;
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: _buildCardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.delete_outline, color: _subTextColor, size: 30),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DOLULUK', style: TextStyle(color: _subTextColor, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  Text('%$fillPercent', style: TextStyle(color: _textColor, fontSize: 48, fontWeight: FontWeight.bold, height: 1.1)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(fillPercent > 80 ? Icons.warning_amber_rounded : Icons.check_circle_outline, color: statusColor, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(IconData icon, String value, String title, String subtitle, bool isAlert) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _buildCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: isAlert ? _alertColor : _subTextColor, size: 24),
          ),
          const SizedBox(height: 20),
          Text(value, style: TextStyle(color: _textColor, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: _textColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: isAlert ? _alertColor : _subTextColor, fontSize: 11)),
        ],
      ),
    );
  }

  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      color: _cardColor,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.03), spreadRadius: 1, blurRadius: 15, offset: const Offset(0, 5)),
      ],
    );
  }
}