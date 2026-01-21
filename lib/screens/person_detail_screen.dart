import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/person.dart';
import '../models/id_card.dart';
import 'card_form_screen.dart';

class PersonDetailScreen extends StatelessWidget {
  final Person person;

  const PersonDetailScreen({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(person.name),
      ),
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          final cards = dataProvider.getCardsForPerson(person.id);

          if (cards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.credit_card,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No cards added yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add a card',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              // Responsive layout
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
                    return _CardTile(card: cards[index]);
                  },
                );
              } else {
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    return _CardTile(card: cards[index]);
                  },
                );
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CardFormScreen(personId: person.id),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CardTile extends StatefulWidget {
  final IdCard card;

  const _CardTile({required this.card});

  @override
  State<_CardTile> createState() => _CardTileState();
}

class _CardTileState extends State<_CardTile> {
  bool _isRevealed = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          setState(() {
            _isRevealed = !_isRevealed;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
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
                                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
