import 'package:balance_sheet/database/operations.dart' as db_ops;
import 'package:balance_sheet/models/tag.dart';
import 'package:balance_sheet/models/transaction.dart';
import 'package:get/get.dart';

class TagController extends GetxController {
  final RxList<Tag> allTags = <Tag>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadTags();
  }

  Future<void> loadTags() async {
    isLoading.value = true;
    try {
      final tags = await db_ops.getTags();
      allTags.assignAll(tags);
    } finally {
      isLoading.value = false;
    }
  }

  Future<Tag?> createTag(String name) async {
    if (name.trim().isEmpty) return null;

    // Check if tag already exists
    final existing = allTags.firstWhereOrNull(
        (t) => t.name.toLowerCase() == name.trim().toLowerCase());
    if (existing != null) return existing;

    final id = await db_ops.addTag(name.trim());
    final newTag = Tag(id: id, name: name.trim());
    allTags.add(newTag);
    allTags.sort((a, b) => a.name.compareTo(b.name));
    return newTag;
  }

  Future<void> deleteTag(Tag tag) async {
    await db_ops.deleteTag(tag.id);
    allTags.remove(tag);
  }

  Future<void> toggleTagForTransaction(Transaction transaction, Tag tag) async {
    final List<Tag> currentTags = List.from(transaction.tags);
    if (currentTags.any((t) => t.id == tag.id)) {
      currentTags.removeWhere((t) => t.id == tag.id);
    } else {
      currentTags.add(tag);
    }

    final updatedTransaction = Transaction(
      id: transaction.id,
      description: transaction.description,
      type: transaction.type,
      amount: transaction.amount,
      date: transaction.date,
      category: transaction.category,
      contactId: transaction.contactId,
      entryIsFcy: transaction.entryIsFcy,
      entryAmountMinor: transaction.entryAmountMinor,
      deletedAt: transaction.deletedAt,
      tags: currentTags,
    );

    await db_ops.updateTransaction(updatedTransaction);

    // We need to notify the UI that the transaction has changed.
    // If we're using GetX controllers for transactions, they should be updated.
  }
}
