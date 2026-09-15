import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/receipt.dart';
import '../services/database_service.dart';

class DataConfirmationScreen extends StatefulWidget {
  final String imagePath;
  final Map<String, String> extractedData;

  const DataConfirmationScreen({
    super.key,
    required this.imagePath,
    required this.extractedData,
  });

  @override
  State<DataConfirmationScreen> createState() => _DataConfirmationScreenState();
}

class _DataConfirmationScreenState extends State<DataConfirmationScreen> {
  late TextEditingController _storeController;
  late TextEditingController _dateController;
  late TextEditingController _amountController;
  final TextEditingController _notesController = TextEditingController();

  String _selectedCategory = 'Alimentación';
  final List<String> _categories = [
    'Alimentación', 'Transporte', 'Servicios', 
    'Educación', 'Tecnología', 'Salud', 'Otros'
  ];

  @override
  void initState() {
    super.initState();
    _storeController = TextEditingController(text: widget.extractedData['storeName']);
    _dateController = TextEditingController(text: widget.extractedData['date']);
    _amountController = TextEditingController(text: widget.extractedData['totalAmount']);
  }

  @override
  void dispose() {
    _storeController.dispose();
    _dateController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // --- Lógica de Formateo de Fecha ---
  String _formatDateForDB(String inputString) {
    if (inputString.trim().isEmpty) return DateTime.now().toIso8601String().split('T')[0];
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(inputString.trim())) return inputString.trim();

    try {
      String clean = inputString.replaceAll('-', '/').replaceAll('.', '/');
      List<String> parts = clean.split('/');
      
      if (parts.length == 3) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2]);
        if (year < 100) year += 2000;
        return DateTime(year, month, day).toIso8601String().split('T')[0];
      }
    } catch (e) {
      debugPrint("El OCR trajo una fecha irreconocible. Error: $e");
    }
    return DateTime.now().toIso8601String().split('T')[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
        title: const Text(
          'Revisa tu recibo',
          style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Extrajimos los datos automáticamente',
              style: TextStyle(color: AppColors.primaryDark, fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Contenedor de la Imagen
            Hero(
              tag: 'receipt_image', // Añade una animación suave si vienes de otra pantalla
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                  image: DecorationImage(
                    image: FileImage(File(widget.imagePath)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Campos de Texto Unificados
            _buildCustomTextField(
              controller: _storeController,
              label: 'Establecimiento',
              icon: Icons.storefront_outlined,
            ),
            const SizedBox(height: 16),
            
            _buildCustomTextField(
              controller: _amountController,
              label: 'Monto Total',
              icon: Icons.attach_money_rounded,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            
            _buildCustomTextField(
              controller: _dateController,
              label: 'Fecha',
              icon: Icons.calendar_today_outlined,
            ),
            const SizedBox(height: 16),

            // Dropdown de Categoría rediseñado
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryDark),
              decoration: InputDecoration(
                labelText: 'Categoría',
                prefixIcon: const Icon(Icons.category_outlined, color: AppColors.primaryDark),
                filled: true,
                fillColor: AppColors.secondarySoft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                floatingLabelStyle: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
              ),
              style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600, fontSize: 16),
              items: _categories.map((String category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) setState(() => _selectedCategory = newValue);
              },
            ),
            const SizedBox(height: 16),

            // Campo de Notas rediseñado
            _buildCustomTextField(
              controller: _notesController,
              label: 'Notas adicionales (Opcional)',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Botón Principal
            ElevatedButton(
              onPressed: () async {
                try {
                  String amountText = _amountController.text.replaceAll(RegExp(r'[^0-9.]'), '');
                  double finalAmount = double.tryParse(amountText) ?? 0.0;

                  final newReceipt = Receipt(
                    storeName: _storeController.text.isEmpty ? 'Sin nombre' : _storeController.text,
                    date: _formatDateForDB(_dateController.text),
                    totalAmount: finalAmount,
                    imagePath: widget.imagePath,
                    category: _selectedCategory,
                    notes: _notesController.text,
                  );

                  await DatabaseService.insertReceipt(newReceipt);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Recibo guardado correctamente'),
                        backgroundColor: AppColors.primaryDark,
                        behavior: SnackBarBehavior.floating, // Hace que el cartel flote
                      ),
                    );
                    Navigator.pop(context); 
                  }
                } catch (e) {
                  debugPrint("ERROR AL GUARDAR: $e");
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.actionVibrant,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                'Guardar Recibo',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // --- Constructor de Campos Reutilizable ---
  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryDark),
        filled: true,
        fillColor: AppColors.secondarySoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none, // Esto elimina la línea negra/gris
        ),
        floatingLabelStyle: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    );
  }
}