# Graph Report - umbral  (2026-10-24)

## Corpus Check
- Corpus is ~37,864 words - fits in a single context window. You may not need a graph.

## Summary
- 1174 nodes · 1593 edges · 77 communities (67 shown, 10 thin omitted)
- Extraction: 92% EXTRACTED · 8% INFERRED · 0% AMBIGUOUS · INFERRED: 120 edges (avg confidence: 0.9)
- Token cost: 266,821 input · 0 output

## Community Hubs (Navigation)
- Game Loop UmbralJuego
- iOS/macOS Runner
- Character DTO (App)
- Game Screen UI
- Theme Color Tokens
- Server API DTOs
- HTTP API Client
- Enemy AI Behavior
- Linux GTK Runner
- Enemy Type Catalog
- Save Slots Screen
- Clearing Zone Map
- Default App Icons
- App Session Services
- New Character Screen
- Player Character
- Login Screen
- Combat Effects
- Service Exceptions
- Windows Runner Main
- Express Routes & Auth
- User DTO (App)
- Windows Flutter Window
- Win32 Window Lifecycle
- Server User DTO & DB
- Combat Styles
- Flame Components
- App Entry & Sprites
- Business Errors & Partidas
- Server TS Config
- Character Sprites
- Umbral Button Widget
- SOA Architecture Docs
- Server Package Manifest
- Structure Sprites
- Class Catalog DTO
- Design System Docs
- Progress Tracking
- Screen Private Widgets
- Dev Memory Server
- Build & Platform Docs
- Save Slot DTO
- Win32 Window Interface
- Enemy Sprites
- Panel Widget
- UI Layer & Sprite Sheets
- Win32 Message Handling
- Playable Save DTO
- Save Slot Service
- Combat Stats DTO
- Service & Error Docs
- Class UI Metadata
- Zod Validation Schemas
- Attributes DTO
- World State DTO
- DTO Contract Docs
- Location DTO
- Form Validations
- Server Dependencies
- Business Rules Docs
- Settings DTO
- Stats DTO
- Server Dev Dependencies
- Server npm Scripts
- Equipment DTO
- Windows Plugin Registrant
- MongoDB Connection
- Default Launch Image
- Win32 Point
- Win32 Size
- Android MainActivity
- User Status Enum

## God Nodes (most connected - your core abstractions)
1. `Flutter Default Logo (placeholder app icon)` - 27 edges
2. `Win32Window` - 21 edges
3. `NegocioError` - 17 edges
4. `compilerOptions` - 12 edges
5. `Character Sprite Sheet` - 12 edges
6. `PersonajeDto` - 11 edges
7. `Umbral - sistema de diseno` - 11 edges
8. `FlutterWindow` - 10 edges
9. `Arquitectura SOA en dos partes (App Dart / Servidor TypeScript)` - 10 edges
10. `Capa de Negocio (servidor)` - 10 edges

## Surprising Connections (you probably didn't know these)
- `validaciones.dart (validaciones locales para TextFormField)` --semantically_similar_to--> `validacion.ts (esquemas zod de forma, enteros 32 bits)`  [INFERRED] [semantically similar]
  lib/ui/README.md → servidor/src/servicio/README.md
- `Binario Linux umbral (com.example.umbral)` --semantically_similar_to--> `Binario Windows umbral`  [INFERRED] [semantically similar]
  linux/CMakeLists.txt → windows/CMakeLists.txt
- `Android launcher icon mipmap-xxxhdpi/ic_launcher.png` --semantically_similar_to--> `iOS AppIcon Icon-App-1024x1024@1x.png`  [INFERRED] [semantically similar]
  android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png → ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
