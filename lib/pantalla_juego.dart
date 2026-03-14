import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pantalla_fin.dart';

class PantallaJuego extends StatefulWidget {
  final String codigoSala;
  final String nombreJugador;

  const PantallaJuego({
    super.key,
    required this.codigoSala,
    required this.nombreJugador,
  });

  @override
  State<PantallaJuego> createState() => _PantallaJuegoState();
}

class _PantallaJuegoState extends State<PantallaJuego> {
  // Colores temáticos
  final Color _rojoOscuro = const Color(0xFF8B0000);
  final Color _azulOscuro = const Color(0xFF0A2F6B);
  final Color _oroPrincipal = const Color(0xFFBF9530);
  final Color _oroBrillante = const Color(0xFFFCF6BA);
  final Color _oroOscuro = const Color(0xFFAA771C);

  // Rutas de imágenes de cartas
  final String _cartaLiberal = 'assets/carta_liberal.png';
  final String _cartaFascista = 'assets/carta_fascista.png';

  // Función para obtener el poder fascista según número de jugadores
  String _obtenerPoderFascista(int numJugadores, int politicasFascistas) {
    if (politicasFascistas == 1) return "🔍 Inspeccionar";
    if (politicasFascistas == 2) return "🕵️ Investigar";

    if (numJugadores <= 6) {
      if (politicasFascistas == 3) return "💀 Ejecutar";
      if (politicasFascistas == 4) return "💀 Ejecutar"; // Segunda ejecución (o lo que corresponda)
      if (politicasFascistas == 5) return ""; // No hay poder en 5ª para 5-6 jugadores
      // La victoria se maneja aparte con nuevasFascistas >= 6
    } else if (numJugadores <= 8) {
      if (politicasFascistas == 3) return "👑 Elección especial";
      if (politicasFascistas == 4) return "💀 Ejecutar";
      if (politicasFascistas >= 5) return "🏆 VICTORIA FASCISTA";
    } else {
      if (politicasFascistas == 3) return "👑 Elección especial";
      if (politicasFascistas == 4) return "💀 Ejecutar";
      if (politicasFascistas == 5) return "💀 Ejecutar";
      if (politicasFascistas >= 6) return "🏆 VICTORIA FASCISTA";
    }
    return "";
  }

