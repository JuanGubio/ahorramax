import 'package:flutter/material.dart';

class WalletScreen extends StatelessWidget {
  final double balance;
  final double monthlyExpenses;
  final double savings;
  final List incomes;
  final List expenses;

  const WalletScreen({
    super.key,
    required this.balance,
    required this.monthlyExpenses,
    required this.savings,
    required this.incomes,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Mi Cartera",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: WalletDashboard(
        balance: balance,
        monthlyExpenses: monthlyExpenses,
        savings: savings,
        incomes: incomes,
        expenses: expenses,
      ),
    );
  }
}

class WalletDashboard extends StatelessWidget {
  final double balance;
  final double monthlyExpenses;
  final double savings;
  final List incomes;
  final List expenses;

  const WalletDashboard({
    super.key,
    required this.balance,
    required this.monthlyExpenses,
    required this.savings,
    required this.incomes,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tarjeta Principal con Degradado
          _buildMainBalanceCard(),

          const SizedBox(height: 20),

          // 2. Fila de Ingresos y Gastos
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildStatCard(
                    "Ingresos Totales",
                    "\$${incomes.fold<double>(0, (sum, income) => sum + income.amount).toStringAsFixed(2)}",
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildStatCard(
                    "Gastos Totales",
                    "\$${monthlyExpenses.toStringAsFixed(2)}",
                    Icons.flash_on,
                    Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          // 3. Título de sección inferior
          const Text(
            "Gastos Recientes",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 10),

          // Placeholder para la lista de gastos
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            alignment: Alignment.center,
            child: Text("0 gastos", style: TextStyle(color: Colors.grey[400])),
          ),
        ],
      ),
    );
  }

  Widget _buildMainBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4ADE80), // Verde claro (izquierda)
            Color(0xFF3B82F6), // Azul (derecha)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Dinero Actual",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "\$${balance.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 25),

          // Fila interna de Ahorros y Gastos del Mes
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSubStat("Ahorros Totales", "\$${savings.toStringAsFixed(2)}"),
                const VerticalDivider(color: Colors.white30, thickness: 1),
                _buildSubStat("Gastos del Mes", "\$${monthlyExpenses.toStringAsFixed(2)}"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubStat(String label, String amount) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String amount, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 5),
          Text(
            amount,
            style: TextStyle(
              color: iconColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}