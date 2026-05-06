import 'package:balance_sheet/saved_views/saved_views_storage.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:balance_sheet/utils/app_haptics.dart';
import 'package:flutter/material.dart';

/// Bottom sheet: list saved presets, save current payload, delete, apply on tap.
Future<void> showSavedViewsSheet(
  BuildContext context, {
  required AppPalette palette,
  required String featureKey,
  required String surfaceTitle,
  required Map<String, dynamic> Function() capturePayload,
  required Future<void> Function(Map<String, dynamic> payload) applyPayload,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: palette.overlay,
    builder: (BuildContext ctx) => _SavedViewsSheetBody(
      palette: palette,
      featureKey: featureKey,
      surfaceTitle: surfaceTitle,
      capturePayload: capturePayload,
      applyPayload: applyPayload,
    ),
  );
}

class _SavedViewsSheetBody extends StatefulWidget {
  const _SavedViewsSheetBody({
    required this.palette,
    required this.featureKey,
    required this.surfaceTitle,
    required this.capturePayload,
    required this.applyPayload,
  });

  final AppPalette palette;
  final String featureKey;
  final String surfaceTitle;
  final Map<String, dynamic> Function() capturePayload;
  final Future<void> Function(Map<String, dynamic> payload) applyPayload;

  @override
  State<_SavedViewsSheetBody> createState() => _SavedViewsSheetBodyState();
}

class _SavedViewsSheetBodyState extends State<_SavedViewsSheetBody> {
  late List<SavedViewRecord> _rows;

  @override
  void initState() {
    super.initState();
    _rows = SavedViewsStorage.listFor(widget.featureKey);
  }

  void _reload() {
    setState(() {
      _rows = SavedViewsStorage.listFor(widget.featureKey);
    });
  }

  Future<void> _onApply(SavedViewRecord r) async {
    AppHaptics.light();
    Navigator.of(context).pop();
    await widget.applyPayload(Map<String, dynamic>.from(r.payload));
  }

  Future<void> _onDelete(SavedViewRecord r) async {
    AppHaptics.light();
    await SavedViewsStorage.remove(widget.featureKey, r.id);
    _reload();
  }

  Future<void> _promptSave() async {
    final AppPalette p = widget.palette;
    final String? name = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (BuildContext ctx) => _SaveViewNameDialog(palette: p),
    );
    final String trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) {
      return;
    }
    AppHaptics.light();
    await SavedViewsStorage.add(
        widget.featureKey, trimmed, widget.capturePayload());
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = widget.palette;
    final double inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: p.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Saved views',
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    color: p.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.surfaceTitle,
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: p.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: p.textSecondary),
                    onPressed: () {
                      AppHaptics.light();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: _promptSave,
                icon: Icon(Icons.add_rounded, color: p.mint, size: 20),
                label: Text(
                  'Save current view',
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: p.mint,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: p.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: _rows.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                      child: Text(
                        'No saved views yet. Adjust filters and tap “Save current view”.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: p.textSecondary,
                              height: 1.4,
                            ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                      itemCount: _rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (BuildContext ctx, int i) {
                        final SavedViewRecord r = _rows[i];
                        return Material(
                          color: p.surface,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => _onApply(r),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        r.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall!
                                            .copyWith(
                                              color: p.textPrimary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      subtitle: Text(
                                        'Tap to apply',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall!
                                            .copyWith(
                                              color: p.textSecondary,
                                            ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete',
                                    icon: Icon(Icons.delete_outline_rounded,
                                        color: p.textSecondary, size: 22),
                                    onPressed: () => _onDelete(r),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// [TextEditingController] is disposed in [State.dispose] after the dialog unmounts.
class _SaveViewNameDialog extends StatefulWidget {
  const _SaveViewNameDialog({required this.palette});

  final AppPalette palette;

  @override
  State<_SaveViewNameDialog> createState() => _SaveViewNameDialogState();
}

class _SaveViewNameDialogState extends State<_SaveViewNameDialog> {
  late final TextEditingController _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = widget.palette;
    return AlertDialog(
      backgroundColor: p.surfaceElevated,
      title: Text('Save view', style: TextStyle(color: p.textPrimary)),
      content: TextField(
        controller: _nameCtrl,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(color: p.textPrimary),
        decoration: InputDecoration(
          labelText: 'Name',
          labelStyle: TextStyle(color: p.textSecondary),
          enabledBorder:
              OutlineInputBorder(borderSide: BorderSide(color: p.border)),
          focusedBorder:
              OutlineInputBorder(borderSide: BorderSide(color: p.mint)),
        ),
        onSubmitted: (_) => Navigator.of(context).pop(_nameCtrl.text.trim()),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: p.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_nameCtrl.text.trim()),
          child: Text('Save',
              style: TextStyle(color: p.mint, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
