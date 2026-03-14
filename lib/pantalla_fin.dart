import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pantalla_sala.dart';

class PantallaFin extends StatelessWidget {
  final String codigoSala;
  final String ganador;
  final String motivo;
  final String nombreJugador;

  const PantallaFin({
    super.key,
    required this.codigoSala,
    required this.ganador,
    required this.motivo,
    required this.nombreJugador,
  });

  // Colores temáticos
  final Color _rojoOscuro = const Color(0xFF8B0000);
  final Color _azulOscuro = const Color(0xFF0A2F6B);
  final Color _oroPrincipal = const Color(0xFFBF9530);
  final Color _oroBrillante = const Color(0xFFFCF6BA);
  final Color _oroOscuro = const Color(0xFFAA771C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text(
          'FIN DE LA PARTIDA',
          style: const TextStyle(
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
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
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .doc(codigoSala)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'Sala no encontrada',
                style: TextStyle(color: _oroBrillante),
              ),
            );
          }

          var datos = snapshot.data!.data() as Map<String, dynamic>;
          var jugadores = datos['jugadores'] as Map<String, dynamic>;
          var roles = datos['roles'] as Map<String, dynamic>;

          String hitlerNombre = '';
          List<Map<String, dynamic>> listaJugadores = [];

          jugadores.forEach((id, jugador) {
            String rol = roles[id] ?? 'desconocido';
            if (rol == 'hitler') {
              hitlerNombre = jugador['nombre'];
            }
            listaJugadores.add({
              'id': id,
              'nombre': jugador['nombre'],
              'rol': rol,
              'esAnfitrion': jugador['esAnfitrion'] ?? false,
            });
          });

          listaJugadores.sort((a, b) {
            if (a['esAnfitrion'] && !b['esAnfitrion']) return -1;
            if (!a['esAnfitrion'] && b['esAnfitrion']) return 1;
            return a['nombre'].compareTo(b['nombre']);
          });

          Color colorGanador = ganador == 'liberales' ? _azulOscuro : _rojoOscuro;
          String iconoGanador = ganador == 'liberales' ? '🏛️' : '⚡';

          return Container(
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Cabecera de victoria (rediseñada con estilo dorado)
                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorGanador.withOpacity(0.8),
                            colorGanador.withOpacity(0.3),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: _oroPrincipal, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: _oroPrincipal.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            iconoGanador,
                            style: const TextStyle(fontSize: 60),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'VICTORIA',
                            style: TextStyle(
                              fontSize: 20,
                              letterSpacing: 4,
                              color: _oroBrillante,
                            ),
                          ),
                          Text(
                            ganador.toUpperCase(),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: _oroBrillante,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _oroPrincipal),
                            ),
                            child: Text(
                              motivo,
                              style: const TextStyle(fontSize: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Tarjeta de Hitler (rediseñada)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.7), Colors.black.withOpacity(0.4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: _rojoOscuro, width: 2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _rojoOscuro,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _rojoOscuro.withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.dangerous,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'HITLER ERA:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _oroBrillante,
                                    letterSpacing: 2,
                                  ),
                                ),
                                Text(
                                  hitlerNombre,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Lista de todos los jugadores (rediseñada)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade900, Colors.grey.shade800],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _oroPrincipal.withOpacity(0.5)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'TODOS LOS JUGADORES',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _oroBrillante,
                            ),
                          ),
                          const SizedBox(height: 15),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: listaJugadores.length,
                            itemBuilder: (context, index) {
                              var jugador = listaJugadores[index];
                              Color colorRol = jugador['rol'] == 'liberal' ? _azulOscuro :
                              jugador['rol'] == 'fascista' ? _rojoOscuro :
                              Colors.black;
                              String icono = jugador['rol'] == 'liberal' ? '😇' :
                              jugador['rol'] == 'fascista' ? '👹' : '👿';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [colorRol.withOpacity(0.3), colorRol.withOpacity(0.1)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: jugador['esAnfitrion'] ? _oroPrincipal : colorRol.withOpacity(0.3),
                                    width: jugador['esAnfitrion'] ? 2 : 1,
                                  ),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: colorRol,
                                    child: Text(
                                      icono,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                  title: Text(
                                    jugador['nombre'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  subtitle: Text(
                                    jugador['rol'].toUpperCase(),
                                    style: TextStyle(
                                      color: colorRol,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: jugador['esAnfitrion']
                                      ? Icon(Icons.star, color: _oroBrillante)
                                      : null,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Botones de acción (rediseñados con estilo dorado)
                    Row(
                      children: [
                        Expanded(
                          child: _buildGoldenButton(
                            onPressed: () {
                              Navigator.popUntil(context, (route) => route.isFirst);
                            },
                            icon: Icons.home,
                            label: 'INICIO',
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildGoldenButton(
                            onPressed: () async {
                              String nuevoCodigo = _generarCodigo();

                              await FirebaseFirestore.instance
                                  .collection('rooms')
                                  .doc(nuevoCodigo)
                                  .set({
                                'nombreCreador': jugadores['jugador1']['nombre'],
                                'createdAt': FieldValue.serverTimestamp(),
                                'estado': 'esperando',
                                'maxJugadores': datos['maxJugadores'] ?? 10,
                                'jugadores': jugadores,
                              });

                              if (context.mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PantallaSala(
                                      codigoSala: nuevoCodigo,
                                      nombreJugador: nombreJugador,
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: Icons.refresh,
                            label: 'JUGAR OTRA VEZ',
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
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

  Widget _buildGoldenButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: onPressed != null
              ? [_oroPrincipal, _oroBrillante, _oroOscuro]
              : [Colors.grey.shade700, Colors.grey.shade800],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: onPressed != null
            ? [
          BoxShadow(
            color: _oroPrincipal.withOpacity(0.5),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: onPressed != null ? Colors.black : Colors.white54),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: onPressed != null ? Colors.black : Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}