import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secrethitler_game/pantalla_juego.dart';
import 'pantalla_sala.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();

  // RUTA DE TU LOGO - Cambia esto por la ruta de tu imagen
  final String _logoPath = 'assets/LogoSecretHitler.png'; // <--- AQUÍ PONES TU RUTA

  int _maxJugadores = 10;
  final List<int> _opcionesJugadores = [5, 6, 7, 8, 9, 10, 11, 12, 13, 14];
  String _mensajeEstado = "";

  // Colores temáticos
  final Color _rojoOscuro = const Color(0xFF8B0000);
  final Color _azulOscuro = const Color(0xFF0A2F6B);
  final Color _oroPrincipal = const Color(0xFFBF9530);
  final Color _oroBrillante = const Color(0xFFFCF6BA);
  final Color _oroOscuro = const Color(0xFFAA771C);

  Future<void> _crearSala() async {
    if (_nombreController.text.isEmpty) {
      setState(() {
        _mensajeEstado = "Escribe tu nombre primero";
      });
      return;
    }

    try {
      setState(() {
        _mensajeEstado = "Creando sala...";
      });

      String codigoSala = _generarCodigo();

      await FirebaseFirestore.instance.collection('rooms').doc(codigoSala).set({
        'nombreCreador': _nombreController.text,
        'createdAt': FieldValue.serverTimestamp(),
        'estado': 'esperando',
        'maxJugadores': _maxJugadores,
        'jugadores': {
          'jugador1': {
            'nombre': _nombreController.text,
            'esAnfitrion': true,
            'estaListo': false,
            'conectado': true,
            'ultimaConexion': FieldValue.serverTimestamp(),
          }
        }
      });

      setState(() {
        _mensajeEstado = "✅ Sala creada: $codigoSala";
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PantallaSala(
              codigoSala: codigoSala,
              nombreJugador: _nombreController.text,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _mensajeEstado = "Error: $e";
      });
    }
  }

  Future<void> _unirseSala() async {
    if (_nombreController.text.isEmpty) {
      setState(() {
        _mensajeEstado = "Escribe tu nombre";
      });
      return;
    }

    if (_codigoController.text.isEmpty) {
      setState(() {
        _mensajeEstado = "Escribe el código de sala";
      });
      return;
    }

    String codigo = _codigoController.text.toUpperCase().trim();

    try {
      setState(() {
        _mensajeEstado = "Buscando sala...";
      });

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(codigo)
          .get();

      if (!doc.exists) {
        setState(() {
          _mensajeEstado = "❌ No existe sala con ese código";
        });
        return;
      }

      var datos = doc.data() as Map<String, dynamic>;
      if (datos['estado'] != 'esperando') {
        setState(() {
          _mensajeEstado = "❌ La partida ya comenzó";
        });
        return;
      }

      var jugadores = datos['jugadores'] as Map<String, dynamic>;
      int maxJugadores = datos['maxJugadores'] ?? 10;

      if (jugadores.length >= maxJugadores) {
        setState(() {
          _mensajeEstado = "❌ Sala llena (máx $maxJugadores jugadores)";
        });
        return;
      }

      String nuevoJugadorId = 'jugador${jugadores.length + 1}';

      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(codigo)
          .update({
        'jugadores.$nuevoJugadorId': {
          'nombre': _nombreController.text,
          'esAnfitrion': false,
          'estaListo': false,
          'conectado': true,
          'ultimaConexion': FieldValue.serverTimestamp(),
        }
      });

      if (datos['estado'] == 'jugando') {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PantallaJuego(
                codigoSala: codigo,
                nombreJugador: _nombreController.text,
              ),
            ),
          );
        }
        return;
      }

      setState(() {
        _mensajeEstado = "✅ Te has unido a la sala $codigo";
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PantallaSala(
              codigoSala: codigo,
              nombreJugador: _nombreController.text,
            ),
          ),
        );
      }

    } catch (e) {
      setState(() {
        _mensajeEstado = "Error: $e";
      });
    }
  }

  String _generarCodigo() {
    const letras = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numeros = '0123456789';
    String codigo = '';
    for (int i = 0; i < 2; i++) {
      codigo += letras[DateTime.now().microsecond % letras.length];
    }
    for (int i = 0; i < 2; i++) {
      codigo += numeros[DateTime.now().microsecond % numeros.length];
    }
    return codigo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text(
          'SECRET HITLER',
          style: TextStyle(
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_rojoOscuro, const Color(0xFF4A0000)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2A2A2A),
              const Color(0xFF1A1A1A),
              const Color(0xFF0A0A0A),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // LOGO PERSONALIZADO (antes era un icono)
                  Container(
                    margin: const EdgeInsets.only(bottom: 30),
                    height: 120, // Ajusta este tamaño según tu logo
                    child: Image.asset(
                      _logoPath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Si no encuentra la imagen, muestra un placeholder
                        return Column(
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 80,
                              color: _oroPrincipal,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Logo no encontrado',
                              style: TextStyle(color: _oroBrillante, fontSize: 12),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Campo de texto con estilo dorado
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: _oroPrincipal.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _nombreController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Tu nombre',
                        labelStyle: TextStyle(color: _oroBrillante),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: _oroPrincipal,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: _oroBrillante,
                            width: 2,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.person,
                          color: _oroPrincipal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Selector de jugadores con estilo
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _oroPrincipal, width: 1),
                      color: Colors.black.withOpacity(0.5),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: DropdownButton<int>(
                      value: _maxJugadores,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF2A2A2A),
                      icon: Icon(Icons.arrow_drop_down, color: _oroPrincipal),
                      hint: Text(
                        'Número de jugadores',
                        style: TextStyle(color: _oroBrillante),
                      ),
                      items: _opcionesJugadores.map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(
                            '$value jugadores',
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _maxJugadores = newValue;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Campo de código
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: _oroPrincipal.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _codigoController,
                      style: const TextStyle(color: Colors.white),
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Código de sala (ej: AB12)',
                        labelStyle: TextStyle(color: _oroBrillante),
                        hintText: '4 letras y números',
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: _oroPrincipal,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: _oroBrillante,
                            width: 2,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.meeting_room,
                          color: _oroPrincipal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Botón CREAR con estilo
                  Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_oroPrincipal, _oroOscuro],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: _oroPrincipal.withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _crearSala,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle, color: Colors.black),
                          SizedBox(width: 10),
                          Text(
                            'CREAR NUEVA SALA',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Botón UNIRSE con estilo
                  Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_oroBrillante, _oroPrincipal],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: _oroPrincipal.withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _unirseSala,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login, color: Colors.black87),
                          SizedBox(width: 10),
                          Text(
                            'UNIRSE A SALA',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Mensaje de estado con estilo
                  if (_mensajeEstado.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _mensajeEstado.contains('✅')
                              ? Colors.green
                              : _mensajeEstado.contains('❌')
                              ? Colors.red
                              : _oroPrincipal,
                        ),
                      ),
                      child: Text(
                        _mensajeEstado,
                        style: TextStyle(
                          fontSize: 14,
                          color: _mensajeEstado.contains('✅')
                              ? Colors.green.shade300
                              : _mensajeEstado.contains('❌')
                              ? Colors.red.shade300
                              : _oroBrillante,
                        ),
                        textAlign: TextAlign.center,
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
}