import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../dominio/api_juego.dart';
import '../dominio/evento.dart';

/// Cliente HTTP contra el servidor del cantor (`server/servidor.js`).
class ApiHttp implements ApiJuego {
  ApiHttp(this.baseUrl, {http.Client? cliente}) : _http = cliente ?? http.Client();
  final String baseUrl;
  final http.Client _http;

  /// En el emulador de Android `localhost` es el propio teléfono; el anfitrión es `10.0.2.2`.
  static String urlPorDefecto() => Platform.isAndroid ? 'http://10.0.2.2:8080' : 'http://localhost:8080';

  Uri _uri(String ruta, [Map<String, String>? q]) => Uri.parse('$baseUrl$ruta').replace(queryParameters: q);

  Future<Map<String, dynamic>> _pedir(
    String metodo,
    Uri uri, {
    Object? cuerpo,
    Map<String, String> cabeceras = const {},
  }) async {
    try {
      final h = {'content-type': 'application/json', ...cabeceras};
      final body = cuerpo == null ? null : jsonEncode(cuerpo);
      final res = await switch (metodo) {
        'GET' => _http.get(uri, headers: h),
        'POST' => _http.post(uri, headers: h, body: body),
        'PUT' => _http.put(uri, headers: h, body: body),
        _ => throw ArgumentError(metodo),
      }.timeout(const Duration(seconds: 6));
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 400) {
        throw ErrorApi('${json['error'] ?? res.statusCode}', '${json['mensaje'] ?? 'Error del servidor'}');
      }
      return json;
    } on ErrorApi {
      rethrow;
    } on Object {
      throw const ErrorApi('SIN_CONEXION', 'No se pudo contactar al cantor');
    }
  }

  @override
  Future<SalaCreada> crearSala() async {
    final j = await _pedir('POST', _uri('/salas'));
    return SalaCreada(j['id'] as String, j['claveCantor'] as String);
  }

  @override
  Future<Union> unirse(String sala, String nombre, DestinoPush? destino) async {
    final j = await _pedir('POST', _uri('/salas/$sala/unirse'), cuerpo: {'nombre': nombre, 'destino': destino?.toJson()});
    return Union(
      nombre: j['nombre'] as String,
      tabla: (j['tabla'] as List).cast<int>(),
      claveJugador: j['claveJugador'] as String,
      cartas: [for (final c in j['cartas'] as List) CartaCantada.desdeJson(c as Map<String, dynamic>)],
    );
  }

  @override
  Future<EstadoSala> estado(String sala, int desde) async {
    final j = await _pedir('GET', _uri('/salas/$sala/estado', {'desde': '$desde'}));
    return EstadoSala(
      ultima: j['ultima'] as int,
      cartas: [for (final c in j['cartas'] as List) CartaCantada.desdeJson(c as Map<String, dynamic>)],
      ganador: j['ganador'] as String?,
      patron: j['patron'] as String?,
    );
  }

  @override
  Future<CartaCantada> cantar(String sala, String claveCantor) async {
    final j = await _pedir('POST', _uri('/salas/$sala/cantar'), cabeceras: {'x-cantor-clave': claveCantor});
    return CartaCantada.desdeJson(j['evento'] as Map<String, dynamic>);
  }

  @override
  Future<ResultadoReclamo> reclamar(String sala, String nombre, String claveJugador) async {
    final j = await _pedir(
      'POST',
      _uri('/salas/$sala/loteria'),
      cuerpo: {'nombre': nombre},
      cabeceras: {'x-jugador-clave': claveJugador},
    );
    return ResultadoReclamo(gano: j['gano'] as bool, patron: j['patron'] as String?);
  }

  @override
  Future<void> actualizarDestino(String sala, String nombre, String claveJugador, DestinoPush destino) async {
    await _pedir(
      'PUT',
      _uri('/salas/$sala/destino'),
      cuerpo: {'nombre': nombre, 'destino': destino.toJson()},
      cabeceras: {'x-jugador-clave': claveJugador},
    );
  }
}