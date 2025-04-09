import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import '../models/card_model.dart';
import '../services/nfc_service.dart';
import '../widgets/card_widget.dart';

class NfcEmulatorScreen extends StatefulWidget {
  final CardModel card;

  const NfcEmulatorScreen({
    Key? key,
    required this.card,
  }) : super(key: key);

  @override
  State<NfcEmulatorScreen> createState() => _NfcEmulatorScreenState();
}

class _NfcEmulatorScreenState extends State<NfcEmulatorScreen> with SingleTickerProviderStateMixin {
  bool _isNfcAvailable = false;
  bool _isEmulating = false;
  String _statusMessage = 'Проверка NFC...';
  int _animationPhase = 0;
  Timer? _animationTimer;
  late AnimationController _pulseController;
  final NfcService _nfcService = NfcService();
  StreamSubscription? _nfcStatusSubscription;
  
  final List<String> _log = [];
  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    // Подписываемся на обновления статуса NFC
    _nfcStatusSubscription = _nfcService.statusStream.listen(_handleNfcStatusChange);
    
    _checkNfcAvailability();
  }

  @override
  void dispose() {
    _stopNfcEmulation();
    _animationTimer?.cancel();
    _pulseController.dispose();
    _logScrollController.dispose();
    _nfcStatusSubscription?.cancel();
    super.dispose();
  }
  
  void _handleNfcStatusChange(NfcStatus status) {
    setState(() {
      _isEmulating = status == NfcStatus.emulating;
      switch (status) {
        case NfcStatus.notStarted:
          _statusMessage = 'NFC готов. Нажмите кнопку для начала эмуляции.';
          _stopAnimation();
          break;
        case NfcStatus.starting:
          _statusMessage = 'Запуск эмуляции NFC...';
          _startAnimation();
          break;
        case NfcStatus.emulating:
          _statusMessage = 'Эмуляция активна. Поднесите телефон к NFC-терминалу.';
          _startAnimation();
          break;
        case NfcStatus.stopping:
          _statusMessage = 'Остановка эмуляции NFC...';
          break;
        case NfcStatus.error:
          _statusMessage = 'Произошла ошибка при работе с NFC';
          _stopAnimation();
          break;
      }
    });
    
    _addToLog('NFC статус: $status');
  }

  Future<void> _checkNfcAvailability() async {
    try {
      bool isAvailable = await _nfcService.isNfcAvailable();
      setState(() {
        _isNfcAvailable = isAvailable;
        _statusMessage = isAvailable
            ? 'NFC доступен. Нажмите кнопку для начала эмуляции.'
            : 'NFC недоступен на этом устройстве или отключен.';
      });
      
      _addToLog('Проверка NFC: ${isAvailable ? 'доступен' : 'недоступен'}');
    } catch (e) {
      setState(() {
        _isNfcAvailable = false;
        _statusMessage = 'Ошибка при проверке NFC: $e';
      });
      _addToLog('Ошибка: $e');
    }
  }

  Future<void> _startNfcEmulation() async {
    if (!_isNfcAvailable) return;

    // Вибрация для тактильной обратной связи
    HapticFeedback.mediumImpact();
    
    try {
      final success = await _nfcService.startCardEmulation(widget.card, context: context);
      
      if (!success) {
        _addToLog('Не удалось запустить эмуляцию карты');
      }
    } catch (e) {
      _addToLog('Ошибка запуска NFC: $e');
    }
  }

  Future<void> _stopNfcEmulation() async {
    try {
      await _nfcService.stopCardEmulation();
      
      // Вибрация для тактильной обратной связи
      HapticFeedback.lightImpact();
    } catch (e) {
      _addToLog('Ошибка остановки: $e');
    }
  }
  
  void _startAnimation() {
    _animationPhase = 0;
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _animationPhase = (_animationPhase + 1) % 3;
        });
      }
    });
  }
  
  void _stopAnimation() {
    _animationTimer?.cancel();
    _animationTimer = null;
    if (mounted) {
      setState(() {
        _animationPhase = 0;
      });
    }
  }
  
  void _addToLog(String message) {
    setState(() {
      _log.add('${DateTime.now().toIso8601String().substring(11, 19)} - $message');
      
      // Прокрутка к последней записи
      Future.delayed(const Duration(milliseconds: 50), () {
        if (_logScrollController.hasClients) {
          _logScrollController.animateTo(
            _logScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC Эмулятор'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Виджет карты
              Animate(
                effects: const [ScaleEffect(duration: Duration(milliseconds: 400))],
                child: CardWidget(
                  card: widget.card,
                  isDetailView: true,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // NFC статус и управление
              _buildNfcStatusCard(),
              
              const SizedBox(height: 24),
              
              // Лог активности
              _buildLogSection(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNfcStatusCard() {
    return Animate(
      effects: const [FadeEffect(duration: Duration(milliseconds: 600))],
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Иконка
              Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 80 + (_isEmulating ? 20 * _pulseController.value : 0),
                        height: 80 + (_isEmulating ? 20 * _pulseController.value : 0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isEmulating 
                              ? Colors.green.withOpacity(0.2 * _pulseController.value)
                              : Colors.grey.withOpacity(0.2),
                        ),
                      );
                    },
                  ),
                  Icon(
                    _isEmulating ? Icons.contactless : Icons.nfc,
                    size: 60,
                    color: _isEmulating ? Colors.green : Colors.grey,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Статусное сообщение
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: _isEmulating ? Colors.green : Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Кнопка управления
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isNfcAvailable
                      ? (_isEmulating ? _stopNfcEmulation : _startNfcEmulation)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEmulating ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isEmulating ? 'Остановить эмуляцию' : 'Начать эмуляцию',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              
              if (!_isNfcAvailable) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _checkNfcAvailability,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Проверить NFC снова'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLogSection() {
    return Animate(
      effects: const [FadeEffect(delay: Duration(milliseconds: 200), duration: Duration(milliseconds: 600))],
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Журнал активности',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.history),
                ],
              ),
              const Divider(),
              SizedBox(
                height: 150,
                child: _log.isEmpty 
                    ? const Center(
                        child: Text(
                          'Нет записей',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ) 
                    : ListView.builder(
                        controller: _logScrollController,
                        itemCount: _log.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              _log[index],
                              style: TextStyle(
                                fontSize: 12,
                                color: _log[index].contains('Ошибка') 
                                    ? Colors.red 
                                    : Colors.grey.shade300,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 