import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';

class ExpenseList extends StatelessWidget {
  final List<Expense> expenses;
  final Function(int) onDeleteExpense;

  const ExpenseList({
    super.key,
    required this.expenses,
    required this.onDeleteExpense,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final cardPadding = isSmallScreen ? 16.0 : 24.0;
    final iconSize = isSmallScreen ? 20.0 : 24.0;
    final titleFontSize = isSmallScreen ? 16.0 : 18.0;

    if (expenses.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Center(
            child: Text(
              'No hay gastos registrados',
              style: TextStyle(color: Colors.grey, fontSize: isSmallScreen ? 14 : 16),
            ),
          ),
        ),
      );
    }

    // Ordenar gastos por fecha (más recientes primero)
    final sortedExpenses = List<Expense>.from(expenses)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: Theme.of(context).primaryColor, size: iconSize),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lista de Gastos',
                    style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedExpenses.length,
              itemBuilder: (context, index) {
                final expense = sortedExpenses[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                color: _getCategoryColor(expense.category).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getCategoryIcon(expense.category),
                                color: _getCategoryColor(expense.category),
                                size: isSmallScreen ? 16 : 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    expense.description,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmallScreen ? 13 : 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    expense.category,
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
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
                                  '\$${expense.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
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
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.access_time, size: 10, color: Colors.grey),
                                const SizedBox(width: 2),
                                Text(
                                  DateFormat('dd/MM HH:mm').format(expense.date),
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: isSmallScreen ? 9 : 11,
                                  ),
                                ),
                              ],
                            ),

                            if (expense.location != null && expense.location!.isNotEmpty) ...[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on, size: 10, color: Colors.grey),
                                  const SizedBox(width: 2),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: isSmallScreen ? 80 : 120),
                                    child: Text(
                                      expense.location!,
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: isSmallScreen ? 9 : 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            if (expense.amountSaved != null && expense.amountSaved! > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.savings,
                                      size: 10,
                                      color: Colors.green.shade800,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '\$${expense.amountSaved!.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: Colors.green.shade800,
                                        fontSize: isSmallScreen ? 9 : 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total de Gastos:',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${expenses.fold<double>(0, (sum, expense) => sum + expense.amount).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
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
          title: const Text('Eliminar Gasto'),
          content: const Text('¿Estás seguro de que quieres eliminar este gasto?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                onDeleteExpense(index);
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

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Restaurantes':
        return Colors.red;
      case 'Transporte':
        return Colors.blue;
      case 'Entretenimiento':
        return Colors.orange;
      case 'Compras':
        return Colors.purple;
      case 'Servicios':
        return Colors.teal;
      case 'Salud':
        return Colors.green;
      case 'Educación':
        return Colors.indigo;
      case 'Otros':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Restaurantes':
        return Icons.restaurant;
      case 'Transporte':
        return Icons.directions_car;
      case 'Entretenimiento':
        return Icons.tv;
      case 'Compras':
        return Icons.shopping_bag;
      case 'Servicios':
        return Icons.build;
      case 'Salud':
        return Icons.favorite;
      case 'Educación':
        return Icons.school;
      case 'Otros':
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }
}