class User {
  int id;
  String email;
  String user;
  String? rol;
  int? hotelId;
  List<String> permisos;
  String token;

  User({
    required this.id,
    required this.email,
    required this.user,
    required this.rol,
    required this.hotelId,
    required this.permisos,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final userData = json;

    return User(
      id: userData["id"],
      email: userData["email"].toString(),
      user: userData["user"].toString(),
      rol: userData["rol"],
      hotelId: userData["hotel_id"],
      permisos: List<String>.from(userData["permisos"] ?? []),
      token: json["token"].toString(),
    );
  }

  @override
  String toString() {
    return 'User(id: $id user: $user, email: $email, rol:$rol, hotelId:$hotelId, permisos:$permisos, token:$token)';
  }

  // Map<String, dynamic> toJson() {
  //   return {
  //     "id": id,
  //     "email": email,
  //     "user": user,
  //     "rol": rol,
  //     "hotel_id": hotelId,
  //     "permisos": permisos,
  //     "token": token,
  //   };
  // }
}
