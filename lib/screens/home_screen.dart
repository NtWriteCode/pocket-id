import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/person.dart';
import '../models/id_card.dart';
import 'card_form_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedPersonId;
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        if (dataProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final people = dataProvider.people;
        
        // Auto-select first person if none selected
        if (_selectedPersonId == null && people.isNotEmpty) {
          _selectedPersonId = people.first.id;
        }
        
        // Clear selection if person was deleted
        if (_selectedPersonId != null && 
            !people.any((p) => p.id == _selectedPersonId)) {
          _selectedPersonId = people.isNotEmpty ? people.first.id : null;
        }

        final selectedPerson = people.firstWhere(
          (p) => p.id == _selectedPersonId,
          orElse: () => people.isNotEmpty ? people.first : Person(id: '', name: '', createdAt: DateTime.now()),
        );

        return Scaffold(
          appBar: AppBar(
            leading: _isSearching
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _stopSearch,
                  )
                : null,
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search cards...',
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  )
                : Text(people.isEmpty ? 'Pocket ID' : selectedPerson.name),
            actions: _isSearching
                ? [
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      ),
                  ]
                : [
                    if (people.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _startSearch,
                      ),
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                      },
                    ),
                  ],
          ),
          drawer: _buildPeopleDrawer(context, people, dataProvider),
          body: people.isEmpty ? _buildEmptyState(context) : _buildCardsList(context, selectedPerson, dataProvider),
          floatingActionButton: people.isEmpty 
              ? null 
              : FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CardFormScreen(personId: _selectedPersonId!),
                      ),
                    );
                  },
                  child: const Icon(Icons.add),
                ),
        );
      },
    );
  }

  Widget _buildPeopleDrawer(BuildContext context, List<Person> people, DataProvider dataProvider) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.people,
                    size: 48,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'People',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: people.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No people added yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: people.length,
                    itemBuilder: (context, index) {
                      final person = people[index];
                      final cardCount = dataProvider.getCardCount(person.id);
                      final isSelected = person.id == _selectedPersonId;

                      return ListTile(
                        selected: isSelected,
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(person.name),
                        subtitle: Text('$cardCount ${cardCount == 1 ? 'card' : 'cards'}'),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditPersonDialog(context, person);
                            } else if (value == 'delete') {
                              _showDeletePersonDialog(context, person, cardCount);
                            }
                          },
                        ),
                        onTap: () {
                          setState(() {
                            _selectedPersonId = person.id;
                          });
                          Navigator.pop(context); // Close drawer
                        },
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Add Person'),
            onTap: () {
              Navigator.pop(context); // Close drawer first
              _showAddPersonDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Builder(
      builder: (scaffoldContext) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No people added yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Open the drawer and add someone',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Scaffold.of(scaffoldContext).openDrawer();
              },
              icon: const Icon(Icons.menu),
              label: const Text('Open Drawer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsList(BuildContext context, Person person, DataProvider dataProvider) {
    final cards = dataProvider.getFilteredCardsForPerson(person.id, searchQuery: _searchQuery.isEmpty ? null : _searchQuery);

    if (cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isEmpty ? Icons.credit_card : Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No cards yet' : 'No cards found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty 
                  ? 'Tap the + button to add a card'
                  : 'Try a different search term',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        
        if (isWide) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: constraints.maxWidth > 900 ? 2 : 1,
              childAspectRatio: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              return _CardTile(card: cards[index], dataProvider: dataProvider);
            },
          );
        } else {
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              return _CardTile(card: cards[index], dataProvider: dataProvider);
            },
          );
        }
      },
    );
  }

  void _showAddPersonDialog(BuildContext context) {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Person'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Enter person\'s name',
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (value) async {
            if (value.isNotEmpty) {
              Navigator.pop(context);
              final person = await context.read<DataProvider>().addPerson(value);
              setState(() {
                _selectedPersonId = person.id;
              });
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context);
                final person = await context.read<DataProvider>().addPerson(name);
                setState(() {
                  _selectedPersonId = person.id;
                });
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditPersonDialog(BuildContext context, Person person) {
    final nameController = TextEditingController(text: person.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Person'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Name',
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              Navigator.pop(context);
              context.read<DataProvider>().updatePerson(person.id, value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context);
                context.read<DataProvider>().updatePerson(person.id, name);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeletePersonDialog(BuildContext context, Person person, int cardCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Person'),
        content: Text(
          cardCount > 0
              ? 'Are you sure you want to delete ${person.name} and all their $cardCount ${cardCount == 1 ? 'card' : 'cards'}?'
              : 'Are you sure you want to delete ${person.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<DataProvider>().deletePerson(person.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CardTile extends StatefulWidget {
  final IdCard card;
  final DataProvider dataProvider;

  const _CardTile({required this.card, required this.dataProvider});

  @override
  State<_CardTile> createState() => _CardTileState();
}

class _CardTileState extends State<_CardTile> {
  bool _isRevealed = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: widget.card.isExpired 
          ? Colors.red.withValues(alpha: 0.1)
          : widget.card.isExpiringSoon
              ? Colors.orange.withValues(alpha: 0.1)
              : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _isRevealed = !_isRevealed;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Pin indicator
                  if (widget.card.isPinned)
                    Icon(
                      Icons.push_pin,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  if (widget.card.isPinned) const SizedBox(width: 8),
                  
                  // Emoji or default icon
                  if (widget.card.emoji != null && widget.card.emoji!.isNotEmpty)
                    Text(
                      widget.card.emoji!,
                      style: const TextStyle(fontSize: 32),
                    )
                  else
                    Icon(
                      Icons.credit_card,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.card.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _isRevealed
                                    ? widget.card.idNumber
                                    : widget.card.maskedIdNumber,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontFamily: 'monospace',
                                      color: _isRevealed
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_isRevealed)
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20),
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: widget.card.idNumber),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('ID copied to clipboard'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                tooltip: 'Copy to clipboard',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Pin button
                  IconButton(
                    icon: Icon(
                      widget.card.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: widget.card.isPinned ? Theme.of(context).colorScheme.primary : null,
                    ),
                    onPressed: () {
                      widget.dataProvider.toggleCardPin(widget.card.id);
                    },
                    tooltip: widget.card.isPinned ? 'Unpin' : 'Pin',
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CardFormScreen(
                              personId: widget.card.personId,
                              card: widget.card,
                            ),
                          ),
                        );
                      } else if (value == 'delete') {
                        _showDeleteCardDialog(context);
                      }
                    },
                  ),
                ],
              ),
              // Expiration warning
              if (widget.card.expirationDate != null && (widget.card.isExpired || widget.card.isExpiringSoon))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        widget.card.isExpired ? Icons.error : Icons.warning,
                        size: 16,
                        color: widget.card.isExpired ? Colors.red : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.card.isExpired
                              ? 'Expired ${widget.card.daysUntilExpiration!.abs()} days ago'
                              : 'Expires in ${widget.card.daysUntilExpiration} days',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: widget.card.isExpired ? Colors.red : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteCardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Card'),
        content: Text(
          'Are you sure you want to delete ${widget.card.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<DataProvider>().deleteCard(widget.card.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
