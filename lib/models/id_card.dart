class IdCard {
  final String id;
  final String personId;
  final String name;
  final String idNumber;
  final String? emoji;
  final DateTime createdAt;
  final DateTime? expirationDate;
  final bool isPinned;

  IdCard({
    required this.id,
    required this.personId,
    required this.name,
    required this.idNumber,
    this.emoji,
    required this.createdAt,
    this.expirationDate,
    this.isPinned = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'personId': personId,
        'name': name,
        'idNumber': idNumber,
        'emoji': emoji,
        'createdAt': createdAt.toIso8601String(),
        'expirationDate': expirationDate?.toIso8601String(),
        'isPinned': isPinned,
      };

  factory IdCard.fromJson(Map<String, dynamic> json) => IdCard(
        id: json['id'],
        personId: json['personId'],
        name: json['name'],
        idNumber: json['idNumber'],
        emoji: json['emoji'],
        createdAt: DateTime.parse(json['createdAt']),
        expirationDate: json['expirationDate'] != null 
            ? DateTime.parse(json['expirationDate']) 
            : null,
        isPinned: json['isPinned'] ?? false,
      );

  IdCard copyWith({
    String? id,
    String? personId,
    String? name,
    String? idNumber,
    String? emoji,
    DateTime? createdAt,
    DateTime? expirationDate,
    bool? isPinned,
  }) {
    return IdCard(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      name: name ?? this.name,
      idNumber: idNumber ?? this.idNumber,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
      expirationDate: expirationDate ?? this.expirationDate,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  /// Masks the ID number for display, showing only first 4 and last 4 characters
  String get maskedIdNumber {
    if (idNumber.length <= 8) {
      return '*' * idNumber.length;
    }
    final first = idNumber.substring(0, 4);
    final last = idNumber.substring(idNumber.length - 4);
    return '$first${'*' * (idNumber.length - 8)}$last';
  }

  /// Check if card is expired
  bool get isExpired {
    if (expirationDate == null) return false;
    return DateTime.now().isAfter(expirationDate!);
  }

  /// Check if card expires within 3 months
  bool get isExpiringSoon {
    if (expirationDate == null) return false;
    final threeMonthsFromNow = DateTime.now().add(const Duration(days: 90));
    return !isExpired && expirationDate!.isBefore(threeMonthsFromNow);
  }

  /// Get days until expiration (negative if expired)
  int? get daysUntilExpiration {
    if (expirationDate == null) return null;
    return expirationDate!.difference(DateTime.now()).inDays;
  }
}
