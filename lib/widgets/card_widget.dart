import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/card_model.dart';

class CardWidget extends StatelessWidget {
  final CardModel card;
  final bool isDetailView;
  final VoidCallback? onTap;

  const CardWidget({
    Key? key,
    required this.card,
    this.isDetailView = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: isDetailView ? 220 : 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: card.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: card.cardColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              card.cardColor,
              card.cardColor.withOpacity(0.8),
              HSLColor.fromColor(card.cardColor)
                  .withLightness((HSLColor.fromColor(card.cardColor).lightness + 0.1).clamp(0.0, 1.0))
                  .withSaturation((HSLColor.fromColor(card.cardColor).saturation - 0.1).clamp(0.0, 1.0))
                  .toColor(),
            ],
          ),
        ),
        child: Stack(
          children: [
            if (card.isDefault)
              const Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.bankName,
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (card.cardNickname != null)
                          Text(
                            card.cardNickname!,
                            style: GoogleFonts.montserrat(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    _buildCardTypeIcon(card.cardType),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  _formatCardNumber(card.cardNumber),
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
                          card.cardholderName,
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
                          card.expiryDate,
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
            
            // Водяной знак платежной системы
            Positioned(
              bottom: 20,
              right: 0,
              child: Opacity(
                opacity: 0.2,
                child: _buildCardTypeBrandLogo(card.cardType),
              ),
            ),
            
            // NFC индикатор
            Positioned(
              top: 50,
              right: 10,
              child: Icon(
                Icons.contactless,
                color: Colors.white.withOpacity(0.5),
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardTypeIcon(CardType cardType) {
    IconData iconData;
    Color iconColor = Colors.white;
    
    switch (cardType) {
      case CardType.visa:
        return const Icon(
          Icons.payment,
          color: Colors.white,
          size: 32,
        );
      case CardType.mastercard:
        return Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
              ),
            ),
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(left: 5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber,
              ),
            ),
          ],
        );
      case CardType.amex:
        return const Icon(
          Icons.credit_score,
          color: Colors.white,
          size: 32,
        );
      case CardType.discover:
        return const Icon(
          Icons.card_membership,
          color: Colors.white,
          size: 32,
        );
      default:
        return const Icon(
          Icons.credit_card,
          color: Colors.white,
          size: 32,
        );
    }
  }
  
  Widget _buildCardTypeBrandLogo(CardType cardType) {
    switch (cardType) {
      case CardType.visa:
        return const Text(
          'VISA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        );
      case CardType.mastercard:
        return const Text(
          'MASTERCARD',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        );
      case CardType.amex:
        return const Text(
          'AMEX',
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        );
      case CardType.discover:
        return const Text(
          'DISCOVER',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        );
      default:
        return const Text(
          'CARD',
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        );
    }
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