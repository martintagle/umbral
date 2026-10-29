import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import '../contrato/ajustes.dart';
import '../contrato/apariencia.dart';
import '../contrato/clase_codigo.dart';
import '../api/preferencias.dart';
import '../api/sesion.dart';
import '../api/usuario_api.dart';

/// Archivos de `assets/audios/`.
abstract final class Audios {
  static const musicaTitulo = 'title-music.mp3';
  static const jefe = 'presentacion-de-jefe.mp3';
  static const ambienteCripta = 'sonidos-enemigos.mp3';
  static const grunido = 'sonidos-enemigos2.mp3';
  static const muerteEnemigo = 'muerte-de-enemigos.mp3';
  static const exp = 'exp.mp3';
  static const oro = 'gold.mp3';
  static const gameOver = 'game-over.mp3';
  static const pasoPasto = 'walk-on-grass.mp3';
  static const pasosPiedra = 'walk.mp3';
  static const danoHombre = 'dano-masculino.mp3';
  static const danoMujer = 'dano-femenino.mp3';

  static String ataque(ClaseCodigo clase) => 'ataque-${clase.name}.mp3';

  static String dano(Apariencia apariencia) =>
      apariencia == Apariencia.mujer ? danoMujer : danoHombre;
}

/// Música y efectos del juego, con el volumen de los ajustes. Hasta que se
/// llama a [iniciar] no suena nada (así las pruebas no tocan el audio del
/// sistema), y un fallo del audio nunca interrumpe el juego.
abstract final class Sonido {
  /// Volúmenes de 0 a 1.
  static final musica = ValueNotifier<double>(0.7);
  static final efectos = ValueNotifier<double>(0.9);

  static bool _activo = false;
  static String? _pista;
  static double _volumenPista = 1;
  static final Map<String, AudioPool> _pools = {};
  static final Map<String, DateTime> _ultimaVez = {};
  static AudioPlayer? _bucle;
  static String? _archivoBucle;
  static bool _bucleSonando = false;

  /// Efectos cortos y frecuentes: se precargan en grupos de reproductores.
  static const _frecuentes = {
    Audios.pasoPasto: 3,
    Audios.muerteEnemigo: 3,
    Audios.danoHombre: 2,
    Audios.danoMujer: 2,
    Audios.grunido: 2,
    'ataque-vagabundo.mp3': 3,
    'ataque-guerrero.mp3': 3,
    'ataque-arquero.mp3': 3,
    'ataque-mago.mp3': 3,
    'ataque-prisionero.mp3': 4,
  };

  static Future<void> iniciar() async {
    musica.value = Preferencias.musica ?? musica.value;
    efectos.value = Preferencias.efectos ?? efectos.value;
    try {
      FlameAudio.updatePrefix('assets/audios/');
      await FlameAudio.bgm.initialize();
      _activo = true;
    } catch (_) {
      return;
    }
    musica.addListener(_aplicarVolumenMusica);
    unawaited(_precargar());
  }

  static Future<void> _precargar() async {
    for (final MapEntry(key: archivo, value: maximo) in _frecuentes.entries) {
      try {
        _pools[archivo] = await FlameAudio.createPool(
          archivo,
          maxPlayers: maximo,
        );
      } catch (_) {
        // Se reproducirá sin grupo.
      }
    }
  }

  /// Toca [archivo] en bucle como música de fondo; `null` la detiene. Si ya
  /// está sonando, no la reinicia. [volumen] se multiplica por el de los
  /// ajustes.
  static void pista(String? archivo, {double volumen = 1}) {
    if (!_activo || archivo == _pista) return;
    _pista = archivo;
    _volumenPista = volumen;
    _intentar(() async {
      if (archivo == null) {
        await FlameAudio.bgm.stop();
      } else {
        await FlameAudio.bgm.play(archivo, volume: musica.value * volumen);
      }
    });
  }

  static void _aplicarVolumenMusica() {
    if (!_activo) return;
    _intentar(
      () => FlameAudio.bgm.audioPlayer.setVolume(musica.value * _volumenPista),
    );
    _intentar(
      () async =>
          _bucle?.setVolume(efectos.value * _volumenBucle(_archivoBucle)),
    );
  }

  /// Un efecto suelto. [espera] evita que el mismo sonido se repita antes de
  /// ese tiempo (por ejemplo, varios enemigos gruñendo a la vez).
  static void efecto(
    String archivo, {
    double volumen = 1,
    Duration espera = Duration.zero,
  }) {
    final v = efectos.value * volumen;
    if (!_activo || v <= 0.01) return;
    if (espera > Duration.zero) {
      final ahora = DateTime.now();
      final antes = _ultimaVez[archivo];
      if (antes != null && ahora.difference(antes) < espera) return;
      _ultimaVez[archivo] = ahora;
    }
    final pool = _pools[archivo];
    _intentar(() async {
      if (pool != null) {
        await pool.start(volume: v);
      } else {
        await FlameAudio.play(archivo, volume: v);
      }
    });
  }

  /// Sonido largo que se repite mientras [sonando] sea verdadero: los pasos
  /// sobre piedra o el ambiente de la cripta. Cambiar de [archivo] corta el
  /// anterior.
  static void bucle(String? archivo, {required bool sonando}) {
    if (!_activo) return;
    if (archivo != _archivoBucle) {
      final anterior = _bucle;
      _bucle = null;
      _archivoBucle = archivo;
      _bucleSonando = false;
      if (anterior != null) _intentar(anterior.dispose);
      if (archivo == null) return;
      _intentar(() async {
        final nuevo = await FlameAudio.loopLongAudio(
          archivo,
          volume: efectos.value * _volumenBucle(archivo),
        );
        // Mientras cargaba pudo pedirse otro bucle.
        if (_archivoBucle != archivo) {
          await nuevo.dispose();
          return;
        }
        _bucle = nuevo;
        if (!_bucleSonando) await nuevo.pause();
      });
      _bucleSonando = sonando;
      return;
    }
    if (sonando == _bucleSonando) return;
    _bucleSonando = sonando;
    // Si aún está cargando, al terminar mira [_bucleSonando].
    final reproductor = _bucle;
    if (reproductor == null) return;
    _intentar(() => sonando ? reproductor.resume() : reproductor.pause());
  }

  static double _volumenBucle(String? archivo) =>
      archivo == Audios.ambienteCripta ? 0.35 : 0.6;

  /// Detiene el bucle y la música (al salir del juego).
  static void silenciarJuego() {
    bucle(null, sonando: false);
  }

  /// Guarda el volumen en el teléfono y, si hay sesión, en la cuenta.
  static void guardarAjustes() {
    Preferencias.guardarVolumen(musica: musica.value, efectos: efectos.value);
    final usuario = Sesion.usuario;
    if (Sesion.token == null) return;
    unawaited(
      UsuarioApi()
          .actualizarAjustes(
            Ajustes(
              idioma: usuario?.ajustes.idioma ?? 'es',
              musica: musica.value,
              efectos: efectos.value,
            ),
          )
          .catchError((_) {}),
    );
  }

  /// Aplica los ajustes de la cuenta (al iniciar sesión en otro teléfono).
  static void aplicarAjustes(Ajustes ajustes) {
    musica.value = ajustes.musica.clamp(0, 1).toDouble();
    efectos.value = ajustes.efectos.clamp(0, 1).toDouble();
    Preferencias.guardarVolumen(musica: musica.value, efectos: efectos.value);
  }

  static void _intentar(Future<void> Function() accion) {
    try {
      unawaited(accion().catchError((Object _) {}));
    } catch (_) {
      // El audio nunca detiene el juego.
    }
  }
}
