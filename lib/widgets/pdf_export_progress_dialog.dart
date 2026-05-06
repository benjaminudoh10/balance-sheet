import 'package:balance_sheet/theme/app_palette.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Non-dismissible modal shown while a PDF export is collecting data and
/// compiling the document.
///
/// The heavy part of the work (building the pages, rendering the table, and
/// serialising the document) runs in a background isolate so this dialog stays
/// animated the entire time.  The caller pushes a stage string into [stage] as
/// the pipeline progresses; the progress indicator itself is always
/// indeterminate because the pdf package does not expose a page-by-page
/// callback.
class PdfExportProgressDialog extends StatelessWidget {
  const PdfExportProgressDialog({super.key, required this.stage});

  final ValueListenable<String> stage;

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
                'Preparing PDF',
                style: tt.titleLarge?.copyWith(color: p.textPrimary),
              ),
            ),
          ],
        ),
        content: ValueListenableBuilder<String>(
          valueListenable: stage,
          builder: (BuildContext context, String message, Widget? _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  message,
                  style: tt.bodyMedium?.copyWith(
                    color: p.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    backgroundColor: p.surfaceElevated,
                    valueColor: AlwaysStoppedAnimation<Color>(p.mint),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Large date ranges can take a few seconds.',
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
