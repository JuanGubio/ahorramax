import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models.dart';

class ExpenseCalendar extends StatefulWidget {
  final List<Expense> expenses;

  const ExpenseCalendar({super.key, required this.expenses});

  @override
  State<ExpenseCalendar> createState() => _ExpenseCalendarState();
}

class _ExpenseCalendarState extends State<ExpenseCalendar> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).cardColor,
              Theme.of(context).cardColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.calendar_month,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Calendario de Gastos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TableCalendar(
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2030),
                  focusedDay: _focusedDate,
                  selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDate = selectedDay;
                      _focusedDate = focusedDay;
                    });

                    // Mostrar diálogo con gastos del día seleccionado
                    final expensesForDay = widget.expenses.where((expense) {
                      return expense.date.year == selectedDay.year &&
                          expense.date.month == selectedDay.month &&
                          expense.date.day == selectedDay.day;
                    }).toList();

                    if (expensesForDay.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                              'Gastos del ${DateFormat('dd/MM/yyyy').format(selectedDay)}'),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: expensesForDay
                                  .map((expense) => Card(
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 30,
                                                    height: 30,
                                                    decoration: BoxDecoration(
                                                      color: _getCategoryColor(
                                                              expense.category)
                                                          .withOpacity(0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    child: Icon(
                                                      _getCategoryIcon(
                                                          expense.category),
                                                      color: _getCategoryColor(
                                                          expense.category),
                                                      size: 18,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          expense.category,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: _getCategoryColor(
                                                                expense
                                                                    .category),
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                        Text(
                                                          expense.description,
                                                          style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Text(
                                                    '\$${expense.amount.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              if (expense.location != null) ...[
                                                Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.location_on,
                                                        size: 14,
                                                        color: Colors.grey),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          // Abrir mapa con las coordenadas
                                                          final coords = expense
                                                              .location!
                                                              .split(', ');
                                                          if (coords.length ==
                                                              2) {
                                                            final lat =
                                                                double.tryParse(
                                                                    coords[0]);
                                                            final lng =
                                                                double.tryParse(
                                                                    coords[1]);
                                                            if (lat != null &&
                                                                lng != null) {
                                                              // Abrir Google Maps o similar
                                                              // Por ahora mostramos un diálogo con las coordenadas
                                                              showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) =>
                                                                        AlertDialog(
                                                                  title: const Text(
                                                                      'Ubicación'),
                                                                  content:
                                                                      Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      Text(
                                                                          'Latitud: $lat'),
                                                                      Text(
                                                                          'Longitud: $lng'),
                                                                      const SizedBox(
                                                                          height:
                                                                              16),
                                                                      const Text(
                                                                        'Para ver el mapa completo, copia estas coordenadas en Google Maps',
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                12,
                                                                            color:
                                                                                Colors.grey),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed:
                                                                          () =>
                                                                              Navigator.of(context).pop(),
                                                                      child: const Text(
                                                                          'Cerrar'),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            }
                                                          }
                                                        },
                                                        child: Text(
                                                          expense.location!,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.blue,
                                                            decoration:
                                                                TextDecoration
                                                                    .underline,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                              ],
                                              if (expense.photoUrl != null &&
                                                  expense.photoUrl!
                                                      .isNotEmpty) ...[
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(Icons.photo_camera,
                                                            size: 14,
                                                            color: Colors.blue),
                                                        const SizedBox(
                                                            width: 4),
                                                        const Text(
                                                          'Foto adjunta',
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  Colors.blue,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Container(
                                                      height: 100,
                                                      width: double.infinity,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        border: Border.all(
                                                            color: Colors
                                                                .grey.shade300),
                                                      ),
                                                      child: Stack(
                                                        children: [
                                                          ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        6),
                                                            child:
                                                                Image.network(
                                                              expense.photoUrl!,
                                                              fit: BoxFit.cover,
                                                              width: double
                                                                  .infinity,
                                                              height: 100,
                                                              errorBuilder:
                                                                  (context,
                                                                      error,
                                                                      stackTrace) {
                                                                return Container(
                                                                  color: Colors
                                                                      .grey
                                                                      .shade200,
                                                                  child:
                                                                      const Center(
                                                                    child: Icon(
                                                                        Icons
                                                                            .broken_image,
                                                                        size:
                                                                            30,
                                                                        color: Colors
                                                                            .grey),
                                                                  ),
                                                                );
                                                              },
                                                              loadingBuilder:
                                                                  (context,
                                                                      child,
                                                                      loadingProgress) {
                                                                if (loadingProgress ==
                                                                    null)
                                                                  return child;
                                                                return Container(
                                                                  color: Colors
                                                                      .grey
                                                                      .shade100,
                                                                  child:
                                                                      const Center(
                                                                    child:
                                                                        CircularProgressIndicator(),
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                          Positioned(
                                                            top: 4,
                                                            right: 4,
                                                            child:
                                                                GestureDetector(
                                                              onTap: () {
                                                                showDialog(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (context) =>
                                                                          Dialog(
                                                                    child:
                                                                        Container(
                                                                      constraints: const BoxConstraints(
                                                                          maxWidth:
                                                                              400,
                                                                          maxHeight:
                                                                              400),
                                                                      child:
                                                                          ClipRRect(
                                                                        borderRadius:
                                                                            BorderRadius.circular(8),
                                                                        child: Image
                                                                            .network(
                                                                          expense
                                                                              .photoUrl!,
                                                                          fit: BoxFit
                                                                              .contain,
                                                                          errorBuilder: (context,
                                                                              error,
                                                                              stackTrace) {
                                                                            return Container(
                                                                              color: Colors.grey.shade200,
                                                                              child: const Center(
                                                                                child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                              child: Container(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(6),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .black
                                                                      .withOpacity(
                                                                          0.7),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              15),
                                                                ),
                                                                child:
                                                                    const Icon(
                                                                  Icons.zoom_in,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 16,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                              ],
                                              if (expense.amountSaved != null &&
                                                  expense.amountSaved! > 0) ...[
                                                Row(
                                                  children: [
                                                    const Icon(Icons.savings,
                                                        size: 14,
                                                        color: Colors.green),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Ahorraste \$${expense.amountSaved!.toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.green,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                              ],
                                              Row(
                                                children: [
                                                  const Icon(Icons.access_time,
                                                      size: 14,
                                                      color: Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    DateFormat('HH:mm')
                                                        .format(expense.date),
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cerrar'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  calendarFormat: _calendarFormat,
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDate = focusedDay;
                  },
                  eventLoader: (day) {
                    return widget.expenses
                        .where((expense) =>
                            expense.date.year == day.year &&
                            expense.date.month == day.month &&
                            expense.date.day == day.day)
                        .toList();
                  },
                  calendarStyle: CalendarStyle(
                    cellMargin: const EdgeInsets.all(4),
                    cellPadding: const EdgeInsets.all(2),
                    selectedDecoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    todayDecoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.7),
                          Theme.of(context).primaryColor.withOpacity(0.4),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    defaultDecoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade800
                          : Colors.grey.shade100,
                    ),
                    weekendDecoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade700
                          : Colors.grey.shade50,
                    ),
                    outsideDecoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade900
                          : Colors.white,
                    ),
                    markerDecoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade400, Colors.red.shade600],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    markerSize: 8,
                    markersMaxCount: 3,
                    markerMargin: const EdgeInsets.symmetric(horizontal: 1),
                    defaultTextStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    weekendTextStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    outsideTextStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    formatButtonShowsNext: false,
                    titleTextStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    formatButtonDecoration: BoxDecoration(
                      border: Border.all(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    formatButtonTextStyle: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    weekendStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white60
                          : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      final expensesForDay = widget.expenses
                          .where((expense) =>
                              expense.date.year == day.year &&
                              expense.date.month == day.month &&
                              expense.date.day == day.day)
                          .toList();

                      if (expensesForDay.isNotEmpty) {
                        // Obtener la categoría más común del día
                        final categoryCount = <String, int>{};
                        for (final expense in expensesForDay) {
                          categoryCount[expense.category] =
                              (categoryCount[expense.category] ?? 0) + 1;
                        }
                        final mostCommonCategory = categoryCount.entries
                            .reduce((a, b) => a.value > b.value ? a : b)
                            .key;

                        return Container(
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getCategoryColor(mostCommonCategory)
                                    .withOpacity(0.3),
                                _getCategoryColor(mostCommonCategory)
                                    .withOpacity(0.1),
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _getCategoryColor(mostCommonCategory)
                                  .withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color:
                                        _getCategoryColor(mostCommonCategory),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).cardColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(mostCommonCategory),
                                    color: Colors.white,
                                    size: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return null;
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      return Container(
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withOpacity(0.8),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                    todayBuilder: (context, day, focusedDay) {
                      return Container(
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor.withOpacity(0.7),
                              Theme.of(context).primaryColor.withOpacity(0.4),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
