import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/receipt.dart';

class DatabaseService {
  static late Database _db;

  // 1. Inicialización y creación de la tabla
  static Future<void> initialize() async {
    final dbPath = await getDatabasesPath();
    // Cambiamos el nombre para generar una tabla limpia
    final path = join(dbPath, 'receipts_v2.db'); 

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE receipts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            storeName TEXT,
            date TEXT NOT NULL,
            totalAmount REAL NOT NULL,
            imagePath TEXT,
            category TEXT NOT NULL, 
            notes TEXT
          )
        ''');
      },
    );
  }

  // 2. Método para insertar un nuevo recibo
  static Future<int> insertReceipt(Receipt receipt) async {
    return await _db.insert(
      'receipts',
      receipt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 3. Método para obtener los últimos 5 gastos (Para el Dashboard)
  static Future<List<Receipt>> getRecentReceipts() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'receipts',
      orderBy: 'date DESC',
      limit: 5,
    );
    return maps.map((map) => Receipt.fromMap(map)).toList();
  }

  // 4. Método para calcular el total del mes
  static Future<double> getMonthlyTotal(String yearMonth) async {
    try {
      final List<Map<String, dynamic>> result = await _db.rawQuery('''
        SELECT SUM(totalAmount) as total 
        FROM receipts 
        WHERE date LIKE ?
      ''', ['$yearMonth%']);

      if (result.isNotEmpty && result.first['total'] != null) {
        // Usamos "num" primero por si SQLite nos devuelve un int en vez de un double
        return (result.first['total'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      print("Error leyendo el total: $e");
      return 0.0;
    }
  }

  // 5. Método para el gráfico: Gastos por día de la semana
  static Future<List<double>> getWeeklyExpenses() async {
    final now = DateTime.now();
    final yearMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    
    final List<Map<String, dynamic>> result = await _db.query(
      'receipts',
      where: 'date LIKE ?',
      whereArgs: ['$yearMonth%'],
    );
    
    List<double> weekDays = List.filled(7, 0.0);
    for (var row in result) {
      try {
        DateTime date = DateTime.parse(row['date']);
        // date.weekday devuelve 1 para Lunes, 7 para Domingo
        weekDays[date.weekday - 1] += (row['totalAmount'] as num).toDouble();
      } catch (e) {
        // Ignorar fechas mal formateadas
      }
    }
    return weekDays;
  }

  // 6. Obtener todos los recibos de un mes específico
  static Future<List<Receipt>> getReceiptsByMonth(String yearMonth) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'receipts',
      where: 'date LIKE ?',
      whereArgs: ['$yearMonth%'],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Receipt.fromMap(map)).toList();
  }

  // 7. Obtener el historial completo
  static Future<List<Receipt>> getAllReceipts() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'receipts',
      orderBy: 'date DESC',
    );
    return maps.map((map) => Receipt.fromMap(map)).toList();
  }
}