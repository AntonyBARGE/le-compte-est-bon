import 'package:flutter/material.dart';

/// A widget that adds a loading indicator overlay that prevents the user from interacting with widgets behind itself.
class LoadingBarrier extends StatelessWidget {
  /// Creates a widget that adds a loading indicator overlay that prevents the user from interacting with widgets behind itself.
  const LoadingBarrier({
    super.key,
    required this.duration,
    this.barrierColor,
    required this.busyBuilder,
    this.isBusy = false,
    this.onClose,
    required this.child,
  });

  /// Duration of the fade animation.
  final Duration duration;

  /// Color of the barrier, displayed when running the task.
  /// Defaults to a translucent black.
  /// Use [Colors.transparent] to hide completely the barrier (still blocks interactions).
  final Color? barrierColor;

  /// Builder for the busy indicator.
  final WidgetBuilder busyBuilder;

  /// Whether to display the barrier.
  final bool isBusy;

  /// Optional callback to show a close ("X") button in the top-right corner.
  final VoidCallback? onClose;

  /// Child to display behind the barrier.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        // Content
        child,

        // Modal barrier
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: duration,
            child: isBusy
                ? Stack(
                    key: const ValueKey('barrier'),
                    children: [
                      Container(
                        color: barrierColor ?? Colors.black54,
                        alignment: Alignment.center,
                        child: busyBuilder(context),
                      ),
                      if (onClose != null)
                        Positioned(
                          top: 32,
                          right: 32,
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 48,
                              weight: 900,
                            ),
                            onPressed: onClose,
                            tooltip: 'Close',
                          ),
                        ),
                    ],
                  )
                : const SizedBox(),
          ),
        ),
      ],
    );
  }
}