- `iOS AppIcon Icon-App-1024x1024@1x.png` --semantically_similar_to--> `macOS AppIcon app_icon_1024.png`  [INFERRED] [semantically similar]
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png → macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png
- `Interfaz de combate (barras PV/PM, turno activo, dano flotante)` --conceptually_related_to--> `juego/ (juego en tiempo real con Flame)`  [AMBIGUOUS]
  docs/diseno/README.md → lib/ui/README.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Flujo SOA de una peticion: UI -> servicio app -> API servicio -> negocio -> conexion -> Atlas** — lib_ui_readme_capa_ui, lib_servicio_readme_capa_servicio_app, servidor_src_servicio_readme_capa_servicio_servidor, servidor_src_negocio_readme_capa_negocio, servidor_src_conexion_readme_conexionbd, readme_mongodb_atlas [EXTRACTED 1.00]
- **Guardado de progreso y subida de nivel en servidor** — lib_ui_juego_registro_progreso, lib_dto_readme_progresodto, lib_servicio_partida_servicio, servidor_src_negocio_readme_partida_negocio, servidor_src_negocio_readme_personaje_negocio, servidor_src_negocio_readme_escrituras_atomicas [INFERRED 0.85]
- **Definicion compartida de la coleccion usuarios (DTO app, DTO servidor, validador)** — lib_dto_readme_capa_dto_app, servidor_src_dto_readme_capa_dto_servidor, servidor_readme_esquema_usuarios, servidor_src_dto_readme_coleccion_usuarios [INFERRED 0.85]
- **Umbral enemy roster (6 regular enemies + Rey Hueco boss)** — assets_sprites_enemigos_ojo_errante_sprite, assets_sprites_enemigos_fauce_sprite, assets_sprites_enemigos_polilla_osaria_sprite, assets_sprites_enemigos_larva_cirio_sprite, assets_sprites_enemigos_manojo_sprite, assets_sprites_enemigos_ahorcado_fungico_sprite, assets_sprites_enemigos_jefe_rey_hueco_sprite [INFERRED 0.85]
- **Umbral overworld structure sprite set** — assets_sprites_estructuras_altar_de_brasas_sprite, assets_sprites_estructuras_pozo_sprite, assets_sprites_estructuras_lapidas_sprite, assets_sprites_estructuras_estatua_sin_rostro_sprite, assets_sprites_estructuras_choza_en_ruinas_sprite, assets_sprites_estructuras_capilla_sprite, assets_sprites_estructuras_torre_derruida_sprite, assets_sprites_estructuras_entrada_de_cripta_sprite, assets_sprites_estructuras_arbol_de_la_jaula_sprite, assets_sprites_estructuras_hoja_estructuras_spritesheet [INFERRED 0.95]
- **Playable Character Classes Roster (vagabond, warrior, archer, mage, prisoner; male and female variants)** — assets_sprites_personajes_vagabundo_hombre_sprite, assets_sprites_personajes_vagabundo_mujer_sprite, assets_sprites_personajes_guerrero_hombre_sprite, assets_sprites_personajes_guerrero_mujer_sprite, assets_sprites_personajes_arquero_hombre_sprite, assets_sprites_personajes_arquero_mujer_sprite, assets_sprites_personajes_mago_hombre_sprite, assets_sprites_personajes_mago_mujer_sprite, assets_sprites_personajes_prisionero_hombre_sprite, assets_sprites_personajes_prisionero_mujer_sprite, docs_diseno_vistas_personajes_character_lineup [INFERRED 0.85]
- **Android launcher icon resolution set** — android_app_src_main_res_mipmap_hdpi_ic_launcher, android_app_src_main_res_mipmap_mdpi_ic_launcher, android_app_src_main_res_mipmap_xhdpi_ic_launcher, android_app_src_main_res_mipmap_xxhdpi_ic_launcher, android_app_src_main_res_mipmap_xxxhdpi_ic_launcher [EXTRACTED 1.00]
- **iOS AppIcon resolution set** — ios_runner_assets_xcassets_appicon_appiconset_icon_app_1024x1024_1x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_20x20_1x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_20x20_2x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_20x20_3x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_29x29_1x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_29x29_2x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_29x29_3x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_40x40_1x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_40x40_2x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_40x40_3x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_60x60_2x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_60x60_3x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_76x76_1x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_76x76_2x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_83_5x83_5_2x [EXTRACTED 1.00]
- **macOS AppIcon resolution set** — macos_runner_assets_xcassets_appicon_appiconset_app_icon_1024, macos_runner_assets_xcassets_appicon_appiconset_app_icon_128, macos_runner_assets_xcassets_appicon_appiconset_app_icon_16, macos_runner_assets_xcassets_appicon_appiconset_app_icon_256, macos_runner_assets_xcassets_appicon_appiconset_app_icon_32, macos_runner_assets_xcassets_appicon_appiconset_app_icon_512, macos_runner_assets_xcassets_appicon_appiconset_app_icon_64 [EXTRACTED 1.00]

