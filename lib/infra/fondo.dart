import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../dominio/evento.dart';
import '../firebase_options.dart';

/// Manejador de mensajes en SEGUNDO PLANO (o con la app cerrada).
/// Requisitos de Flutter/Android/iOS:
///   1. Función de nivel superior (no método de una clase).
///   2. Anotada con `@pragma('vm:entry-point')` para que el compilador no la borre.
///   3. Corre en su PROPIO isolate: no toca widgets ni memoria de la UI.
///   4. Debe terminar rápido (Android la corta a los ~10 segundos).
@pragma('vm:entry-point')
Future<void> manejarMensajeEnFondo(RemoteMessage mensaje) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  final evento = EventoJuego.desdeDatos(Map<String, Object?>.from(mensaje.data));
  debugPrint('[push fondo] sala=${EventoJuego.salaDe(mensaje.data)} evento=$evento');
}