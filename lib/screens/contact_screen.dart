import 'package:balance_sheet/constants/app.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/utils/app_haptics.dart';
import 'package:balance_sheet/controllers/contact_controller.dart';
import 'package:balance_sheet/dialogs/contact.dart';
import 'package:balance_sheet/models/contact.dart';
import 'package:balance_sheet/widgets/inputs.dart';
import 'package:balance_sheet/widgets/midnight_grid_painter.dart';
import 'package:balance_sheet/widgets/slidable_peek_hint.dart';
import 'package:balance_sheet/widgets/widgets.dart';
import 'package:balance_sheet/utils/app_snack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';

const double _horizontalPad = 20.0;

/// Search bar — pill-shaped.
const double _searchFieldRadius = 24.0;

/// Bottom composer shell — large rounded rect.
const double _composerDockRadius = 32.0;

/// Contact row: square left edge (flush with mint bar), rounded right only.
const BorderRadius _contactTileBorderRadius = BorderRadius.only(
  topRight: Radius.circular(14),
  bottomRight: Radius.circular(14),
);

/// Avatar / row accent hues derived from name (on-brand variety).
Color _accentForContactName(String name, AppPalette p) {
  final List<Color> palette = [
    p.mint,
    const Color(0xFF2DD4BF),
    const Color(0xFF34D399),
    const Color(0xFF5EEAD4),
    const Color(0xFF14B8A6),
  ];
  if (name.isEmpty) return palette[0];
  return palette[name.hashCode.abs() % palette.length];
}

class ContactView extends StatefulWidget {
  const ContactView({super.key});

  @override
  State<ContactView> createState() => _ContactViewState();
}

