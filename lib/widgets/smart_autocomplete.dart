import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class SmartAutocomplete extends StatefulWidget {
  final String hintText;
  final Function(String) onSuggestionSelected;
  final TextEditingController? controller;
  final String fieldType; // 'description', 'category', 'amount'

  const SmartAutocomplete({
    super.key,
    required this.hintText,
    required this.onSuggestionSelected,
    this.controller,
    this.fieldType = 'description',
  });

  @override
  State<SmartAutocomplete> createState() => _SmartAutocompleteState();
}

class _SmartAutocompleteState extends State<SmartAutocomplete> {
  final List<String> _suggestions = [];
  bool _isLoading = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  late GenerativeModel _model;

  static const String _apiKey = 'AIzaSyA1tTTe2loIRAAUNnkYIIVhwP0TvTck_Ac';

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: _apiKey,
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _getSuggestions(String input) async {
    if (input.length < 2) {
      _removeOverlay();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prompt = _buildPrompt(input);
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null) {
        final suggestions = _parseSuggestions(response.text!, input);
        setState(() {
          _suggestions.clear();
          _suggestions.addAll(suggestions);
          _isLoading = false;
        });
        _showSuggestions();
      }
    } catch (e) {
      print('Error getting suggestions: $e');
      setState(() => _isLoading = false);
    }
  }

  String _buildPrompt(String input) {
    switch (widget.fieldType) {
      case 'category':
        return '''
        Eres un clasificador inteligente de gastos. El usuario está escribiendo una categoría de gasto.
        Input: "$input"

        Sugiere 3-5 categorías relacionadas que sean relevantes para finanzas personales.
        Solo responde con las categorías separadas por comas, sin explicaciones adicionales.

        Ejemplos:
        - Si escribe "come" → "Comida, Restaurantes, Supermercado"
        - Si escribe "trans" → "Transporte, Taxi, Autobús, Metro"
        - Si escribe "cine" → "Entretenimiento, Cine, Películas"
        ''';
      case 'amount':
        return '''
        Eres un estimador inteligente de precios. El usuario está escribiendo un monto.
        Input: "$input"

        Basado en precios típicos en Ecuador, sugiere 2-3 montos realistas relacionados.
        Solo responde con los montos separados por comas, sin símbolos de moneda.

        Ejemplos:
        - Si escribe "3" → "3.50, 3.99, 3.25"
        - Si escribe "10" → "9.99, 10.50, 9.50"
        ''';
      default: // description
        return '''
        Eres un completador inteligente de descripciones de gastos. El usuario está escribiendo una descripción.
        Input: "$input"

        Sugiere 3-5 descripciones completas relacionadas que sean útiles para finanzas personales.
        Solo responde con las descripciones separadas por comas.

        Ejemplos:
        - Si escribe "Pizza" → "Pizza mediana familiar, Pizza con delivery, Pizza vegetariana"
        - Si escribe "Uber" → "Uber a centro comercial, Uber al trabajo, Uber aeropuerto"
        - Si escribe "Café" → "Café con leche, Café americano, Café expresso"
        ''';
    }
  }

  List<String> _parseSuggestions(String response, String originalInput) {
    // Clean the response and split by commas
    final cleaned = response.trim().replaceAll('"', '').replaceAll('\n', '');
    final suggestions = cleaned.split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 1)
        .take(5)
        .toList();

    // If we have suggestions, return them; otherwise, provide fallbacks
    if (suggestions.isNotEmpty) {
      return suggestions;
    }

    // Fallback suggestions based on input
    return _getFallbackSuggestions(originalInput);
  }

  List<String> _getFallbackSuggestions(String input) {
    final inputLower = input.toLowerCase();

    if (widget.fieldType == 'category') {
      if (inputLower.contains('come') || inputLower.contains('food')) {
        return ['Comida', 'Restaurantes', 'Supermercado', 'Delivery'];
      }
      if (inputLower.contains('trans') || inputLower.contains('taxi')) {
        return ['Transporte', 'Taxi', 'Autobús', 'Metro'];
      }
      if (inputLower.contains('entre') || inputLower.contains('cine')) {
        return ['Entretenimiento', 'Cine', 'Música', 'Deportes'];
      }
      return ['Comida', 'Transporte', 'Compras', 'Servicios'];
    }

    if (widget.fieldType == 'amount') {
      if (inputLower.startsWith('1') || inputLower.startsWith('2')) {
        return ['1.50', '2.00', '2.50', '1.99'];
      }
      if (inputLower.startsWith('5') || inputLower.startsWith('10')) {
        return ['5.99', '9.99', '10.50', '4.99'];
      }
      return ['1.00', '2.00', '5.00', '10.00'];
    }

    // Description fallbacks
    if (inputLower.contains('pizza') || inputLower.contains('food')) {
      return ['Pizza mediana', 'Pizza familiar', 'Pizza con delivery', 'Pizza vegetariana'];
    }
    if (inputLower.contains('uber') || inputLower.contains('taxi')) {
      return ['Uber al trabajo', 'Uber al centro', 'Uber aeropuerto', 'Uber casa'];
    }
    if (inputLower.contains('cafe') || inputLower.contains('coffee')) {
      return ['Café con leche', 'Café americano', 'Café expresso', 'Café capuchino'];
    }

    return ['Compra general', 'Servicio básico', 'Producto estándar', 'Gasto regular'];
  }

  void _showSuggestions() {
    _removeOverlay();

    if (_suggestions.isEmpty) return;

    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 5,
        width: size.width,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return InkWell(
                  onTap: () {
                    widget.onSuggestionSelected(suggestion);
                    _removeOverlay();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: index < _suggestions.length - 1
                          ? Border(bottom: BorderSide(color: Colors.grey.shade100))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.fieldType == 'category' ? Icons.category :
                          widget.fieldType == 'amount' ? Icons.attach_money : Icons.description,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          suffixIcon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Icon(
                  Icons.smart_toy,
                  color: Colors.blue.shade400,
                  size: 20,
                ),
        ),
        onChanged: (value) {
          if (value.length >= 2) {
            _getSuggestions(value);
          } else {
            _removeOverlay();
          }
        },
        onTapOutside: (_) => _removeOverlay(),
      ),
    );
  }
}