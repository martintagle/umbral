/// Cuentas sobre el progreso jugado sin conexión, en la forma JSON en que se
/// guarda en el teléfono y se envía al servidor. No deciden nada: el servidor
/// valida y aplica el progreso al recibirlo, con sus reglas.
library;

/// Junta el progreso [nuevo] con el [anterior] que aún no se envió. El
/// servidor puede validar la suma igual que cada parte: los segundos siguen
/// sin pasar del tiempo transcurrido desde su último guardado, y la
/// experiencia y el oro caben en la suma de los rangos de esos enemigos.
Map<String, dynamic> sumarProgresos(
  Map<String, dynamic> anterior,
  Map<String, dynamic> nuevo,
) {
  final enemigos = {..._enemigos(anterior)};
  _enemigos(nuevo).forEach(
    (id, n) => enemigos.update(id, (m) => m + n, ifAbsent: () => n),
  );
  int suma(String campo) => (anterior[campo] as int) + (nuevo[campo] as int);
  return {
    'enemigosDerrotados': enemigos,
    'exp': suma('exp'),
    'oro': suma('oro'),
    'muertes': suma('muertes'),
    'segundosJugados': suma('segundosJugados'),
    'vidaActual': nuevo['vidaActual'],
    'ubicacion': nuevo['ubicacion'],
    'cofresAbiertos': {..._cofres(anterior), ..._cofres(nuevo)}.toList(),
    'oroCofres': _oroCofres(anterior) + _oroCofres(nuevo),
  };
}

/// La [partida] (una `PartidaJugable` en JSON) como quedará cuando el
/// servidor reciba [progreso]: es lo que se ve mientras no hay conexión.
/// [jefes] son los ids de los enemigos de categoría jefe.
Map<String, dynamic> partidaConProgreso(
  Map<String, dynamic> partida,
  Map<String, dynamic> progreso,
  Set<String> jefes,
) {
  final datos = partida['partida'] as Map<String, dynamic>;
  final p = datos['personaje'] as Map<String, dynamic>;
  final mundo = p['mundo'] as Map<String, dynamic>;
  final e = p['estadisticas'] as Map<String, dynamic>;
  final enemigos = _enemigos(progreso);
  return {
    ...partida,
    'partida': {
      ...datos,
      'personaje': {
        ...p,
        'exp': (p['exp'] as int) + (progreso['exp'] as int),
        'oro':
            (p['oro'] as int) +
            (progreso['oro'] as int) +
            _oroCofres(progreso),
        'vidaActual': progreso['vidaActual'],
        'ubicacion': progreso['ubicacion'],
        'mundo': {
          ...mundo,
          'cofresAbiertos': {
            ...(mundo['cofresAbiertos'] as List).cast<String>(),
            ..._cofres(progreso),
          }.toList(),
          'jefesDerrotados': {
            ...(mundo['jefesDerrotados'] as List).cast<String>(),
            ...enemigos.keys.where(jefes.contains),
          }.toList(),
        },
        'estadisticas': {
          ...e,
          'enemigosDerrotados':
              (e['enemigosDerrotados'] as int) +
              enemigos.values.fold(0, (a, b) => a + b),
          'muertes': (e['muertes'] as int) + (progreso['muertes'] as int),
          'tiempoJugadoSeg':
              (e['tiempoJugadoSeg'] as int) +
              (progreso['segundosJugados'] as int),
        },
      },
    },
  };
}

Map<String, int> _enemigos(Map<String, dynamic> progreso) =>
    (progreso['enemigosDerrotados'] as Map).cast<String, int>();

/// Los progresos guardados antes de que hubiera cofres no los traen.
List<String> _cofres(Map<String, dynamic> progreso) =>
    (progreso['cofresAbiertos'] as List? ?? const []).cast<String>();

int _oroCofres(Map<String, dynamic> progreso) =>
    progreso['oroCofres'] as int? ?? 0;
