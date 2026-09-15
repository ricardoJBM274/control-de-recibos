import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/foundation.dart';

class OcrService {
  static Future<Map<String, String>> processReceipt(String imagePath) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    RecognizedText recognizedText;
    
    try {
      recognizedText = await textRecognizer.processImage(InputImage.fromFilePath(imagePath));
    } catch (e) {
      debugPrint("Error en OCR: $e");
      return {'storeName': '', 'date': '', 'totalAmount': ''};
    } finally {
      textRecognizer.close();
    }

    // =========================================================================
    // 1. ANÁLISIS ESPACIAL: RECONSTRUCCIÓN DE LÍNEAS HORIZONTALES
    // =========================================================================
    List<TextElement> allElements = [];
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        for (TextElement element in line.elements) {
          allElements.add(element);
        }
      }
    }

    // Ordenamos todas las palabras de arriba hacia abajo (Eje Y)
    allElements.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    List<String> lines = [];
    if (allElements.isNotEmpty) {
      double currentY = allElements.first.boundingBox.center.dy;
      List<TextElement> currentLineElements = [];

      for (var element in allElements) {
        // Si la palabra está en la misma "altura" (margen de 15 píxeles)
        if ((element.boundingBox.center.dy - currentY).abs() < 15) {
          currentLineElements.add(element);
        } else {
          // Ordenamos la línea de izquierda a derecha (Eje X) antes de guardarla
          currentLineElements.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
          lines.add(currentLineElements.map((e) => e.text).join(' '));
          
          currentLineElements = [element];
          currentY = element.boundingBox.center.dy;
        }
      }
      if (currentLineElements.isNotEmpty) {
        currentLineElements.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
        lines.add(currentLineElements.map((e) => e.text).join(' '));
      }
    }

    // =========================================================================
    // 2. EXTRACCIÓN INTELIGENTE DE DATOS
    // =========================================================================
    String storeName = '';
    String date = '';
    String totalAmount = '';

    // A. Extraer Establecimiento (Primera línea válida que no sea un número de registro)
    for (String line in lines) {
      String upperLine = line.toUpperCase();
      if (upperLine.trim().isNotEmpty && 
          !RegExp(r'(NIT|NRC|FACTURA|TICKET|RESOLUCION|SUCURSAL|GIRO|TEL|CAJA)').hasMatch(upperLine)) {
        storeName = line;
        break; // Detenemos la búsqueda al encontrar el primer nombre lógico
      }
    }

    // B. Extraer Fecha
    final dateRegEx = RegExp(r'(\d{1,2})\s*[\/\-\.]\s*(\d{1,2})\s*[\/\-\.]\s*(\d{2,4})');
    for (String line in lines) {
      final match = dateRegEx.firstMatch(line);
      if (match != null) {
        // Reconstruimos la fecha limpia sin espacios
        date = "${match.group(1)}/${match.group(2)}/${match.group(3)}";
        break;
      }
    }

    // C. Extraer Total
    double maxTotal = 0.0;
    bool foundTotalKeyword = false;

    for (String line in lines) {
      String upperLine = line.toUpperCase();

      // Descartamos en la misma línea cualquier billete entregado o vuelto
      if (upperLine.contains('VUELTO') || upperLine.contains('CAMBIO') || upperLine.contains('EFECTIVO')) {
        continue; 
      }

      // Buscamos la palabra TOTAL
      if (upperLine.contains('TOTAL') && !upperLine.contains('SUB')) {
        foundTotalKeyword = true;
        double? lineAmount = _extractAmount(line);
        if (lineAmount != null && lineAmount > maxTotal) {
          maxTotal = lineAmount;
        }
      }
    }

    // Plan B: Si la palabra "Total" estaba borrosa, buscamos el número lógico más alto
    if (!foundTotalKeyword || maxTotal == 0.0) {
      for (String line in lines) {
        String upperLine = line.toUpperCase();
        // Volvemos a ignorar el efectivo
        if (upperLine.contains('VUELTO') || upperLine.contains('CAMBIO') || upperLine.contains('EFECTIVO')) continue;
        
        // Ignoramos números de teléfono, NITs o códigos de barras
        if (line.contains('-') || line.replaceAll(RegExp(r'[^0-9]'), '').length > 6) continue;
        
        double? amount = _extractAmount(line);
        if (amount != null && amount > maxTotal && amount < 2000) { // Límite de seguridad
          maxTotal = amount;
        }
      }
    }

    if (maxTotal > 0) {
      totalAmount = maxTotal.toStringAsFixed(2);
    }

    return {
      'storeName': storeName,
      'date': date,
      'totalAmount': totalAmount,
    };
  }

  // --- FUNCIÓN AUXILIAR PARA LIMPIAR NÚMEROS ---
  static double? _extractAmount(String text) {
    // Detecta números con o sin el signo $, separados por comas o puntos
    final regex = RegExp(r'\$?\s*\b(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2}))\b');
    final match = regex.firstMatch(text);
    
    if (match != null) {
      String numStr = match.group(1)!; // Extrae solo el número sin el $
      
      if (numStr.contains(',') && numStr.contains('.')) {
        numStr = numStr.replaceAll(',', ''); 
      } else if (numStr.contains(',')) {
        numStr = numStr.replaceAll(',', '.');
      }
      
      return double.tryParse(numStr);
    }
    return null;
  }
}