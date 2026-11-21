import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'dominio/controlador.dart';
import 'firebase_options.dart';
import 'infra/almacen_prefs.dart';
import 'infra/api_http.dart';
import 'infra/canales_android.dart';
import 'infra/fondo.dart';
import 'infra/puerto_fcm.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(manejarMensajeEnFondo);
    await registrarCanalesAndroid();
  } catch (e, st) {
    debugPrint('Error inicializando Firebase/Notificaciones: $e\n$st');
  }

  const definida = String.fromEnvironment('SERVIDOR');
  final api = ApiHttp(definida.isEmpty ? ApiHttp.urlPorDefecto() : definida);
  final controlador = ControladorPartida(api: api, push: PuertoFcm(), almacen: AlmacenPrefs());

  var restaurada = false;
  try {
    restaurada = await controlador.restaurar().timeout(const Duration(seconds: 4));
  } catch (e) {
    debugPrint('No se pudo restaurar sesión al inicio: $e');
  }

  runApp(LoteriaApp(controlador: controlador, api: api, hayPartidaActiva: restaurada));
}