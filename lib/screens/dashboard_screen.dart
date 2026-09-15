import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';
import '../services/ocr_service.dart';
import '../services/database_service.dart';
import '../models/receipt.dart';
import 'data_confirmation_screen.dart';
import 'receipt_detail_screen.dart';
import 'history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _monthlyTotal = 0.0;
  List<Receipt> _recentReceipts = [];
  List<double> _weeklyExpenses = List.filled(7, 0.0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final now = DateTime.now();
      final yearMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";
      
      final total = await DatabaseService.getMonthlyTotal(yearMonth);
      final receipts = await DatabaseService.getRecentReceipts();
      final weekly = await DatabaseService.getWeeklyExpenses();
      
      setState(() {
        _monthlyTotal = total;
        _recentReceipts = receipts;
        _weeklyExpenses = weekly;
      });
    } catch (e) {
      debugPrint("Error cargando Dashboard: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppColors.actionVibrant))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  
                  // 1. Cabecera (Total del mes)
                  Text(
                    '\$${_monthlyTotal.toStringAsFixed(2)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const Text(
                    'Gasto total este mes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 2. Gráfico Dinámico
                  SizedBox(
                    height: 120,
                    child: _buildBarChart(),
                  ),
                  const SizedBox(height: 40),

                  // 3. Título de sección
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Actividad reciente',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const HistoryScreen()),
                          );
                        },
                        child: Text(
                          'Ver todo',
                          style: TextStyle(
                            color: AppColors.primaryDark.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 4. Lista de Transacciones
                  Expanded(
                    child: _recentReceipts.isEmpty 
                      ? const Center(
                          child: Text(
                            'Aún no hay recibos guardados.', 
                            style: TextStyle(color: AppColors.primaryDark)
                          )
                        )
                      : ListView.builder(
                          itemCount: _recentReceipts.length,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            return _buildTransactionTile(_recentReceipts[index]);
                          },
                        ),
                  ),
                ],
              ),
        ),
      ),
      
      // 5. Botón Flotante
      floatingActionButton: SizedBox(
        width: 64,
        height: 64,
        child: FloatingActionButton(
          onPressed: () async {
            final picker = ImagePicker();
            final XFile? image = await picker.pickImage(source: ImageSource.camera);

            if (image != null && context.mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Dialog(
                  backgroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/images/recarga.svg', // <-- Nombre actualizado
                          height: 120,
                        ),
                        const SizedBox(height: 24),
                        const CircularProgressIndicator(color: AppColors.actionVibrant),
                        const SizedBox(height: 16),
                        const Text('Analizando recibo...', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              );

              final extractedData = await OcrService.processReceipt(image.path);

              if (context.mounted) {
                Navigator.pop(context);

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DataConfirmationScreen(
                      imagePath: image.path,
                      extractedData: extractedData,
                    ),
                  ),
                );

                _loadData(); // Recarga los datos al volver
              }
            }
          },
          backgroundColor: AppColors.actionVibrant,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.camera_alt, color: AppColors.primaryDark, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // --- WIDGETS INTERNOS ---

  Widget _buildTransactionTile(Receipt receipt) {
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

  Widget _buildBarChart() {
    double maxAmount = _weeklyExpenses.reduce((a, b) => a > b ? a : b);
    double chartMaxY = maxAmount > 0 ? maxAmount * 1.2 : 100; 

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: chartMaxY,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    days[value.toInt()],
                    style: const TextStyle(color: AppColors.primaryDark, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (index) {
          return _makeBarData(
            index, 
            _weeklyExpenses[index], 
            _weeklyExpenses[index] > 0 ? AppColors.primaryDark : AppColors.secondarySoft
          );
        }),
      ),
    );
  }

  BarChartGroupData _makeBarData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 12,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(show: true, toY: 100, color: Colors.transparent),
        ),
      ],
    );
  }
}