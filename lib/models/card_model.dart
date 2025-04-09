import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';
import 'dart:typed_data';

enum CardType {
  visa,
  mastercard,
  amex,
  discover,
  other
}

class CardModel {
  final String id;
  final String cardNumber;
  final String cardholderName;
  final String expiryDate;
  final String cvv;
  final Color cardColor;
  final String bankName;
  final CardType cardType;
  final String? lastUsed;
  final bool isDefault;
  final String? cardNickname;
  final int? usageCount;

  CardModel({
    required this.id,
    required this.cardNumber,
    required this.cardholderName,
    required this.expiryDate,
    required this.cvv,
    required this.cardColor,
    required this.bankName,
    required this.cardType,
    this.lastUsed,
    this.isDefault = false,
    this.cardNickname,
    this.usageCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardNumber': cardNumber,
      'cardholderName': cardholderName,
      'expiryDate': expiryDate,
      'cvv': cvv,
      'cardColor': cardColor.value,
      'bankName': bankName,
      'cardType': cardType.index,
      'lastUsed': lastUsed,
      'isDefault': isDefault,
      'cardNickname': cardNickname,
      'usageCount': usageCount ?? 0,
    };
  }

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'],
      cardNumber: json['cardNumber'],
      cardholderName: json['cardholderName'],
      expiryDate: json['expiryDate'],
      cvv: json['cvv'] ?? '000',
      cardColor: Color(json['cardColor']),
      bankName: json['bankName'],
      cardType: CardType.values[json['cardType'] ?? 0],
      lastUsed: json['lastUsed'],
      isDefault: json['isDefault'] ?? false,
      cardNickname: json['cardNickname'],
      usageCount: json['usageCount'] ?? 0,
    );
  }

  // Создает копию карты с измененными свойствами
  CardModel copyWith({
    String? cardNickname,
    bool? isDefault,
    int? usageCount,
    String? lastUsed,
  }) {
    return CardModel(
      id: this.id,
      cardNumber: this.cardNumber,
      cardholderName: this.cardholderName,
      expiryDate: this.expiryDate,
      cvv: this.cvv,
      cardColor: this.cardColor,
      bankName: this.bankName,
      cardType: this.cardType,
      lastUsed: lastUsed ?? this.lastUsed,
      isDefault: isDefault ?? this.isDefault,
      cardNickname: cardNickname ?? this.cardNickname,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  // Возвращает первые 4 и последние 4 цифры номера карты
  String getObfuscatedNumber() {
    if (cardNumber.length < 8) return cardNumber;
    return '${cardNumber.substring(0, 4)} **** **** ${cardNumber.substring(cardNumber.length - 4)}';
  }

  // Проверяет тип карты на основе первых цифр номера
  static CardType detectCardType(String cardNumber) {
    // Удаляем пробелы и дефисы
    final String cleanNumber = cardNumber.replaceAll(RegExp(r'[\s-]'), '');
    
    // Visa: начинается с 4
    if (RegExp(r'^4').hasMatch(cleanNumber)) {
      return CardType.visa;
    }
    
    // Mastercard: начинается с 51-55 или 2221-2720
    if (RegExp(r'^5[1-5]').hasMatch(cleanNumber) || 
        RegExp(r'^2(22[1-9]|2[3-9][0-9]|[3-6][0-9]{2}|7[0-1][0-9]|720)').hasMatch(cleanNumber)) {
      return CardType.mastercard;
    }
    
    // American Express: начинается с 34 или 37
    if (RegExp(r'^3[47]').hasMatch(cleanNumber)) {
      return CardType.amex;
    }
    
    // Discover: начинается с 6011, 622126-622925, 644-649 или 65
    if (RegExp(r'^6(011|22[0-9]{2}|44[0-9]|5[0-9]{2})').hasMatch(cleanNumber) || 
        RegExp(r'^65').hasMatch(cleanNumber)) {
      return CardType.discover;
    }
    
    return CardType.other;
  }

  // APDU команда для эмуляции NFC карты
  List<int> getNfcApduCommand() {
    switch (cardType) {
      case CardType.visa:
        return [0x00, 0xA4, 0x04, 0x00, 0x07, 0xA0, 0x00, 0x00, 0x00, 0x03, 0x10, 0x10];
      case CardType.mastercard:
        return [0x00, 0xA4, 0x04, 0x00, 0x07, 0xA0, 0x00, 0x00, 0x00, 0x04, 0x10, 0x10];
      case CardType.amex:
        return [0x00, 0xA4, 0x04, 0x00, 0x09, 0xA0, 0x00, 0x00, 0x00, 0x25, 0x01, 0x08, 0x01, 0x00];
      default:
        return [0x00, 0xA4, 0x04, 0x00, 0x07, 0xA0, 0x00, 0x00, 0x00, 0x04, 0x10, 0x10];
    }
  }

  // Проверка валидности карты
  bool isValid() {
    // Проверка номера карты (алгоритм Луна)
    final cleanNumber = cardNumber.replaceAll(RegExp(r'[\s-]'), '');
    if (!isLuhnValid(cleanNumber)) return false;
    
    // Проверка срока действия
    final parts = expiryDate.split('/');
    if (parts.length != 2) return false;
    
    try {
      final month = int.parse(parts[0]);
      final year = int.parse('20${parts[1]}');
      
      final now = DateTime.now();
      final expiryDateTime = DateTime(year, month + 1, 0);
      
      if (expiryDateTime.isBefore(now)) return false;
    } catch (e) {
      return false;
    }
    
    return true;
  }
  
  // Алгоритм Луна для проверки номера карты
  static bool isLuhnValid(String number) {
    int sum = 0;
    bool alternate = false;
    
    for (int i = number.length - 1; i >= 0; i--) {
      int digit = int.parse(number[i]);
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    return sum % 10 == 0;
  }
}

class CardCollection extends ChangeNotifier {
  List<CardModel> _cards = [];
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _encryptionKeyName = 'card_encryption_key';
  late encrypt.Key _encryptionKey;
  late encrypt.IV _iv;
  bool _isInitialized = false;

  List<CardModel> get cards => _cards;
  
  // Получить карту по умолчанию
  CardModel? get defaultCard {
    try {
      return _cards.firstWhere((card) => card.isDefault);
    } catch (e) {
      return _cards.isNotEmpty ? _cards.first : null;
    }
  }

  CardCollection() {
    _initEncryption();
  }

  Future<void> _initEncryption() async {
    if (_isInitialized) return;
    
    // Получаем ключ шифрования из безопасного хранилища или создаем новый
    String? storedKey = await _secureStorage.read(key: _encryptionKeyName);
    
    if (storedKey == null) {
      // Генерируем случайный ключ 256 бит (32 байта)
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      final keyBase64 = base64Encode(keyBytes);
      
      // Сохраняем ключ в безопасном хранилище
      await _secureStorage.write(key: _encryptionKeyName, value: keyBase64);
      storedKey = keyBase64;
    }
    
    // Инициализируем ключ и вектор инициализации
    final keyBytes = base64Decode(storedKey);
    _encryptionKey = encrypt.Key(Uint8List.fromList(keyBytes));
    _iv = encrypt.IV(Uint8List(16)); // Используем нулевой IV для простоты
    
    _isInitialized = true;
    await _loadCards();
  }

  Future<void> _loadCards() async {
    if (!_isInitialized) await _initEncryption();
    
    final prefs = await SharedPreferences.getInstance();
    final String? encryptedCardsJson = prefs.getString('encrypted_cards');
    
    if (encryptedCardsJson != null) {
      try {
        // Расшифровываем данные
        final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
        final decrypted = encrypter.decrypt64(encryptedCardsJson, iv: _iv);
        
        final List<dynamic> decoded = jsonDecode(decrypted);
        _cards = decoded.map((item) => CardModel.fromJson(item)).toList();
        notifyListeners();
      } catch (e) {
        print('Ошибка при расшифровке карт: $e');
        // В случае ошибки расшифровки, начинаем с пустого списка
        _cards = [];
      }
    }
  }

  Future<void> _saveCards() async {
    if (!_isInitialized) await _initEncryption();
    
    final prefs = await SharedPreferences.getInstance();
    final String jsonData = jsonEncode(_cards.map((card) => card.toJson()).toList());
    
    // Шифруем данные перед сохранением
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
    final encrypted = encrypter.encrypt(jsonData, iv: _iv);
    
    await prefs.setString('encrypted_cards', encrypted.base64);
  }

  Future<void> addCard(CardModel card) async {
    // Если это первая карта или помечена как карта по умолчанию,
    // убираем пометку с других карт
    if (_cards.isEmpty || card.isDefault) {
      _cards = _cards.map((c) => c.copyWith(isDefault: false)).toList();
    }
    
    _cards.add(card);
    await _saveCards();
    notifyListeners();
  }

  Future<void> updateCard(String id, {
    String? cardNickname,
    bool? isDefault,
    int? usageCount,
    String? lastUsed,
  }) async {
    final index = _cards.indexWhere((card) => card.id == id);
    if (index == -1) return;
    
    // Если карта устанавливается как карта по умолчанию,
    // убираем пометку с других карт
    if (isDefault == true) {
      _cards = _cards.map((c) => c.copyWith(isDefault: c.id == id)).toList();
    } else {
      _cards[index] = _cards[index].copyWith(
        cardNickname: cardNickname,
        isDefault: isDefault,
        usageCount: usageCount,
        lastUsed: lastUsed,
      );
    }
    
    await _saveCards();
    notifyListeners();
  }

  Future<void> removeCard(String id) async {
    final wasDefault = _cards.any((card) => card.id == id && card.isDefault);
    
    _cards.removeWhere((card) => card.id == id);
    
    // Если удалили карту по умолчанию и есть другие карты,
    // делаем первую карту в списке картой по умолчанию
    if (wasDefault && _cards.isNotEmpty) {
      _cards[0] = _cards[0].copyWith(isDefault: true);
    }
    
    await _saveCards();
    notifyListeners();
  }

  Future<void> incrementUsageCount(String id) async {
    final index = _cards.indexWhere((card) => card.id == id);
    if (index == -1) return;
    
    final currentCount = _cards[index].usageCount ?? 0;
    _cards[index] = _cards[index].copyWith(
      usageCount: currentCount + 1,
      lastUsed: DateTime.now().toIso8601String(),
    );
    
    await _saveCards();
    notifyListeners();
  }

  List<CardModel> getCardsByBankName(String bankName) {
    return _cards.where((card) => card.bankName.toLowerCase().contains(bankName.toLowerCase())).toList();
  }

  List<CardModel> getCardsByType(CardType type) {
    return _cards.where((card) => card.cardType == type).toList();
  }

  Future<void> clearAll() async {
    _cards.clear();
    await _saveCards();
    notifyListeners();
  }
} 