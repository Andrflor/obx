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
  /// I'm joking, but no kidding it's faster than ChangeNotifier
  void _addListener(Function(T e) listener) {
    assert(Reactive.debugAssertNotDisposed(this));
    if (_count == _listeners.length) {
      final List<Function(T e)?> newListeners =
          List<Function(T e)?>.filled(_listeners.length + 5, null);
      for (int i = 0; i < _count; i++) {
        newListeners[i] = _listeners[i];
      }
      _listeners = newListeners;
    }

    // Use the value of _count and increase it by +1 after
    _listeners[(_reserveInt++) & 65535] = listener;
  }

  void _removeAt(int index) {
    // The list holding the listeners is not growable for performances reasons.
    // We still want to shrink this list if a lot of listeners have been added
    // and then removed outside a notifyListeners iteration.
    // We do this only when the real number of listeners is half the length
    // of our list.
    _reserveInt -= 1;
    if (_count + 5 < _listeners.length) {
      final List<Function(T e)?> newListeners =
          List<Function(T e)?>.filled(_count, null);

      // Listeners before the index are at the same place.
      for (int i = 0; i < index; i++) {
        newListeners[i] = _listeners[i];
      }

      // Listeners after the index move towards the start of the list.
      for (int i = index; i < _count; i++) {
        newListeners[i] = _listeners[i + 1];
      }

      _listeners = newListeners;
    } else {
      // When there are more listeners than half the length of the list, we only
      // shift our listeners, so that we avoid to reallocate memory for the
      // whole list.
      for (int i = index; i < _count; i++) {
        _listeners[i] = _listeners[i + 1];
      }
      _listeners[_count] = null;
    }
  }

  /// Used to remove the listener
  ///
  /// This function is made to be ultra fast
  /// We won't remove anything here
  /// Just set thos to null
  /// Then we will garbage collect manually the list
  void _removeListener(Function(T e) listener) {
    // Check if the _callStackDepth is > 0
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
      for (int i = 0; i < _count; i++) {
        if (_listeners[i] == listener) {
          _listeners[i] = null;
          _removeAt(i);
          break;
        }
      }
    }
  }

  /// Shift existing callbacks to the null values are at the end
  ///
  /// This is a sort of manual garbage collection
  /// Will reallocate the List if it shrinks to much
  void _shift() {
    // We really remove the listeners when all notifications are done.
    final int newLength = _count - _removedReantrant;
    if (newLength + 5 < _listeners.length) {
      // As in _removeAt, we only shrink the list when the real number of
      // listeners is half the length of our list.
      final List<Function(T e)?> newListeners =
          List<Function(T e)?>.filled(newLength, null);

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

  @mustCallSuper
  void dispose() {
    assert(Reactive.debugAssertNotDisposed(this));
    _listeners = [];
    _reserveInt = 0;
  }

  /// Trigger update with current value
  /// Force notify listeners and update Widgets
  @protected
  @visibleForTesting
  @pragma('vm:notify-debugger-on-exception')
  void emit() {
    assert(Reactive.debugAssertNotDisposed(this));
    // Increase the _callStackDepth by +1
    _reserveInt += 65536;
    for (int i = 0; i < _count; i++) {
      _listeners[i]?.call(_value as T);
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

  VoidCallback subscribe(
    Function(T value) callback,
  ) {
    _addListener(callback);
    return () => _removeListener(callback);
  }

  VoidCallback subNow(Function(T value) callback) {
    callback(_value as T);
    _addListener(callback);
    return () => _removeListener(callback);
  }

  VoidCallback subDiff(
    Function(T last, T current) callback,
  ) {
    T oldVal = _value as T;
    listener(T value) {
      callback(oldVal, value);
      oldVal = _value as T;
    }

    _addListener(listener);
    return () => _removeListener(listener);
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
