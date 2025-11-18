import 'package:flutter/material.dart';

class CustomNavBar extends StatelessWidget {
  final VoidCallback? onHomeTap;
  final VoidCallback? onAddTap;
  final VoidCallback? onWalletTap;

  const CustomNavBar({
    super.key,
    this.onHomeTap,
    this.onAddTap,
    this.onWalletTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Contenedor principal de la barra
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Botón 1: Inicio (Activo)
          _buildActiveItem(Icons.home_filled, "Inicio"),

          // Botón 2: Agregar (Inactivo)
          _buildInactiveItem(Icons.add, "Agregar", isCircle: true, onTap: onAddTap),

          // Botón 3: Cartera (Inactivo)
          _buildInactiveItem(Icons.wallet, "Cartera", isCircle: false, onTap: onWalletTap),
        ],
      ),
    );
  }

  // Widget para el ítem activo (Verde)
  Widget _buildActiveItem(IconData icon, String label) {
    return GestureDetector(
      onTap: onHomeTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF4CD97B), // Color verde similar a la imagen
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para los ítems inactivos
  Widget _buildInactiveItem(IconData icon, String label, {required bool isCircle, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6), // Gris muy claro
              shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isCircle ? null : BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF6B7280), size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280), // Texto gris
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}