/// Una versión de la app publicada, leída de la última Release de GitHub
/// (`GET /repos/{repo}/releases/latest`), donde `release.yml` sube el APK.
/// No es una respuesta de la API de Umbral.
class Actualizacion {
  /// `x.y.z`, sin la `v` ni el sufijo del tag (`v0.1.7-beta` → `0.1.7`).
  final String version;

  /// Descarga directa del APK, o la página de la Release si no lo trae.
  final String url;

  const Actualizacion({required this.version, required this.url});

  factory Actualizacion.fromMap(Map<String, dynamic> map) {
    final apk = (map['assets'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .where((a) => (a['name'] as String).endsWith('.apk'))
        .firstOrNull;
    return Actualizacion(
      version: RegExp(r'\d+(\.\d+)*')
              .firstMatch(map['tag_name'] as String)
              ?.group(0) ??
          '0',
      url: (apk?['browser_download_url'] ?? map['html_url']) as String,
    );
  }
}
