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
    if (incomes.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No hay ingresos registrados',
              style: TextStyle(color: Colors.grey, fontSize: 16),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green.shade600, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Lista de Ingresos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getSourceColor(income.source).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getSourceIcon(income.source),
                        color: _getSourceColor(income.source),
                        size: 24,
                      ),
                    ),
                    title: Text(
                      income.description,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          income.source,
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(income.date),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '+\$${income.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _showDeleteDialog(context, index),
                          icon: const Icon(Icons.delete, color: Colors.red),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total de Ingresos:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '+\$${incomes.fold<double>(0, (sum, income) => sum + income.amount).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
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