import 'package:balance_sheet/constants/app.dart';
import 'package:balance_sheet/utils/app_haptics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get_storage/get_storage.dart';

/// Which action pane to briefly reveal for the one-time peek animation.
enum SlidablePeekSide {
  start,
  end,
}

/// Runs a short open → pause → close animation on the parent [Slidable] once
/// per [storageKey] (persisted in [GetStorage]), so new users notice swipe
/// actions. Place as the **child** of [Slidable].
///
/// Use keys from `package:balance_sheet/constants/app.dart` (e.g. `SLIDABLE_PEEK_TRANSACTIONS`).
class SlidablePeekHint extends StatefulWidget {
  const SlidablePeekHint({
    super.key,
    required this.storageKey,
    required this.child,
    this.enabled = true,
    this.peekSide = SlidablePeekSide.end,

    /// Portion of the full action extent to reveal (e.g. `0.5` ≈ half-open).
    this.peekExtentFraction = 0.52,
  });

  final String storageKey;
  final Widget child;
  final bool enabled;
  final SlidablePeekSide peekSide;
  final double peekExtentFraction;

  @override
  State<SlidablePeekHint> createState() => _SlidablePeekHintState();
}

class _SlidablePeekHintState extends State<SlidablePeekHint> {
  @override
  void initState() {
    super.initState();
    if (!widget.enabled) {
      return;
    }
    final GetStorage box = GetStorage();
    if (box.read(widget.storageKey) == true) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _runPeek();
    });
  }

  Future<void> _runPeek() async {
    await Future<void>.delayed(const Duration(milliseconds: 320));
    if (!mounted) {
      return;
    }
    final SlidableController? controller = Slidable.of(context);
    if (controller == null) {
      return;
    }

    final double frac = widget.peekExtentFraction.clamp(0.2, 1.0);
    final Duration openDuration = const Duration(milliseconds: 380);
    final Duration pause = const Duration(milliseconds: 520);
    final Duration closeDuration = const Duration(milliseconds: 320);

    if (widget.peekSide == SlidablePeekSide.end &&
        controller.enableEndActionPane) {
      final double full = controller.endActionPaneExtentRatio;
      if (full <= 0) {
        return;
      }
      await controller.openTo(
        -full * frac,
        duration: openDuration,
        curve: Curves.easeOutCubic,
      );
    } else if (widget.peekSide == SlidablePeekSide.start &&
        controller.enableStartActionPane) {
      final double full = controller.startActionPaneExtentRatio;
      if (full <= 0) {
        return;
      }
      await controller.openTo(
        full * frac,
        duration: openDuration,
        curve: Curves.easeOutCubic,
      );
    } else {
      return;
    }

    if (!mounted) {
      return;
    }
    AppHaptics.selection();
    await Future<void>.delayed(pause);
    if (!mounted) {
      return;
    }
    await controller.close(
      duration: closeDuration,
      curve: Curves.easeInCubic,
    );
    if (!mounted) {
      return;
    }
    await GetStorage().write(widget.storageKey, true);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Clears all one-time slidable peek completion flags so the swipe demos can run again.
Future<void> clearSlidablePeekCompletionRecords(GetStorage box) async {
  await box.remove(AppConstants.SLIDABLE_PEEK_TRANSACTIONS);
  await box.remove(AppConstants.SLIDABLE_PEEK_BUDGET);
  await box.remove(AppConstants.SLIDABLE_PEEK_CONTACTS);
  await box.remove(AppConstants.SLIDABLE_PEEK_INVESTMENTS);
  await box.remove(AppConstants.SLIDABLE_PEEK_INVESTMENTS_OTHER);
  await box.remove(AppConstants.SLIDABLE_PEEK_TRASH);
}

/// Clears slidable peeks plus the home balance / net worth pager coach.
Future<void> clearAllFirstRunUiHints(GetStorage box) async {
  await clearSlidablePeekCompletionRecords(box);
  await box.remove(AppConstants.HOME_BALANCE_PAGER_COACH_DONE);
}