class _ContactViewState extends State<ContactView> {
  final ContactController _contactController = Get.find();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Contact> _filtered(List<Contact> all) {
    if (_searchQuery.isEmpty) return all;
    final String q = _searchQuery.toLowerCase();
    return all.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(
              painter: MidnightGridPainter(
                heightFraction: 1.0,
                gridLineColor: palette.gridLine,
              ),
            ),
          ),
          SafeArea(
            // When the keyboard is up, omit bottom safe padding so the column has a few
            // extra pixels; header + list + composer otherwise overflow in short viewports.
            bottom: keyboardInset == 0,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                // [Obx] must wrap the subtree that reads observables — not sit above
                // [LayoutBuilder], or GetX may not register [RxList] subscriptions.
                return Obx(() {
                  final AppPalette p = AppPalette.of(context);
                  final RxList<Contact> rxContacts =
                      _contactController.contacts;
                  // Explicit read so Obx registers this [RxList] (GetX 4.7+).
                  rxContacts.length;
                  final List<Contact> all = rxContacts;
                  final List<Contact> shown = _filtered(all);

                  final Orientation orientation =
                      MediaQuery.orientationOf(context);
                  final bool landscapeContactsHeader =
                      orientation == Orientation.landscape && all.isNotEmpty;

                  final bool tightVertical = constraints.maxHeight < 220;
                  final double headerTopPad = tightVertical ? 4 : 8;
                  final double afterHeaderGap =
                      tightVertical ? 8 : (landscapeContactsHeader ? 14 : 20);
                  final EdgeInsets composerOuter = tightVertical
                      ? const EdgeInsets.fromLTRB(
                          _horizontalPad,
                          4,
                          _horizontalPad,
                          6,
                        )
                      : const EdgeInsets.fromLTRB(
                          _horizontalPad,
                          6,
                          _horizontalPad,
                          10,
                        );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          _horizontalPad,
                          headerTopPad,
                          _horizontalPad,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (landscapeContactsHeader)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Expanded(
                                    flex: 3,
                                    child: _ContactsHeader(
                                      isFiltering: _searchQuery.isNotEmpty,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: _SearchField(
                                        controller: _searchController),
                                  ),
                                ],
                              )
                            else ...<Widget>[
                              _ContactsHeader(
                                isFiltering:
                                    all.isNotEmpty && _searchQuery.isNotEmpty,
                              ),
                              if (all.isNotEmpty) ...<Widget>[
                                SizedBox(height: tightVertical ? 12 : 18),
                                _SearchField(controller: _searchController),
                              ],
                            ],
                            if (all.isNotEmpty)
                              SizedBox(height: afterHeaderGap),
                          ],
                        ),
                      ),
                      Expanded(
                        child: shown.isEmpty
                            ? _EmptyContactsState(
                                hasQuery: _searchQuery.isNotEmpty,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  _horizontalPad,
                                  0,
                                  _horizontalPad,
                                  8,
                                ),
                                itemCount: shown.length,
                                itemBuilder: (context, index) {
                                  final Contact contact = shown[index];
                                  final Color accent =
                                      _accentForContactName(contact.name, p);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Slidable(
                                      key: ValueKey<int>(contact.id),
                                      groupTag: 'contact_rows',
                                      closeOnScroll: true,
                                      startActionPane: ActionPane(
                                        motion: const DrawerMotion(),
                                        extentRatio: 0.28,
                                        children: <Widget>[
                                          SlidableAction(
                                            onPressed: AppHaptics.wrapSlidable(
                                              (_) => showEditContactSheet(
                                                  context, contact),
                                            ),
                                            backgroundColor: p.mint,
                                            foregroundColor: Colors.black87,
                                            icon: Icons.edit_rounded,
                                            label: 'Edit',
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ],
                                      ),
                                      endActionPane: ActionPane(
                                        motion: const DrawerMotion(),
                                        extentRatio: 0.28,
                                        children: <Widget>[
                                          SlidableAction(
                                            onPressed:
                                                AppHaptics.wrapSlidable((_) {
                                              showDeleteContactConfirmation(
                                                  context, contact);
                                            }),
                                            backgroundColor: p.coral,
                                            foregroundColor: Colors.white,
                                            icon: Icons.delete_outline_rounded,
                                            label: 'Delete',
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ],
                                      ),
                                      child: SlidablePeekHint(
                                        storageKey:
                                            AppConstants.SLIDABLE_PEEK_CONTACTS,
                                        enabled: index == 0,
                                        child: _ContactTile(
                                          contact: contact,
                                          accent: accent,
                                          onTap: () => showEditContactSheet(
                                              context, contact),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      Padding(
                        padding: composerOuter,
                        child: _ComposerDock(
                          contactController: _contactController,
                          onAddTap: () {
                            if (contactDataInvalid()) {
                              AppSnack.show(
                                'Error',
                                'Name is required',
                                colorText: p.textPrimary,
                                snackPosition: SnackPosition.TOP,
                                backgroundColor:
                                    p.coral.withValues(alpha: 0.85),
                              );
                              return;
                            }
                            final Contact contact = Contact(
                              name: _contactController.name.value,
                            );
                            _contactController.addContact(contact);
                          },
                          contactDataInvalid: contactDataInvalid,
                        ),
                      ),
                    ],
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  bool contactDataInvalid() {
    return _contactController.name.value == '';
  }
}

class _ContactsHeader extends StatelessWidget {
  const _ContactsHeader({required this.isFiltering});

  final bool isFiltering;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: p.mint.withValues(alpha: 0.14),
            border: Border.all(
              color: p.mint.withValues(alpha: 0.28),
            ),
          ),
          child: Icon(
            Icons.groups_rounded,
            color: p.mint,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contacts',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      color: p.textPrimary,
                      letterSpacing: -0.6,
                      height: 1.15,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                isFiltering
                    ? 'Showing matches in your network'
                    : 'Names you attach to income, expenses, and budgets',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      height: 1.4,
                      color: p.textSecondary.withValues(alpha: 0.95),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return TextField(
      controller: controller,
      style: Theme.of(context).textTheme.titleSmall!.copyWith(
            color: p.textPrimary,
          ),
      cursorColor: p.mint,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: p.surface,
        hintText: 'Search contacts',
        hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: p.textSecondary.withValues(alpha: 0.85),
            ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: p.textSecondary.withValues(alpha: 0.9),
          size: 22,
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: p.textSecondary,
                  size: 20,
                ),
                onPressed: () {
                  AppHaptics.light();
                  controller.clear();
                },
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_searchFieldRadius),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_searchFieldRadius),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_searchFieldRadius),
          borderSide: BorderSide(color: p.mint.withValues(alpha: 0.55)),
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.contact,
    required this.accent,
    required this.onTap,
  });

  final Contact contact;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: AppHaptics.wrap(onTap),
        borderRadius: _contactTileBorderRadius,
        splashColor: accent.withValues(alpha: 0.12),
        highlightColor: accent.withValues(alpha: 0.06),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: _contactTileBorderRadius,
            color: p.surface,
            border: Border.all(color: p.border),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accent,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withValues(alpha: 0.22),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              contact.name.isNotEmpty
                                  ? contact.name.substring(0, 1).toUpperCase()
                                  : '?',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge!
                                  .copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            contact.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  color: p.textPrimary,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: p.textSecondary.withValues(alpha: 0.85),
                          size: 22,
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
    );
  }
}

class _ComposerDock extends StatelessWidget {
  const _ComposerDock({
    required this.contactController,
    required this.onAddTap,
    required this.contactDataInvalid,
  });

  final ContactController contactController;
  final VoidCallback onAddTap;
  final bool Function() contactDataInvalid;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: p.surfaceElevated.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(_composerDockRadius),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: ContactInput(compact: true),
            ),
          ),
          const SizedBox(width: 8),
          Obx(() {
            final bool invalid = contactDataInvalid();
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: AppHaptics.wrap(onAddTap),
                customBorder: const CircleBorder(),
                child: Ink(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: invalid ? p.surface : p.mint,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: invalid ? p.border : Colors.transparent,
                    ),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 26,
                    color: invalid ? p.textSecondary : Colors.black87,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _EmptyContactsState extends StatelessWidget {
  const _EmptyContactsState({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EmptyStateIconFrame(
              circular: true,
              padding: const EdgeInsets.all(28),
              child: Icon(
                hasQuery
                    ? Icons.search_off_rounded
                    : Icons.people_outline_rounded,
                color: p.mint.withValues(alpha: 0.75),
                size: 56,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              hasQuery ? 'No matches' : 'No contacts yet',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: p.textPrimary,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              hasQuery
                  ? 'Try a different search'
                  : 'Add someone you split costs or income with',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: p.textSecondary,
                    height: 1.35,
                    fontWeight: FontWeight.w400,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
