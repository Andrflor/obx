import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../orchestrator.dart';
import '../../equality.dart';
import 'rx_types.dart';
import 'rx_mixins.dart';

/// Complete implementation of Rx
class RxImpl<T> extends Reactive<T> {
  RxImpl(super.val, {bool distinct = true})
      : _distinct = distinct,
        _equalizer = val == null
            ? equalizer<T>(distinct)
            : (val is Iterable || val is Map)
                ? equalizing<T>(val, distinct)
                : distinct
                    ? const DefaultEquality()
                    : const DefaultIndistinctEquality();

  final List<Disposer> _disposers = <Disposer>[];

  @override
  // ignore: overridden_fields
  final Equality _equalizer;

  @override
  bool get isDistinct => _distinct;
  final bool _distinct;

  // This value will only be set if it matches
  @override
  set value(T newValue) {
    // if (_equalizer.memberEquals(_value, newValue)) return;
    trigger(newValue);
  }

  /// Trigger update with a new value
  /// Update the value, force notify listeners and update Widgets
  void trigger(T v) {
    // _controller?.add(v);
    _value = v;
    notifyListeners();
  }

  bool get hasValue => _value != null || null is T;

  @override
  Disposer listenNow(
    void Function(T e) onData, {
    Function? onError,
    void Function()? onDone,
    StreamFilter<T>? filter,
    bool? cancelOnError,
  }) {
    if (hasValue) {
      onData(_value as T);
    }
    return listen(
      onData,
      filter: filter,
    );
  }

  StreamController<T>? _controller;

  Stream<T>? _stream;

  Stream<T> get stream {
    if (_controller == null) {
      _controller = StreamController<T>();
      _controller!.onCancel = dispose;
      _stream = _controller!.stream;
    }
    return _stream!;
  }

  /// This method allow to remove all incoming subs
  /// This will detatched this obs from stream listenable other piped obs
  void detatch() {
    for (Disposer disposer in _disposers) {
      disposer();
    }
    _disposers.clear();
  }

  @override
  @mustCallSuper
  void dispose() {
    detatch();
    if (_controller != null) {
      _controller?.close();
    }
    super.dispose();
  }

  /// Allow to listen to the observable
  Disposer listen(
    void Function(T e) onData, {
    StreamFilter<T>? filter,
  }) {
    if (filter == null) {
      listener() => onData(staticOrNull as T);
      addListener(listener);
      return () => removeListener(listener);
    }
    return filter(stream)
        .listen(
          onData,
          cancelOnError: false,
        )
        .cancel;
  }

  @override
  bool operator ==(Object other) {
    if (other is ValueListenable<T?>) {
      return _equalizer.equals(value, other.value);
    }
    return _equalizer.foreignEquals(value, other);
  }

  @override
  int get hashCode => value.hashCode;

  T call([T? v]) {
    if (v != null) {
      value = v;
    }
    return value;
  }

  /// Binds an existing `Stream<T>` to this Rx<T> to keep the values in sync.
  ///
  /// You can bind multiple sources to update the value.
  /// Once a stream closes the subscription will cancel itself
  /// You can also cancel the sub with the provided callback
  Disposer bindStream(Stream<T> stream) {
    final sub = stream.listen((e) {
      value = e;
    }, cancelOnError: false);
    _disposers.add(sub.cancel);
    clean() {
      _disposers.remove(sub.cancel);
      sub.cancel();
    }

    sub.onDone(clean);
    return clean;
  }

  /// Binding to this [Rx<T>] to any other [Rx<T>]
  ///
  /// Binds an existing [ValueListenable<T>] this might be a [ValueNotifier<T>]
  /// Keeping this [Rx<T>] values in sync.
  /// You can bind multiple sources to update the value.
  /// It's impossible to know when a [ValueListenable] is done
  /// You will have to clean it up yourself
  /// For that you can call the provided [Disposer]
  Disposer bindRx(StreamCapable<T> rx, [StreamFilter<T>? filter]) {
    final sub = rx.listen(
      (e) {
        value = e;
      },
      filter: filter,
    );
    _disposers.add(sub);
    clean() {
      _disposers.remove(sub);
      sub();
    }

    return clean;
  }

  /// Binding to any listener with callback
  ///
  /// Binds an existing [ValueListenable<T>] this might be a [ValueNotifier<T>]
  /// Keeping this [Rx<T>] values in sync.
  /// You can bind multiple sources to update the value.
  /// It's impossible to know when a [ValueListenable] is done
  /// You will have to clean it up yourself
  /// For that you can call the provided [Disposer]
  Disposer bindValueListenable(
    ValueListenable<T> listenable,
  ) {
    closure() {
      value = listenable.value;
    }

    listenable.addListener(closure);
    cancel() => listenable.removeListener(closure);
    _disposers.add(cancel);

    return () {
      _disposers.remove(cancel);
      cancel();
    };
  }

  /// Binding to any listener with provided `onEvent` callback
  ///
  /// Binds an existing [Listenable]
  /// Keeping this [Rx<T>] values in sync.
  /// You can bind multiple sources to update the value.
  /// It's impossible to know when a [Listenable] is done
  /// You will have to clean it up yourself
  /// For that you can call the provided [Disposer]
  Disposer bindListenable(Listenable listenable,
      {required T Function() onEvent}) {
    closure() => value = onEvent();
    listenable.addListener(closure);
    cancel() => listenable.removeListener(closure);
    _disposers.add(cancel);

    return () {
      _disposers.remove(cancel);
      cancel();
    };
  }

  /// Trigger update with current value
  /// Force notify listeners and update Widgets
  void emit() {
    trigger(_value as T);
  }

  /// Silent update
  /// Update value without updating widgets and listeners
  /// This means that piped object won't recieve the update
  void silent(T v) {
    _value = v;
  }

