import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// En Android 8+ cada notificación pertenece a un CANAL que controla sonido,
/// vibración e importancia — y que el usuario puede silenciar por separado.
/// Los identificadores ('cartas', 'momentos') coinciden con `server/mensajes.js`.
Future<void> registrarCanalesAndroid() async {
  if (!Platform.isAndroid) return;
  final plugin = FlutterLocalNotificationsPlugin();
  const opciones = InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher'));
  await plugin.initialize(settings: opciones);
  final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  if (android == null) return;

  await android.createNotificationChannel(const AndroidNotificationChannel(
    'cartas',
    'Cartas cantadas',
    description: 'Cada carta que canta el gritón.',
    importance: Importance.defaultImportance,
  ));
  await android.createNotificationChannel(const AndroidNotificationChannel(
    'momentos',
    '¡Casi! y ¡Lotería!',
    description: 'Avisos importantes de la partida.',
    importance: Importance.high,
  ));
}