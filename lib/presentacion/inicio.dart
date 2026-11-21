import 'package:flutter/material.dart';

import '../dominio/api_juego.dart';
import '../dominio/controlador.dart';
import 'cantor.dart';
import 'tablero.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key, required this.controlador, required this.api});
  final ControladorPartida controlador;
  final ApiJuego api;

  @override
  State<PantallaInicio> createState() => _EstadoInicio();
}

class _EstadoInicio extends State<PantallaInicio> {
  final _sala = TextEditingController();
  final _nombre = TextEditingController();
  bool _ocupado = false;
  String? _error;

  @override
  void dispose() {
    _sala.dispose();
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _unirse() async {
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await widget.controlador.unirse(sala: _sala.text, nombre: _nombre.text);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PantallaTablero(controlador: widget.controlador),
      ));
    } on ErrorApi catch (e) {
      setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _crearSala() async {
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      final creada = await widget.api.crearSala();
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PantallaCantor(api: widget.api, sala: creada.id, claveCantor: creada.claveCantor),
      ));
    } on ErrorApi catch (e) {
      setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lotería Push')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Unirse a una partida', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                key: const Key('campo-sala'),
                controller: _sala,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Código de sala', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('campo-nombre'),
                controller: _nombre,
                decoration: const InputDecoration(labelText: 'Tu nombre', border: OutlineInputBorder()),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('boton-unirse'),
                onPressed: _ocupado ? null : _unirse,
                child: const Text('Entrar a jugar'),
              ),
              const Divider(height: 40),
              Text('¿Tú cantas las cartas?', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('boton-crear-sala'),
                onPressed: _ocupado ? null : _crearSala,
                icon: const Icon(Icons.campaign_outlined),
                label: const Text('Crear sala como cantor'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}