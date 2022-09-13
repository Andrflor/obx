part of '../../orchestrator.dart';

/// Extension to safe access value on uninitialized Reactives
extension ValueOrNull<T> on Reactive<T> {
  T? get valueOrNull {
    if (!Orchestrator.notInBuild) _reportRead();
    return _value;
  }
}

/// This is the mos basic reactive component
/// This will just update the ui when it updates
class Reactive<T> {
  /// 64 bit integer that store 3 16bit integer and 3 booleans (51 bit)
  int _reserveInt = 0;

  List<Disposer>? _disposers;

  T? _value;

  final Equality _eq;
  Equality get equalizer =>
      _eq is CacheWrapper<T> ? (_eq as CacheWrapper<T>).eq : _eq;

  T call([T? v]) {
    if (v != null) {
      value = v;
    }
    return value;
  }

  bool get hasValue => _value != null || null is T;

  bool get disposed => _listeners.isEmpty;
  bool get hasListeners => (_count) != 0;

  /// First 16 bit used for the listener count
  int get _count => _reserveInt & 65535;

  /// Third 16 bit used to store the number of removed elements during iteration
  /// The second 16 bit is used to store the callStackDepth
  int get _removedReantrant => (_reserveInt & 562949953355776) >> 32;

  /// First boolean on the 49th bit for the streamController
  bool get _hasController => (_reserveInt & 281474976710656) != 0;
  void _toggleHasController() => _reserveInt ^= 281474976710656;

  /// Second boolean on the 50th bit for the disposerListeners
  bool get _hasDisposers => (_reserveInt & 562949953421312) != 0;
  void _toggleHasDisposers() => _reserveInt ^= 562949953421312;
  void _setHasDisposers() => _reserveInt |= 562949953421312;

  /// Third bolean on the 51th bit for the errorListeners
  bool get _hasErrorListeners => (_reserveInt & 1125899906842624) != 0;
  void _toggleHasHasErrorListeners() => _reserveInt ^= 1125899906842624;

  Reactive({T? initial, Equality eq = const Equality()})
      : _value = initial,
        _eq = eq;

  List<Function(T e)?> _listeners = List<Function(T e)?>.filled(1, null);

  static bool debugAssertNotDisposed(Reactive notifier) {
    assert(() {
      if (notifier.disposed) {
        throw FlutterError(
          'A ${notifier.runtimeType} was used after being disposed.\n'
          'Once you have called dispose() on a ${notifier.runtimeType}, it '
          'can no longer be used.',
        );
      }
      return true;
    }());
    return true;
  }

  /// Used to add listeners
  ///
  /// This function is optimized with voodoo to be as fast as possible
  ///
  void _addListener(Function(T e) listener) {
    assert(Reactive.debugAssertNotDisposed(this));
    assert(() {
      // If we had more than 65535 listeners (u16) it will cause unexpected
      // behaviors, this should never happen and may be due to a StackOverflow.
      if (_count == 65535) {
        throw FlutterError(
            'You are trying to add more than 65535 listeners to a $runtimeType which is not supported.\nMaybe you recursivly called [ever] or [listen] inside another [ever] or [listen]');
      }
      return true;
    }());
    if (_count == _listeners.length) {
      final List<Function(T e)?> newListeners =
          List<Function(T e)?>.filled(2 * _count, null);
      for (int i = 0; i < _count; i++) {
        newListeners[i] = _listeners[i];
      }
      _listeners = newListeners;
    }

    // Use the value of _count and increase it by +1 after
    _listeners[(_reserveInt++) & 65535] = listener;
  }

  /// Used to remove the listener
  ///
  /// This function is made to be ultra fast
  /// It's even a tiny bit faster than ChangeNotifier
  ///
  /// We remove only if we really need it
  /// Otherwise inside a listener loop we just assign null
  void _removeListener(Function(T e) listener) {
    if ((_reserveInt & 4294901760) != 0) {
      for (int i = 0; i < _count; i++) {
        if (_listeners[i] == listener) {
          _listeners[i] = null;
          // Increase the _removedReantrant by +1
          _reserveInt += 4294967296;
          break;
        }
      }
    } else {
      for (int index = 0; index < _count; index++) {
        if (_listeners[index] == listener) {
          // The list holding the listeners is not growable for performances reasons.
          // We still want to shrink this list if a lot of listeners have been added
          // and then removed outside a notifyListeners iteration.
          // We do this only when the real number of listeners is half the length
          // of our list.
          _reserveInt -= 1;
          final count = _count;
          if (count * 2 <= _listeners.length) {
            final List<Function(T e)?> newListeners =
                List<Function(T e)?>.filled(count + 1, null);

            // Listeners before the index are at the same place.
            for (int i = 0; i < index; i++) {
              newListeners[i] = _listeners[i];
            }

            // Listeners after the index move towards the start of the list.
            for (int i = index; i < count; i++) {
              newListeners[i] = _listeners[i + 1];
            }

            _listeners = newListeners;
          } else {
            // When there are more listeners than half the length of the list, we only
            // shift our listeners, so that we avoid to reallocate memory for the
            // whole list.
            for (int i = index; i < count; i++) {
              _listeners[i] = _listeners[i + 1];
            }
            _listeners[count] = null;
          }

          break;
        }
      }
    }
  }

