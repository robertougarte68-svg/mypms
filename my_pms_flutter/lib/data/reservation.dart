import 'client.dart';
import 'room.dart';

class Reservation {
  final int id;
  final String cod_reserva;
  final Client client;
  final int n_personas;
  final List<Room> rooms;
  final DateTime fecha_reserva;
  final DateTime fecha_in;
  final DateTime fecha_out;
  final double total;
  final double anticipo;
  final String metodo_pago;
  final String estado;
  final String? observaciones;
  final String? proof_url;

  Reservation({
    required this.cod_reserva,
    required this.id,
    required this.client,
    required this.n_personas,
    required this.rooms,
    required this.fecha_reserva,
    required this.fecha_in,
    required this.fecha_out,
    required this.total,
    required this.anticipo,
    required this.metodo_pago,
    required this.estado,
    required this.observaciones,
    required this.proof_url,
  });

  Reservation.fromJson(Map<String, dynamic> json)
    : cod_reserva = json['cod_reserva'],
      id = json['id'],
      client = Client.fromJson(json['client']),
      rooms = (json['rooms'] as List).map((r) => Room.fromJson(r)).toList(),
      fecha_reserva = DateTime.parse(json['fecha_reserva']),
      fecha_in = DateTime.parse(json['fecha_in']),
      fecha_out = DateTime.parse(json['fecha_out']),
      total = double.parse(json['total']),
      anticipo = double.parse(json['anticipo']),
      metodo_pago = json['metodo_pago'],
      n_personas = json['n_personas'],
      estado = json['estado'],
      observaciones = json['observaciones'],
      proof_url = json['proof_url'];
}
