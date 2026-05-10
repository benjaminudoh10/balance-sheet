import 'package:balance_sheet/constants/app.dart';
import 'package:balance_sheet/constants/category.dart';
import 'package:balance_sheet/controllers/app_controller.dart';
import 'package:balance_sheet/controllers/transaction_controller.dart';
import 'package:balance_sheet/enums.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/utils/app_haptics.dart';
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
            },
            child: Text('Empty Trash',
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

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: p.textPrimary),
        ),
        title: Text(
          'Trash',
          style: tt.headlineSmall!.copyWith(
            color: p.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Obx(() => _transactionController.trashedTransactions.isNotEmpty
              ? IconButton(
                  onPressed: _confirmEmptyTrash,
                  icon: Icon(Icons.delete_sweep_outlined, color: p.coral),
                  tooltip: 'Empty Trash',
                )
              : const SizedBox.shrink()),
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
                  child: Slidable(
                    key: ValueKey(t.id),
                    startActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      extentRatio: 0.25,
                      children: [
                        SlidableAction(
                          onPressed: (_) {
                            AppHaptics.medium();
                            _transactionController.restoreTransaction(t);
                          },
                          backgroundColor: p.mint,
                          foregroundColor: Colors.black87,
                          icon: Icons.restore_rounded,
                          label: 'Restore',
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ],
                    ),
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      extentRatio: 0.25,
                      children: [
                        SlidableAction(
                          onPressed: (_) {
                            AppHaptics.medium();
                            _transactionController
                                .permanentlyDeleteTransaction(t);
                          },
                          backgroundColor: p.coral,
                          foregroundColor: Colors.white,
                          icon: Icons.delete_forever_rounded,
                          label: 'Delete',
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ],
                    ),
                    child: SlidablePeekHint(
                      storageKey: AppConstants.SLIDABLE_PEEK_TRASH,
                      child: Container(
                        decoration: BoxDecoration(
                          color: p.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: p.border),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: p.textSecondary.withValues(alpha: 0.1),
                            ),
                            child: Icon(
                              Categories.iconForKey(t.category),
                              color: p.textPrimary,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            t.description,
                            style: tt.titleMedium!.copyWith(
                              color: p.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM dd, yyyy • HH:mm')
                                    .format(t.date),
                                style: tt.bodySmall!
                                    .copyWith(color: p.textSecondary),
                              ),
                              if (t.deletedAt != null) ...[
                                const SizedBox(height: 2),
                                Builder(builder: (context) {
                                  final int daysInTrash = DateTime.now()
                                      .difference(t.deletedAt!)
                                      .inDays;
                                  final int remaining =
                                      _appController.trashPeriodDays.value -
                                          daysInTrash;
                                  return Text(
                                    'Deleted: ${DateFormat('MMM dd').format(t.deletedAt!)} • ${remaining > 0 ? '$remaining days left' : 'Expiring soon'}',
                                    style: tt.labelSmall!.copyWith(
                                        color: remaining < 3
                                            ? p.coral
                                            : p.textSecondary),
                                  );
                                }),
                              ],
                            ],
                          ),
                          trailing: Text(
                            (t.type == TransactionType.income ? '+ ' : '- ') +
                                NumberFormat.simpleCurrency(name: 'NGN')
                                    .format(t.amount / 100),
                            style: tt.titleMedium!.copyWith(
                              color: t.type == TransactionType.income
                                  ? p.mint
                                  : p.coral,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
