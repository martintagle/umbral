import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/actualizacion_api.dart';
import '../../contrato/actualizacion.dart';
import '../tema/tema_umbral.dart';
import 'boton_umbral.dart';
import 'panel_umbral.dart';

/// Avisa de que hay una versión nueva de la app: la primera vez que se sabe
/// en cada apertura, con un diálogo; después, con esta franja y su botón de
/// descarga. Mientras no haya versión nueva no ocupa nada.
class AvisoActualizacion extends StatefulWidget {
  const AvisoActualizacion({super.key});

  @override
  State<AvisoActualizacion> createState() => _AvisoActualizacionState();
}

class _AvisoActualizacionState extends State<AvisoActualizacion> {
  static bool _dialogoMostrado = false;
  Actualizacion? _nueva;

  @override
  void initState() {
    super.initState();
    ActualizacionApi().buscar().then((nueva) {
      if (!mounted || nueva == null) return;
      setState(() => _nueva = nueva);
      if (!_dialogoMostrado) {
        _dialogoMostrado = true;
        _preguntar(nueva);
      }
    });
  }

  Future<void> _preguntar(Actualizacion nueva) async {
    final descargar = await showDialog<bool>(
      context: context,
      barrierColor: Colores.abismo.withValues(alpha: 0.6),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(Espacios.paso4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: PanelUmbral(
            colorBorde: Colores.brasa,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Nueva versión', style: Textos.encabezado()),
                const SizedBox(height: Espacios.paso2),
                Text(
                  'Umbral ${nueva.version} ya está disponible. Descárgala e '
                  'instálala encima de esta: tus partidas no se pierden.',
                  style: Textos.cuerpo(color: Colores.ceniza),
                ),
                const SizedBox(height: Espacios.paso6),
                Row(
                  children: [
                    Expanded(
                      child: BotonUmbral(
                        texto: 'Más tarde',
                        estilo: EstiloBoton.secundario,
                        alPulsar: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: Espacios.paso4),
                    Expanded(
                      child: BotonUmbral(
                        texto: 'Descargar',
                        alPulsar: () => Navigator.of(context).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (descargar == true) await _descargar(nueva);
  }

  /// Abre la descarga del APK en el navegador; Android pide instalarlo al
  /// terminar.
  Future<void> _descargar(Actualizacion nueva) async {
    final abierto = await launchUrl(
      Uri.parse(nueva.url),
      mode: LaunchMode.externalApplication,
    );
    if (!abierto && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir ${nueva.url}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nueva = _nueva;
    if (nueva == null) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: PanelUmbral(
        colorBorde: Colores.brasa,
        padding: const EdgeInsets.symmetric(
          horizontal: Espacios.paso4,
          vertical: Espacios.paso2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.system_update_rounded,
              color: Colores.brasa,
              size: 20,
            ),
            const SizedBox(width: Espacios.paso2),
            Flexible(
              child: Text(
                'Versión ${nueva.version} disponible',
                style: Textos.cuerpo(),
              ),
            ),
            const SizedBox(width: Espacios.paso4),
            BotonUmbral(
              texto: 'Descargar',
              expandido: false,
              alPulsar: () => _descargar(nueva),
            ),
          ],
        ),
      ),
    );
  }
}
