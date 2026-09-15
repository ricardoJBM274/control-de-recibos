import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/receipt.dart';
import '../services/database_service.dart';
import 'receipt_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Receipt> _receipts = [];
  bool _isLoading = true;

  // Variables para los filtros
  late int _selectedYear;
  late int _selectedMonth;

  final List<int> _availableYears = [2024, 2025, 2026, 2027];
  final List<String> _months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    _loadFilteredHistory();
  }

  Future<void> _loadFilteredHistory() async {
    setState(() => _isLoading = true);
    try {
      // Formateamos el año y mes seleccionado (ej. 2026-09)
      final yearMonth = "$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}";
      final filteredReceipts = await DatabaseService.getReceiptsByMonth(yearMonth);
      
      setState(() {
        _receipts = filteredReceipts;
      });
    } catch (e) {
      debugPrint("Error cargando historial: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
        title: const Text(
          'Historial de Gastos', 
          style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)
        ),
      ),
      body: Column(
        children: [
          // BARRA DE FILTROS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Row(
              children: [
                // Dropdown de Mes
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.secondarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedMonth,
                        isExpanded: true,
                        dropdownColor: AppColors.background,
                        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryDark),
                        items: List.generate(12, (index) {
                          return DropdownMenuItem(
                            value: index + 1,
                            child: Text(_months[index], style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                          );
                        }),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedMonth = value);
                            _loadFilteredHistory(); // Recargar al cambiar
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Dropdown de Año
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.secondarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedYear,
                        isExpanded: true,
                        dropdownColor: AppColors.background,
                        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryDark),
                        items: _availableYears.map((year) {
                          return DropdownMenuItem(
                            value: year,
                            child: Text(year.toString(), style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedYear = value);
                            _loadFilteredHistory(); // Recargar al cambiar
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),

          // LISTA DE RECIBOS
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.actionVibrant))
              : _receipts.isEmpty
                  ? Center(
                      child: Text(
                        'No hay gastos registrados en este periodo.', 
                        style: TextStyle(color: AppColors.primaryDark.withOpacity(0.7))
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(24.0),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _receipts.length,
                      itemBuilder: (context, index) {
                        return _buildTransactionTile(_receipts[index], context);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Receipt receipt, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ReceiptDetailScreen(receipt: receipt)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_long, color: AppColors.primaryDark, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receipt.storeName ?? 'Desconocido', 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    receipt.date, 
                    style: TextStyle(color: AppColors.primaryDark.withOpacity(0.7), fontSize: 12)
                  ),
                ],
              ),
            ),
            Text(
              '-\$${receipt.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}