import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loteria_push/app.dart';
import 'package:loteria_push/dominio/almacen.dart';
import 'package:loteria_push/dominio/controlador.dart';
import 'package:loteria_push/dominio/puerto_push.dart';

import 'falsos.dart';

void main() {
  late ApiFalsa api;
  late PuertoPushFalso push;
  late ControladorPartida controlador;

  setUp(() {
    api = ApiFalsa();
    push = PuertoPushFalso();
    controlador = ControladorPartida(api: api, push: push, almacen: AlmacenMemoria());
  });

  tearDown(() => controlador.cerrar());

  testWidgets('unirse -> aparece el banner de pre-permiso, llega un push y se marca la tabla', (tester) async {
    await tester.pumpWidget(LoteriaApp(controlador: controlador, api: api));

    await tester.enterText(find.byKey(const Key('campo-sala')), 'abcde');
    await tester.enterText(find.byKey(const Key('campo-nombre')), 'Ana');
    await tester.tap(find.byKey(const Key('boton-unirse')));
    await tester.pumpAndSettle();

    expect(find.text('Sala ABCDE · Ana'), findsOneWidget);
    expect(find.byKey(const Key('banner-permiso')), findsOneWidget);
    expect(push.vecesPidioPermiso, 0, reason: 'primero explicamos, luego pedimos');

    // El usuario acepta los avisos desde el banner
    await tester.tap(find.byKey(const Key('boton-activar-avisos')));
    await tester.pumpAndSettle();
    expect(push.vecesPidioPermiso, 1);

    // Llega una carta por push -> se muestra y se marca la casilla 0
    push.emitirEnPrimerPlano(mensajeCarta(1, 1));
    await tester.pumpAndSettle();
    expect(find.text('Carta 1'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('completar una línea habilita "¡LOTERÍA!" y muestra al ganador', (tester) async {
    await controlador.unirse(sala: 'ABCDE', nombre: 'Ana');
    await tester.pumpWidget(LoteriaApp(controlador: controlador, api: api, hayPartidaActiva: true));
    await tester.pumpAndSettle();

    final boton = () => tester.widget<FilledButton>(find.byKey(const Key('boton-loteria')));
    expect(boton().onPressed, isNull);

    for (var i = 1; i <= 4; i++) {
      push.emitirEnPrimerPlano(mensajeCarta(i, i));
    }
    await tester.pumpAndSettle();
    expect(boton().onPressed, isNotNull);

    api.reclamoGana = true;
    await tester.tap(find.byKey(const Key('boton-loteria')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('banner-ganador')), findsOneWidget);
  });

  testWidgets('si el permiso fue denegado, la pantalla avisa pero no estorba', (tester) async {
    push.permiso = PermisoPush.denegado;
    await controlador.unirse(sala: 'ABCDE', nombre: 'Ana');
    await tester.pumpWidget(LoteriaApp(controlador: controlador, api: api, hayPartidaActiva: true));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('banner-permiso')), findsOneWidget);
    expect(find.byKey(const Key('boton-activar-avisos')), findsNothing);
  });
}