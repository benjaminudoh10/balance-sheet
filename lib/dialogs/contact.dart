import 'package:balance_sheet/controllers/app_controller.dart';
import 'package:balance_sheet/controllers/contact_controller.dart';
import 'package:balance_sheet/models/contact.dart';
import 'package:balance_sheet/screens/home.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/utils/app_haptics.dart';
import 'package:balance_sheet/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Floating bottom sheet to rename a contact (same shell as income/expense modals).
Future<void> showEditContactSheet(BuildContext context, Contact contact) async {
  AppHaptics.light();
  final AppPalette p = AppPalette.of(context);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: p.overlay,
    builder: (BuildContext ctx) => Wrap(
      children: <Widget>[
        _EditContactSheet(contact: contact),
      ],
    ),
  );
}

/// Confirmation dialog for contact deletion.
Future<void> showDeleteContactConfirmation(
    BuildContext context, Contact contact) async {
  AppHaptics.light();
  final AppPalette p = AppPalette.of(context);
  final ContactController contactController = Get.find();
  final bool hasLinked = await contactController.hasLinkedItems(contact.id);

  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: p.overlay,
    builder: (BuildContext ctx) => Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: p.surfaceElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: p.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.coral.withValues(alpha: 0.12),
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              color: p.coral,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Delete contact?',
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  color: p.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            hasLinked
                ? 'This contact is linked to existing transactions or budgets. Deleting it will remove the link, but the transactions will remain.'
                : 'Are you sure you want to delete "${contact.name}"?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: p.textSecondary,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 32),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    AppHaptics.light();
                    Get.back();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: p.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: p.textPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    AppHaptics.medium();
                    Get.back();
                    contactController.deleteContact(contact);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: p.coral,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Delete',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _EditContactSheet extends StatefulWidget {
  const _EditContactSheet({required this.contact});

  final Contact contact;

  @override
  State<_EditContactSheet> createState() => _EditContactSheetState();
}

