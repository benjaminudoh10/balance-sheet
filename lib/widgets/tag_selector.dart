import 'package:balance_sheet/controllers/tag_controller.dart';
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/models/tag.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/utils/app_haptics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TagSelector extends StatefulWidget {
  final Rx<Transaction> transaction;

  const TagSelector({
    super.key,
    required this.transaction,
  });

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  final TagController _tagController = Get.find();
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDeleteTag(BuildContext context, Tag tag) {
    final AppPalette p = AppPalette.of(context);
    AppHaptics.heavy();
    Get.dialog(
      AlertDialog(
        backgroundColor: p.surfaceElevated,
        title: Text('Delete Tag?',
            style:
                TextStyle(color: p.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
            'This will permanently remove the tag "${tag.name}" and unlink it from all transactions.',
            style: TextStyle(color: p.textSecondary)),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: p.border)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: p.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              await _tagController.deleteTag(tag);

              // If the deleted tag was on the current transaction, remove it from the Rx state
              final tx = widget.transaction.value;
              if (tx.tags.any((t) => t.id == tag.id)) {
                final List<Tag> newTags = List.from(tx.tags);
                newTags.removeWhere((t) => t.id == tag.id);
                widget.transaction.value = tx.copyWith(tags: newTags);
              }

              Get.back();
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: p.surfaceElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: p.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Manage Tags',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: p.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _SearchInput(
            controller: _searchController,
            onChanged: (v) => _searchQuery.value = v,
          ),
          const SizedBox(height: 16),
          Flexible(
            child: Obx(() {
              final tx = widget.transaction.value;
              final query = _searchQuery.value.trim().toLowerCase();
              final filteredTags = _tagController.allTags.where((t) {
                return t.name.toLowerCase().contains(query);
              }).toList();

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_tagController.allTags.isEmpty &&
                        !_tagController.isLoading.value)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_offer_outlined,
                                size: 48,
                                color: p.textSecondary.withValues(alpha: 0.2)),
                            const SizedBox(height: 16),
                            Text(
                              'No tags created yet.',
                              style: TextStyle(color: p.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Type in the search box to create your first tag.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                    color:
                                        p.textSecondary.withValues(alpha: 0.7),
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    if (_tagController.allTags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, left: 4),
                        child: Text(
                          'Long press a tag to delete it',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall!
                              .copyWith(
                                color: p.textSecondary.withValues(alpha: 0.6),
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...filteredTags.map((tag) {
                          final bool isSelected =
                              tx.tags.any((t) => t.id == tag.id);
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onLongPress: () => _confirmDeleteTag(context, tag),
                            child: FilterChip(
                              label: Text(tag.name),
                              selected: isSelected,
                              onSelected: (_) async {
                                AppHaptics.light();
                                await _tagController.toggleTagForTransaction(
                                    tx, tag);

                                // Update the Rx transaction in the widget
                                final List<Tag> newTags = List.from(tx.tags);
                                if (isSelected) {
                                  newTags.removeWhere((t) => t.id == tag.id);
                                } else {
                                  newTags.add(tag);
                                }
                                widget.transaction.value =
                                    tx.copyWith(tags: newTags);
                              },
                              selectedColor: p.mint.withValues(alpha: 0.2),
                              checkmarkColor: p.mint,
                              labelStyle: TextStyle(
                                color: isSelected ? p.mint : p.textPrimary,
                                fontSize: 13,
                              ),
                              backgroundColor: p.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: isSelected ? p.mint : p.border,
                                ),
                              ),
                            ),
                          );
                        }),
                        if (query.isNotEmpty &&
                            !_tagController.allTags
                                .any((t) => t.name.toLowerCase() == query))
                          ActionChip(
                            label: Text('Create "$query"'),
                            avatar: const Icon(Icons.add, size: 16),
                            onPressed: () async {
                              AppHaptics.medium();
                              final newTag =
                                  await _tagController.createTag(query);
                              if (newTag != null) {
                                await _tagController.toggleTagForTransaction(
                                    tx, newTag);

                                final List<Tag> newTags = List.from(tx.tags);
                                newTags.add(newTag);
                                widget.transaction.value =
                                    tx.copyWith(tags: newTags);

                                _searchController.clear();
                                _searchQuery.value = '';
                              }
                            },
                            backgroundColor: p.surface,
                            labelStyle: TextStyle(color: p.mint, fontSize: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: p.mint),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SearchInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const _SearchInput({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: Theme.of(context)
          .textTheme
          .bodyMedium!
          .copyWith(color: p.textPrimary),
      decoration: InputDecoration(
        hintText: 'Search or create tag...',
        hintStyle: TextStyle(color: p.textSecondary.withValues(alpha: 0.6)),
        prefixIcon:
            Icon(Icons.search_rounded, color: p.textSecondary, size: 20),
        filled: true,
        fillColor: p.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: p.mint),
        ),
      ),
    );
  }
}

extension TransactionCopyWith on Transaction {
  Transaction copyWith({
    int? id,
    String? description,
    TransactionType? type,
    int? amount,
    DateTime? date,
    String? category,
    int? contactId,
    bool? entryIsFcy,
    int? entryAmountMinor,
    DateTime? deletedAt,
    List<Tag>? tags,
  }) {
    return Transaction(
      id: id ?? this.id,
      description: description ?? this.description,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      contactId: contactId ?? this.contactId,
      entryIsFcy: entryIsFcy ?? this.entryIsFcy,
      entryAmountMinor: entryAmountMinor ?? this.entryAmountMinor,
      deletedAt: deletedAt ?? this.deletedAt,
      tags: tags ?? this.tags,
    );
  }
}
