import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../models/card_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../widgets/card_widget.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({Key? key}) : super(key: key);

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardholderNameController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _cardNicknameController = TextEditingController();
  
  CardType _cardType = CardType.visa;
  bool _isDefault = false;
  Color _cardColor = const Color(0xFF1E1E1E);
  
  // Предустановленные цвета карт
  final List<Color> _presetColors = [
    const Color(0xFF1E1E1E), // Черный
    const Color(0xFF004D40), // Темно-зеленый
    const Color(0xFF0D47A1), // Темно-синий
    const Color(0xFF4A148C), // Пурпурный
    const Color(0xFF880E4F), // Бордовый
    const Color(0xFF3E2723), // Коричневый
    const Color(0xFF212121), // Темно-серый
    const Color(0xFF263238), // Сине-серый
  ];
  
  // Доступные банки
  final List<String> _banks = [
    'СБЕРБАНК', 
    'ТИНЬКОФФ', 
    'АЛЬФА-БАНК', 
    'ВТБ', 
    'ГАЗПРОМБАНК', 
    'РАЙФФАЙЗЕНБАНК',
    'ОТКРЫТИЕ',
    'РОКСКАРД'
  ];

  @override
  void initState() {
    super.initState();
    
    // Добавляем слушатель для автоопределения типа карты
    _cardNumberController.addListener(_updateCardType);
    
    // Выбираем случайный цвет по умолчанию
    _cardColor = _presetColors[Random().nextInt(_presetColors.length)];
  }

  @override
  void dispose() {
    _cardNumberController.removeListener(_updateCardType);
    _cardNumberController.dispose();
    _cardholderNameController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _bankNameController.dispose();
    _cardNicknameController.dispose();
    super.dispose();
  }

  void _updateCardType() {
    if (_cardNumberController.text.isNotEmpty) {
      setState(() {
        _cardType = CardModel.detectCardType(_cardNumberController.text);
      });
    }
  }

  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите номер карты';
    }
    
    final cleanNumber = value.replaceAll(RegExp(r'[\s-]'), '');
    
    if (cleanNumber.length < 15 || cleanNumber.length > 19) {
      return 'Номер карты должен содержать от 15 до 19 цифр';
    }
    
    if (!CardModel.isLuhnValid(cleanNumber)) {
      return 'Неверный номер карты';
    }
    
    return null;
  }

  String? _validateExpiryDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите срок действия';
    }
    
    final parts = value.split('/');
    if (parts.length != 2) {
      return 'Используйте формат ММ/ГГ';
    }
    
    try {
      final month = int.parse(parts[0]);
      final year = int.parse('20${parts[1]}');
      
      if (month < 1 || month > 12) {
        return 'Неверный месяц';
      }
      
      final now = DateTime.now();
      final expiryDate = DateTime(year, month);
      
      if (expiryDate.isBefore(DateTime(now.year, now.month))) {
        return 'Срок действия карты истек';
      }
    } catch (e) {
      return 'Неверный формат даты';
    }
    
    return null;
  }

  String? _validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите CVV/CVC код';
    }
    
    if (value.length < 3 || value.length > 4) {
      return 'CVV/CVC должен содержать 3 или 4 цифры';
    }
    
    return null;
  }

  void _saveCard() {
    if (_formKey.currentState?.validate() ?? false) {
      final random = Random();
      final id = DateTime.now().millisecondsSinceEpoch.toString() + random.nextInt(1000).toString();
      
      final cardModel = CardModel(
        id: id,
        cardNumber: _cardNumberController.text.replaceAll(' ', ''),
        cardholderName: _cardholderNameController.text.toUpperCase(),
        expiryDate: _expiryDateController.text,
        cvv: _cvvController.text,
        cardColor: _cardColor,
        bankName: _bankNameController.text.toUpperCase(),
        cardType: _cardType,
        isDefault: _isDefault,
        cardNickname: _cardNicknameController.text.isNotEmpty ? _cardNicknameController.text : null,
        lastUsed: null,
        usageCount: 0,
      );
      
      Provider.of<CardCollection>(context, listen: false).addCard(cardModel);
      
      // Вибрация для тактильной обратной связи
      HapticFeedback.mediumImpact();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Карта успешно добавлена!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавление карты'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Превью карты
                CardPreview(
                  cardNumber: _cardNumberController.text.isEmpty 
                      ? '•••• •••• •••• ••••' 
                      : _cardNumberController.text,
                  cardholderName: _cardholderNameController.text.isEmpty
                      ? 'ИМЯ ДЕРЖАТЕЛЯ'
                      : _cardholderNameController.text.toUpperCase(),
                  expiryDate: _expiryDateController.text.isEmpty
                      ? 'ММ/ГГ'
                      : _expiryDateController.text,
                  cardColor: _cardColor,
                  bankName: _bankNameController.text.isEmpty 
                      ? 'БАНК'
                      : _bankNameController.text.toUpperCase(),
                  cardType: _cardType,
                ),
                
                const SizedBox(height: 24),
                
                // Выбор цвета карты
                _buildColorSelector(),
                
                const SizedBox(height: 16),
                
                // Номер карты
                TextFormField(
                  controller: _cardNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Номер карты',
                    hintText: '1234 5678 9012 3456',
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _CardNumberFormatter(),
                  ],
                  validator: _validateCardNumber,
                ),
                
                const SizedBox(height: 16),
                
                // Имя держателя
                TextFormField(
                  controller: _cardholderNameController,
                  decoration: const InputDecoration(
                    labelText: 'Имя держателя карты',
                    hintText: 'IVAN IVANOV',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) => value!.isEmpty ? 'Введите имя держателя' : null,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Срок действия и CVV в одной строке
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _expiryDateController,
                        decoration: const InputDecoration(
                          labelText: 'Срок действия',
                          hintText: 'ММ/ГГ',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        keyboardType: TextInputType.number,
                        validator: _validateExpiryDate,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _ExpiryDateFormatter(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _cvvController,
                        decoration: const InputDecoration(
                          labelText: 'CVV/CVC',
                          hintText: '123',
                          prefixIcon: Icon(Icons.security),
                        ),
                        keyboardType: TextInputType.number,
                        validator: _validateCVV,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        obscureText: true,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Название банка (выпадающий список)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Банк',
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                  hint: const Text('Выберите банк'),
                  items: _banks.map((bank) => DropdownMenuItem(
                    value: bank,
                    child: Text(bank),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _bankNameController.text = value ?? '';
                    });
                  },
                  validator: (value) => value == null || value.isEmpty ? 'Выберите банк' : null,
                ),
                
                const SizedBox(height: 16),
                
                // Название карты (необязательно)
                TextFormField(
                  controller: _cardNicknameController,
                  decoration: const InputDecoration(
                    labelText: 'Название карты (необязательно)',
                    hintText: 'Например: Зарплатная',
                    prefixIcon: Icon(Icons.label),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Карта по умолчанию
                SwitchListTile(
                  title: const Text('Сделать картой по умолчанию'),
                  subtitle: const Text('Эта карта будет использоваться при эмуляции по умолчанию'),
                  value: _isDefault,
                  onChanged: (value) {
                    setState(() {
                      _isDefault = value;
                    });
                  },
                  secondary: const Icon(Icons.stars),
                ),
                
                const SizedBox(height: 24),
                
                // Кнопка сохранения
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveCard,
                    child: const Text(
                      'СОХРАНИТЬ КАРТУ',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Text(
            'Цвет карты',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _presetColors.length,
            itemBuilder: (context, index) {
              final color = _presetColors[index];
              final isSelected = _cardColor == color;
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _cardColor = color;
                    });
                  },
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class CardPreview extends StatelessWidget {
  final String cardNumber;
  final String cardholderName;
  final String expiryDate;
  final Color cardColor;
  final String bankName;
  final CardType cardType;

  const CardPreview({
    Key? key,
    required this.cardNumber,
    required this.cardholderName,
    required this.expiryDate,
    required this.cardColor,
    required this.bankName,
    required this.cardType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Animate(
      effects: const [FadeEffect(), ScaleEffect()],
      child: Container(
        width: double.infinity,
        height: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  bankName,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildCardTypeIcon(cardType),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              cardNumber.isEmpty ? '•••• •••• •••• ••••' : _formatCardNumber(cardNumber),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 18,
                letterSpacing: 2,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ДЕРЖАТЕЛЬ',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cardholderName,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'СРОК ДО',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expiryDate,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardTypeIcon(CardType type) {
    IconData iconData;
    
    switch (type) {
      case CardType.visa:
        iconData = Icons.payment;
        break;
      case CardType.mastercard:
        iconData = Icons.credit_card;
        break;
      case CardType.amex:
        iconData = Icons.credit_score;
        break;
      case CardType.discover:
        iconData = Icons.card_membership;
        break;
      default:
        iconData = Icons.credit_card;
    }
    
    return Icon(
      iconData,
      color: Colors.white,
      size: 32,
    );
  }

  String _formatCardNumber(String number) {
    if (number.length <= 4) return number;
    
    final formattedNumber = StringBuffer();
    for (int i = 0; i < number.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formattedNumber.write(' ');
      }
      formattedNumber.write(number[i]);
    }
    
    return formattedNumber.toString();
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }
    
    final string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    final text = newValue.text;
    
    if (text.length > 2 && !text.contains('/')) {
      final month = text.substring(0, 2);
      final year = text.substring(2);
      final formatted = '$month/$year';
      
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    
    return newValue;
  }
} 