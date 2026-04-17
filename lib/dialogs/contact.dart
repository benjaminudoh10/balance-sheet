import 'package:balance_sheet/controllers/appController.dart';
import 'package:balance_sheet/controllers/contactController.dart';
import 'package:balance_sheet/models/contact.dart';
import 'package:balance_sheet/screens/home.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/utils/app_haptics.dart';
import 'package:balance_sheet/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
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
                          hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
                            borderSide: BorderSide(color: p.mint.withValues(alpha: 0.65)),
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
                            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: p.textPrimary,
                                ),
                          ),
                          secondaryText: Text(
                            'Tap below to add a contact',
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  color: p.textSecondary,
                                ),
                          ),
                        ),
                        TextButton(
                          onPressed: _openAddContact,
                          child: Text(
                            'Add contact',
                            style: Theme.of(context).textTheme.labelLarge!.copyWith(
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
                          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
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
