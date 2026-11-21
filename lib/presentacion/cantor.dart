import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../dominio/api_juego.dart';
import '../dominio/evento.dart';

class PantallaCantor extends StatefulWidget {
  const PantallaCantor({super.key, required this.api, required this.sala, required this.claveCantor});
  final ApiJuego api;
  final String sala;
  final String claveCantor;

  @override
  State<PantallaCantor> createState() => _EstadoCantor();
}

class _EstadoCantor extends State<PantallaCantor> {
  final List<CartaCantada> _cantadas = [];
  bool _cantando = false;
  String? _error;

  Future<void> _cantar() async {
    setState(() {
      _cantando = true;
      _error = null;
    });
    try {
      final c = await widget.api.cantar(widget.sala, widget.claveCantor);
      setState(() => _cantadas.insert(0, c));
    } on ErrorApi catch (e) {
      setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cantando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ultima = _cantadas.isEmpty ? null : _cantadas.first;
    return Scaffold(
      appBar: AppBar(title: Text('Cantor · Sala ${widget.sala}')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: Text('Código para compartir: ${widget.sala}'),
                subtitle: const Text('Dáselo a quienes quieran jugar'),
                trailing: IconButton(
                  tooltip: 'Copiar código',
                  icon: const Icon(Icons.copy),
                  onPressed: () => Clipboard.setData(ClipboardData(text: widget.sala)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (ultima != null)
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('#${ultima.n} de 54', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 4),
                      Text(ultima.nombre, style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(ultima.pista, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('boton-cantar'),
                onPressed: _cantando ? null : _cantar,
                icon: const Icon(Icons.record_voice_over),
                label: const Text('Cantar siguiente carta'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _cantadas.length,
                itemBuilder: (_, i) {
                  final c = _cantadas[i];
                  return ListTile(dense: true, leading: Text('#${c.n}'), title: Text(c.nombre));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}