  List<Widget> _getInformacionAdicional(String miRol, Map jugadores, Map roles, String miId) {
    List<Widget> widgets = [];

    if (miRol == 'fascista') {
      List<String> otrosFascistas = [];
      String hitlerNombre = '';

      roles.forEach((id, rol) {
        if (id != miId) {
          if (rol == 'fascista') {
            otrosFascistas.add(jugadores[id]['nombre']);
          } else if (rol == 'hitler') {
            hitlerNombre = jugadores[id]['nombre'];
          }
        }
      });

      widgets.add(
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.withOpacity(0.3), Colors.red.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _oroPrincipal, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🤝 TUS CAMARADAS FASCISTAS:',
                style: TextStyle(fontWeight: FontWeight.bold, color: _oroBrillante),
              ),
              const SizedBox(height: 5),
              ...otrosFascistas.map((nombre) => Text('• $nombre', style: const TextStyle(color: Colors.white))),
              const SizedBox(height: 8),
              Text(
                '👑 HITLER ES:',
                style: TextStyle(fontWeight: FontWeight.bold, color: _oroBrillante),
              ),
              Text('• $hitlerNombre', style: const TextStyle(color: Colors.white)),
              Text(
                '(Pero Hitler no lo sabe)',
                style: TextStyle(fontSize: 12, color: _oroPrincipal),
              ),
            ],
          ),
        ),
      );
    }

    if (miRol == 'hitler') {
      widgets.add(
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.5), Colors.black.withOpacity(0.2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _oroPrincipal, width: 1),
          ),
          child: const Text(
            '❓ No sabes quiénes son los fascistas. Confía en tu intuición...',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white70),
          ),
        ),
      );
    }

    return widgets;
  }

  void _mostrarSelectorCanciller(BuildContext context, Map jugadores, Map gameState, String miId) {
    List<String> vivos = List.from(gameState['jugadoresVivos']);
    String? investigado = gameState['investigado'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text('Elige Canciller', style: TextStyle(color: _oroBrillante)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: vivos.length,
            itemBuilder: (context, index) {
              String jugadorId = vivos[index];
              if (jugadorId == gameState['presidenteId']) return const SizedBox();

              if (jugadorId == investigado) {
                return ListTile(
                  title: Text(jugadores[jugadorId]?['nombre'] ?? '???', style: const TextStyle(color: Colors.white70)),
                  subtitle: Text('🚫 INVESTIGADO - No puede ser canciller', style: TextStyle(color: _oroPrincipal)),
                  enabled: false,
                );
              }

              return ListTile(
                title: Text(jugadores[jugadorId]?['nombre'] ?? '???', style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _proponerCanciller(jugadorId);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _proponerCanciller(String cancillerId) async {
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.codigoSala)
        .update({
      'gameState.cancillerId': cancillerId,
      'gameState.fase': 'votacion',
      'gameState.votantes': {},
    });
  }

  Future<void> _votar(String miId, bool voto) async {
    final roomRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.codigoSala);

    await roomRef.update({
      'gameState.votantes.$miId': voto,
    });

    final doc = await roomRef.get();
    var data = doc.data() as Map<String, dynamic>;
    var gameState = data['gameState'];
    var jugadoresVivos = (gameState['jugadoresVivos'] as List).length;
    var votosEmitidos = (gameState['votantes'] as Map).length;

    if (votosEmitidos == jugadoresVivos) {
      _contarVotos();
    }
  }

  Future<void> _contarVotos() async {
    final roomRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.codigoSala);

    final doc = await roomRef.get();
    var data = doc.data() as Map<String, dynamic>;
    var gameState = data['gameState'];
    var votantes = gameState['votantes'] as Map;

    int votosSi = 0;
    int votosNo = 0;
    votantes.forEach((key, value) {
      if (value == true) votosSi++; else votosNo++;
    });

    bool gobiernoAprobado = votosSi > votosNo;

    List<String> nuevoHistorial = List.from(gameState['historial'] ?? []);
    nuevoHistorial.insert(0, '${DateTime.now().hour}:${DateTime.now().minute} - Votación: $votosSi sí, $votosNo no → ${gobiernoAprobado ? "APROBADO" : "RECHAZADO"}');
    if (nuevoHistorial.length > 10) nuevoHistorial.removeLast();

    if (gobiernoAprobado) {
      await roomRef.update({
        'gameState.fase': 'legislativa',
        'gameState.eleccionesFallidas': 0,
        'gameState.historial': nuevoHistorial,
      });
    } else {
      int nuevasFallidas = (gameState['eleccionesFallidas'] ?? 0) + 1;

      if (nuevasFallidas >= 3) {
        await _promulgarCartaSuperior();
      } else {
        await _siguienteTurno();
      }
    }
  }

  // Función para promulgar carta superior (con mecánica correcta)
  Future<void> _promulgarCartaSuperior() async {
    final roomRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.codigoSala);

    final doc = await roomRef.get();
    var data = doc.data() as Map<String, dynamic>;
    var gameState = data['gameState'];

    // Obtener mazo actual y descartes
    List<String> mazo = List.from(gameState['mazo'] ?? []);
    List<String> descartes = List.from(gameState['descartes'] ?? []);

    // Si no hay cartas en el mazo, rebarajar descartes
    if (mazo.isEmpty) {
      if (descartes.isEmpty) {
        // Esto no debería pasar, pero por si acaso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No hay cartas')),
        );
        return;
      }

      mazo = List.from(descartes);
      mazo.shuffle();
      descartes = [];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🔄 Rebarajando descartes...'),
          backgroundColor: _oroPrincipal,
        ),
      );
    }

    // Robar la carta superior
    String carta = mazo.removeAt(0);

    // Mostrar notificación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ Carta superior: $carta'),
        backgroundColor: _rojoOscuro,
        duration: const Duration(seconds: 2),
      ),
    );

    // Aplicar la carta
    await _aplicarCarta(carta, mazo: mazo, descartes: descartes, esPorFallidas: true);
  }

