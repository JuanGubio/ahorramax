import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models.dart';
import 'success_notification.dart';

class FinancialGoalsWidget extends StatefulWidget {
  const FinancialGoalsWidget({super.key});

  @override
  State<FinancialGoalsWidget> createState() => _FinancialGoalsWidgetState();
}

class _FinancialGoalsWidgetState extends State<FinancialGoalsWidget> {
  final List<FinancialGoal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final goalsSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('metas')
          .orderBy('createdDate', descending: true)
          .get();

      final goals = goalsSnapshot.docs
          .map((doc) => FinancialGoal.fromMap(doc.data()))
          .toList();

      setState(() {
        _goals.clear();
        _goals.addAll(goals);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading goals: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveGoal(FinancialGoal goal) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('metas')
          .doc(goal.id)
          .set(goal.toMap());

      await _loadGoals();
    } catch (e) {
      print('Error saving goal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar meta: $e')),
      );
    }
  }

  Future<void> _deleteGoal(String goalId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('metas')
          .doc(goalId)
          .delete();

      setState(() {
        _goals.removeWhere((goal) => goal.id == goalId);
      });
    } catch (e) {
      print('Error deleting goal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar meta: $e')),
      );
    }
  }

  void _showCreateGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateGoalDialog(
        onSave: (goal) async {
          await _saveGoal(goal);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

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
              Builder(
                builder: (context) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final isSmallScreen = screenWidth < 360;

                  return Container(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.purple, Colors.pink],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: isSmallScreen ? 40 : 48,
                              height: isSmallScreen ? 40 : 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(Icons.flag, color: Colors.white, size: isSmallScreen ? 24 : 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mis Metas Financieras',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 18 : 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Gestiona tus objetivos de ahorro',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: isSmallScreen ? 12 : 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Botón de agregar más prominente
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          child: ElevatedButton.icon(
                            onPressed: _showCreateGoalDialog,
                            icon: const Icon(Icons.add, size: 28, color: Colors.white),
                            label: const Text(
                              'NUEVA META',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              shadowColor: Colors.purple.withOpacity(0.5),
                              minimumSize: const Size(double.infinity, 56),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              if (_goals.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No tienes metas financieras',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Crea tu primera meta para empezar a ahorrar',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showCreateGoalDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Crear Primera Meta'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _goals.length,
                  itemBuilder: (context, index) {
                    final goal = _goals[index];
                    return GoalCard(
                      goal: goal,
                      onDelete: () => _deleteGoal(goal.id),
                      onUpdate: _saveGoal,
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class GoalCard extends StatelessWidget {
  final FinancialGoal goal;
  final VoidCallback onDelete;
  final Function(FinancialGoal) onUpdate;

  const GoalCard({
    super.key,
    required this.goal,
    required this.onDelete,
    required this.onUpdate,
  });

  Color _getGoalColor(FinancialGoal goal) {
    if (goal.isCompleted) return Colors.green;
    if (goal.progressPercentage >= 0.8) return Colors.blue;
    if (goal.progressPercentage >= 0.5) return Colors.orange;
    return Colors.grey;
  }

  String _getGoalTypeText(GoalType type) {
    switch (type) {
      case GoalType.savings:
        return 'Ahorro General';
      case GoalType.emergencyFund:
        return 'Fondo de Emergencia';
      case GoalType.debtPayment:
        return 'Pago de Deudas';
      case GoalType.investment:
        return 'Inversión';
      case GoalType.vacation:
        return 'Vacaciones';
      case GoalType.purchase:
        return 'Compra';
      case GoalType.custom:
        return 'Personalizada';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getGoalColor(goal);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      goal.isCompleted ? Icons.check_circle : Icons.flag,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getGoalTypeText(goal.type),
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Eliminar Meta'),
                            content: const Text('¿Estás seguro de que quieres eliminar esta meta?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () {
                                  onDelete();
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Eliminar'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Eliminar'),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),
              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${goal.currentAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '\$${goal.targetAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.grey.shade200,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: goal.progressPercentage,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(goal.progressPercentage * 100).toStringAsFixed(1)}% completado',
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (goal.remainingAmount > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.blue.shade100],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Te faltan \$${goal.remainingAmount.toStringAsFixed(2)} para completar esta meta',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (goal.daysRemaining > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${goal.daysRemaining} días restantes',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CreateGoalDialog extends StatefulWidget {
  final Function(FinancialGoal) onSave;

  const CreateGoalDialog({super.key, required this.onSave});

  @override
  State<CreateGoalDialog> createState() => _CreateGoalDialogState();
}

class _CreateGoalDialogState extends State<CreateGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();

  GoalType _selectedType = GoalType.savings;
  GoalPeriod _selectedPeriod = GoalPeriod.monthly;
  DateTime? _targetDate;

  // Voice input
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _speechText = '';
  double _confidence = 1.0;
  bool _isProcessingVoice = false;

  // AI processing
  late GenerativeModel _model;
  static const String _apiKey = 'AIzaSyBjQ9EZdV56NFAPbEBs77HiWKN4PM-If_I';

  @override
  void initState() {
    super.initState();

    // Initialize speech-to-text
    _speech = stt.SpeechToText();

    // Initialize AI model
    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: _apiKey,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  // Voice input functions
  Future<void> _listenForGoal() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _speechText = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
          localeId: 'es_ES', // Spanish locale
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_speechText.isNotEmpty) {
        await _processVoiceInput(_speechText);
      }
    }
  }

  Future<void> _processVoiceInput(String voiceText) async {
    setState(() => _isProcessingVoice = true);

    try {
      final prompt = '''Analiza el siguiente texto hablado sobre una meta financiera y extrae la información relevante.
Texto: "$voiceText"

IMPORTANTE: Identifica números como montos objetivos. Por ejemplo:
- "Quiero ahorrar 5000 dolares para un carro" -> amount: "5000"
- "Meta de 10000 para vacaciones" -> amount: "10000"
- "Ahorrar 2500 mensuales" -> amount: "2500"

Responde SOLO con un JSON válido en este formato exacto:
{
  "amount": "número decimal o null si no se menciona",
  "title": "título breve de la meta",
  "description": "descripción más detallada",
  "type": "uno de estos tipos exactos: savings, emergencyFund, debtPayment, investment, vacation, purchase, custom"
}

Reglas:
- Busca números precedidos por \$, dolares, pesos, etc. como montos
- Si no se menciona monto, usa null
- El título debe ser breve pero descriptivo
- Elige el tipo de meta más apropiado de la lista
- Si no puedes determinar algo, usa valores por defecto apropiados''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null) {
        final result = _parseVoiceResponse(response.text!);

        setState(() {
          if (result['amount'] != null && result['amount']!.isNotEmpty) {
            _targetAmountController.text = result['amount']!;
          }
          if (result['title'] != null && result['title']!.isNotEmpty) {
            _titleController.text = result['title']!;
          }
          if (result['description'] != null && result['description']!.isNotEmpty) {
            _descriptionController.text = result['description']!;
          }
          if (result['type'] != null && result['type']!.isNotEmpty) {
            _selectedType = _parseGoalType(result['type']!);
          }
        });

        // Mostrar confirmación
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.mic, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Procesado: ${result['title'] ?? 'Sin título'} - \$${result['amount'] ?? 'Sin monto'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error processing voice: $e');

      // Check for quota/rate limit errors
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('quota') ||
          errorString.contains('limit') ||
          errorString.contains('rate') ||
          errorString.contains('429')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La función de voz está temporalmente limitada. Puedes escribir manualmente.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al procesar el audio. Intenta de nuevo.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } finally {
      setState(() => _isProcessingVoice = false);
    }
  }

  Map<String, String?> _parseVoiceResponse(String response) {
    try {
      // Limpiar la respuesta de posibles caracteres extra
      final cleanResponse = response.trim();

      // Extraer JSON del response
      final jsonStart = cleanResponse.indexOf('{');
      final jsonEnd = cleanResponse.lastIndexOf('}') + 1;
      if (jsonStart != -1 && jsonEnd != -1) {
        final jsonStr = cleanResponse.substring(jsonStart, jsonEnd);

        // Buscar patrones comunes de montos
        String? amount;
        String? title;
        String? description;
        String? type;

        // Buscar amount
        final amountPattern1 = RegExp(r'"amount":\s*"([^"]*)"').firstMatch(jsonStr);
        final amountPattern2 = RegExp(r'"amount":\s*([^,}\s]+)').firstMatch(jsonStr);
        amount = amountPattern1?.group(1) ?? amountPattern2?.group(1);

        // Buscar title
        final titlePattern1 = RegExp(r'"title":\s*"([^"]*)"').firstMatch(jsonStr);
        final titlePattern2 = RegExp(r'"title":\s*([^,}\s]+)').firstMatch(jsonStr);
        title = titlePattern1?.group(1) ?? titlePattern2?.group(1);

        // Buscar description
        final descriptionPattern1 = RegExp(r'"description":\s*"([^"]*)"').firstMatch(jsonStr);
        final descriptionPattern2 = RegExp(r'"description":\s*([^,}]+)').firstMatch(jsonStr);
        description = descriptionPattern1?.group(1) ?? descriptionPattern2?.group(1);

        // Buscar type
        final typePattern1 = RegExp(r'"type":\s*"([^"]*)"').firstMatch(jsonStr);
        final typePattern2 = RegExp(r'"type":\s*([^,}\s]+)').firstMatch(jsonStr);
        type = typePattern1?.group(1) ?? typePattern2?.group(1);

        // Limpiar valores
        amount = amount?.replaceAll('"', '').trim();
        title = title?.replaceAll('"', '').trim();
        description = description?.replaceAll('"', '').trim();
        type = type?.replaceAll('"', '').trim();

        // Validar que amount sea un número válido
        if (amount != null && amount.isNotEmpty) {
          final numAmount = double.tryParse(amount.replaceAll(',', '.'));
          if (numAmount == null || numAmount <= 0) {
            amount = null; // Invalidar si no es un número válido
          }
        }

        return {
          'amount': amount,
          'title': title,
          'description': description,
          'type': type,
        };
      }
    } catch (e) {
      print('Error parsing voice response: $e');
    }

    // Fallback mejorado - intentar extraer información del texto original
    final originalText = response.toLowerCase();

    // Buscar patrones comunes de montos
    final amountPatterns = [
      RegExp(r'(\d+(?:[.,]\d{1,2})?)\s*(?:dólares?|pesos?|\$|usd)'),
      RegExp(r'\$?\s*(\d+(?:[.,]\d{1,2})?)'),
    ];

    String? extractedAmount;
    for (final pattern in amountPatterns) {
      final match = pattern.firstMatch(originalText);
      if (match != null) {
        extractedAmount = match.group(1)?.replaceAll(',', '.');
        break;
      }
    }

    return {
      'amount': extractedAmount,
      'title': response.length > 30 ? response.substring(0, 30) : response,
      'description': response.length > 50 ? response.substring(0, 50) : response,
      'type': 'savings',
    };
  }

  GoalType _parseGoalType(String type) {
    switch (type.toLowerCase()) {
      case 'savings':
        return GoalType.savings;
      case 'emergencyfund':
        return GoalType.emergencyFund;
      case 'debtpayment':
        return GoalType.debtPayment;
      case 'investment':
        return GoalType.investment;
      case 'vacation':
        return GoalType.vacation;
      case 'purchase':
        return GoalType.purchase;
      case 'custom':
        return GoalType.custom;
      default:
        return GoalType.savings;
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final goal = FinancialGoal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        targetAmount: double.parse(_targetAmountController.text.replaceAll(',', '.')),
        currentAmount: 0,
        type: _selectedType,
        period: _selectedPeriod,
        createdDate: DateTime.now(),
        targetDate: _targetDate,
      );

      widget.onSave(goal);

      // Mostrar notificación de éxito
      SuccessNotification.show(
        context,
        message: 'Meta creada exitosamente',
        amount: goal.targetAmount.toStringAsFixed(2),
        isIncome: true,
      );
    }
  }

  String _getGoalTypeText(GoalType type) {
    switch (type) {
      case GoalType.savings:
        return 'Ahorro General';
      case GoalType.emergencyFund:
        return 'Fondo de Emergencia';
      case GoalType.debtPayment:
        return 'Pago de Deudas';
      case GoalType.investment:
        return 'Inversión';
      case GoalType.vacation:
        return 'Vacaciones';
      case GoalType.purchase:
        return 'Compra';
      case GoalType.custom:
        return 'Personalizada';
    }
  }

  String _getGoalPeriodText(GoalPeriod period) {
    switch (period) {
      case GoalPeriod.monthly:
        return 'Mensual';
      case GoalPeriod.yearly:
        return 'Anual';
      case GoalPeriod.custom:
        return 'Personalizado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF0FFF4),
              const Color(0xFFE6FBFF),
              const Color(0xFFFFF6EA),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2ECC71).withOpacity(0.1),
                          const Color(0xFF4FA3FF).withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF2ECC71).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2ECC71), Color(0xFF4FA3FF)],
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2ECC71).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.flag, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF2ECC71), Color(0xFF4FA3FF)],
                              ).createShader(bounds),
                              child: const Text(
                                'Nueva Meta Financiera',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Define tu objetivo de ahorro',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Form Fields in Cards
                  _buildFormFieldCard(
                    icon: Icons.title,
                    iconColor: const Color(0xFF2ECC71),
                    child: Column(
                      children: [
                        // Indicador de procesamiento de voz
                        if (_isProcessingVoice) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Procesando tu voz con IA...',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _titleController,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Título de la meta',
                                  hintText: 'Ej: Comprar un carro',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingresa un título';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            IconButton(
                              onPressed: _isProcessingVoice ? null : _listenForGoal,
                              icon: Icon(
                                _isListening ? Icons.mic_off : Icons.mic,
                                color: _isListening ? Colors.red : Colors.blue,
                              ),
                              tooltip: _isListening ? 'Escuchando...' : 'Hablar para crear meta',
                              style: IconButton.styleFrom(
                                backgroundColor: _isListening
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.blue.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildFormFieldCard(
                    icon: Icons.description,
                    iconColor: const Color(0xFF4FA3FF),
                    child: TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Descripción (opcional)',
                        hintText: 'Detalles adicionales de tu meta',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildFormFieldCard(
                    icon: Icons.attach_money,
                    iconColor: const Color(0xFF00C853),
                    child: TextFormField(
                      controller: _targetAmountController,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Monto objetivo',
                        hintText: 'Ej: 5000.00',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        prefixIcon: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C853).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '\$',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00C853),
                            ),
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa un monto';
                        }
                        final amount = double.tryParse(value.replaceAll(',', '.'));
                        if (amount == null || amount <= 0) {
                          return 'Ingresa un monto válido mayor a 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Dropdowns in Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildFormFieldCard(
                          icon: Icons.category,
                          iconColor: const Color(0xFF9C27B0),
                          child: DropdownButtonFormField<GoalType>(
                            value: _selectedType,
                            isExpanded: true,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Tipo de meta',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            items: GoalType.values.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(
                                  _getGoalTypeText(type),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedType = value);
                              }
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Selecciona un tipo de meta';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildFormFieldCard(
                          icon: Icons.schedule,
                          iconColor: const Color(0xFFFF9800),
                          child: DropdownButtonFormField<GoalPeriod>(
                            value: _selectedPeriod,
                            isExpanded: true,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Período',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            items: GoalPeriod.values.map((period) {
                              return DropdownMenuItem(
                                value: period,
                                child: Text(
                                  _getGoalPeriodText(period),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedPeriod = value);
                              }
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Selecciona un período';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Date Picker
                  _buildFormFieldCard(
                    icon: Icons.calendar_today,
                    iconColor: const Color(0xFF795548),
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                        );
                        if (date != null) {
                          setState(() => _targetDate = date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fecha objetivo (opcional)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _targetDate != null
                                        ? '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}'
                                        : 'Seleccionar fecha',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: _targetDate != null ? Colors.black87 : Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey[400],
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Buttons
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF2ECC71), width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.white,
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(
                                color: Color(0xFF2ECC71),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2ECC71),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 4,
                              shadowColor: const Color(0xFF2ECC71).withOpacity(0.3),
                            ),
                            child: const Text(
                              'Crear Meta',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormFieldCard({required IconData icon, required Color iconColor, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}