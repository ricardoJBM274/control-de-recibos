class Receipt {
  final int? id;
  final String? storeName;
  final String date;
  final double totalAmount;
  final String? imagePath;
  final String category; // Nuevo campo
  final String? notes;   // Nuevo campo (opcional)

  Receipt({
    this.id,
    this.storeName,
    required this.date,
    required this.totalAmount,
    this.imagePath,
    this.category = 'Otros', 
    this.notes,
  });

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'storeName': storeName,
      'date': date,
      'totalAmount': totalAmount,
      'imagePath': imagePath,
      'category': category,
      'notes': notes,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory Receipt.fromMap(Map<String, dynamic> map) {
    return Receipt(
      id: map['id'],
      storeName: map['storeName'],
      date: map['date'],
      totalAmount: map['totalAmount'],
      imagePath: map['imagePath'],
      category: map['category'] ?? 'Otros',
      notes: map['notes'],
    );
  }
}