import 'package:flutter/material.dart';

import '../dominio/api_juego.dart';
import '../dominio/cartas.dart';
import '../dominio/controlador.dart';
import '../dominio/lineas.dart';
import '../dominio/partida.dart';
import '../dominio/puerto_push.dart';

class PantallaTablero extends StatefulWidget {
  const PantallaTablero({super.key, required this.controlador});
  final ControladorPartida controlador;

  @override
  State<PantallaTablero> createState() => _EstadoTablero();
}

class _EstadoTablero extends State<PantallaTablero> with WidgetsBindingObserver {
  bool _ocultarBannerPermiso = false;
  bool _reclamando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver al primer plano, nos ponemos al día: pudo llegar un push o perderse.
    if (state == AppLifecycleState.resumed) widget.controlador.sincronizar();
  }

  Future<void> _activarAvisos() async {
    final res = await widget.controlador.pedirPermisoAvisos();
    if (!mounted) return;
    if (res == PermisoPush.concedido) {
      final p = widget.controlador.partida;
      if (p != null) {
        await widget.controlador.push.suscribirTema('sala_${p.sala}');
        widget.controlador.avisosActivos = true;
        setState(() {});
      }
    }
  }

  Future<void> _cantarLoteria() async {
    setState(() => _reclamando = true);
    try {
      final r = await widget.controlador.reclamarLoteria();
      if (!mounted) return;
      if (!r.gano) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aún no tienes una línea completa según el cantor.')),
        );
      }
    } on ErrorApi catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensaje)));
    } finally {
      if (mounted) setState(() => _reclamando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: widget.controlador.cambios,
      builder: (context, _) {
        final p = widget.controlador.partida;
        if (p == null) {
          return const Scaffold(body: Center(child: Text('Sin partida activa')));
        }
        return Scaffold(
          appBar: AppBar(
            title: Text('Sala ${p.sala} · ${p.nombre}'),
            actions: [
              IconButton(
                key: const Key('boton-sincronizar'),
                tooltip: 'Ponerse al día con el servidor',
                icon: const Icon(Icons.refresh),
                onPressed: widget.controlador.sincronizar,
              ),
            ],
          ),
          body: Column(
            children: [
              _BannerPermiso(
                permiso: widget.controlador.permiso,
                avisosActivos: widget.controlador.avisosActivos,
                oculto: _ocultarBannerPermiso,
                onActivar: _activarAvisos,
                onOcultar: () => setState(() => _ocultarBannerPermiso = true),
              ),
              if (widget.controlador.ultimoError != null)
                MaterialBanner(
                  content: Text(widget.controlador.ultimoError!),
                  actions: [TextButton(onPressed: widget.controlador.sincronizar, child: const Text('Reintentar'))],
                ),
              if (p.ganador != null) _BannerGanador(ganador: p.ganador!, patron: p.patronGanador ?? ''),
              if (p.casi && p.ganador == null)
                Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('¡Casi! Te falta: ${nombreDeCarta(p.cartaQueFalta ?? 0)}'),
                ),
              _UltimaCarta(partida: p),
              Expanded(child: _Cuadricula(partida: p)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('boton-loteria'),
                    onPressed: (p.puedeCantarLoteria && !_reclamando) ? _cantarLoteria : null,
                    icon: const Icon(Icons.celebration),
                    label: const Text('¡LOTERÍA!'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Patrón "pre-permiso": explicamos el valor ANTES de pedir permiso al sistema, y el
/// juego sigue funcionando aunque el usuario diga que no.
class _BannerPermiso extends StatelessWidget {
  const _BannerPermiso({
    required this.permiso,
    required this.avisosActivos,
    required this.oculto,
    required this.onActivar,
    required this.onOcultar,
  });

  final PermisoPush permiso;
  final bool avisosActivos;
  final bool oculto;
  final VoidCallback onActivar;
  final VoidCallback onOcultar;

  @override
  Widget build(BuildContext context) {
    if (avisosActivos || oculto) return const SizedBox.shrink();
    final texto = permiso == PermisoPush.denegado
        ? 'Avisos desactivados: sigue jugando y pulsa actualizar cuando quieras.'
        : 'Activa los avisos para enterarte de cada carta incluso con la pantalla apagada.';
    return Container(
      key: const Key('banner-permiso'),
      color: Theme.of(context).colorScheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(texto)),
          if (permiso == PermisoPush.sinPreguntar)
            TextButton(key: const Key('boton-activar-avisos'), onPressed: onActivar, child: const Text('Activar')),
          IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onOcultar),
        ],
      ),
    );
  }
}

class _BannerGanador extends StatelessWidget {
  const _BannerGanador({required this.ganador, required this.patron});
  final String ganador;
  final String patron;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('banner-ganador'),
      width: double.infinity,
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.all(12),
      child: Text(
        '🎉 ¡Lotería! $ganador ganó con ${describirPatron(patron)}.',
        style: Theme.of(context).textTheme.titleMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _UltimaCarta extends StatelessWidget {
  const _UltimaCarta({required this.partida});
  final Partida partida;

  @override
  Widget build(BuildContext context) {
    final c = partida.ultimaCarta;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Card(
        child: ListTile(
          key: const Key('ultima-carta'),
          leading: CircleAvatar(child: Text('${partida.ultima}')),
          title: Text(c == null ? 'Esperando la primera carta...' : c.nombre),
          subtitle: Text(c == null ? 'El cantor aún no empieza' : c.pista),
        ),
      ),
    );
  }
}

class _Cuadricula extends StatelessWidget {
  const _Cuadricula({required this.partida});
  final Partida partida;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: partida.tabla.length,
      itemBuilder: (context, i) {
        final id = partida.tabla[i];
        final marcada = partida.estaMarcada(id);
        return AnimatedContainer(
          key: Key('casilla-$i'),
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: marcada
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: marcada ? Theme.of(context).colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (marcada) Icon(Icons.check_circle, size: 16, color: Theme.of(context).colorScheme.primary),
              Text(
                nombreDeCarta(id),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        );
      },
    );
  }
}