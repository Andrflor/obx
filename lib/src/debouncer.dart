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

/// This debouncer will fire each X call
class EveryDebouncer extends Debouncer {
  bool _enabled;
  final int retries;
  int _tried = 0;

  EveryDebouncer({required super.delay, required this.retries, bool? enabled})
      : _enabled = enabled ?? true,
        assert(retries > 0);

  @override
  void call(void Function() action) {
    if (!_enabled) return;
    if (_tried++ < retries) return super(action);
    _tried = 0;
    cancel();
    action();
  }

  void start() {
    _enabled = true;
  }
}
