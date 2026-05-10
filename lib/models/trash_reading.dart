class TrashReading {
  final int id;
  final int binId;
  final double distanceCm;
  final double fillPercent;
  final double gasRaw;
  final String status;
  final bool isFull;
  final bool odorAlert;
  final DateTime createdAt;

  TrashReading({
    required this.id,
    required this.binId,
    required this.distanceCm,
    required this.fillPercent,
    required this.gasRaw,
    required this.status,
    required this.isFull,
    required this.odorAlert,
    required this.createdAt,
  });

  // İnternetten gelen JSON verisini objeye çeviren fonksiyon
  factory TrashReading.fromJson(Map<String, dynamic> json) {
    return TrashReading(
      id: json['id'] ?? 0,
      binId: json['bin_id'] ?? 0,
      distanceCm: (json['distance_cm'] ?? 0).toDouble(),
      fillPercent: (json['fill_percent'] ?? 0).toDouble(),
      gasRaw: (json['gas_raw'] ?? 0).toDouble(),
      status: json['status'] ?? 'unknown',
      isFull: json['is_full'] ?? false,
      odorAlert: json['odor_alert'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}