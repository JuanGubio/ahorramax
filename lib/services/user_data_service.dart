import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserDataService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  /// Crear el perfil del usuario automaticamente
  Future<void> crearPerfilAutomatico() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection('usuarios').doc(user.uid);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      await docRef.set({
        "nombre": user.displayName ?? "Nuevo Usuario",
        "email": user.email,
        "idioma": "es",
        "temaColor": "verde",
        "notificacionesActivas": true,
        "balanceActual": 0,
        "metaPrincipal": 0,
        "fechaRegistro": DateTime.now(),
      });

      // Crear ingreso inicial
      await docRef.collection('ingresos').add({
        "descripcion": "Saldo inicial",
        "monto": 0,
        "fecha": DateTime.now(),
      });

      // Crear notificación de bienvenida
      await docRef.collection('notificaciones').add({
        "titulo": "Bienvenido a AhorraMax",
        "mensaje": "Empieza a registrar tus gastos e ingresos desde hoy.",
        "fecha": DateTime.now(),
        "leido": false,
      });

      print("Perfil completo creado automáticamente");
    } else {
      print("⚡ El usuario ya tiene datos guardados");
    }
  }

  /// 🔹 Agregar gasto con imagen
  Future<void> agregarGasto({
    required String descripcion,
    required double monto,
    File? imagen,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    String? imageUrl;

    if (imagen != null) {
      final ref = _storage.ref().child('usuarios/${user.uid}/gastos/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(imagen);
      imageUrl = await ref.getDownloadURL();
    }

    await _firestore.collection('usuarios').doc(user.uid).collection('gastos').add({
      "descripcion": descripcion,
      "monto": monto,
      "fecha": DateTime.now(),
      "imagenUrl": imageUrl ?? "",
    });

    print("Gasto agregado automáticamente con imagen");
  }
}