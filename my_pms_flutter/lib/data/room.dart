class Room {
  final int id;
  final int number;
  final int slots;
  final String cat;
  String state;
  final double price;
  final String? features;
  String? device;

  Room({
    required this.id,
    required this.number,
    required this.slots,
    required this.cat,
    required this.state,
    required this.price,
    this.features,
    this.device,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      number: json['number'],
      slots: json['slots'],
      cat: json['cat'],
      state: json['state'],
      price: double.parse(json['price']),
      features: json['features'],
      device: json['device'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'slots': slots,
      'cat': cat,
      'state': state,
      'price': price,
      'features': features,
      'device': device,
    };
  }
}
