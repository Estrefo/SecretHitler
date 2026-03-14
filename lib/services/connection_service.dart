import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  final Map<String, StreamSubscription<DocumentSnapshot>> _subscriptions = {};
  final Map<String, Timer> _timers = {}; // Para controlar frecuencia de actualizaciones

  void startMonitoring(String roomCode, String playerId, BuildContext context) {
    stopMonitoring(roomCode);

    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomCode);

    // No actualizar timestamp en cada snapshot, usar un timer separado
    _timers[roomCode] = Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        await roomRef.update({
          'jugadores.$playerId.ultimaConexion': FieldValue.serverTimestamp(),
          'jugadores.$playerId.conectado': true,
        });
      } catch (e) {
        print('Error actualizando conexión: $e');
      }
    });

    _subscriptions[roomCode] = roomRef.snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;

      var data = snapshot.data() as Map<String, dynamic>;
      var jugadores = data['jugadores'] as Map<String, dynamic>;

      // Comprobar inactivos SIN actualizar mi propio timestamp
      DateTime ahora = DateTime.now();
      List<String> inactivos = [];

      jugadores.forEach((id, jugador) {
        if (id == playerId) return; // Ignorarme a mí mismo

        var ultimaConexion = (jugador['ultimaConexion'] as Timestamp?)?.toDate();
        var conectado = jugador['conectado'] ?? false;

        if (ultimaConexion != null && conectado) {
          if (ahora.difference(ultimaConexion).inSeconds > 25) { // 25 segundos de tolerancia
            inactivos.add(id);
          }
        }
      });

      // Marcar inactivos como desconectados (solo si es necesario)
      for (String id in inactivos) {
        if (jugadores[id]['conectado'] == true) {
          await roomRef.update({
            'jugadores.$id.conectado': false,
          });

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${jugadores[id]['nombre']} se ha desconectado'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    });
  }

  void stopMonitoring(String roomCode) {
    _subscriptions[roomCode]?.cancel();
    _subscriptions.remove(roomCode);

    _timers[roomCode]?.cancel();
    _timers.remove(roomCode);
  }

  Future<void> markDisconnected(String roomCode, String playerId) async {
    stopMonitoring(roomCode);
    try {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomCode)
          .update({
        'jugadores.$playerId.conectado': false,
      });
    } catch (e) {
      print('Error marcando desconexión: $e');
    }
  }

  void dispose() {
    _subscriptions.forEach((key, sub) => sub.cancel());
    _subscriptions.clear();
    _timers.forEach((key, timer) => timer.cancel());
    _timers.clear();
  }
}