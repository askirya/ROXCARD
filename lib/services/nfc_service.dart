import 'dart:async';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:roxcard/models/card_model.dart';
import 'package:flutter/material.dart';

class NfcService {
  static final NfcService _instance = NfcService._internal();
  factory NfcService() => _instance;
  NfcService._internal();

  final MethodChannel _channel = const MethodChannel('com.roxcard.app/nfc');
  
  // Контроллер для потока событий NFC
  final StreamController<NfcStatus> _statusController = StreamController<NfcStatus>.broadcast();
  Stream<NfcStatus> get statusStream => _statusController.stream;
  
  // Текущий статус NFC
  NfcStatus _currentStatus = NfcStatus.notStarted;
  NfcStatus get currentStatus => _currentStatus;
  
  // Информация о текущей эмулируемой карте
  CardModel? _currentCard;
  CardModel? get currentCard => _currentCard;

  // Проверяет доступность NFC на устройстве
  Future<bool> isNfcAvailable() async {
    try {
      final bool isAvailable = await _channel.invokeMethod('isNfcAvailable');
      return isAvailable;
    } on PlatformException catch (e) {
      _updateStatus(NfcStatus.error, 'Ошибка при проверке NFC: ${e.message}');
      return false;
    }
  }

  // Запускает эмуляцию карты
  Future<bool> startCardEmulation(CardModel card, {BuildContext? context}) async {
    try {
      _updateStatus(NfcStatus.starting, 'Запуск эмуляции карты...');
      
      final Map<String, dynamic> cardData = {
        'cardNumber': card.cardNumber,
        'cardholderName': card.cardholderName,
        'expiryDate': card.expiryDate,
        'cardType': card.cardType.toString().split('.').last,
      };
      
      final bool success = await _channel.invokeMethod('startCardEmulation', {'cardData': cardData});
      
      if (success) {
        _currentCard = card;
        _updateStatus(NfcStatus.emulating, 'Карта активирована для бесконтактной оплаты');
        
        // Увеличиваем счетчик использования с помощью CardCollection
        if (context != null) {
          final cardCollection = Provider.of<CardCollection>(context, listen: false);
          cardCollection.incrementUsageCount(card.id);
        }
      } else {
        _updateStatus(NfcStatus.error, 'Не удалось запустить эмуляцию карты');
      }
      
      return success;
    } on PlatformException catch (e) {
      _updateStatus(NfcStatus.error, 'Ошибка при эмуляции карты: ${e.message}');
      return false;
    }
  }

  // Останавливает эмуляцию карты
  Future<bool> stopCardEmulation() async {
    try {
      _updateStatus(NfcStatus.stopping, 'Остановка эмуляции карты...');
      
      final bool success = await _channel.invokeMethod('stopCardEmulation');
      
      if (success) {
        _currentCard = null;
        _updateStatus(NfcStatus.notStarted, 'Эмуляция карты остановлена');
      } else {
        _updateStatus(NfcStatus.error, 'Не удалось остановить эмуляцию карты');
      }
      
      return success;
    } on PlatformException catch (e) {
      _updateStatus(NfcStatus.error, 'Ошибка при остановке эмуляции: ${e.message}');
      return false;
    }
  }
  
  // Обновляет статус эмуляции карты и отправляет событие в поток
  void _updateStatus(NfcStatus status, String message) {
    _currentStatus = status;
    _statusController.add(status);
    print('NFC статус: $status - $message');
  }
  
  // Освобождаем ресурсы
  void dispose() {
    _statusController.close();
  }
}

// Перечисление возможных статусов NFC
enum NfcStatus {
  notStarted,
  starting,
  emulating,
  stopping,
  error,
} 