import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/trash_reading.dart';

class ApiService {
  // 1. ANA EKRAN İÇİN: En güncel tekil okumayı getirir
  static Future<TrashReading?> getLatestReading() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/dashboard/latest'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Veritabanı boşsa dönen mesajı kontrol et
        if (data['message'] == "No readings found") {
          return null;
        }

        return TrashReading.fromJson(data);
      } else {
        print('Dashboard API Hatası: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Dashboard Bağlantı Hatası: $e');
      return null;
    }
  }

  // 2. İSTATİSTİK EKRANI İÇİN: Geçmiş okumaları liste olarak getirir
  static Future<List<TrashReading>> getRecentReadings({int limit = 20}) async {
    try {
      // API'ye limit parametresini ekleyerek istek atıyoruz
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/readings/recent?limit=$limit'),
      );

      if (response.statusCode == 200) {
        // Gelen veri bir liste olduğu için List<dynamic> olarak işliyoruz
        final List<dynamic> data = json.decode(response.body);

        // Her JSON objesini TrashReading nesnesine dönüştürüp listeye çeviriyoruz
        return data.map((json) => TrashReading.fromJson(json)).toList();
      } else {
        print('İstatistik API Hatası: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('İstatistik Bağlantı Hatası: $e');
      return [];
    }
  }
}