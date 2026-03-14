import 'package:flutter/material.dart';
import 'pantalla_juego.dart';

class PantallaRevelacion extends StatefulWidget {
  final String rol;
  final String codigoSala;
  final String nombreJugador;

  const PantallaRevelacion({
    super.key,
    required this.rol,
    required this.codigoSala,
    required this.nombreJugador,
  });

  @override
  State<PantallaRevelacion> createState() => _PantallaRevelacionState();
}

class _PantallaRevelacionState extends State<PantallaRevelacion>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacidad;
  late Animation<double> _escala;

  // Colores según rol
  Color get _colorRol {
    switch (widget.rol) {
      case 'liberal':
        return const Color(0xFF0A2F6B); // Azul oscuro
      case 'fascista':
        return const Color(0xFF8B0000); // Rojo oscuro
      case 'hitler':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  // Imagen según rol (asume que tienes las imágenes en assets)
  String get _imagenRol {
    switch (widget.rol) {
      case 'liberal':
        return 'assets/rol_liberal.png';
      case 'fascista':
        return 'assets/rol_fascista.png';
      case 'hitler':
        return 'assets/rol_hitler.png';
      default:
        return 'assets/rol_desconocido.png';
    }
  }

  // Texto descriptivo según rol
  String get _descripcion {
    switch (widget.rol) {
      case 'liberal':
        return 'Defiende la democracia';
      case 'fascista':
        return 'Impon el nuevo orden';
      case 'hitler':
        return 'El Führer';
      default:
        return '';
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _opacidad = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _escala = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _controller.forward();

    // Esperar 4 segundos y luego ir a la pantalla de juego
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PantallaJuego(
              codigoSala: widget.codigoSala,
              nombreJugador: widget.nombreJugador,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              _colorRol,
              _colorRol.withOpacity(0.5),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _opacidad,
              child: ScaleTransition(
                scale: _escala,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Imagen del rol (AHORA RECTANGULAR VERTICAL)
                    Container(
                      width: 200,      // Ancho fijo
                      height: 280,     // Alto para formato vertical (ej: proporción 5:7)
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15), // Esquinas redondeadas
                        boxShadow: [
                          BoxShadow(
                            color: _colorRol.withOpacity(0.8),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset(
                          _imagenRol,
                          fit: BoxFit.cover, // 'cover' para que llene el rectángulo
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback si no hay imagen
                            return Container(
                              color: _colorRol,
                              child: Center(
                                child: Icon(
                                  widget.rol == 'liberal'
                                      ? Icons.thumb_up
                                      : widget.rol == 'fascista'
                                      ? Icons.warning
                                      : Icons.dangerous,
                                  size: 100,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Texto del rol
                    Text(
                      widget.rol.toUpperCase(),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: _colorRol,
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Descripción
                    Text(
                      _descripcion,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Indicador de carga
                    const CircularProgressIndicator(
                      color: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Preparando partida...',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
