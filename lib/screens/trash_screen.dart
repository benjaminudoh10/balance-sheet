import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/constants/app.dart';
import 'package:balance_sheet/constants/category.dart';
import 'package:balance_sheet/controllers/app_controller.dart';
import 'package:balance_sheet/controllers/transaction_controller.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/utils/app_haptics.dart';
import 'package:balance_sheet/utils.dart';
import 'package:balance_sheet/widgets/midnight_grid_painter.dart';
import 'package:balance_sheet/widgets/slidable_peek_hint.dart';
import 'package:balance_sheet/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class TrashView extends StatefulWidget {
  const TrashView({super.key});

  @override
  State<TrashView> createState() => _TrashViewState();
}

class _TrashViewState extends State<TrashView> {
  final TransactionController _transactionController = Get.find();
  final AppController _appController = Get.find();
  final RxBool _loading = true.obs;
  final RxBool _isMultiSelectMode = false.obs;
  final RxSet<int> _selectedTransactionIds = <int>{}.obs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _loading.value = true;
    await _transactionController.loadTrashedTransactions();
    _loading.value = false;
  }

  void _toggleMultiSelectMode() {
    _isMultiSelectMode.value = !_isMultiSelectMode.value;
    if (!_isMultiSelectMode.value) {
      _selectedTransactionIds.clear();
    }
  }

  void _toggleSelection(int transactionId) {
    if (_selectedTransactionIds.contains(transactionId)) {
      _selectedTransactionIds.remove(transactionId);
      if (_selectedTransactionIds.isEmpty) {
        _isMultiSelectMode.value = false;
      }
    } else {
      _selectedTransactionIds.add(transactionId);
    }
    AppHaptics.selection();
  }

  void _selectAllTransactions(List<Transaction> transactions) {
    if (_selectedTransactionIds.length == transactions.length) {
      _selectedTransactionIds.clear();
      _isMultiSelectMode.value =
          false; // Exit multi-select if all were deselected
    } else {
      _selectedTransactionIds.clear();
      for (final transaction in transactions) {
        _selectedTransactionIds.add(transaction.id);
      }
      _isMultiSelectMode.value = true; // Ensure multi-select mode is on
    }
    AppHaptics.selection();
  }

  void _confirmEmptyTrash() {
    AppHaptics.medium();
    final AppPalette p = AppPalette.of(context);
    Get.dialog(
      AlertDialog(
        backgroundColor: p.surfaceElevated,
        title: Text('Empty Trash?',
            style:
                TextStyle(color: p.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'All items in the trash will be permanently deleted. This action cannot be undone.',
          style: TextStyle(color: p.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: p.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _transactionController.emptyTrash();
              _selectedTransactionIds.clear();
              _isMultiSelectMode.value = false;
            },
            child: Text('Empty Trash',
                style: TextStyle(color: p.coral, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmRestoreAll() {
    final List<Transaction> trashed =
        _transactionController.trashedTransactions;
    if (trashed.isEmpty) return;

    AppHaptics.medium();
    final AppPalette p = AppPalette.of(context);
    Get.dialog(
      AlertDialog(
        backgroundColor: p.surfaceElevated,
        title: Text('Restore All Items?',
            style:
                TextStyle(color: p.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'Restore all items back to your transaction list.',
          style: TextStyle(color: p.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: p.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _transactionController
                  .bulkRestoreTransactions(trashed.map((t) => t.id).toList());
              _selectedTransactionIds.clear();
              _isMultiSelectMode.value = false;
            },
            child: Text('Restore All',
                style: TextStyle(color: p.mint, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmBulkRestore({List<int>? ids}) {
    final List<int> targetIds = ids ?? _selectedTransactionIds.toList();
    if (targetIds.isEmpty) return;

    AppHaptics.medium();
    final AppPalette p = AppPalette.of(context);
    final bool isSingle = targetIds.length == 1;

    Get.dialog(
      AlertDialog(
        backgroundColor: p.surfaceElevated,
        title: Text(isSingle ? 'Restore Item?' : 'Restore Items?',
            style:
                TextStyle(color: p.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          isSingle
              ? 'Restore this item back to your transaction list.'
              : 'Restore selected items back to your transaction list.',
          style: TextStyle(color: p.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: p.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _transactionController.bulkRestoreTransactions(targetIds);
              if (ids == null) {
                _selectedTransactionIds.clear();
                _isMultiSelectMode.value = false;
              }
            },
            child: Text('Restore',
                style: TextStyle(color: p.mint, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmBulkDelete({List<int>? ids}) {
    final List<int> targetIds = ids ?? _selectedTransactionIds.toList();
    if (targetIds.isEmpty) return;

    AppHaptics.medium();
    final AppPalette p = AppPalette.of(context);
    final bool isSingle = targetIds.length == 1;

    Get.dialog(
      AlertDialog(
        backgroundColor: p.surfaceElevated,
        title: Text(
            isSingle ? 'Permanently Delete Item?' : 'Permanently Delete Items?',
            style:
                TextStyle(color: p.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          isSingle
              ? 'This item will be permanently deleted and cannot be recovered.'
              : 'Selected items will be permanently deleted and cannot be recovered.',
          style: TextStyle(color: p.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: p.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _transactionController
                  .bulkPermanentlyDeleteTransactions(targetIds);
              if (ids == null) {
                _selectedTransactionIds.clear();
                _isMultiSelectMode.value = false;
              }
            },
            child: Text('Delete',
                style: TextStyle(color: p.coral, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final TextTheme tt = Theme.of(context).textTheme;

    return Obx(
      () => PopScope(
        canPop: !_isMultiSelectMode.value,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _isMultiSelectMode.value) {
            AppHaptics.light();
            _toggleMultiSelectMode();
            _selectedTransactionIds.clear();
          }
        },
        child: Scaffold(
          backgroundColor: p.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            systemOverlayStyle: p.systemUiOverlayStyle,
            leading: Obx(() => _isMultiSelectMode.value
                ? IconButton(
                    onPressed: () {
                      AppHaptics.light();
                      _toggleMultiSelectMode();
                      _selectedTransactionIds.clear();
                    },
                    icon: Icon(Icons.close_rounded,
                        color: p.textPrimary, size: 24),
                    tooltip: 'Cancel Selection',
                  )
                : IconButton(
                    onPressed: () {
                      AppHaptics.light();
                      Get.back();
                    },
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: p.textPrimary, size: 20),
                    tooltip: 'Back',
                  )),
            title: Obx(() => _isMultiSelectMode.value
                ? Text(
                    '${_selectedTransactionIds.length} selected',
                    style: tt.headlineSmall!.copyWith(
                      color: p.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  )
                : Text(
                    'Trash',
                    style: tt.headlineSmall!.copyWith(
                      color: p.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  )),
            actions: [
              Obx(() {
                final List<Transaction> trashed =
                    _transactionController.trashedTransactions;
                final bool allSelected =
                    _selectedTransactionIds.length == trashed.length &&
                        trashed.isNotEmpty;

                if (_isMultiSelectMode.value) {
                  return Row(
                    children: [
                      IconButton(
                        onPressed: () => _selectAllTransactions(trashed),
                        icon: Icon(
                          allSelected
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          color: p.mint,
                        ),
                        tooltip: allSelected ? 'Deselect all' : 'Select all',
                      ),
                      if (_selectedTransactionIds.isNotEmpty) ...[
                        IconButton(
                          onPressed: () => _confirmBulkRestore(),
                          icon: Icon(Icons.restore_rounded, color: p.mint),
                          tooltip: 'Restore Selected',
                        ),
                        IconButton(
                          onPressed: () => _confirmBulkDelete(),
                          icon: Icon(Icons.delete_forever_outlined,
                              color: p.coral),
                          tooltip: 'Delete Selected',
                        ),
                      ] else if (trashed.isNotEmpty) ...[
                        // Only show empty trash if no items are selected but multi-select is active
                        IconButton(
                          onPressed: _confirmEmptyTrash,
                          icon:
                              Icon(Icons.delete_sweep_outlined, color: p.coral),
                          tooltip: 'Empty Trash',
                        ),
                      ]
                    ],
                  );
                } else {
                  // Standard AppBar actions when not in multi-select mode
                  return trashed.isNotEmpty
                      ? Row(
                          children: [
                            IconButton(
                              onPressed: _confirmRestoreAll,
                              icon: Icon(Icons.restore_rounded, color: p.mint),
                              tooltip: 'Restore All',
                            ),
                            IconButton(
                              onPressed: _confirmEmptyTrash,
                              icon: Icon(Icons.delete_sweep_outlined,
                                  color: p.coral),
                              tooltip: 'Empty Trash',
                            ),
                          ],
                        )
                      : const SizedBox.shrink();
                }
              }),
            ],
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: MidnightGridPainter(
                    heightFraction: 1.0,
                    gridLineColor: p.gridLine,
                  ),
                ),
              ),
              Obx(() {
                final List<Transaction> trashed =
                    _transactionController.trashedTransactions;
                final bool isLoading = _loading.value;

                if (isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (trashed.isEmpty) {
                  return Center(
                    child: EmptyState(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 64,
                        color: p.textSecondary.withValues(alpha: 0.2),
                      ),
                      primaryText: Text(
                        'Trash is empty',
                        style: tt.titleLarge!.copyWith(
                          color: p.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      secondaryText: Text(
                        _appController.useTrash.value
                            ? 'Deleted transactions will appear here.'
                            : 'Trash is disabled. Deleted transactions will be permanently removed.',
                        style: tt.bodyMedium!.copyWith(color: p.textSecondary),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: trashed.length,
                  itemBuilder: (context, index) {
                    final Transaction t = trashed[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Obx(() {
                        return _TrashTransactionRow(
                          transaction: t,
                          isSelected: _selectedTransactionIds.contains(t.id),
                          applyPeek: index == 0,
                          isMultiSelectMode: _isMultiSelectMode.value,
                          onTap: () {
                            if (_isMultiSelectMode.value) {
                              AppHaptics.selection();
                              _toggleSelection(t.id);
                            }
                          },
                          onLongPress: () {
                            AppHaptics.heavy();
                            if (!_isMultiSelectMode.value) {
                              _toggleMultiSelectMode();
                            }
                            _toggleSelection(t.id);
                          },
                          onRestore: () => _confirmBulkRestore(ids: [t.id]),
                          onDelete: () => _confirmBulkDelete(ids: [t.id]),
                        );
                      }),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrashTransactionRow extends StatelessWidget {
  const _TrashTransactionRow({
    required this.transaction,
    required this.isSelected,
    required this.applyPeek,
    required this.isMultiSelectMode,
    required this.onTap,
    required this.onLongPress,
    required this.onRestore,
    required this.onDelete,
  });

  final Transaction transaction;
  final bool isSelected;
  final bool applyPeek;
  final bool isMultiSelectMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final TextTheme tt = Theme.of(context).textTheme;
    final AppController appController = Get.find();

    // Pure grayscale aesthetic for trashed items
    final Color unselectedAccent = p.textSecondary.withValues(alpha: 0.3);
    final Color selectedAccent = p.textPrimary.withValues(alpha: 0.7);
    final Color accent = isSelected ? selectedAccent : unselectedAccent;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? p.textSecondary.withValues(alpha: 0.15) : p.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isSelected ? selectedAccent : p.border,
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: Slidable(
        key: ValueKey<int>(transaction.id),
        groupTag: 'trash_rows',
        closeOnScroll: true,
        enabled: !isSelected && !isMultiSelectMode,
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.28,
          children: [
            SlidableAction(
              onPressed: AppHaptics.wrapSlidable((_) => onRestore()),
              backgroundColor: p.mint,
              foregroundColor: Colors.black87,
              icon: Icons.restore_rounded,
              label: 'Restore',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.28,
          children: [
            SlidableAction(
              onPressed: AppHaptics.wrapSlidable((_) => onDelete()),
              backgroundColor: p.coral,
              foregroundColor: Colors.white,
              icon: Icons.delete_forever_outlined,
              label: 'Delete',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        child: SlidablePeekHint(
          storageKey: AppConstants.SLIDABLE_PEEK_TRASH,
          enabled: applyPeek,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              borderRadius: BorderRadius.circular(12.0),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 4,
                        color: transaction.type == TransactionType.income
                            ? p.mint
                            : p.coral,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 12.0),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  border: Border.all(
                                      color: accent.withValues(alpha: 0.4)),
                                  color: accent.withValues(alpha: 0.1),
                                ),
                                child: isSelected
                                    ? Icon(Icons.check_rounded,
                                        color: p.textPrimary, size: 24.0)
                                    : Icon(
                                        Categories.iconForKey(
                                            transaction.category),
                                        color: p.textSecondary,
                                        size: 22.0,
                                      ),
                              ),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      transaction.description,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: tt.titleSmall!.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? p.textPrimary
                                            : p.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6.0),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat('MMM dd, yyyy • HH:mm')
                                              .format(transaction.date),
                                          style: tt.bodySmall!.copyWith(
                                            color: p.textSecondary,
                                          ),
                                        ),
                                        if (transaction.deletedAt != null) ...[
                                          const SizedBox(height: 2),
                                          Builder(builder: (context) {
                                            final int daysInTrash =
                                                DateTime.now()
                                                    .difference(
                                                        transaction.deletedAt!)
                                                    .inDays;
                                            final int remaining = appController
                                                    .trashPeriodDays.value -
                                                daysInTrash;
                                            return Text(
                                              'Deleted: ${DateFormat('MMM dd').format(transaction.deletedAt!)} • ${remaining > 0 ? '$remaining days left' : 'Expiring soon'}',
                                              style: tt.labelSmall!.copyWith(
                                                  color: remaining < 3
                                                      ? p.coral.withValues(
                                                          alpha: 0.8)
                                                      : p.textSecondary),
                                            );
                                          }),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formatTransactionDisplayAmount(transaction),
                                style: tt.titleSmall!.copyWith(
                                  color: isSelected
                                      ? p.textPrimary
                                      : p.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
