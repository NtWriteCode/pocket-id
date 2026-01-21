import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/id_card.dart';
import '../widgets/emoji_picker.dart';

class CardFormScreen extends StatefulWidget {
  final String personId;
  final IdCard? card; // null for new card, populated for edit

  const CardFormScreen({
    super.key,
    required this.personId,
    this.card,
  });

  @override
  State<CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends State<CardFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _idNumberController;
  String? _selectedEmoji;
  DateTime? _expirationDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.card?.name ?? '');
    _idNumberController = TextEditingController(text: widget.card?.idNumber ?? '');
    _selectedEmoji = widget.card?.emoji;
    _expirationDate = widget.card?.expirationDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.card != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Card' : 'Add Card'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Emoji selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Icon (optional)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...EmojiPicker.commonEmojis.map((emoji) {
                          final isSelected = _selectedEmoji == emoji;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedEmoji = isSelected ? null : emoji;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primaryContainer
                                    : Theme.of(context).colorScheme.surface,
                              ),
                              child: Center(
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                            ),
                          );
                        }),
                        // Custom emoji button
                        InkWell(
                          onTap: _showCustomEmojiDialog,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline,
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.add,
                                size: 28,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Name field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Card Name',
                hintText: 'e.g., Driver\'s License, Passport',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // ID Number field
            TextField(
              controller: _idNumberController,
              decoration: const InputDecoration(
                labelText: 'ID Number',
                hintText: 'Enter the identification number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),

            // Expiration Date field
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _expirationDate ?? DateTime.now().add(const Duration(days: 365)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
                );
                if (date != null) {
                  setState(() {
                    _expirationDate = date;
                  });
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Expiration Date (optional)',
                  hintText: 'Tap to select date',
                  border: const OutlineInputBorder(),
                  suffixIcon: _expirationDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _expirationDate = null;
                            });
                          },
                        )
                      : const Icon(Icons.calendar_today),
                ),
                child: Text(
                  _expirationDate != null
                      ? '${_expirationDate!.day}/${_expirationDate!.month}/${_expirationDate!.year}'
                      : 'No expiration date',
                  style: _expirationDate != null
                      ? null
                      : Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            FilledButton(
              onPressed: _isSaving ? null : _saveCard,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEdit ? 'Save Changes' : 'Add Card'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomEmojiDialog() {
    final emojiController = TextEditingController(text: _selectedEmoji ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Custom Emoji'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter any emoji:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emojiController,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 48),
                decoration: const InputDecoration(
                  hintText: '😀',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(16),
                ),
                maxLength: 2, // Allow for some multi-codepoint emojis
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    Navigator.pop(context);
                    setState(() {
                      _selectedEmoji = value.trim();
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Tip: Copy an emoji from your device\'s emoji keyboard',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final emoji = emojiController.text.trim();
              if (emoji.isNotEmpty) {
                Navigator.pop(context);
                setState(() {
                  _selectedEmoji = emoji;
                });
              }
            },
            child: const Text('Use This'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCard() async {
    final name = _nameController.text.trim();
    final idNumber = _idNumberController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a card name')),
      );
      return;
    }

    if (idNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an ID number')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final dataProvider = context.read<DataProvider>();

      if (widget.card != null) {
        // Edit existing card
        await dataProvider.updateCard(
          id: widget.card!.id,
          name: name,
          idNumber: idNumber,
          emoji: _selectedEmoji,
          expirationDate: _expirationDate,
        );
      } else {
        // Add new card
        await dataProvider.addCard(
          personId: widget.personId,
          name: name,
          idNumber: idNumber,
          emoji: _selectedEmoji,
          expirationDate: _expirationDate,
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving card: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
