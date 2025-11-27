 import 'package:flutter/material.dart';
 import 'package:cloud_firestore/cloud_firestore.dart';
 import 'package:firebase_auth/firebase_auth.dart';
 import 'package:speech_to_text/speech_to_text.dart' as stt;
 import 'package:google_generative_ai/google_generative_ai.dart';
 import '../services/usage_limits_service.dart';
 import '../models.dart';

class AddIncomeForm extends StatefulWidget {
  final void Function(Income) onAddIncome;

  const AddIncomeForm({super.key, required this.onAddIncome});

  @override
  State<AddIncomeForm> createState() => _AddIncomeFormState();
}

class _AddIncomeFormState extends State<AddIncomeForm> {
  bool isOpen = false;
  String source = "";
  String amount = "";
  String description = "";
  DateTime incomeDate = DateTime.now();

  // Voice input
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _speechText = '';
  double _confidence = 1.0;
  bool _isProcessingVoice = false;

  // AI processing
  late GenerativeModel _model;
  static const String _apiKey = 'AIzaSyBxg6Ot1ZHCeXMnbHA8t9eVC9CL8aiJKWo';

  // Controllers for proper text field management
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;

  final List<String> incomeSources = [
    "Salario",
    "Freelance",
    "Inversiones",
    "Regalos",
    "Bonos",
    "Otros",
  ];

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _descriptionController = TextEditingController(text: description);
    _amountController = TextEditingController(text: amount);

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
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> guardarIngresoEnFirebase(Income income) async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // Crear documento del ingreso en la subcolección "ingresos"
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('ingresos')
          .add({
            'fuente': income.source,
            'monto': income.amount,
            'descripcion': income.description,
            'fecha': income.date,
            'fechaCreacion': DateTime.now(),
          });

