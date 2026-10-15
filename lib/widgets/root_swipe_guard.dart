import 'package:flutter/material.dart';

class RootSwipeCoordinator extends ChangeNotifier {
  var _protectedPointers = 0;

  bool get blocked => _protectedPointers > 0;

  void begin() {
    _protectedPointers++;
    notifyListeners();
  }

  void end() {
    if (_protectedPointers == 0) return;
    _protectedPointers--;
    notifyListeners();
  }
}

class RootSwipeScope extends InheritedWidget {
  final RootSwipeCoordinator coordinator;

  const RootSwipeScope({
    super.key,
    required this.coordinator,
    required super.child,
  });

  static RootSwipeCoordinator? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RootSwipeScope>()?.coordinator;

  @override
  bool updateShouldNotify(RootSwipeScope oldWidget) =>
      oldWidget.coordinator != coordinator;
}

/// Gives an existing horizontal component priority over root tab paging.
class RootSwipeGuard extends StatefulWidget {
  final Widget child;

  const RootSwipeGuard({super.key, required this.child});

  @override
  State<RootSwipeGuard> createState() => _RootSwipeGuardState();
}

class _RootSwipeGuardState extends State<RootSwipeGuard> {
  final Set<int> _pointers = {};
  RootSwipeCoordinator? _coordinator;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _coordinator = RootSwipeScope.maybeOf(context);
  }

  void _begin(PointerDownEvent event) {
    if (_pointers.add(event.pointer)) _coordinator?.begin();
  }

  void _end(PointerEvent event) {
    if (_pointers.remove(event.pointer)) _coordinator?.end();
  }

  @override
  void dispose() {
    for (final _ in _pointers) {
      _coordinator?.end();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: _begin,
    onPointerUp: _end,
    onPointerCancel: _end,
    child: widget.child,
  );
}
