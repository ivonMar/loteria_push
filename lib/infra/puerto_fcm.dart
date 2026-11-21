import 'package:firebase_messaging/firebase_messaging.dart';

import '../dominio/api_juego.dart';
import '../dominio/puerto_push.dart';

/// Adaptador real de Firebase Cloud Messaging. Es el ÚNICO archivo de la app
/// que habla con `firebase_messaging`.
class PuertoFcm implements PuertoPush {
  PuertoFcm([FirebaseMessaging? fcm]) : _fcm = fcm ?? FirebaseMessaging.instance;
  final FirebaseMessaging _fcm;

  static PermisoPush _traducirPermiso(AuthorizationStatus s) => switch (s) {
        AuthorizationStatus.authorized || AuthorizationStatus.provisional => PermisoPush.concedido,
        AuthorizationStatus.denied => PermisoPush.denegado,
        AuthorizationStatus.notDetermined => PermisoPush.sinPreguntar,
    // TODO: Handle this case.
    AuthorizationStatus.deniedPermanently => throw UnimplementedError(),
      };

  static MensajePush _traducirMensaje(RemoteMessage m) => MensajePush(
        datos: Map<String, Object?>.from(m.data),
        titulo: m.notification?.title,
        cuerpo: m.notification?.body,
      );

  @override
  Future<PermisoPush> estadoPermiso() async => _traducirPermiso((await _fcm.getNotificationSettings()).authorizationStatus);

  @override
  Future<PermisoPush> pedirPermiso() async => _traducirPermiso((await _fcm.requestPermission()).authorizationStatus);

  @override
  Future<DestinoPush?> obtenerDestino() async {
    final token = await _fcm.getToken();
    return token == null ? null : DestinoPush('token', token);
  }

  @override
  Stream<DestinoPush> get destinoCambiado => _fcm.onTokenRefresh.map((t) => DestinoPush('token', t));

  @override
  Stream<MensajePush> get enPrimerPlano => FirebaseMessaging.onMessage.map(_traducirMensaje);

  @override
  Stream<MensajePush> get alAbrirDesdeNotificacion => FirebaseMessaging.onMessageOpenedApp.map(_traducirMensaje);

  @override
  Future<MensajePush?> mensajeInicial() async {
    final m = await _fcm.getInitialMessage();
    return m == null ? null : _traducirMensaje(m);
  }

  @override
  Future<void> suscribirTema(String tema) => _fcm.subscribeToTopic(tema);

  @override
  Future<void> desuscribirTema(String tema) => _fcm.unsubscribeFromTopic(tema);
}