## Communities (77 total, 10 thin omitted)

### Community 0 - "Game Loop UmbralJuego"
Cohesion: 0.03
Nodes (44): alGuardar, alPedirMenu, atacando, aviso, _avisoId, _avisoNivelMostrado, _azar, backgroundColor (+36 more)

### Community 1 - "iOS/macOS Runner"
Cohesion: 0.06
Nodes (13): Cocoa, Flutter, FlutterMacOS, Foundation, AppDelegate, SceneDelegate, RunnerTests, RegisterGeneratedPlugins() (+5 more)

### Community 2 - "Character DTO (App)"
Cohesion: 0.06
Nodes (26): apariencia, atributos, clase, equipo, estadisticas, estaminaActual, exp, fromMap (+18 more)

### Community 3 - "Game Screen UI"
Cohesion: 0.07
Nodes (27): _abrirMenu, alto, build, _cerrarMenu, color, createState, etiqueta, _guardarYSalir (+19 more)

### Community 4 - "Theme Color Tokens"
Cohesion: 0.06
Nodes (30): abismo, alma, astilla, base, borde, brasa, ceniza, Colores (+22 more)

### Community 5 - "Server API DTOs"
Cohesion: 0.15
Nodes (22): CatalogoClasesDto, ClaseDto, CombateDto, ProgresoDto, AtributosDto, EquipoDto, EstadisticasDto, MundoDto (+14 more)

### Community 6 - "HTTP API Client"
Cohesion: 0.07
Nodes (18): ApiCliente, base, _cliente, delete, _enviar, _espera, _json, post (+10 more)

### Community 7 - "Enemy AI Behavior"
Cohesion: 0.07
Nodes (27): _atacar, _azar, centro, _destello, _destino, _direccionEmbestida, _distanciaMaximaDelHogar, _embestidaAcerto (+19 more)

