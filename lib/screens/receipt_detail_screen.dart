import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/receipt.dart';

class ReceiptDetailScreen extends StatelessWidget {
  final Receipt receipt;
  const ReceiptDetailScreen({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
        title: const Text('Detalle del Recibo', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (receipt.imagePath != null && File(receipt.imagePath!).existsSync())
              Container(
                height: 350,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: FileImage(File(receipt.imagePath!)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            _buildInfoCard('Establecimiento', receipt.storeName ?? 'Desconocido'),
            const SizedBox(height: 16),
            _buildInfoCard('Fecha', receipt.date),
            const SizedBox(height: 16),
            _buildInfoCard('Total', '\$${receipt.totalAmount.toStringAsFixed(2)}', isHighlight: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlight ? AppColors.actionVibrant : AppColors.secondarySoft, 
        borderRadius: BorderRadius.circular(12)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: AppColors.primaryDark.withOpacity(0.7), fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: AppColors.primaryDark, fontSize: isHighlight ? 28 : 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}