class _EditContactSheetState extends State<_EditContactSheet> {
  late final TextEditingController _nameController;
  final ContactController _contactController = Get.find();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    AppHaptics.light();
    final String name = _nameController.text.trim();
    await _contactController.updateContact(
      Contact(id: widget.contact.id, name: name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final double insetBottom = MediaQuery.viewInsetsOf(context).bottom;
    final double maxSheetHeight = MediaQuery.sizeOf(context).height * 0.92;

    return Padding(
      padding: EdgeInsets.only(bottom: insetBottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        decoration: BoxDecoration(
          color: p.surfaceElevated,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: p.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 6),
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
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: p.mint.withValues(alpha: 0.12),
                        border:
                            Border.all(color: p.mint.withValues(alpha: 0.28)),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: p.mint,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Edit contact',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall!
                                .copyWith(
                                  color: p.textPrimary,
                                  letterSpacing: -0.4,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Update how this name appears across transactions.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  height: 1.35,
                                  color: p.textSecondary.withValues(alpha: 0.9),
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        AppHaptics.light();
                        Get.back();
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: p.surface,
                        foregroundColor: p.textSecondary,
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(40, 40),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'NAME',
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        letterSpacing: 1.15,
                        height: 1.2,
                        color: p.textPrimary.withValues(alpha: 0.88),
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: p.border),
                    borderRadius: BorderRadius.circular(12),
                    color: p.surface,
                  ),
                  child: TextField(
                    controller: _nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    keyboardType: TextInputType.name,
                    cursorColor: p.mint,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: p.textPrimary,
                        ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Jane Doe',
                      hintStyle:
                          Theme.of(context).textTheme.bodyMedium!.copyWith(
                                color: p.textSecondary,
                              ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: p.mint,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    onPressed: _save,
                    child: Text(
                      'Save',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
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
}

/// Opens a searchable bottom sheet to pick a contact. Works with any controller
/// that exposes a reactive `.contact` with `.value` assignable to [Contact]
/// (e.g. [TransactionController], [ReportController]).
Future<void> showContactPickerSheet(
  BuildContext context, {
  required dynamic controller,

  /// When true, navigating to add a contact also dismisses the sheet under this
  /// one (e.g. the new-transaction bottom sheet).
  bool popUnderlyingSheetWhenAddingContact = false,
}) {
  AppHaptics.light();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppPalette.of(context).overlay,
    builder: (ctx) => _ContactPickerSheet(
      controller: controller,
      popUnderlyingSheetWhenAddingContact: popUnderlyingSheetWhenAddingContact,
    ),
  );
}

class _ContactPickerSheet extends StatefulWidget {
  const _ContactPickerSheet({
    required this.controller,
    required this.popUnderlyingSheetWhenAddingContact,
  });

  final dynamic controller;
  final bool popUnderlyingSheetWhenAddingContact;

  @override
  State<_ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<_ContactPickerSheet> {
  final ContactController _contactController = Get.find();
  final AppController _appController = Get.find();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _select(Contact contact) {
    AppHaptics.selection();
    widget.controller.contact.value = contact;
    Navigator.of(context).pop();
  }

  void _openAddContact() {
    AppHaptics.light();
    final NavigatorState nav = Navigator.of(context);
    nav.pop();
    if (widget.popUnderlyingSheetWhenAddingContact) {
      nav.pop();
    }
    Get.to(() => Home());
    _appController.setIndex(1);
  }

  List<Contact> _filtered() {
    final String q = _searchController.text.trim().toLowerCase();
    final List<Contact> all = List<Contact>.from(_contactController.contacts);
    if (q.isEmpty) {
      return all;
    }
    return all.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final double insetBottom = MediaQuery.viewInsetsOf(context).bottom;
    final double maxH = MediaQuery.sizeOf(context).height * 0.88;

    return Padding(
      padding: EdgeInsets.only(bottom: insetBottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          height: maxH,
          decoration: BoxDecoration(
            color: p.surfaceElevated,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: p.border),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: p.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                child: Row(
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: Text(
                        'Select contact',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  color: p.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        AppHaptics.light();
                        Navigator.of(context).pop();
                      },
                      style: IconButton.styleFrom(
                        foregroundColor: p.textSecondary,
                      ),
                      icon: const Icon(Icons.close_rounded, size: 22),
                    ),
                  ],
                ),
              ),
              Obx(() {
                if (_contactController.contacts.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              color: p.textPrimary,
                            ),
                        cursorColor: p.mint,
                        decoration: InputDecoration(
                          hintText: 'Search contacts',
                          hintStyle:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: p.textSecondary,
                                  ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: p.textSecondary.withValues(alpha: 0.85),
                            size: 22,
                          ),
                          filled: true,
                          fillColor: p.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: p.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: p.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: p.mint.withValues(alpha: 0.65)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              }),
              Expanded(
                child: Obx(() {
                  _contactController.contacts.length;
                  final List<Contact> filtered = _filtered();
                  if (filtered.isEmpty && _contactController.contacts.isEmpty) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        EmptyState(
                          icon: Icon(
                            Icons.person_outline,
                            color: p.mint.withValues(alpha: 0.7),
                            size: 48,
                          ),
                          primaryText: Text(
                            'No contact has been added',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: p.textPrimary,
                                ),
                          ),
                          secondaryText: Text(
                            'Tap below to add a contact',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: p.textSecondary,
                                ),
                          ),
                        ),
                        TextButton(
                          onPressed: _openAddContact,
                          child: Text(
                            'Add contact',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge!
                                .copyWith(
                                  color: p.mint,
                                ),
                          ),
                        ),
                      ],
                    );
                  }
                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No matching contacts',
                          style:
                              Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    color: p.textSecondary,
                                  ),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final Contact c = filtered[index];
                      final bool selected =
                          widget.controller.contact.value?.id == c.id;
                      return _ContactRow(
                        contact: c,
                        selected: selected,
                        onTap: () => _select(c),
                      );
                    },
                  );
                }),
              ),
              if (_contactController.contacts.isNotEmpty)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextButton(
                      onPressed: _openAddContact,
                      child: Text(
                        'Add new contact',
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                              color: p.mint,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.contact,
    required this.selected,
    required this.onTap,
  });

  final Contact contact;
  final bool selected;
  final VoidCallback onTap;

  static String _initials(String name) {
    final String t = name.trim();
    if (t.isEmpty) {
      return '?';
    }
    final List<String> parts =
        t.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) {
      final String a = parts[0].isNotEmpty ? parts[0][0] : '';
      final String b = parts[1].isNotEmpty ? parts[1][0] : '';
      return ('$a$b').toUpperCase();
    }
    if (t.length >= 2) {
      return t.substring(0, 2).toUpperCase();
    }
    return t[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: AppHaptics.wrap(onTap),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? p.mint.withValues(alpha: 0.16) : p.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? p.mint.withValues(alpha: 0.45) : p.border,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: p.mint.withValues(alpha: 0.22),
                foregroundColor: p.mint,
                radius: 22,
                child: Text(
                  _initials(contact.name),
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: p.mint,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  contact.name,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: p.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  color: p.mint,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
