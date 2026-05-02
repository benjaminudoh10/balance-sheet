import 'package:balance_sheet/backup/backup_service.dart';
import 'package:balance_sheet/theme/app_palette.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Modal shown while [BackupService.importFromJsonString] and
/// [BackupService.refreshControllersAfterImport] run.
///
/// Pairs an indeterminate [CircularProgressIndicator] (so the user sees the
/// app is alive even when the bar isn't moving) with a determinate
/// [LinearProgressIndicator] that tracks row inserts during the data-restore
/// phase. The progress bar falls back to indeterminate during the parsing,
/// preferences, and controller-refresh phases where there is no per-row
/// counter.
///
/// The dialog is intentionally non-dismissible: cancelling mid-import would
/// leave the database in a half-replaced state.
class BackupImportProgressDialog extends StatelessWidget {
  const BackupImportProgressDialog({super.key, required this.progress});

  final ValueListenable<BackupImportProgress> progress;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = AppPalette.of(context);
    final TextTheme tt = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: <Widget>[
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(p.mint),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Restoring backup',
                style: tt.titleLarge?.copyWith(color: p.textPrimary),
              ),
            ),
          ],
        ),
        content: ValueListenableBuilder<BackupImportProgress>(
          valueListenable: progress,
          builder: (BuildContext context, BackupImportProgress prog, Widget? _) {
            final double? value = prog.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  prog.message,
                  style: tt.bodyMedium?.copyWith(
                    color: p.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: p.surfaceElevated,
                    valueColor: AlwaysStoppedAnimation<Color>(p.mint),
                  ),
                ),
                if (value != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${(value.clamp(0.0, 1.0) * 100).round()}%',
                      style: tt.labelSmall?.copyWith(color: p.textSecondary),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Please keep the app open until this finishes.',
                  style: tt.bodySmall?.copyWith(
                    color: p.textSecondary.withValues(alpha: 0.75),
                    height: 1.3,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
