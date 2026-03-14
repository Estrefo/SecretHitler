import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pantalla_juego.dart';
import 'pantalla_revelacion.dart';
import 'services/connection_service.dart';

class PantallaSala extends StatefulWidget {
  final String codigoSala;
  final String nombreJugador;

  const PantallaSala({
    super.key,
    required this.codigoSala,
    required this.nombreJugador,
  });

  @override
  State<PantallaSala> createState() => _PantallaSalaState();
}

class _PantallaSalaState extends State<PantallaSala> {
  final ConnectionService _connectionService = ConnectionService();
  bool _monitoreoIniciado = false;

  // Colores temáticos (coincidiendo con pantalla_inicio)
  final Color _rojoOscuro = const Color(0xFF8B0000);
  final Color _azulOscuro = const Color(0xFF0A2F6B);
  final Color _oroPrincipal = const Color(0xFFBF9530);
  final Color _oroBrillante = const Color(0xFFFCF6BA);
  final Color _oroOscuro = const Color(0xFFAA771C);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _connectionService.stopMonitoring(widget.codigoSala);
    super.dispose();
  }

  void _iniciarMonitoreo(String miId) {
    if (!_monitoreoIniciado) {
      _connectionService.startMonitoring(widget.codigoSala, miId, context);
      _monitoreoIniciado = true;
    }
  }

  String _getMyId() {
    return '';
  }

  void _mostrarReglas(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(
          '📜 REGLAS RÁPIDAS',
          style: TextStyle(
            color: _oroBrillante,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildReglaTitulo('🎯 OBJETIVOS'),
              _buildReglaTexto('• Liberales: 5 políticas liberales O matar a Hitler'),
              _buildReglaTexto('• Fascistas: 6 políticas fascistas O Hitler canciller (con 3+ fascistas)'),

              const SizedBox(height: 16),
              _buildReglaTitulo('👥 ROLES'),
              _buildReglaTexto('• Liberales: No saben nada, buscan la verdad'),
              _buildReglaTexto('• Fascistas: Se conocen entre ellos, saben quién es Hitler'),
              _buildReglaTexto('• Hitler: Los fascistas le conocen, él no sabe quiénes son'),

              const SizedBox(height: 16),
              _buildReglaTitulo('🔄 CÓMO SE JUEGA'),
              _buildReglaTexto('1. El presidente elige un canciller'),
              _buildReglaTexto('2. Todos votan (Sí/No) al gobierno'),
              _buildReglaTexto('3. Si se aprueba: el presidente roba 3 cartas, descarta 1, pasa 2 al canciller'),
              _buildReglaTexto('4. El canciller elige 1 carta para promulgarla'),

              const SizedBox(height: 16),
              _buildReglaTitulo('⚡ PODERES FASCISTAS'),
              _buildReglaTexto('1ª: Inspeccionar - Ver partido de un jugador'),
              _buildReglaTexto('2ª: Investigar - Un jugador no puede ser canciller'),
              _buildReglaTexto('3ª: Elección especial - Elegir próximo presidente'),
              _buildReglaTexto('4ª/5ª: Ejecutar - Matar a un jugador (si es Hitler, ganan liberales)'),

              const SizedBox(height: 16),
              _buildReglaTitulo('⚠️ IMPORTANTE'),
              _buildReglaTexto('• 3 elecciones fallidas = se promulga la carta superior'),
              _buildReglaTexto('• Veto disponible con 5+ políticas (descartar si ambas son fascistas)'),
              _buildReglaTexto('• Los fascistas pueden mentir, los liberales buscan coherencia'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ENTENDIDO',
              style: TextStyle(color: _oroPrincipal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReglaTitulo(String texto) {
    return Text(
      texto,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: _oroBrillante,
      ),
    );
  }

  Widget _buildReglaTexto(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 13, color: Colors.white70),
      ),
    );
  }

  Map<String, String> _repartirRoles(int numJugadores) {
    Map<int, List<int>> tablaRoles = {
      5: [3, 1, 1],
      6: [4, 1, 1],
      7: [4, 2, 1],
      8: [5, 2, 1],
      9: [5, 3, 1],
      10: [6, 3, 1],
      11: [7, 3, 1],
      12: [8, 3, 1],
      13: [8, 4, 1],
      14: [9, 4, 1],
    };

    List<int>? config = tablaRoles[numJugadores];
    if (config == null) return {};

    int liberales = config[0];
    int fascistas = config[1];
    int hitler = config[2];

    List<String> roles = [];
    for (int i = 0; i < liberales; i++) roles.add('liberal');
    for (int i = 0; i < fascistas; i++) roles.add('fascista');
    for (int i = 0; i < hitler; i++) roles.add('hitler');

    roles.shuffle();

    Map<String, String> asignacion = {};
    for (int i = 0; i < numJugadores; i++) {
      asignacion['jugador${i + 1}'] = roles[i];
    }

    return asignacion;
  }

  List<String> _crearMazo() {
    List<String> mazo = [];
    for (int i = 0; i < 11; i++) mazo.add('fascista');
    for (int i = 0; i < 6; i++) mazo.add('liberal');
    mazo.shuffle();
    return mazo;
  }

  List<String> _listaJugadoresVivos(int total) {
    List<String> vivos = [];
    for (int i = 0; i < total; i++) {
      vivos.add('jugador${i + 1}');
    }
    return vivos;
  }

  Future<void> _cambiarEstadoListo(String miId, bool nuevoEstado) async {
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.codigoSala)
        .update({
      'jugadores.$miId.estaListo': nuevoEstado,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text(
          'SALA: ${widget.codigoSala}',
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
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: _oroBrillante),
            onPressed: () => _mostrarReglas(context),
            tooltip: 'Ver reglas',
          ),
        ],
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.codigoSala)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Sala no encontrada'));
          }

          var datos = snapshot.data!.data() as Map<String, dynamic>;

          var jugadores = datos['jugadores'] as Map<String, dynamic>;
          int maxJugadores = datos['maxJugadores'] ?? 10;

          String miId = '';
          bool miEstadoListo = false;
          jugadores.forEach((key, value) {
            if (value['nombre'] == widget.nombreJugador) {
              miId = key;
              miEstadoListo = value['estaListo'] ?? false;
            }
          });

          if (datos['estado'] == 'jugando') {
            // Obtener mi rol antes de navegar
            String miRol = datos['roles'][miId] ?? 'desconocido';

            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => PantallaRevelacion(
                    rol: miRol,
                    codigoSala: widget.codigoSala,
                    nombreJugador: widget.nombreJugador,
                  ),
                ),
              );
            });
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    '¡Revelando tu rol...',
                    style: TextStyle(color: _oroBrillante),
                  ),
                ],
              ),
            );
          }

          if (miId.isNotEmpty) {
            _iniciarMonitoreo(miId);
          }

          bool esAnfitrion = datos['jugadores']['jugador1']['nombre'] == widget.nombreJugador;
          bool puedeEmpezar = jugadores.length >= 5;

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
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Código de sala con estilo dorado
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_oroPrincipal, _oroBrillante, _oroOscuro],
                          stops: const [0.0, 0.5, 1.0],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: _oroPrincipal.withOpacity(0.5),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.meeting_room, color: Colors.black87),
                          const SizedBox(width: 10),
                          Text(
                            'CÓDIGO: ${widget.codigoSala}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Contador de jugadores con estilo
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _oroPrincipal, width: 1),
                      ),
                      child: Text(
                        '${jugadores.length}/$maxJugadores jugadores',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _oroBrillante,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Lista de jugadores
                    const Text(
                      'JUGADORES',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _oroPrincipal.withOpacity(0.3)),
                      ),
                      height: 300,
                      child: ListView.builder(
                        itemCount: jugadores.length,
                        itemBuilder: (context, index) {
                          String key = 'jugador${index + 1}';
                          var jugador = jugadores[key];
                          bool soyYo = jugador['nombre'] == widget.nombreJugador;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: soyYo
                                    ? [_rojoOscuro, const Color(0xFF4A0000)]
                                    : [Colors.grey.shade800, Colors.grey.shade900],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: soyYo ? _oroBrillante : _oroPrincipal.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _oroPrincipal,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.black),
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
                                jugador['esAnfitrion']
                                    ? 'Anfitrión'
                                    : (jugador['estaListo'] == true ? 'Listo' : 'No listo'),
                                style: TextStyle(
                                  color: jugador['esAnfitrion']
                                      ? _oroBrillante
                                      : Colors.white70,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: jugador['conectado'] == true
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  if (jugador['estaListo'] == true)
                                    Icon(Icons.check_circle, color: _oroBrillante),
                                  if (soyYo)
                                    Icon(Icons.person, color: _oroBrillante),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Botones de estado
                    if (miId.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _oroPrincipal.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            if (!miEstadoListo)
                              _buildGoldenButton(
                                onPressed: () => _cambiarEstadoListo(miId, true),
                                icon: Icons.check,
                                label: 'ESTOY LISTO',
                                color: Colors.green,
                              )
                            else
                              _buildGoldenButton(
                                onPressed: () => _cambiarEstadoListo(miId, false),
                                icon: Icons.cancel,
                                label: 'CANCELAR LISTO',
                                color: Colors.orange,
                              ),

                            const SizedBox(height: 15),

                            Text(
                              miEstadoListo
                                  ? '✅ Estás listo. Esperando a otros jugadores...'
                                  : '👆 Pulsa "LISTO" cuando estés preparado',
                              style: TextStyle(
                                color: miEstadoListo ? Colors.green : Colors.grey,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 30),

                    // Botón para empezar (solo anfitrión)
                    if (esAnfitrion)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _oroPrincipal.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            _buildGoldenButton(
                              onPressed: puedeEmpezar
                                  ? () async {
                                bool? confirmar = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: const Color(0xFF2A2A2A),
                                    title: Text(
                                      '¿Empezar partida?',
                                      style: TextStyle(color: _oroBrillante),
                                    ),
                                    content: Text(
                                      '${jugadores.length} jugadores. ¿Asignar roles?',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text(
                                          'Cancelar',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _oroPrincipal,
                                        ),
                                        child: const Text(
                                          '¡Empezar!',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                // Cuando el anfitrión confirma empezar
                                if (confirmar == true) {
                                  // Repartir roles
                                  Map<String, String> roles = _repartirRoles(jugadores.length);

                                  // Crear mapa de roles
                                  Map<String, dynamic> rolesMap = {};
                                  roles.forEach((jugadorId, rol) {
                                    rolesMap[jugadorId] = rol;
                                  });

                                  // NUEVO: Elegir presidente inicial aleatorio
                                  List<String> jugadoresIds = jugadores.keys.toList();
                                  jugadoresIds.shuffle(); // Barajar para orden aleatorio
                                  String presidenteInicial = jugadoresIds.first;

                                  // Encontrar el índice del presidente inicial en la lista de vivos
                                  List<String> jugadoresVivos = _listaJugadoresVivos(jugadores.length);
                                  int turnoInicial = jugadoresVivos.indexOf(presidenteInicial);

                                  // Crear estado inicial del juego
                                  Map<String, dynamic> gameState = {
                                    'turno': turnoInicial, // <-- Índice aleatorio
                                    'presidenteId': presidenteInicial, // <-- Presidente aleatorio
                                    'cancillerId': null,
                                    'eleccionesFallidas': 0,
                                    'politicasLiberales': 0,
                                    'politicasFascistas': 0,
                                    'mazo': _crearMazo(),
                                    'jugadoresVivos': jugadoresVivos,
                                    'ultimoGobierno': [],
                                    'vetoHabilitado': false,
                                    'fase': 'eleccion',
                                    'historialVotaciones': {},
                                    'descartes': [], // Asegúrate de tener esto si ya lo implementaste
                                  };

                                  await FirebaseFirestore.instance
                                      .collection('rooms')
                                      .doc(widget.codigoSala)
                                      .update({
                                    'estado': 'jugando',
                                    'roles': rolesMap,
                                    'gameState': gameState,
                                  });
                                }
                              }
                                  : null,
                              icon: Icons.play_arrow,
                              label: 'EMPEZAR PARTIDA',
                              color: puedeEmpezar ? Colors.purple : Colors.grey,
                              enabled: puedeEmpezar,
                            ),

                            const SizedBox(height: 10),

                            Text(
                              'Mínimo 5 jugadores para empezar',
                              style: TextStyle(
                                color: puedeEmpezar ? Colors.green : Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoldenButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool enabled = true,
  }) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: enabled
            ? LinearGradient(
          colors: [_oroPrincipal, _oroBrillante, _oroOscuro],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        color: enabled ? null : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
        boxShadow: enabled
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
            Icon(icon, color: enabled ? Colors.black : Colors.white54),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: enabled ? Colors.black : Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}