import 'package:flutter/material.dart';

import 'dominio/api_juego.dart';
import 'dominio/controlador.dart';
import 'presentacion/inicio.dart';
import 'presentacion/tablero.dart';

class LoteriaApp extends StatelessWidget {
  const LoteriaApp({super.key, required this.controlador, required this.api, this.hayPartidaActiva = false});
  final ControladorPartida controlador;
  final ApiJuego api;
  final bool hayPartidaActiva;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lotería Push',
      theme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true),
      home: hayPartidaActiva
          ? PantallaTablero(controlador: controlador)
          : PantallaInicio(controlador: controlador, api: api),
    );
  }
}