import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';

class IncomeList extends StatelessWidget {
  final List<Income> incomes;
  final Function(int) onDeleteIncome;

  const IncomeList({
    super.key,
    required this.incomes,
    required this.onDeleteIncome,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    if (incomes.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: Center(
            child: Text(
              'No hay ingresos registrados',
              style: TextStyle(color: Colors.grey, fontSize: isSmallScreen ? 14 : 16),
            ),
          ),
        ),
      );
    }

    // Ordenar ingresos por fecha (más recientes primero)
    final sortedIncomes = List<Income>.from(incomes)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green.shade600, size: isSmallScreen ? 20 : 24),
                const SizedBox(width: 8),
                Text(
                  'Lista de Ingresos',
                  style: TextStyle(fontSize: isSmallScreen ? 16 : 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedIncomes.length,
              itemBuilder: (context, index) {
                final income = sortedIncomes[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: Column(
                      children: [
                        // Header row with icon, description, and amount
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: isSmallScreen ? 32 : 40,
                              height: isSmallScreen ? 32 : 40,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: _getSourceColor(income.source).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getSourceIcon(income.source),
                                color: _getSourceColor(income.source),
                                size: isSmallScreen ? 16 : 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    income.description,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmallScreen ? 13 : 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    income.source,
                                    style: TextStyle(
                                      color: Colors.green.shade600,
                                      fontWeight: FontWeight.w500,
                                      fontSize: isSmallScreen ? 11 : 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '+\$${income.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                IconButton(
                                  onPressed: () => _showDeleteDialog(context, index),
                                  icon: Icon(Icons.delete, color: Colors.red, size: isSmallScreen ? 16 : 18),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(2),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.red.shade50,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Additional details - more compact
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 10, color: Colors.grey),
                            const SizedBox(width: 2),
                            Text(
                              DateFormat('dd/MM HH:mm').format(income.date),
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: isSmallScreen ? 9 : 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total de Ingresos:',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '+\$${incomes.fold<double>(0, (sum, income) => sum + income.amount).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Eliminar Ingreso'),
          content: const Text('¿Estás seguro de que quieres eliminar este ingreso?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                onDeleteIncome(index);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Color _getSourceColor(String source) {
    switch (source) {
      case 'Salario':
        return Colors.blue;
      case 'Freelance':
        return Colors.purple;
      case 'Inversiones':
        return Colors.green;
      case 'Regalos':
        return Colors.pink;
      case 'Bonos':
        return Colors.orange;
      case 'Otros':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getSourceIcon(String source) {
    switch (source) {
      case 'Salario':
        return Icons.work;
      case 'Freelance':
        return Icons.computer;
      case 'Inversiones':
        return Icons.trending_up;
      case 'Regalos':
        return Icons.card_giftcard;
      case 'Bonos':
        return Icons.star;
      case 'Otros':
        return Icons.more_horiz;
      default:
        return Icons.attach_money;
    }
  }
}