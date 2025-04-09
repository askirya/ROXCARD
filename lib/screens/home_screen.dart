import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/card_model.dart';
import '../widgets/card_widget.dart';
import 'add_card_screen.dart';
import 'nfc_emulator_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<CardModel> _filterCards(List<CardModel> cards) {
    if (_searchQuery.isEmpty) return cards;
    
    return cards.where((card) {
      final bankName = card.bankName.toLowerCase();
      final cardholderName = card.cardholderName.toLowerCase();
      final cardNumber = card.cardNumber;
      final nickname = card.cardNickname?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      
      return bankName.contains(query) || 
             cardholderName.contains(query) || 
             cardNumber.contains(query) ||
             nickname.contains(query);
    }).toList();
  }
  
  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }
  
  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _navigateToCardEmulation(BuildContext context, CardModel card) {
    // Вибрация для тактильной обратной связи
    HapticFeedback.selectionClick();
    
    // Обновляем счетчик использования
    Provider.of<CardCollection>(context, listen: false).incrementUsageCount(card.id);
    
    // Переходим на экран эмуляции
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NfcEmulatorScreen(card: card),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Поиск карт...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : const Text('ROXCARD'),
        centerTitle: !_isSearching,
        elevation: 0,
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _stopSearch,
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _startSearch,
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'about') {
                _showAboutDialog();
              } else if (value == 'settings') {
                _showSettingsDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Настройки'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('О приложении'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: !_isSearching
            ? TabBar(
                controller: _tabController,
                indicatorColor: Theme.of(context).colorScheme.secondary,
                tabs: const [
                  Tab(text: 'Все карты'),
                  Tab(text: 'Избранные'),
                ],
              )
            : null,
      ),
      body: Consumer<CardCollection>(
        builder: (context, cardCollection, child) {
          final allCards = cardCollection.cards;
          final filteredCards = _filterCards(allCards);
          final favoriteCards = filteredCards.where((card) => card.isDefault).toList();
          
          if (allCards.isEmpty) {
            return _buildEmptyState();
          }
          
          if (_isSearching && filteredCards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_off,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Карты не найдены',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Попробуйте изменить поисковый запрос',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }
          
          if (_isSearching) {
            return _buildCardList(filteredCards);
          }
          
          return TabBarView(
            controller: _tabController,
            children: [
              _buildCardList(filteredCards),
              favoriteCards.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.star_border,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Нет избранных карт',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Сделайте карту избранной, чтобы она отображалась здесь',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : _buildCardList(favoriteCards),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddCardScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.credit_card_off,
            size: 100,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 24),
          Text(
            'Нет добавленных карт',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'Добавьте банковские карты для эмуляции через NFC',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddCardScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Добавить карту'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    ).animate().fade(duration: const Duration(milliseconds: 600));
  }
  
  Widget _buildCardList(List<CardModel> cards) {
    if (cards.isEmpty) {
      return const Center(
        child: Text('Нет карт для отображения'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Slidable(
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) {
                    _toggleFavorite(card);
                  },
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  icon: card.isDefault ? Icons.star : Icons.star_border,
                  label: card.isDefault ? 'Убрать из избранного' : 'В избранное',
                ),
                SlidableAction(
                  onPressed: (context) {
                    _confirmCardDeletion(card);
                  },
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: 'Удалить',
                ),
              ],
            ),
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: () => _navigateToCardEmulation(context, card),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Column(
                    children: [
                      CardWidget(card: card),
                      if (card.lastUsed != null) _buildLastUsedInfo(card),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ).animate().fadeIn(duration: const Duration(milliseconds: 300)).slideY(
          begin: 0.1,
          end: 0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      },
    );
  }
  
  Widget _buildLastUsedInfo(CardModel card) {
    final lastUsed = card.lastUsed;
    if (lastUsed == null) return const SizedBox.shrink();
    
    try {
      final dateTime = DateTime.parse(lastUsed);
      final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  'Последнее использование: $formattedDate',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            if (card.usageCount != null && card.usageCount! > 0)
              Text(
                'Использований: ${card.usageCount}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }
  
  void _toggleFavorite(CardModel card) {
    Provider.of<CardCollection>(context, listen: false).updateCard(
      card.id,
      isDefault: !card.isDefault,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          card.isDefault
              ? 'Карта удалена из избранного'
              : 'Карта добавлена в избранное',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _confirmCardDeletion(CardModel card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить карту?'),
        content: Text(
          'Вы уверены, что хотите удалить карту ${card.cardNickname ?? card.bankName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<CardCollection>(context, listen: false).removeCard(card.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Карта удалена'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
  
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: 'ROXCARD',
        applicationVersion: '1.0.0',
        applicationIcon: const Icon(
          Icons.credit_card,
          size: 48,
          color: Colors.blue,
        ),
        children: [
          const Text(
            'ROXCARD - приложение для эмуляции банковских карт через NFC.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            '© 2023 ROXCARD Team',
            style: TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Настройки'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: const Text('Удалить все карты'),
              subtitle: const Text('Это действие нельзя отменить'),
              onTap: () {
                Navigator.pop(context);
                _confirmClearAllCards();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Безопасность'),
              subtitle: const Text('Настройки шифрования и защиты данных'),
              onTap: () {
                Navigator.pop(context);
                // Здесь можно добавить переход на экран настроек безопасности
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
  
  void _confirmClearAllCards() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить все карты?'),
        content: const Text(
          'Вы уверены, что хотите удалить все карты? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<CardCollection>(context, listen: false).clearAll();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Все карты удалены'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
} 