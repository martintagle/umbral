import 'package:flutter/material.dart';

import '../../servicio/servicio_excepcion.dart';
import '../../servicio/usuario_servicio.dart';
import '../tema/tema_umbral.dart';
import '../validaciones/validaciones.dart';
import '../widgets/boton_umbral.dart';
import '../widgets/campo_umbral.dart';
import '../widgets/panel_umbral.dart';
import 'partidas_pantalla.dart';

class LoginPantalla extends StatefulWidget {
  const LoginPantalla({super.key});

  @override
  State<LoginPantalla> createState() => _LoginPantallaState();
}

class _LoginPantallaState extends State<LoginPantalla> {
  final _servicio = UsuarioServicio();
  final _formulario = GlobalKey<FormState>();
  final _identificador = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmar = TextEditingController();

  bool _registro = false;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_identificador, _username, _email, _password, _confirmar]) {
      c.dispose();
    }
    super.dispose();
  }

  void _cambiarModo() {
    setState(() {
      _registro = !_registro;
      _error = null;
      _formulario.currentState?.reset();
    });
  }

  Future<void> _enviar() async {
    if (_cargando) return;
    if (!_formulario.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      // El servicio deja la sesión abierta.
      if (_registro) {
        await _servicio.registrar(
          username: _username.text,
          email: _email.text,
          password: _password.text,
        );
      } else {
        await _servicio.iniciarSesion(_identificador.text, _password.text);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PartidasPantalla()),
      );
    } on ServicioExcepcion catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Espacios.paso4),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Umbral',
                      textAlign: TextAlign.center,
                      style: Textos.tituloJuego()),
                  const SizedBox(height: Espacios.paso6),
                  PanelUmbral(
                    child: AutofillGroup(
                      child: Form(
                        key: _formulario,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(_registro ? 'Crear cuenta' : 'Iniciar sesión',
                                style: Textos.encabezado()),
                            const SizedBox(height: Espacios.paso4),
                            ..._campos(),
                            if (_error != null) ...[
                              const SizedBox(height: Espacios.paso4),
                              AvisoError(_error!),
                            ],
                            const SizedBox(height: Espacios.paso6),
                            BotonUmbral(
                              texto: _registro ? 'Crear cuenta' : 'Entrar',
                              cargando: _cargando,
                              alPulsar: _enviar,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Espacios.paso4),
                  TextButton(
                    onPressed: _cargando ? null : _cambiarModo,
                    style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(48)),
                    child: Text(
                      _registro
                          ? '¿Ya tienes cuenta? Inicia sesión'
                          : '¿No tienes cuenta? Créala',
                      style: Textos.cuerpo(color: Colores.brasa),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _campos() {
    const separacion = SizedBox(height: Espacios.paso4);
    if (!_registro) {
      return [
        CampoUmbral(
          etiqueta: 'Correo o usuario',
          controlador: _identificador,
          validador: (v) => Validaciones.requerido(v, campo: 'El correo o usuario'),
          autocompletar: const [AutofillHints.username, AutofillHints.email],
        ),
        separacion,
        CampoUmbral(
          etiqueta: 'Contraseña',
          controlador: _password,
          oculto: true,
          accion: TextInputAction.done,
          validador: (v) => Validaciones.requerido(v, campo: 'La contraseña'),
          autocompletar: const [AutofillHints.password],
          alEnviar: (_) => _enviar(),
        ),
      ];
    }
    return [
      CampoUmbral(
        etiqueta: 'Nombre de usuario',
        controlador: _username,
        validador: Validaciones.username,
        autocompletar: const [AutofillHints.newUsername],
        maximo: 20,
      ),
      separacion,
      CampoUmbral(
        etiqueta: 'Correo',
        controlador: _email,
        teclado: TextInputType.emailAddress,
        validador: Validaciones.email,
        autocompletar: const [AutofillHints.email],
      ),
      separacion,
      CampoUmbral(
        etiqueta: 'Contraseña',
        controlador: _password,
        oculto: true,
        validador: Validaciones.password,
        autocompletar: const [AutofillHints.newPassword],
      ),
      separacion,
      CampoUmbral(
        etiqueta: 'Repite la contraseña',
        controlador: _confirmar,
        oculto: true,
        accion: TextInputAction.done,
        validador: Validaciones.confirmarPassword(() => _password.text),
        alEnviar: (_) => _enviar(),
      ),
    ];
  }
}