  /// Called without a value it will refesh the ui
  /// Called with a value it will refresh the ui and update value
  void refresh([T? v]) {
    if (v != null) {
      _value = v;
    }
    notifyListeners();
  }
}

class SingleShot<T> extends Reactive<T> {
  SingleShot() : super(null);

  void init(T val) {
    _value = val;
  }
}

class MultiShot<T> extends Reactive<T> {
  MultiShot() : super(null);

  void init(T val) {
    _value = val;
  }

  /// Allow to listen to the observable
  Disposer listen(
    void Function(T e) onData, {
    StreamFilter<T>? filter,
  }) {
    listener() => onData(staticOrNull as T);
    addListener(listener);
    return () => removeListener(listener);
  }

  @override
  Disposer listenNow(
    void Function(T e) onData, {
    Function? onError,
    void Function()? onDone,
    StreamFilter<T>? filter,
    bool? cancelOnError,
  }) {
    onData(_value as T);
    return listen(
      onData,
      filter: filter,
    );
  }
}

// /// Simple emitter for when you don't care about the value
// ///
// /// Example:
// /// ```dart
// /// final emitter = Emitter();
// /// emitter.emit(); \\ Will emit a null value
// /// ```
// ///
// /// This null emit will be forwareded to Listeners
// //ignore: prefer_void_to_null
// class Emitter extends Reactive<Null> {
//   Emitter() : super(null);
//
//   /// Creates an emitter that emits from an Interval
//   factory Emitter.fromInterval(
//     Duration delay,
//   ) =>
//       Emitter()..emitEvery(delay);
//
//   /// Cancel the emitter from auto emitting
//   void cancel() {
//     for (Disposer disposer in _disposers!) {
//       disposer();
//     }
//     disposers!.clear();
//   }
//
//   /// Will emit after `delay`
//   void emitIn(Duration delay) {
//     _disposers!.add(Timer.periodic(delay, (_) {
//       emit();
//     }).cancel);
//   }
//
//   /// Will emit every `delay`
//   void emitEvery(Duration delay) {
//     _disposers!.add(Timer(delay, () {
//       emit();
//     }).cancel);
//   }
//
//   @override
//   //ignore: prefer_void_to_null
//   set value(Null value) => emit();
//
//   @override
//   Null get value {
//     if (!Orchestrator.notInBuild) _reportRead();
//     return null;
//   }
//
//   /// Emit a change to update UI/Listeners
//   @override
//   emit() {
//     streamController?.add(null);
//     _notify();
//   }
//
//   /// Bundle a [T] with this emitter
//   ///
//   /// This allow to pass the emitter inside the UI
//   /// Example:
//   /// ```dart
//   /// Obx(() => Text(emiter.bundle(myVariable)));
//   /// ```
//   T bundle<T>(T value) {
//     if (!Orchestrator.notInBuild) _reportRead();
//     return value;
//   }
// }
//
// /// This is an internal class
// /// It's the basic class for the [observe] function
// /// It's name comes from the fact that it is set up
// /// Then it fire once, and then it dies
// /// So it really has a "single shot"
// class SingleShot<T> extends Shot<T> {
//   @override
//   void _notify() {
//     super._notify();
//     for (final disposer in _disposers!) {
//       disposer();
//     }
//     _disposers!.clear();
//     _disposers = null;
//     dispose();
//   }
// }
//
// /// This is an internal class
// /// It's the basic class for the [ever] function
// class MultiShot<T> = Shot<T> with StreamCapable<T>;
//
// /// This is an internal class
// /// It's the basic class for [observe] and [ever]
// /// It's name comes from the fact that it shoots
// class Shot<T> extends Reactive<T> with DisposersTrackable<T>, Equalizable<T> {
//   Shot() : super(null);
//
//   @override
//   set value(T newValue) {
//     if (_equalizer.equals(_value, newValue)) {
//       return;
//     }
//     _value = newValue;
//     _notify();
//   }
//
//   void init(T value) {
//     _equalizer =
//         value == null ? equalizer<T>(true) : equalizing<T>(value, true);
//     _value = value;
//   }
// }

mixin DisposersTrackable<T> on Reactive<T> {
  List<Disposer>? _disposers = <Disposer>[];
}

/// This is the mos basic reactive component
/// This will just update the ui when it updates
class Reactive<T> extends ChangeNotifier {
  Reactive(T? val) : _value = val;

  T? _value;

  void init(T val) {
    _value = val;
  }

  /// You should make sure to not call this if there is no value
  T get value {
    if (!Orchestrator.notInBuild) _reportRead();
    return _value as T;
  }

  set value(T newValue) {
    if (value == newValue) {
      return;
    }
    _value = newValue;
    notifyListeners();
  }

  @protected
  void _reportRead() => Orchestrator.read(this);

  @protected
  void reportAdd(VoidCallback disposer) => Orchestrator.add(disposer);
}

extension ValueOrNull<T> on Reactive<T> {
  T? get valueOrNull {
    if (!Orchestrator.notInBuild) _reportRead();
    return _value;
  }
}

/// This is used to pass private fields to other files
extension ReactiveProtectedAccess<T> on Reactive<T> {
  T? get staticOrNull => _value;
  void notify() => notifyListeners();
}

/// This is used to pass private fields to other files
extension DisposerTrackableProtectedAccess<T> on DisposersTrackable<T> {
  List<Disposer>? get disposers => _disposers;
  set disposers(List<Disposer>? newDisposers) => _disposers = newDisposers;
}

/// This is used to pass private fields to other files
extension RxTrackableProtectedAccess<T> on RxImpl<T> {
  List<Disposer>? get disposers => _disposers;
}
