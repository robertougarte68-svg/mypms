class Device {
  final String id;
  final bool online;
  final String ip;
  // final DateTime last_seen;

  Device({
    required this.id,
    required this.online,
    required this.ip,
    // required this.last_seen,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['device_id'],
      ip: json['ip'],
      online: json['online'],
      // last_seen: DateTime.parse(json['last_seen']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': id,
      'ip': ip,
      'online': online,
      // 'last_seen': last_seen.toIso8601String(),
    };
  }

  @override
  String toString() {
    return '''
Device(
  id: $id,
  ip: $ip,
  online: $online,
 
)
''';
  }
}
