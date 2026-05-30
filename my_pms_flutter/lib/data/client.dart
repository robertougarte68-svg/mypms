class Client {
  final int? id;
  final String name;
  final String? birth;
  final String ci;
  final String addr;
  final int? phone;
  dynamic statics;

  Client({
    this.id,
    required this.name,
    required this.birth,
    required this.ci,
    required this.addr,
    required this.phone,
    this.statics,
  });

  Client.fromJson(Map<String, dynamic> json)
    : name = json['name'],
      birth = json['birth'],
      ci = json['ci'],
      addr = json['addr'],
      phone = json['phone'],
      id = json['id'],
      statics = null;
}
