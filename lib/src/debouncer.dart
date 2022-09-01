import 'dart:async';

/// This "function" class is the implementation of `debouncer()` Worker.
/// It calls the function passed after specified [delay] parameter.
/// Example:
/// ```
/// final delayed = Debouncer( delay: Duration( seconds: 1 )) ;
/// print( 'the next function will be called after 1 sec' );
/// delayed( () => print( 'called after 1 sec' ));
/// ```
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Notifies if the delayed call is active.
  bool get isRunning => _timer?.isActive ?? false;

  /// Cancel the current delayed call.
  void cancel() => _timer?.cancel();
}

class MaxedDebouncer extends Debouncer {
  final int retries;
  int _tried = 0;

  MaxedDebouncer({required super.delay, required this.retries})
      : assert(retries > 0);

  @override
  void call(void Function() action) {
    if (++_tried <= retries) super(action);
  }
}
