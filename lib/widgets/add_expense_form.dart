import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'smart_autocomplete.dart';

class AddExpenseForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddExpense;

  const AddExpenseForm({super.key, required this.onAddExpense});

  @override
  State<AddExpenseForm> createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends State<AddExpenseForm> {
  bool isOpen = false;
  String category = "";
  String amount = "";
  String description = "";
  DateTime expenseDate = DateTime.now();
  File? photoFile;
  String location = "";
  bool isLoadingLocation = false;
  bool showSavingsOption = false;
  String amountSaved = "";

  // Voice input
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _speechText = '';
  double _confidence = 1.0;
  bool _isProcessingVoice = false;

  // AI processing
  late GenerativeModel _model;
  static const String _apiKey = 'AIzaSyBjQ9EZdV56NFAPbEBs77HiWKN4PM-If_I';

  // Controllers for proper text field management
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;

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

  final List<String> categories = [
    "Restaurantes",
    "Transporte",
    "Entretenimiento",
    "Compras",
    "Servicios",
    "Salud",
    "Educación",
    "Otros",
  ];

  final Map<String, IconData> categoryIcons = {
    "Restaurantes": Icons.restaurant,
    "Transporte": Icons.directions_car,
    "Entretenimiento": Icons.tv,
    "Compras": Icons.shopping_bag,
    "Servicios": Icons.build,
    "Salud": Icons.favorite,
    "Educación": Icons.school,
    "Otros": Icons.more_horiz,
  };

  final List<Color> categoryColors = [
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
    Colors.red,
  ];

  Future<void> getLocation() async {
    setState(() => isLoadingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            location = "Permiso denegado";
            isLoadingLocation = false;
          });
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        location = "${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
        isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        location = "Ubicación no disponible";
        isLoadingLocation = false;
      });
    }
  }

  // Voice input functions
  Future<void> _listenForExpense() async {
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
      final prompt = '''Analiza el siguiente texto hablado sobre un gasto y extrae la informacion relevante.
Texto: "$voiceText"

IMPORTANTE: Identifica numeros como montos. Por ejemplo:
- "50 dolares para comida" -> amount: "50"
- "Gaste 25.50 en transporte" -> amount: "25.50"
- "Pago de 100 por servicios" -> amount: "100"

Responde SOLO con un JSON valido en este formato exacto:
{
  "amount": "numero decimal o null si no se menciona",
  "category": "una de estas categorias exactas: Restaurantes, Transporte, Entretenimiento, Compras, Servicios, Salud, Educacion, Otros",
  "description": "descripcion breve del gasto"
}

Reglas:
- Busca numeros precedidos por \$, dolares, pesos, etc. como montos
- Si no se menciona monto, usa null
- Elige la categoria mas apropiada de la lista
- La descripcion debe ser breve pero descriptiva
- Si no puedes determinar algo, usa valores por defecto apropiados''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null) {
        final result = _parseVoiceResponse(response.text!);

        setState(() {
          if (result['amount'] != null && result['amount']!.isNotEmpty) {
            amount = result['amount']!;
            _amountController.text = amount;
          }
          if (result['category'] != null && result['category']!.isNotEmpty) {
            category = result['category']!;
          }
          if (result['description'] != null && result['description']!.isNotEmpty) {
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
                      'Procesado: ${result['amount'] ?? 'Sin monto'} - ${result['category'] ?? 'Sin categoría'}',
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
              content: Text('La función de voz está temporalmente limitada. Puedes escribir manualmente o usar sugerencias básicas.'),
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

        // Intentar diferentes patrones de regex para mayor robustez
        String? amount;
        String? category;
        String? description;

        // Buscar amount - puede estar con o sin comillas
        final amountPattern1 = RegExp(r'"amount":\s*"([^"]*)"').firstMatch(jsonStr);
        final amountPattern2 = RegExp(r'"amount":\s*([^,}\s]+)').firstMatch(jsonStr);
        amount = amountPattern1?.group(1) ?? amountPattern2?.group(1);

        // Buscar category
        final categoryPattern1 = RegExp(r'"category":\s*"([^"]*)"').firstMatch(jsonStr);
        final categoryPattern2 = RegExp(r'"category":\s*([^,}\s]+)').firstMatch(jsonStr);
        category = categoryPattern1?.group(1) ?? categoryPattern2?.group(1);

        // Buscar description
        final descriptionPattern1 = RegExp(r'"description":\s*"([^"]*)"').firstMatch(jsonStr);
        final descriptionPattern2 = RegExp(r'"description":\s*([^,}]+)').firstMatch(jsonStr);
        description = descriptionPattern1?.group(1) ?? descriptionPattern2?.group(1);

        // Limpiar valores
        amount = amount?.replaceAll('"', '').trim();
        category = category?.replaceAll('"', '').trim();
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
          'category': category,
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
      'category': 'Otros',
      'description': response.length > 50 ? response.substring(0, 50) : response,
    };
  }

  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );

      if (image != null) {
        // Solo asignar la imagen sin restricciones
        setState(() {
          photoFile = File(image.path);
        });
        print("Imagen seleccionada: ${image.path}");
      }
    } catch (e) {
      print("Error al seleccionar imagen: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.image_not_supported, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error al seleccionar imagen: $e')),
              ],
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> guardarGastoEnFirebase(Map<String, dynamic> expenseData) async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // Crear documento del gasto en la subcolección "gastos"
      DocumentReference gastoRef = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('gastos')
          .add({
            'categoria': expenseData['category'],
            'monto': expenseData['amount'],
            'descripcion': expenseData['description'],
            'fecha': expenseData['date'],
            'ubicacion': expenseData['location'],
            'montoAhorrado': expenseData['amountSaved'],
            'fechaCreacion': DateTime.now(),
          });

      print("✅ Gasto guardado correctamente en Firebase con ID: ${gastoRef.id}");

      // Actualizar balance y ahorro total del usuario
      DocumentReference userDoc = FirebaseFirestore.instance.collection('usuarios').doc(uid);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userDoc);
        if (snapshot.exists) {
          double currentBalance = (snapshot['balanceActual'] ?? 0.0).toDouble();
          double currentSavings = (snapshot['ahorroTotal'] ?? 0.0).toDouble();

          transaction.update(userDoc, {
            'balanceActual': currentBalance - expenseData['amount'],
            'ahorroTotal': currentSavings + (expenseData['amountSaved'] ?? 0.0),
          });
        } else {
          // Si no existe el documento, crearlo
          transaction.set(userDoc, {
            'balanceActual': -expenseData['amount'],
            'ahorroTotal': expenseData['amountSaved'] ?? 0.0,
            'nombre': FirebaseAuth.instance.currentUser?.displayName ?? "Usuario",
            'email': FirebaseAuth.instance.currentUser?.email ?? "",
            'fechaRegistro': DateTime.now(),
          });
        }
      });

      print("✅ Balance y ahorros actualizados correctamente");
    } catch (e) {
      print("❌ Error al guardar gasto: $e");
      throw e;
    }
  }

  void handleSubmit() async {
    if (category.isNotEmpty && amount.isNotEmpty && description.isNotEmpty) {
      Map<String, dynamic> expenseData = {
        'category': category,
        'amount': double.parse(amount),
        'description': description,
        'date': expenseDate,
        'photoFile': photoFile,
        'location': location.isNotEmpty ? location : null,
        'amountSaved': amountSaved.isNotEmpty ? double.parse(amountSaved) : null,
      };

      try {
        print("Iniciando guardado del gasto...");
        // Guardar en Firebase primero
        await guardarGastoEnFirebase(expenseData);
        print("Gasto guardado en Firebase exitosamente");

        // Luego llamar al callback local
        widget.onAddExpense(expenseData);
        print("Callback local ejecutado");

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text("¡Gasto guardado correctamente!"),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Reset form
        setState(() {
          category = "";
          amount = "";
          description = "";
          expenseDate = DateTime.now();
          photoFile = null;
          location = "";
          showSavingsOption = false;
          amountSaved = "";
          isOpen = false;
        });

        // Reset controllers
        _descriptionController.clear();
        _amountController.clear();

        print("Formulario reseteado correctamente");
      } catch (e) {
        print("Error completo al guardar gasto: $e");
        // Mostrar error al usuario
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text("Error al guardar gasto: $e")),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } else {
      // Mostrar mensaje si faltan campos requeridos
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text("Por favor completa todos los campos requeridos"),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
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
                Colors.red.shade50,
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.red.shade200,
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
                          Colors.red.shade400,
                          Colors.red.shade600,
                          Colors.pink.shade500,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.shade300.withOpacity(0.5),
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
                          const SizedBox(width: 12),
                          const Text(
                            'Agregar Gasto',
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
                      // Header con diseño mejorado
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.shade400,
                              Colors.pink.shade400,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.shade300.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nuevo Gasto',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Registra en qué gastaste',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Categoría
                      const Text(
                        'Categoría',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final isSelected = category == cat;

                          return GestureDetector(
                            onTap: () => setState(() => category = cat),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                color: isSelected
                                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                                    : Colors.transparent,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? LinearGradient(colors: [
                                              categoryColors[index % categoryColors.length],
                                              categoryColors[index % categoryColors.length].withOpacity(0.7),
                                            ])
                                          : null,
                                      color: isSelected ? null : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      categoryIcons[cat],
                                      color: isSelected ? Colors.white : Colors.grey.shade600,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    cat,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey.shade700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Monto
                      const Text(
                        'Monto',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        onChanged: (value) => setState(() => amount = value),
                        style: const TextStyle(fontSize: 18, color: Colors.black),
                        decoration: InputDecoration(
                          prefixText: '\$ ',
                          hintText: '0.00',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Descripción con autocompletado inteligente y voz
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Descripción',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            onPressed: _isProcessingVoice ? null : _listenForExpense,
                            icon: Icon(
                              _isListening ? Icons.mic_off : Icons.mic,
                              color: _isListening ? Colors.red : Colors.blue,
                            ),
                            tooltip: _isListening ? 'Escuchando...' : 'Hablar para ingresar gasto',
                            style: IconButton.styleFrom(
                              backgroundColor: _isListening
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.blue.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

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

                      SmartAutocomplete(
                        hintText: '¿En qué gastaste? (Escribe o habla)',
                        fieldType: 'description',
                        controller: _descriptionController,
                        onChanged: (value) => setState(() => description = value),
                        onSuggestionSelected: (suggestion) {
                          setState(() {
                            description = suggestion;
                            _descriptionController.text = suggestion;
                          });
                        },
                      ),

                      const SizedBox(height: 24),

                      // Fecha y Hora
                      const Text(
                        'Fecha y Hora',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: expenseDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (pickedDate != null) {
                            final TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(expenseDate),
                            );
                            if (pickedTime != null) {
                              setState(() {
                                expenseDate = DateTime(
                                  pickedDate.year,
                                  pickedDate.month,
                                  pickedDate.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );
                              });
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.grey.shade600),
                              const SizedBox(width: 12),
                              Text(
                                '${expenseDate.day}/${expenseDate.month}/${expenseDate.year} ${expenseDate.hour}:${expenseDate.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Ubicación
                      const Text(
                        'Ubicación (Opcional)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isLoadingLocation ? null : getLocation,
                              icon: const Icon(Icons.location_on),
                              label: Text(isLoadingLocation ? 'Obteniendo...' : (location.isNotEmpty ? location : 'Agregar Ubicación')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Theme.of(context).primaryColor,
                                elevation: 0,
                                side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          if (location.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () => setState(() => location = ""),
                              icon: const Icon(Icons.close),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.grey.shade200,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Foto
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Foto de evidencia',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'OPCIONAL',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: pickImage,
                              icon: const Icon(Icons.camera_alt),
                              label: Text(photoFile != null ? 'Cambiar foto' : 'Agregar foto (opcional)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Theme.of(context).primaryColor,
                                elevation: 0,
                                side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          if (photoFile != null) ...[
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () => setState(() => photoFile = null),
                              icon: const Icon(Icons.close),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.grey.shade200,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      if (photoFile != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: double.infinity,
                                  height: 200,
                                  child: Image.network(
                                    photoFile!.path,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 200,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey.shade100,
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
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
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Row(
                                  children: [
                                    // Botón de zoom
                                    GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => Dialog(
                                            child: Container(
                                              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  photoFile!.path,
                                                  fit: BoxFit.contain,
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    if (loadingProgress == null) return child;
                                                    return Container(
                                                      color: Colors.grey.shade100,
                                                      child: const Center(
                                                        child: CircularProgressIndicator(),
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder: (context, error, stackTrace) {
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
                                        padding: const EdgeInsets.all(8),
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Icon(
                                          Icons.zoom_in,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                    // Botón de cerrar
                                    GestureDetector(
                                      onTap: () => setState(() => photoFile = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Opción de ahorro
                      GestureDetector(
                        onTap: () => setState(() => showSavingsOption = !showSavingsOption),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: showSavingsOption
                                ? Theme.of(context).primaryColor.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                showSavingsOption ? Icons.check : Icons.add,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                showSavingsOption ? '✓ ¿Ahorraste dinero?' : '+ ¿Ahorraste dinero?',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (showSavingsOption) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            border: Border.all(color: Colors.green.shade300, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¡Muy bien! Registra cuánto ahorraste en este gasto',
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                keyboardType: TextInputType.number,
                                initialValue: amountSaved,
                                onChanged: (value) => setState(() => amountSaved = value),
                                style: const TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  prefixText: '\$ ',
                                  hintText: '0.00',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.green, width: 2),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.green, width: 2),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.green, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                              if (amountSaved.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.trending_up,
                                        size: 16,
                                        color: Colors.green.shade800,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Agregarás \$${double.parse(amountSaved).toStringAsFixed(2)} a tus ahorros totales',
                                        style: TextStyle(
                                          color: Colors.green.shade800,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Botones
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setState(() {
                                isOpen = false;
                                photoFile = null;
                                location = "";
                                showSavingsOption = false;
                                amountSaved = "";
                                // Reset controllers
                                _descriptionController.clear();
                                _amountController.clear();
                              }),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: const BorderSide(width: 2),
                              ),
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: const Text(
                                'Guardar Gasto',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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