      // Actualizar balance del usuario
      DocumentReference userDoc = FirebaseFirestore.instance.collection('usuarios').doc(uid);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userDoc);
        if (snapshot.exists) {
          double currentBalance = (snapshot['balanceActual'] ?? 0.0).toDouble();
          transaction.update(userDoc, {
            'balanceActual': currentBalance + income.amount,
          });
        } else {
          // Si no existe el documento, crearlo
          transaction.set(userDoc, {
            'balanceActual': income.amount,
            'ahorroTotal': 0.0,
            'nombre': FirebaseAuth.instance.currentUser?.displayName ?? "Usuario",
            'email': FirebaseAuth.instance.currentUser?.email ?? "",
            'fechaRegistro': DateTime.now(),
          });
        }
      });

      print("✅ Ingreso guardado correctamente en Firebase - Monto: ${income.amount}, Fuente: ${income.source}");

      // Forzar recarga de datos para mostrar el ingreso inmediatamente
      if (context.mounted) {
        // Aquí podríamos llamar a un callback para recargar datos
        // pero por ahora solo mostramos el log
      }
    } catch (e) {
      print("❌ Error al guardar ingreso: $e");
      throw e;
    }
  }

  // Voice input functions
  Future<void> _listenForIncome() async {
    if (!_isListening) {
      // Verificar límites de voz
      final canUseVoice = await UsageLimitsService.canUseVoice(context);
      if (!canUseVoice) return;

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
        // Mostrar diálogo de confirmación para voz
        UsageLimitsService.showVoiceValidationDialog(
          context,
          _speechText,
          () async {
            await UsageLimitsService.incrementVoiceUsage();
            await _processVoiceInputIncome(_speechText);
          },
          () {
            // Limpiar texto y reiniciar
            _speechText = '';
          }
        );
      }
    }
  }

  Future<void> _processVoiceInputIncome(String voiceText) async {
    setState(() => _isProcessingVoice = true);

    try {
      final prompt = '''Analiza el siguiente texto hablado sobre un ingreso y extrae la informacion relevante.
Texto: "$voiceText"

IMPORTANTE: Identifica numeros como montos. Por ejemplo:
- "50 dolares de salario" -> amount: "50"
- "Gane 25.50 en freelance" -> amount: "25.50"
- "Recibi 100 por bono" -> amount: "100"
- "50 \$ de zapatos" -> amount: "50"

Responde SOLO con un JSON valido en este formato exacto:
{
  "amount": "numero decimal o null si no se menciona",
  "source": "una de estas fuentes exactas: Salario, Freelance, Inversiones, Regalos, Bonos, Otros",
  "description": "descripcion breve del ingreso"
}

Reglas:
- Busca numeros precedidos por \$, dolares, pesos, etc. como montos
- Si no se menciona monto, usa null
- Elige la fuente mas apropiada de la lista
- La descripcion debe ser breve pero descriptiva
- Si no puedes determinar algo, usa valores por defecto apropiados''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null) {
        final result = _parseVoiceResponseIncome(response.text!);

        setState(() {
          if (result['amount'] != null) {
            amount = result['amount']!;
            _amountController.text = amount;
          }
          if (result['source'] != null) {
            source = result['source']!;
          }
          if (result['description'] != null) {
            description = result['description']!;
            _descriptionController.text = description;
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
                      'Procesado: ${result['amount'] ?? 'Sin monto'} - ${result['source'] ?? 'Sin fuente'}',
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al procesar el audio. Intenta de nuevo.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() => _isProcessingVoice = false);
    }
  }

  Map<String, String?> _parseVoiceResponseIncome(String response) {
    try {
      // Limpiar la respuesta de posibles caracteres extra
      final cleanResponse = response.trim();

      // Extraer JSON del response
      final jsonStart = cleanResponse.indexOf('{');
      final jsonEnd = cleanResponse.lastIndexOf('}') + 1;
      if (jsonStart != -1 && jsonEnd != -1) {
        final jsonStr = cleanResponse.substring(jsonStart, jsonEnd);

        // Intentar diferentes patrones de regex para mayor robustez
        String? amount;
        String? source;
        String? description;

        // Buscar amount - puede estar con o sin comillas
        final amountPattern1 = RegExp(r'"amount":\s*"([^"]*)"').firstMatch(jsonStr);
        final amountPattern2 = RegExp(r'"amount":\s*([^,}\s]+)').firstMatch(jsonStr);
        amount = amountPattern1?.group(1) ?? amountPattern2?.group(1);

        // Buscar source
        final sourcePattern1 = RegExp(r'"source":\s*"([^"]*)"').firstMatch(jsonStr);
        final sourcePattern2 = RegExp(r'"source":\s*([^,}\s]+)').firstMatch(jsonStr);
        source = sourcePattern1?.group(1) ?? sourcePattern2?.group(1);

        // Buscar description
        final descriptionPattern1 = RegExp(r'"description":\s*"([^"]*)"').firstMatch(jsonStr);
        final descriptionPattern2 = RegExp(r'"description":\s*([^,}]+)').firstMatch(jsonStr);
        description = descriptionPattern1?.group(1) ?? descriptionPattern2?.group(1);

        // Limpiar valores
        amount = amount?.replaceAll('"', '').trim();
        source = source?.replaceAll('"', '').trim();
        description = description?.replaceAll('"', '').trim();

        // Validar que amount sea un número válido
        if (amount != null && amount.isNotEmpty) {
          final numAmount = double.tryParse(amount.replaceAll(',', '.'));
          if (numAmount == null || numAmount <= 0) {
            amount = null; // Invalidar si no es un número válido
          }
        }

        return {
          'amount': amount,
          'source': source,
          'description': description,
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
      'source': 'Otros',
      'description': response.length > 50 ? response.substring(0, 50) : response,
    };
  }

  void handleSubmit() async {
    // Validar campos
    if (source.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Por favor selecciona una fuente de ingreso"),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (amount.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Por favor ingresa el monto del ingreso"),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Validar que el monto sea un número válido
    double? parsedAmount;
    try {
      parsedAmount = double.parse(amount.replaceAll(',', '.'));
      if (parsedAmount <= 0) {
        throw const FormatException("Monto debe ser mayor a 0");
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Por favor ingresa un monto válido (ej: 100.50)"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (description.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Por favor ingresa una descripción"),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final income = Income(
      source: source,
      amount: parsedAmount,
      description: description,
      date: incomeDate,
    );

    try {
      // Guardar en Firebase primero
      await guardarIngresoEnFirebase(income);

      // Luego llamar al callback local
      widget.onAddIncome(income);

      // Reset form
      setState(() {
        source = "";
        amount = "";
        description = "";
        incomeDate = DateTime.now();
        isOpen = false;
      });

      // Reset controllers
      _descriptionController.clear();
      _amountController.clear();

      // Mostrar mensaje de éxito
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text("Ingreso de \$${income.amount.toStringAsFixed(2)} guardado correctamente"),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Mostrar error al usuario
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al guardar ingreso: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.green.shade50,
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.green.shade200,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: !isOpen
                ? Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade400,
                          Colors.green.shade600,
                          Colors.teal.shade500,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade300.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => setState(() => isOpen = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Agregar Ingreso',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header con animación
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade400,
                              Colors.teal.shade400,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.trending_up,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 20),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '💰 Nuevo Ingreso',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '¡Registra tus ganancias!',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Fuente de ingreso con diseño mejorado
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet,
                                  color: Colors.green.shade600,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Fuente de Ingreso',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: incomeSources.map((src) {
                                final isSelected = source == src;
                                return GestureDetector(
                                  onTap: () => setState(() => source = src),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? LinearGradient(
                                              colors: [
                                                Colors.green.shade400,
                                                Colors.teal.shade400,
                                              ],
                                            )
                                          : LinearGradient(
                                              colors: [
                                                Colors.grey.shade100,
                                                Colors.grey.shade200,
                                              ],
                                            ),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.green.shade600
                                            : Colors.grey.shade300,
                                        width: 2,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: Colors.green.shade200.withOpacity(0.5),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Text(
                                      src,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.grey.shade700,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Monto con diseño mejorado
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.attach_money,
                                  color: Colors.green.shade600,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Monto del Ingreso',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.shade300,
                                  width: 2,
                                ),
                              ),
                              child: TextFormField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                onChanged: (value) => setState(() => amount = value),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(12),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '\$',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                  hintText: '0.00',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 18,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Descripción con voz y autocompletado inteligente
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.description,
                                  color: Colors.green.shade600,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Descripción',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2E7D32),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _isProcessingVoice ? null : _listenForIncome,
                                  icon: Icon(
                                    _isListening ? Icons.mic_off : Icons.mic,
                                    color: _isListening ? Colors.red : Colors.blue,
                                  ),
                                  tooltip: _isListening ? 'Escuchando...' : 'Hablar para ingresar ingreso',
                                  style: IconButton.styleFrom(
                                    backgroundColor: _isListening
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.blue.withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Indicador de procesamiento de voz
                            if (_isProcessingVoice) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
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
                              const SizedBox(height: 8),
                            ],

                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.shade300,
                                  width: 2,
                                ),
                              ),
                              child: TextFormField(
                                controller: _descriptionController,
                                onChanged: (value) => setState(() => description = value),
                                maxLines: 3,
                                style: const TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  hintText: '¿De dónde viene este ingreso? (Escribe o habla)',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Fecha con diseño mejorado
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Colors.green.shade600,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Fecha del Ingreso',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: () async {
                                final DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: incomeDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (pickedDate != null) {
                                  setState(() {
                                    incomeDate = pickedDate;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.green.shade300,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.green.shade50,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: Colors.green.shade600,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      '${incomeDate.day}/${incomeDate.month}/${incomeDate.year}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.green.shade600,
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Botones con diseño mejorado
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade400,
                                  width: 2,
                                ),
                              ),
                              child: OutlinedButton(
                                onPressed: () => setState(() {
                                  isOpen = false;
                                  // Reset controllers
                                  _descriptionController.clear();
                                  _amountController.clear();
                                }),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.shade500,
                                    Colors.teal.shade500,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.shade300.withOpacity(0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: handleSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  '💰 Guardar Ingreso',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}