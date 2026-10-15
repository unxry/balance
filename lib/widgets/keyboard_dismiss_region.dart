import 'package:flutter/material.dart';

/// One app-level keyboard policy: pointer-down outside an input and vertical
/// drag both dismiss focus without rebuilding or clearing the input state.
class KeyboardDismissRegion extends StatelessWidget {
  final Widget child;

  const KeyboardDismissRegion({super.key, required this.child});

  void _dismiss() => FocusManager.instance.primaryFocus?.unfocus();

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (_) => _dismiss(),
    child: NotificationListener<ScrollStartNotification>(
      onNotification: (notification) {
        if (notification.dragDetails != null &&
            notification.metrics.axis == Axis.vertical) {
          _dismiss();
        }
        return false;
      },
      child: child,
    ),
  );
}