### Community 8 - "Linux GTK Runner"
Cohesion: 0.09
Nodes (14): fl_register_plugins(), main(), first_frame_cb(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line() (+6 more)

### Community 9 - "Enemy Type Catalog"
Cohesion: 0.07
Nodes (28): ahorcadoFungico, alcance, Ataque, colorProyectil, dano, deteccion, embestida, Enemigos (+20 more)

### Community 10 - "Save Slots Screen"
Cohesion: 0.07
Nodes (20): activa, alBorrar, alJugar, _borrar, build, _cargar, _cerrarSesion, createState (+12 more)

### Community 11 - "Clearing Zone Map"
Cohesion: 0.07
Nodes (26): _azar, bloquea, _camino, cercaDelAltar, _chispas, _enemigos, enemigosVivos, entrada (+18 more)

### Community 12 - "Default App Icons"
Cohesion: 0.08
Nodes (28): Android launcher icon mipmap-hdpi/ic_launcher.png, Android launcher icon mipmap-mdpi/ic_launcher.png, Android launcher icon mipmap-xhdpi/ic_launcher.png, Android launcher icon mipmap-xxhdpi/ic_launcher.png, Android launcher icon mipmap-xxxhdpi/ic_launcher.png, Flutter Default Logo (placeholder app icon), iOS AppIcon Icon-App-1024x1024@1x.png, iOS AppIcon Icon-App-20x20@1x.png (+20 more)

### Community 13 - "App Session Services"
Cohesion: 0.07
Nodes (15): _catalogo, ClaseServicio, abrir, cerrar, SesionServicio, _token, _usuario, _abrirSesion (+7 more)

### Community 14 - "New Character Screen"
Cohesion: 0.07
Nodes (24): alElegir, ancho, _apariencia, build, _cargando, _cargarCatalogo, _catalogo, _clase (+16 more)

### Community 15 - "Player Character"
Cohesion: 0.07
Nodes (21): _altoPies, _anchoPies, _apuntar, _atacar, centro, estilo, _invulnerabilidad, _invulnerable (+13 more)

### Community 16 - "Login Screen"
Cohesion: 0.08
Nodes (18): build, _cambiarModo, _campos, _cargando, _confirmar, createState, dispose, _email (+10 more)

### Community 17 - "Combat Effects"
Cohesion: 0.07
Nodes (21): arco, color, critico, dano, delJugador, direccion, distanciaMaxima, _duracion (+13 more)

### Community 18 - "Service Exceptions"
Cohesion: 0.08
Nodes (15): estado, mensaje, ServicioExcepcion, sesionCaducada, toString, accion, alEnviar, autocompletar (+7 more)

### Community 19 - "Windows Runner Main"
Cohesion: 0.12
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 20 - "Express Routes & Auth"
Cohesion: 0.15
Nodes (18): express, express-rate-limit, jsonwebtoken, zod, partidaNegocio, personajeNegocio, usuarioNegocio, ESTADO_HTTP (+10 more)

### Community 21 - "User DTO (App)"
Cohesion: 0.11
Nodes (14): actualizadoEn, ajustes, creadoEn, email, estado, fromMap, id, partidaActiva (+6 more)

### Community 22 - "Windows Flutter Window"
Cohesion: 0.11
Nodes (4): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_

### Community 23 - "Win32 Window Lifecycle"
Cohesion: 0.18
Nodes (5): Scale(), Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, instance_

### Community 24 - "Server User DTO & DB"
Cohesion: 0.22
Nodes (12): mongodb, BASE_DATOS, AjustesDto, ESTADOS_USUARIO, EstadoUsuario, UsuarioDto, ajustesDocumento, documentoUsuario() (+4 more)

### Community 25 - "Combat Styles"
Cohesion: 0.12
Nodes (13): alcance, arco, autoapuntado, colorProyectil, dispara, distanciaProyectil, EstiloCombate, estiloDe (+5 more)

### Community 26 - "Flame Components"
Cohesion: 0.14
Nodes (10): Estallido, Proyectil, Tajo, TextoFlotante, Enemigo, Jugador, UmbralJuego, _Brasas (+2 more)

### Community 27 - "App Entry & Sprites"
Cohesion: 0.13
Nodes (10): build, main, UmbralApp, alto, ancho, build, descripcion, escala (+2 more)

### Community 28 - "Business Errors & Partidas"
Cohesion: 0.24
Nodes (12): usuarios(), conErroresMongo(), idMongo(), NegocioError, TipoError, traducir(), listarPartidas(), noExistePartida() (+4 more)

### Community 29 - "Server TS Config"
Cohesion: 0.14
Nodes (13): compilerOptions, esModuleInterop, module, moduleResolution, noUncheckedIndexedAccess, outDir, resolveJsonModule, rootDir (+5 more)

### Community 30 - "Character Sprites"
Cohesion: 0.17
Nodes (13): Archer (Male) Sprite, Archer (Female) Sprite, Warrior (Male) Sprite, Warrior (Female) Sprite, Character Sprite Sheet, Mage (Male) Sprite, Mage (Female) Sprite, Prisoner (Male) Sprite (+5 more)

### Community 31 - "Umbral Button Widget"
Cohesion: 0.17
Nodes (11): alPulsar, BotonUmbral, _BotonUmbralState, build, cargando, createState, estilo, EstiloBoton (+3 more)

### Community 32 - "SOA Architecture Docs"
Cohesion: 0.33
Nodes (11): API_URL (--dart-define, por defecto 10.0.2.2:3000/api), MongoDB Atlas, Umbral (RPG de accion movil), npm run dev:memoria (base temporal en memoria), bd/esquema-usuarios.json (validador de rpg.usuarios), Servidor de Umbral (API REST TypeScript), conexionBD (abrir, coleccion, cerrar), Capa DTO (servidor) (+3 more)

### Community 33 - "Server Package Manifest"
Cohesion: 0.15
Nodes (12): bcryptjs, tsx, @types/express, @types/jsonwebtoken, @types/node, typescript, description, main (+4 more)

### Community 34 - "Structure Sprites"
Cohesion: 0.20
Nodes (12): Altar de Brasas sprite (stone brazier altar with flame), Arbol de la Jaula sprite (dead tree with hanging candle cage), Capilla sprite (stone chapel with bell tower), Choza en Ruinas sprite (ruined wooden hut, holed thatch roof), Entrada de Cripta sprite (mound crypt entrance with gate), Estatua sin Rostro sprite (faceless hooded statue), Hoja de Estructuras (structures sprite sheet, 10 structures in a row), Lapidas sprite (cross and tombstone on grass) (+4 more)

### Community 35 - "Class Catalog DTO"
Cohesion: 0.17
Nodes (9): apariencias, atributos, CatalogoClasesDto, ClaseDto, clases, combate, fromMap, id (+1 more)

### Community 36 - "Design System Docs"
Cohesion: 0.26
Nodes (10): Altar de brasas (punto de descanso y guardado), Interfaz de combate (barras PV/PM, turno activo, dano flotante), Jefe: el Rey Hueco, Paleta de interfaz (abismo, piedra, borde, hueso, ceniza, sangre, brasa, alma, podredumbre), Umbral - sistema de diseno, Sprites de enemigos (ojo errante, fauce, polilla osaria, larva cirio, manojo, ahorcado fungico), Sprites de estructuras (altar de brasas, capilla, cripta, ...), juego/ (juego en tiempo real con Flame) (+2 more)

### Community 37 - "Progress Tracking"
Cohesion: 0.17
Nodes (9): aDto, descontar, enemigoDerrotado, enemigos, exp, muertes, oro, RegistroProgreso (+1 more)

### Community 38 - "Screen Private Widgets"
Cohesion: 0.17
Nodes (11): _Acciones, _Aviso, _Barra, _Capa, _Estado, _Estadistica, _OpcionClase, _TarjetaPartida (+3 more)

### Community 39 - "Dev Memory Server"
Cohesion: 0.18
Nodes (8): dotenv, mongodb-memory-server, esquema, db, esquema, puerto, servidor, crearApp()

### Community 40 - "Build & Platform Docs"
Cohesion: 0.20
Nodes (11): Analisis con flutter_lints (excluye carpetas de plataforma), Tipografia pixel (Jacquard 12, Pixelify Sans, Silkscreen), Launch Screen Assets (iOS), Binario Linux umbral (com.example.umbral), flutter_assemble (Linux), Runner Linux (GTK), google_fonts ^9.0.0, umbral (paquete Flutter) (+3 more)

### Community 41 - "Save Slot DTO"
Cohesion: 0.18
Nodes (7): creadaEn, fromMap, PartidaDto, partidaId, personaje, toMap, ultimaVezJugada

### Community 42 - "Win32 Window Interface"
Cohesion: 0.24
Nodes (4): Win32Window, child_content_, quit_on_close_, window_handle_

### Community 43 - "Enemy Sprites"
Cohesion: 0.27
Nodes (10): Ahorcado Fungico Sprite (mushroom-capped humanoid enemy), Dark-fantasy body-horror pixel art style (dark palette, eyes motif), Fauce Sprite (spider-legged toothed maw enemy), Enemy Sprite Sheet (hoja-enemigos, all enemies + boss in one strip), Jefe Rey Hueco Sprite (crowned hooded boss with eye-filled cloak), Larva Cirio Sprite (candle-bearing larva enemy), Manojo Sprite (multi-eyed tentacled cluster enemy), Ojo Errante Sprite (floating eyeball with tendrils enemy) (+2 more)

### Community 44 - "Panel Widget"
Cohesion: 0.20
Nodes (5): build, child, colorBorde, mensaje, padding

### Community 45 - "UI Layer & Sprite Sheets"
Cohesion: 0.20
Nodes (9): Hojas de sprites (hoja-<grupo>.png + .json con x,y,w,h), Sprites de personajes (vagabundo, guerrero, arquero, mago, prisionero), tokens.json (tokens de diseno), Capa de Interfaz (UI), clases_ui.dart (nombre, arma, sprite de cada clase), Pantallas (titulo, login, partidas, nuevo personaje, juego), tema/ (tokens del sistema de diseno en Flutter), validaciones.dart (validaciones locales para TextFormField) (+1 more)

### Community 47 - "Playable Save DTO"
Cohesion: 0.22
Nodes (4): combate, fromMap, partida, PartidaJugableDto

### Community 48 - "Save Slot Service"
Cohesion: 0.22
Nodes (6): crearPartida, eliminarPartida, listarPartidas, PartidaServicio, registrarProgreso, seleccionarPartidaActiva

### Community 49 - "Combat Stats DTO"
Cohesion: 0.22
Nodes (8): CombateDto, dano, defensa, expSiguiente, fromMap, multiplicadorCritico, probabilidadCritico, vidaMaxima

### Community 50 - "Service & Error Docs"
Cohesion: 0.22
Nodes (9): api_cliente.dart (cliente HTTP), Capa de Servicio (app), ServicioExcepcion (sesionCaducada en 401), sesion_servicio.dart (usuario y token de sesion), http ^1.6.0, NegocioError y conErroresMongo (11000 duplicado, 121 esquema), app.ts (Express, rutas y errores HTTP), autenticacion.ts (token JWT Bearer) (+1 more)

### Community 51 - "Class UI Metadata"
Cohesion: 0.22
Nodes (7): arma, clasesUi, ClaseUi, descripcion, id, nombre, sprite

### Community 52 - "Zod Validation Schemas"
Cohesion: 0.22
Nodes (7): ajustes, crearPartida, login, partidaActiva, progreso, registro, texto

### Community 53 - "Attributes DTO"
Cohesion: 0.25
Nodes (7): AtributosDto, destreza, fromMap, fuerza, inteligencia, toMap, vida

### Community 54 - "World State DTO"
Cohesion: 0.25
Nodes (6): cofresAbiertos, fromMap, jefesDerrotados, MundoDto, toMap, zonasDesbloqueadas

### Community 55 - "DTO Contract Docs"
Cohesion: 0.32
Nodes (7): Capa DTO (app), combate_dto.dart (CombateDto), PersonajeDto (Dart), progreso_dto.dart (ProgresoDto), UsuarioDto (Dart), api.dto.ts (CombateDto, ClaseDto, CatalogoClasesDto, ProgresoDto), respuestas.ts (fechas ISO, id texto, sin passwordHash)

### Community 56 - "Location DTO"
Cohesion: 0.25
Nodes (7): fromMap, toMap, UbicacionDto, ultimoPuntoGuardado, x, y, zonaId

### Community 57 - "Form Validations"
Cohesion: 0.25
Nodes (6): _email, nombrePersonaje, password, requerido, _username, Validaciones

### Community 58 - "Server Dependencies"
Cohesion: 0.25
Nodes (8): dependencies, bcryptjs, dotenv, express, express-rate-limit, jsonwebtoken, mongodb, zod

### Community 59 - "Business Rules Docs"
Cohesion: 0.32
Nodes (7): coleccion-usuarios.ts (conversion DTO <-> documento), Maximo de 10 partidas por usuario, partida.negocio.ts (partidas embebidas), personaje.negocio.ts (estadisticas, combate, subida de nivel), Reglas de cuentas (username 3-20 sin @, contrasena 8-72, rechazo baneado/eliminado), usuario.negocio.ts (registro bcrypt, login, ajustes, borrado), Rutas /api/usuarios, /api/partidas, /api/clases

### Community 60 - "Settings DTO"
Cohesion: 0.29
Nodes (6): AjustesDto, efectos, fromMap, idioma, musica, toMap

### Community 61 - "Stats DTO"
Cohesion: 0.29
Nodes (6): enemigosDerrotados, EstadisticasDto, fromMap, muertes, tiempoJugadoSeg, toMap

### Community 62 - "Server Dev Dependencies"
Cohesion: 0.29
Nodes (7): devDependencies, mongodb-memory-server, tsx, @types/express, @types/jsonwebtoken, @types/node, typescript

### Community 63 - "Server npm Scripts"
Cohesion: 0.29
Nodes (7): scripts, bd:esquema, build, dev, dev:memoria, start, tipos

### Community 64 - "Equipment DTO"
Cohesion: 0.33
Nodes (5): EquipoDto, fromMap, nivelArma, nivelArmadura, toMap

### Community 67 - "Default Launch Image"
Cohesion: 0.50
Nodes (4): Flutter Default Blank Launch Image (placeholder), iOS LaunchImage LaunchImage.png, iOS LaunchImage LaunchImage@2x.png, iOS LaunchImage LaunchImage@3x.png

### Community 68 - "Win32 Point"
Cohesion: 0.50
Nodes (3): Point, x, y

### Community 69 - "Win32 Size"
Cohesion: 0.50
Nodes (3): Size, height, width

## Ambiguous Edges - Review These
- `Interfaz de combate (barras PV/PM, turno activo, dano flotante)` → `juego/ (juego en tiempo real con Flame)`  [AMBIGUOUS]
  docs/diseno/README.md · relation: conceptually_related_to
- `Altar de Brasas sprite (stone brazier altar with flame)` → `Capilla sprite (stone chapel with bell tower)`  [AMBIGUOUS]
  assets/sprites/estructuras/altar-de-brasas.png · relation: conceptually_related_to

## Knowledge Gaps
- **619 isolated node(s):** `AjustesDto`, `idioma`, `musica`, `efectos`, `fromMap` (+614 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 748 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **10 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Interfaz de combate (barras PV/PM, turno activo, dano flotante)` and `juego/ (juego en tiempo real con Flame)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `Capa de Servicio (app)` connect `Service & Error Docs` to `SOA Architecture Docs`, `UI Layer & Sprite Sheets`, `App Session Services`, `Save Slot Service`, `Business Rules Docs`?**
  _High betweenness centrality (0.027) - this node is a cross-community bridge._
- **Are the 27 inferred relationships involving `Flutter Default Logo (placeholder app icon)` (e.g. with `Android launcher icon mipmap-hdpi/ic_launcher.png` and `Android launcher icon mipmap-mdpi/ic_launcher.png`) actually correct?**
  _`Flutter Default Logo (placeholder app icon)` has 27 INFERRED edges - model-reasoned connections that need verification._
- **What connects `AjustesDto`, `idioma`, `musica` to the rest of the system?**
  _619 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Game Loop UmbralJuego` be split into smaller, more focused modules?**
  _Cohesion score 0.03389830508474576 - nodes in this community are weakly interconnected._
- **What is the exact relationship between `Altar de Brasas sprite (stone brazier altar with flame)` and `Capilla sprite (stone chapel with bell tower)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `juego/ (juego en tiempo real con Flame)` connect `Design System Docs` to `Progress Tracking`, `UI Layer & Sprite Sheets`, `DTO Contract Docs`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._