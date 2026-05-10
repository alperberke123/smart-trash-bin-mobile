import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/trash_reading.dart';
import '../services/api_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<TrashReading> _readings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getRecentReadings();
    setState(() {
      // Verileri zaman sırasına göre diziyoruz (Eskiden yeniye)
      _readings = data.reversed.toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: AppBar(
        title: const Text('Kullanım İstatistikleri'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF3E3A36),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh))
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : _readings.isEmpty
          ? const Center(child: Text("Henüz istatistik verisi yok."))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildChartCard(),
            const SizedBox(height: 20),
            _buildHistoryList(), // Alt tarafa verilerin listesini de ekleyelim
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      height: 350,
      padding: const EdgeInsets.only(right: 30, left: 10, top: 20, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
      ),
      child: LineChart(
        LineChartData(
          minY: 0, maxY: 100,
          gridData: FlGridData(
              show: true,
              horizontalInterval: 25,
              getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), dashArray: [5, 5])
          ),
          titlesData: _buildTitlesData(),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              // BURASI KRİTİK: TrashReading listesini FlSpot (grafik noktası) listesine çeviriyoruz
              spots: _readings.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.fillPercent);
              }).toList(),
              isCurved: true,
              color: const Color(0xFF4CAF50),
              barWidth: 4,
              belowBarData: BarAreaData(show: true, color: const Color(0xFF4CAF50).withOpacity(0.1)),
              dotData: const FlDotData(show: true), // Noktaları görelim
            ),
          ],
        ),
      ),
    );
  }

  // Alt eksende okuma saatlerini gösteriyoruz
  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            int index = value.toInt();
            if (index >= 0 && index < _readings.length && index % 3 == 0) {
              var time = _readings[index].createdAt;
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _readings.length,
      itemBuilder: (context, index) {
        final item = _readings.reversed.toList()[index];
        return ListTile(
          leading: Icon(Icons.circle, color: item.fillPercent > 80 ? Colors.red : Colors.green, size: 12),
          title: Text('%${item.fillPercent.toInt()} Doluluk'),
          subtitle: Text('${item.createdAt.hour}:${item.createdAt.minute}'),
          trailing: Text(item.status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}