  // TODO: test shift to make sure it works properly
  /// Shift existing callbacks so the null values are at the end
  ///
  /// This is a sort of manual garbage collection
  /// Will reallocate the List if it shrinks too much
  void _shift() {
    // We really remove the listeners when all notifications are done.
    final int newLength = _count - _removedReantrant;
    if (newLength * 2 <= _listeners.length) {
      // As in _removeAt, we only shrink the list when the real number of
      // listeners is half the length of our list.
      final List<Function(T e)?> newListeners =
          List<Function(T e)?>.filled(newLength + 1, null);

      int newIndex = 0;
      for (int i = 0; i < _count; i++) {
        final listener = _listeners[i];
        if (listener != null) {
          newListeners[newIndex++] = listener;
        }
      }

      _listeners = newListeners;
    } else {
      // Otherwise we put all the null references at the end.
      for (int i = 0; i < newLength; i += 1) {
        if (_listeners[i] == null) {
          // We swap this item with the next not null item.
          int swapIndex = i + 1;
          while (_listeners[swapIndex] == null) {
            swapIndex += 1;
          }
          _listeners[i] = _listeners[swapIndex];
          _listeners[swapIndex] = null;
        }
      }
    }

    // Set the _removedReantrant to 0
    _reserveInt |= 1970329131941887;
    // Set _count to newLength
    _reserveInt = newLength + (2251799813619712 & _reserveInt);
  }

  // TODO: implement detatch if needed
  void detatch() {}

  // Recursive function that allow to resume the loop after any error
  void _continueLooping(int i) {
    try {
      for (i; i < _count; i++) {
        _listeners[i]?.call(_value as T);
      }
    } catch (exception, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'obx library',
        silent: true,
        context: ErrorSummary(
            'dispatching notifications for $runtimeType\nThis error was catched to ensure that listener events are dispatched\nSome of your listeners for this Rx is throwing an exception\nMake sure that your listeners do not throw to ensure optimal performance'),
      ));

      // There is an error we should continue the loop
      _continueLooping(++i);
    }
  }

  @mustCallSuper
  void dispose() {
    assert(Reactive.debugAssertNotDisposed(this));
    _listeners = [];
    _reserveInt = 0;
  }

  /// Trigger update with current value
  /// Force notify listeners and update Widgets
  ///
  /// This function is really fast
  /// It's up to 2x faster than ChangeNotifier
  /// When there is 10 listeners
  @protected
  @visibleForTesting
  @pragma('vm:notify-debugger-on-exception')
  void emit() {
    assert(Reactive.debugAssertNotDisposed(this));
    assert(() {
      // If we have already 8191 _callStackDepth we can assume a StackOverflow
      if (_reserveInt & 4294901760 == 536805376) {
        throw FlutterError(
            'A $runtimeType as a listener that causes a StackOverflow.\nMake sure to not infinitly emit values inside [listen], [ever]...');
      }
      return true;
    }());

    // Increase the _callStackDepth by +1
    _reserveInt += 65536;
    int i = 0;
    // Could have called _continueLooping(0) instead
    // But it's slower than putting the first iteration try here
    // This implementation is what mainly makes reactive up to 2x faster than
    // ChangeNotifier. Here we avoid try catching on each loop
    // But we still catch all the errors properly thanks to recursivity
    try {
      for (i; i < _count; i++) {
        _listeners[i]?.call(_value as T);
      }
    } catch (exception, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'obx library',
        silent: true,
        context: ErrorSummary(
            'dispatching notifications for $runtimeType\nThis error was catched to ensure that listener events are dispatched\nSome of your listeners for this Rx is throwing an exception\nMake sure that your listeners do not throw to ensure optimal performance'),
      ));

      // There is an error we should continue the loop
      _continueLooping(++i);
    }
    // Decrease the _callStackDepth by -1
    _reserveInt -= 65536;

    // If we have _callStackDepth 0 && _removedReantrant > 0
    // Then we need to swap the null values to the end
    if ((_reserveInt & 281470681743360) != 0 &&
        (_reserveInt & 4294901760) == 0) {
      _shift();
    }
  }

  /// You should make sure to not call this if there is no value
  T get value {
    if (!Orchestrator.notInBuild) _reportRead();
    return _value as T;
  }

  /// Change the value if it matches the equality constraint
  set value(T val) {
    if (_eq.equals(_value, val)) return;
    _value = val;
    emit();
  }

  /// Silent update
  /// Update value without updating widgets and listeners
  /// This means that piped object won't recieve the update
  void silent(T v) {
    _value = v;
  }

  /// Trigger update
  /// Force update value and notify all elements
  /// This means that piped object will recieve the update
  void trigger(T v) {
    _value = v;
    emit();
  }

  /// Allow to listen to a Reactive
  ///
  /// Return a VoidCallback to dispose the listen
  VoidCallback listen(
    Function(T value) callback,
  ) {
    _addListener(callback);
    return () => _removeListener(callback);
  }

  @protected
  void _reportRead() {
    if (Orchestrator.notInObserve) {
      final reactives = Orchestrator.element!.reactives;
      for (int i = 0; i < reactives.length; i++) {
        if (reactives[i] == this) return;
      }
      reactives.add(this);
      _addListener(Orchestrator.element!.refresh);
    } else {
      final reactives = Orchestrator.reactives;
      for (int i = 0; i < reactives.length; i++) {
        if (reactives[i] == this) return;
      }
      final listener = Orchestrator.notifyData!.updater;
      reactives.add(this);
      _addListener(listener);
      Orchestrator.notifyData!.disposers.add(() => _removeListener(listener));
    }
  }
}
