import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/person.dart';
import '../models/id_card.dart';
import '../services/storage_service.dart';

/// Main data provider managing all people and cards
class DataProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final _uuid = const Uuid();

  List<Person> _people = [];
  List<IdCard> _cards = [];
  bool _isLoading = true;

  List<Person> get people => List.unmodifiable(_people);
  List<IdCard> get cards => List.unmodifiable(_cards);
  bool get isLoading => _isLoading;

  DataProvider() {
    _loadData();
  }

  /// Get cards for a specific person
  List<IdCard> getCardsForPerson(String personId) {
    return _cards.where((card) => card.personId == personId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get card count for a person
  int getCardCount(String personId) {
    return _cards.where((card) => card.personId == personId).length;
  }

  /// Load data from storage
  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final jsonString = await _storage.read();
      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        
        _people = (data['people'] as List?)
                ?.map((json) => Person.fromJson(json))
                .toList() ??
            [];
        
        _cards = (data['cards'] as List?)
                ?.map((json) => IdCard.fromJson(json))
                .toList() ??
            [];
        
        // Sort by creation date
        _people.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _cards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (e) {
      print('Error loading data: $e');
      _people = [];
      _cards = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Save data to storage
  Future<void> _saveData() async {
    try {
      final data = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'people': _people.map((p) => p.toJson()).toList(),
        'cards': _cards.map((c) => c.toJson()).toList(),
      };
      
      final jsonString = jsonEncode(data);
      await _storage.write(jsonString);
    } catch (e) {
      print('Error saving data: $e');
      rethrow;
    }
  }

  /// Add a new person
  Future<Person> addPerson(String name) async {
    final person = Person(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
    );
    
    _people.insert(0, person);
    notifyListeners();
    await _saveData();
    
    return person;
  }

  /// Update an existing person
  Future<void> updatePerson(String id, String name) async {
    final index = _people.indexWhere((p) => p.id == id);
    if (index != -1) {
      _people[index] = _people[index].copyWith(name: name);
      notifyListeners();
      await _saveData();
    }
  }

  /// Delete a person and all their cards
  Future<void> deletePerson(String id) async {
    _people.removeWhere((p) => p.id == id);
    _cards.removeWhere((c) => c.personId == id);
    notifyListeners();
    await _saveData();
  }

  /// Add a new card
  Future<IdCard> addCard({
    required String personId,
    required String name,
    required String idNumber,
    String? emoji,
    DateTime? expirationDate,
    bool isPinned = false,
  }) async {
    final card = IdCard(
      id: _uuid.v4(),
      personId: personId,
      name: name,
      idNumber: idNumber,
      emoji: emoji,
      createdAt: DateTime.now(),
      expirationDate: expirationDate,
      isPinned: isPinned,
    );
    
    _cards.insert(0, card);
    notifyListeners();
    await _saveData();
    
    return card;
  }

  /// Update an existing card
  Future<void> updateCard({
    required String id,
    required String name,
    required String idNumber,
    String? emoji,
    DateTime? expirationDate,
    bool? isPinned,
  }) async {
    final index = _cards.indexWhere((c) => c.id == id);
    if (index != -1) {
      _cards[index] = _cards[index].copyWith(
        name: name,
        idNumber: idNumber,
        emoji: emoji,
        expirationDate: expirationDate,
        isPinned: isPinned,
      );
      notifyListeners();
      await _saveData();
    }
  }

  /// Toggle pin status of a card
  Future<void> toggleCardPin(String id) async {
    final index = _cards.indexWhere((c) => c.id == id);
    if (index != -1) {
      _cards[index] = _cards[index].copyWith(
        isPinned: !_cards[index].isPinned,
      );
      notifyListeners();
      await _saveData();
    }
  }

  /// Delete a card
  Future<void> deleteCard(String id) async {
    _cards.removeWhere((c) => c.id == id);
    notifyListeners();
    await _saveData();
  }

  /// Get filtered and sorted cards for a person
  List<IdCard> getFilteredCardsForPerson(String personId, {String? searchQuery}) {
    var cards = _cards.where((c) => c.personId == personId).toList();
    
    // Apply search filter
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      cards = cards.where((c) => 
        c.name.toLowerCase().contains(query) ||
        c.idNumber.toLowerCase().contains(query)
      ).toList();
    }
    
    // Sort: pinned first, then by creation date
    cards.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    
    return cards;
  }

  /// Get all expiring cards (within 3 months)
  List<IdCard> get expiringCards {
    return _cards.where((c) => c.isExpiringSoon).toList();
  }

  /// Get all expired cards
  List<IdCard> get expiredCards {
    return _cards.where((c) => c.isExpired).toList();
  }

  /// Export data as JSON string (for backup)
  String exportData() {
    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'people': _people.map((p) => p.toJson()).toList(),
      'cards': _cards.map((c) => c.toJson()).toList(),
    };
    return jsonEncode(data);
  }

  /// Import data from JSON string (for restore)
  Future<void> importData(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      _people = (data['people'] as List?)
              ?.map((json) => Person.fromJson(json))
              .toList() ??
          [];
      
      _cards = (data['cards'] as List?)
              ?.map((json) => IdCard.fromJson(json))
              .toList() ??
          [];
      
      // Sort by creation date
      _people.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _cards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      notifyListeners();
      await _saveData();
    } catch (e) {
      print('Error importing data: $e');
      rethrow;
    }
  }

  /// Clear all data
  Future<void> clearAllData() async {
    _people = [];
    _cards = [];
    notifyListeners();
    await _storage.clear();
  }
}