// Función auxiliar para aplicar carta (para no duplicar código)
  Future<void> _aplicarCarta(
      String carta, {
        required List<String> mazo,
        required List<String> descartes,
        bool esPorFallidas = false,
      }) async {
    final roomRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.codigoSala);

    final doc = await roomRef.get();
    var data = doc.data() as Map<String, dynamic>;
    var gameState = data['gameState'];

    List<String> nuevoHistorial = List.from(gameState['historial'] ?? []);
    nuevoHistorial.insert(0, '${DateTime.now().hour}:${DateTime.now().minute} - Se promulgó $carta');
    if (nuevoHistorial.length > 10) nuevoHistorial.removeLast();

    if (carta == 'liberal') {
      int nuevasLiberales = (gameState['politicasLiberales'] ?? 0) + 1;

      if (nuevasLiberales >= 5) {
        await roomRef.update({
          'estado': 'terminada',
          'ganador': 'liberales',
          'motivo': '5 políticas liberales',
          'gameState.historial': nuevoHistorial,
        });
        _mostrarVictoria('LIBERALES', motivo: '5 políticas liberales');
        return;
      }

      await roomRef.update({
        'gameState.politicasLiberales': nuevasLiberales,
        'gameState.mazo': mazo,
        'gameState.descartes': descartes,
        'gameState.eleccionesFallidas': 0,
        'gameState.historial': nuevoHistorial,
      });
    } else {
      int nuevasFascistas = (gameState['politicasFascistas'] ?? 0) + 1;
      int numJugadores = (data['jugadores'] as Map).length;

      if (nuevasFascistas >= 6) {
        await roomRef.update({
          'estado': 'terminada',
          'ganador': 'fascistas',
          'motivo': '${nuevasFascistas} políticas fascistas',
          'gameState.historial': nuevoHistorial,
        });
        _mostrarVictoria('FASCISTAS', motivo: 'Se han elegido $nuevasFascistas políticas fascistas');
        return;
      }

      // Comprobar victoria por Hitler canciller (si hay 3+ fascistas)
      if (nuevasFascistas >= 3 && !esPorFallidas) { // No aplica si es por fallidas
        String cancillerId = gameState['cancillerId'];
        String rolCanciller = data['roles'][cancillerId];

        if (rolCanciller == 'hitler') {
          await roomRef.update({
            'estado': 'terminada',
            'ganador': 'fascistas',
            'motivo': 'Hitler elegido canciller',
            'gameState.historial': nuevoHistorial,
          });
          _mostrarVictoria('FASCISTAS', motivo: 'Hitler elegido canciller');
          return;
        }
      }

      String poder = _obtenerPoderFascista(numJugadores, nuevasFascistas);

      await roomRef.update({
        'gameState.politicasFascistas': nuevasFascistas,
        'gameState.ultimoPoder': poder,
        'gameState.mazo': mazo,
        'gameState.descartes': descartes,
        'gameState.eleccionesFallidas': 0,
        'gameState.historial': nuevoHistorial,
      });

      if (!esPorFallidas && (poder.contains('Inspeccionar') || poder.contains('Investigar') ||
          poder.contains('Ejecutar') || poder.contains('Elección'))) {
        await roomRef.update({
          'gameState.fase': 'poder_${nuevasFascistas}',
          'gameState.poderPendiente': poder,
        });
        _ejecutarPoder(poder);
        return;
      }
    }

    if (!esPorFallidas) {
      await _siguienteTurno();
    }
  }

  Future<void> _siguienteTurno() async {
    final roomRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.codigoSala);

    final doc = await roomRef.get();
    var data = doc.data() as Map<String, dynamic>;
    var gameState = data['gameState'];
    var jugadoresVivos = List<String>.from(gameState['jugadoresVivos']);

    int turnoActual = gameState['turno'] ?? 0;
    int siguienteTurno = (turnoActual + 1) % jugadoresVivos.length;

    await roomRef.update({
      'gameState.turno': siguienteTurno,
      'gameState.presidenteId': jugadoresVivos[siguienteTurno],
      'gameState.cancillerId': null,
      'gameState.fase': 'eleccion',
      'gameState.votantes': {},
      'gameState.cartasPresidente': null,
      'gameState.cartasCanciller': null,
      'gameState.eleccionesFallidas': gameState['eleccionesFallidas'] ?? 0,
    });
  }

  // Función para robar cartas (con la mecánica correcta)
  Future<void> _robarCartas() async {
    final roomRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.codigoSala);

    final doc = await roomRef.get();
    var data = doc.data() as Map<String, dynamic>;
    var gameState = data['gameState'];

    // Obtener mazo actual y descartes
    List<String> mazo = List.from(gameState['mazo'] ?? []);
    List<String> descartes = List.from(gameState['descartes'] ?? []);

    List<String> cartasRobadas = [];

    // Robar 3 cartas, rebarajando si es necesario
    for (int i = 0; i < 3; i++) {
      if (mazo.isEmpty) {
        // Si no quedan cartas en el mazo, rebarajar descartes
        if (descartes.isEmpty) {
          // Esto no debería pasar, pero por si acaso
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: No hay cartas')),
          );
          return;
        }

        // Rebarajar descartes para formar nuevo mazo
        mazo = List.from(descartes);
        mazo.shuffle();
        descartes = [];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🔄 Rebarajando descartes...'),
            backgroundColor: _oroPrincipal,
          ),
        );
      }

      // Robar una carta
      cartasRobadas.add(mazo.removeAt(0));
    }

    // Guardar estado actualizado
    await roomRef.update({
      'gameState.mazo': mazo,
      'gameState.descartes': descartes,
      'gameState.cartasPresidente': cartasRobadas,
      'gameState.fase': 'presidente_descarta',
    });

    _mostrarSeleccionPresidente(cartasRobadas);
  }

  void _mostrarSeleccionPresidente(List<String> cartas) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        contentPadding: const EdgeInsets.all(20),
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(
          'ELIGE UNA CARTA PARA DESCARTAR',
          style: TextStyle(color: _oroBrillante, fontSize: 18),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pasarás las otras 2 al canciller',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Cartas en horizontal
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: cartas.asMap().entries.map((entry) {
                  int index = entry.key;
                  String carta = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildCartaBoton(
                      onPressed: () => _descartarCarta(index, cartas),
                      carta: carta,
                      texto: carta.toUpperCase(),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _descartarCarta(int indice, List<String> cartas) async {
    Navigator.pop(context);

    List<String> cartasRestantes = [];
    for (int i = 0; i < cartas.length; i++) {
      if (i != indice) cartasRestantes.add(cartas[i]);
    }

    final roomRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.codigoSala);

    await roomRef.update({
      'gameState.cartasCanciller': cartasRestantes,
      'gameState.fase': 'canciller_elige',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cartas enviadas al canciller'),
        backgroundColor: _oroPrincipal,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _elegirPolitica() async {
    final roomRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.codigoSala);

    final doc = await roomRef.get();
    var data = doc.data() as Map<String, dynamic>;
    var gameState = data['gameState'];
    var cartas = List<String>.from(gameState['cartasCanciller'] ?? []);

    if (cartas.isEmpty) return;

    _mostrarSeleccionCanciller(cartas);
  }

  void _mostrarSeleccionCanciller(List<String> cartas) async {
    final roomRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.codigoSala);

    final doc = await roomRef.get();
    var data = doc.data() as Map<String, dynamic>;
    var gameState = data['gameState'];

    int totalPoliticas = (gameState['politicasLiberales'] ?? 0) +
        (gameState['politicasFascistas'] ?? 0);
    bool vetoDisponible = totalPoliticas >= 5 &&
        cartas.every((c) => c == 'fascista');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        contentPadding: const EdgeInsets.all(20),
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(
          'ELIGE UNA POLÍTICA PARA PROMULGAR',
          style: TextStyle(color: _oroBrillante, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (vetoDisponible) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: _oroPrincipal),
                ),
                child: Text(
                  '⚠️ VETO DISPONIBLE',
                  style: TextStyle(color: _oroBrillante, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Ambas cartas son fascistas. Puedes vetar.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
            ],

            // Cartas en horizontal
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: cartas.asMap().entries.map((entry) {
                  int index = entry.key;
                  String carta = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildCartaBoton(
                      onPressed: () => _promulgarCarta(carta, cartas, index),
                      carta: carta,
                      texto: carta.toUpperCase(),
                    ),
                  );
                }).toList(),
              ),
            ),

            if (vetoDisponible) ...[
              const SizedBox(height: 20),
              _buildGoldenButton(
                onPressed: _vetar,
                icon: Icons.block,
                label: '🚫 VETAR',
                color: Colors.orange,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCartaBoton({
    required VoidCallback onPressed,
    required String carta,
    required String texto,
  }) {
    // Determinar qué imagen usar
    String imagenPath = carta == 'liberal' ? 'assets/carta_liberal.png' : 'assets/carta_fascista.png';
    Color colorBorde = carta == 'liberal' ? _azulOscuro : _rojoOscuro;

    return Container(
      width: 100,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white, // <-- FONDO BLANCO
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _oroPrincipal, width: 2),
        boxShadow: [
          BoxShadow(
            color: _oroPrincipal.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Imagen de la carta (ahora con fondo blanco)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              color: Colors.white, // <-- Fondo blanco también aquí por si acaso
              child: Image.asset(
                imagenPath,
                fit: BoxFit.contain, // <-- Cambiado a contain para que no se estire
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback si no hay imagen
                  return Container(
                    color: Colors.white, // <-- Fondo blanco en fallback
                    child: Center(
                      child: Text(
                        texto,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: carta == 'liberal' ? _azulOscuro : _rojoOscuro,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Overlay táctil (mantiene el efecto al pulsar)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(10),
                splashColor: _oroPrincipal.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _vetar() async {
    Navigator.pop(context);

    final roomRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.codigoSala);

    final doc = await roomRef.get();
    var data = doc.data() as Map<String, dynamic>;
    var gameState = data['gameState'];

    int nuevasFallidas = (gameState['eleccionesFallidas'] ?? 0) + 1;

    List<String> nuevoHistorial = List.from(gameState['historial'] ?? []);
    nuevoHistorial.insert(0, '${DateTime.now().hour}:${DateTime.now().minute} - 🚫 VETO');
    if (nuevoHistorial.length > 10) nuevoHistorial.removeLast();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('🚫 VETO: Ambas cartas descartadas'),
        backgroundColor: Colors.orange,
      ),
    );

    await roomRef.update({
      'gameState.cartasPresidente': null,
      'gameState.cartasCanciller': null,
      'gameState.votantes': {},
      'gameState.eleccionesFallidas': nuevasFallidas,
      'gameState.historial': nuevoHistorial,
    });

    if (nuevasFallidas >= 3) {
      await _promulgarCartaSuperior();
    } else {
      await _siguienteTurno();
    }
  }

  Future<void> _promulgarCarta(String cartaElegida, List<String> cartas, int indice) async {
    Navigator.pop(context);

    final roomRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.codigoSala);

    final doc = await roomRef.get();
    var data = doc.data() as Map<String, dynamic>;
    var gameState = data['gameState'];

    // La carta no elegida va a descartes
    String cartaDescartada = cartas[indice == 0 ? 1 : 0];
    List<String> descartes = List.from(gameState['descartes'] ?? []);
    descartes.add(cartaDescartada);

    // Obtener mazo actual
    List<String> mazo = List.from(gameState['mazo'] ?? []);

    // Aplicar la carta elegida
    await _aplicarCarta(
      cartaElegida,
      mazo: mazo,
      descartes: descartes,
      esPorFallidas: false,
    );
  }

  void _ejecutarPoder(String poder) {
    if (poder.contains('Inspeccionar')) {
      _poderInspeccionar();
    } else if (poder.contains('Investigar')) {
      _poderInvestigar();
    } else if (poder.contains('Ejecutar')) {
      _poderEjecutar();
    } else if (poder.contains('Elección')) {
      _poderEleccionEspecial();
    }
  }

  Future<void> _poderInspeccionar() async {
    final roomRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.codigoSala);

    final doc = await roomRef.get();
    var data = doc.data() as Map<String, dynamic>;
    var jugadoresVivos = List<String>.from(data['gameState']['jugadoresVivos']);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text('🔍 INSPECCIONAR', style: TextStyle(color: _oroBrillante)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Elige un jugador para ver su afiliación:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            ...jugadoresVivos.map((jugadorId) {
              if (jugadorId == data['gameState']['presidenteId']) return const SizedBox();
              return ListTile(
                title: Text(data['jugadores'][jugadorId]['nombre'], style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  String rol = data['roles'][jugadorId];
                  String afiliacion = (rol == 'liberal') ? 'LIBERAL' : 'FASCISTA';

                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF2A2A2A),
                      title: Text('${data['jugadores'][jugadorId]['nombre']} es...', style: TextStyle(color: _oroBrillante)),
                      content: Text(
                        afiliacion,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: afiliacion == 'LIBERAL' ? Colors.blue : Colors.red,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);

                            List<String> nuevoHistorial = List.from(data['gameState']['historial'] ?? []);
                            nuevoHistorial.insert(0, '${DateTime.now().hour}:${DateTime.now().minute} - 🔍 Inspección realizada');
                            if (nuevoHistorial.length > 10) nuevoHistorial.removeLast();

                            await roomRef.update({
                              'gameState.fase': 'eleccion',
                              'gameState.poderPendiente': null,
                              'gameState.historial': nuevoHistorial,
                            });
                            await _siguienteTurno();
                          },
                          child: Text('CONTINUAR', style: TextStyle(color: _oroPrincipal)),
                        ),
                      ],
                    ),
                  );
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Future<void> _poderInvestigar() async {
    final roomRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.codigoSala);

    final doc = await roomRef.get();
    var data = doc.data() as Map<String, dynamic>;
    var jugadoresVivos = List<String>.from(data['gameState']['jugadoresVivos']);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text('🕵️ INVESTIGAR', style: TextStyle(color: _oroBrillante)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Elige un jugador que NO podrá ser canciller:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            ...jugadoresVivos.map((jugadorId) {
              return ListTile(
                title: Text(data['jugadores'][jugadorId]['nombre'], style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);

                  List<String> nuevoHistorial = List.from(data['gameState']['historial'] ?? []);
                  nuevoHistorial.insert(0, '${DateTime.now().hour}:${DateTime.now().minute} - 🕵️ Investigación: ${data['jugadores'][jugadorId]['nombre']} no será canciller');
                  if (nuevoHistorial.length > 10) nuevoHistorial.removeLast();

                  await roomRef.update({
                    'gameState.investigado': jugadorId,
                    'gameState.fase': 'eleccion',
                    'gameState.poderPendiente': null,
                    'gameState.historial': nuevoHistorial,
                  });
                  await _siguienteTurno();
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Future<void> _poderEjecutar() async {
    final roomRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.codigoSala);

    final doc = await roomRef.get();
    var data = doc.data() as Map<String, dynamic>;
    var jugadoresVivos = List<String>.from(data['gameState']['jugadoresVivos']);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text('💀 EJECUTAR', style: TextStyle(color: _oroBrillante)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Elige un jugador para MATAR:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            ...jugadoresVivos.map((jugadorId) {
              if (jugadorId == data['gameState']['presidenteId']) return const SizedBox();
              return ListTile(
                title: Text(data['jugadores'][jugadorId]['nombre'], style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);

                  List<String> nuevoHistorial = List.from(data['gameState']['historial'] ?? []);

                  if (data['roles'][jugadorId] == 'hitler') {
                    nuevoHistorial.insert(0, '${DateTime.now().hour}:${DateTime.now().minute} - 💀 ¡HITLER EJECUTADO!');
                    await roomRef.update({
                      'estado': 'terminada',
                      'ganador': 'liberales',
                      'motivo': 'Hitler ejecutado',
                      'gameState.historial': nuevoHistorial,
                    });
                    _mostrarVictoria('LIBERALES', motivo: 'Hitler ha muerto');
                    return;
                  }

                  nuevoHistorial.insert(0, '${DateTime.now().hour}:${DateTime.now().minute} - 💀 Ejecutado: ${data['jugadores'][jugadorId]['nombre']}');
                  if (nuevoHistorial.length > 10) nuevoHistorial.removeLast();

                  jugadoresVivos.remove(jugadorId);
                  await roomRef.update({
                    'gameState.jugadoresVivos': jugadoresVivos,
                    'gameState.fase': 'eleccion',
                    'gameState.poderPendiente': null,
                    'gameState.historial': nuevoHistorial,
                  });
                  await _siguienteTurno();
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Future<void> _poderEleccionEspecial() async {
    final roomRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.codigoSala);

    final doc = await roomRef.get();
    var data = doc.data() as Map<String, dynamic>;
    var jugadoresVivos = List<String>.from(data['gameState']['jugadoresVivos']);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text('👑 ELECCIÓN ESPECIAL', style: TextStyle(color: _oroBrillante)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Elige al próximo presidente:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            ...jugadoresVivos.map((jugadorId) {
              return ListTile(
                title: Text(data['jugadores'][jugadorId]['nombre'], style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);

                  List<String> nuevoHistorial = List.from(data['gameState']['historial'] ?? []);
                  nuevoHistorial.insert(0, '${DateTime.now().hour}:${DateTime.now().minute} - 👑 Elección especial: ${data['jugadores'][jugadorId]['nombre']} será presidente');
                  if (nuevoHistorial.length > 10) nuevoHistorial.removeLast();

                  int nuevoIndice = jugadoresVivos.indexOf(jugadorId);

                  await roomRef.update({
                    'gameState.turno': nuevoIndice,
                    'gameState.presidenteId': jugadorId,
                    'gameState.fase': 'eleccion',
                    'gameState.poderPendiente': null,
                    'gameState.historial': nuevoHistorial,
                  });
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _mostrarVictoria(String bando, {String motivo = ''}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaFin(
          codigoSala: widget.codigoSala,
          ganador: bando.toLowerCase(),
          motivo: motivo,
          nombreJugador: widget.nombreJugador,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text(
          'PARTIDA: ${widget.codigoSala}',
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
            .doc(widget.codigoSala)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Sala no encontrada', style: TextStyle(color: _oroBrillante)));
          }

          var datos = snapshot.data!.data() as Map<String, dynamic>;

          var jugadores = datos['jugadores'] as Map<String, dynamic>;
          var roles = datos['roles'] as Map<String, dynamic>;
          var gameState = datos['gameState'] as Map<String, dynamic>;
          var historial = gameState['historial'] ?? [];

          String miId = '';
          String miRol = '';
          jugadores.forEach((key, value) {
            if (value['nombre'] == widget.nombreJugador) {
              miId = key;
              miRol = roles[key] ?? 'desconocido';
            }
          });

          bool estoyVivo = (gameState['jugadoresVivos'] as List).contains(miId);
          String presidenteId = gameState['presidenteId'];
          String? cancillerId = gameState['cancillerId'];

          bool soyPresidente = presidenteId == miId;
          bool soyCanciller = cancillerId == miId;

          Color colorRol = miRol == 'liberal' ? _azulOscuro :
          (miRol == 'fascista' ? _rojoOscuro : Colors.black);

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
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Cabecera con rol (rediseñada)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorRol.withOpacity(0.5), colorRol.withOpacity(0.2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _oroPrincipal, width: 2),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            miRol == 'liberal' ? Icons.thumb_up :
                            miRol == 'fascista' ? Icons.warning :
                            Icons.dangerous,
                            color: _oroBrillante,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ERES: ${miRol.toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _oroBrillante,
                                  ),
                                ),
                                if (miRol == 'hitler')
                                  Text(
                                    'Los fascistas te conocen, tú no los conoces',
                                    style: TextStyle(color: _oroPrincipal, fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    ..._getInformacionAdicional(miRol, jugadores, roles, miId),

                    const SizedBox(height: 20),

                    // Tablero de políticas (responsive y con estilo)
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
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          bool isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

                          if (isPortrait) {
                            return Column(
                              children: [
                                _buildPoliticasColumna('LIBERAL', Colors.blue, 5, gameState['politicasLiberales'] ?? 0),
                                const SizedBox(height: 20),
                                _buildPoliticasColumna('FASCISTA', Colors.red, 6, gameState['politicasFascistas'] ?? 0),
                              ],
                            );
                          } else {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildPoliticasColumna('LIBERAL', Colors.blue, 5, gameState['politicasLiberales'] ?? 0),
                                const SizedBox(width: 30),
                                _buildPoliticasColumna('FASCISTA', Colors.red, 6, gameState['politicasFascistas'] ?? 0),
                              ],
                            );
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Información del turno (rediseñada)
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
                            'TURNO ACTUAL',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _oroBrillante,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildJugadorTile(
                            jugadores[presidenteId]?['nombre'] ?? 'Desconocido',
                            'PRESIDENTE',
                            presidenteId == miId,
                          ),
                          if (cancillerId != null) ...[
                            const SizedBox(height: 5),
                            _buildJugadorTile(
                              jugadores[cancillerId]?['nombre'] ?? 'Desconocido',
                              'CANDIDATO A CANCILLER',
                              cancillerId == miId,
                            ),
                          ],
                          const SizedBox(height: 10),
                          Text(
                            'Fase: ${gameState['fase']}',
                            style: TextStyle(color: _oroPrincipal),
                          ),
                          Text(
                            'Elecciones fallidas: ${gameState['eleccionesFallidas'] ?? 0}/3',
                            style: TextStyle(
                              color: (gameState['eleccionesFallidas'] ?? 0) >= 2 ? Colors.orange : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Lista de jugadores vivos (rediseñada)
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
                            'JUGADORES VIVOS',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _oroBrillante,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...(gameState['jugadoresVivos'] as List).map((jugadorId) {
                            bool soyYo = jugadorId == miId;
                            bool esInvestigado = jugadorId == gameState['investigado'];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 5),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: soyYo ? _rojoOscuro.withOpacity(0.3) : Colors.transparent,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: esInvestigado ? _oroPrincipal : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _oroPrincipal,
                                  child: Text(
                                    jugadorId.replaceAll('jugador', ''),
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                                title: Text(
                                  jugadores[jugadorId]?['nombre'] ?? '???',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: soyYo
                                    ? const Text('Tú', style: TextStyle(color: Colors.white70))
                                    : (esInvestigado ? Text('🚫 Investigado', style: TextStyle(color: _oroPrincipal)) : null),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Historial de acciones (rediseñado)
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📜 HISTORIAL',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _oroBrillante,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (historial.isEmpty)
                            const Text('Sin acciones aún', style: TextStyle(color: Colors.white70))
                          else
                            ...historial.take(5).map((accion) => Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Text(
                                '• $accion',
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                              ),
                            )),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Botones de acción (rediseñados)
                    if (estoyVivo) ...[
                      if (gameState['fase'] == 'eleccion' && soyPresidente)
                        _buildGoldenButton(
                          onPressed: () => _mostrarSelectorCanciller(context, jugadores, gameState, miId),
                          icon: Icons.how_to_vote,
                          label: 'ELEGIR CANCILLER',
                          color: Colors.blue,
                        ),

                      if (gameState['fase'] == 'votacion' && gameState['votantes']?[miId] == null)
                        Row(
                          children: [
                            Expanded(
                              child: _buildGoldenButton(
                                onPressed: () => _votar(miId, false),
                                icon: Icons.close,
                                label: 'NO',
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildGoldenButton(
                                onPressed: () => _votar(miId, true),
                                icon: Icons.check,
                                label: 'SÍ',
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),

                      if (gameState['fase'] == 'legislativa' && soyPresidente)
                        _buildGoldenButton(
                          onPressed: _robarCartas,
                          icon: Icons.style,
                          label: 'ROBAR CARTAS',
                          color: Colors.purple,
                        ),

                      if (gameState['fase'] == 'presidente_descarta' && soyPresidente)
                        _buildGoldenButton(
                          onPressed: () {},
                          icon: Icons.hourglass_empty,
                          label: 'SELECCIONANDO CARTA...',
                          color: Colors.grey,
                        ),

                      if (gameState['fase'] == 'canciller_elige' && soyCanciller)
                        _buildGoldenButton(
                          onPressed: _elegirPolitica,
                          icon: Icons.card_giftcard,
                          label: 'ELEGIR POLÍTICA',
                          color: Colors.orange,
                        ),
                    ],

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

  Widget _buildPoliticasColumna(String titulo, Color color, int total, int activas) {
    return Column(
      children: [
        Text(titulo, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Wrap(
          alignment: WrapAlignment.center,
          children: List.generate(total, (index) {
            bool activa = index < activas;
            return Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: activa
                    ? LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                color: activa ? null : color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: _oroPrincipal, width: 1),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildJugadorTile(String nombre, String rol, bool soyYo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: soyYo ? _rojoOscuro.withOpacity(0.3) : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _oroPrincipal.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: soyYo ? _rojoOscuro : _oroPrincipal.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              rol,
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldenButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      height: 50,
      margin: const EdgeInsets.only(bottom: 10),
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