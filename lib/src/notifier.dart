import 'dart:async';
import 'package:flutter/foundation.dart';

import 'rx/rx_impl/rx_core.dart';
import 'debouncer.dart';

// This callback remove the listener on addListener function
typedef Disposer = void Function();

// replacing StateSetter, return if the Widget is mounted for extra validation.
// if it brings overhead the extra call,
typedef StateUpdate = void Function();

/// A Notifier with single listeners
class ListNotifier = Listenable with ListNotifierMixin;

/// This mixin add to Listenable the addListener, removerListener and
/// containsListener implementation
mixin ListNotifierMixin on Listenable {
  List<StateUpdate>? _updaters = <StateUpdate>[];

  @override
  Disposer addListener(StateUpdate listener) {
    assert(_debugAssertNotDisposed());
    _updaters!.add(listener);
    return () => _updaters!.remove(listener);
  }

  bool containsListener(StateUpdate listener) {
    return _updaters?.contains(listener) ?? false;
  }

  @override
  void removeListener(VoidCallback listener) {
    assert(_debugAssertNotDisposed());
    _updaters!.remove(listener);
  }

  @protected
  void _notify() {
    assert(_debugAssertNotDisposed());
    _notifyUpdate();
  }

  @protected
  void reportRead() {
    Notifier.instance.read(this);
  }

  @protected
  void reportAdd(VoidCallback disposer) {
    Notifier.instance.add(disposer);
  }

  void _notifyUpdate() {
    final list = _updaters?.toList() ?? [];

    for (var element in list) {
      element();
    }
  }

  bool get isDisposed => _updaters == null;

  bool _debugAssertNotDisposed() {
    assert(() {
      if (isDisposed) {
        throw FlutterError('''A $runtimeType was used after being disposed.\n
'Once you have called dispose() on a $runtimeType, it can no longer be used.''');
      }
      return true;
    }());
    return true;
  }

  int get listenersLength {
    assert(_debugAssertNotDisposed());
    return _updaters!.length;
  }

  @mustCallSuper
  void dispose() {
    assert(_debugAssertNotDisposed());
    _updaters = null;
  }
}

class Notifier {
  Notifier._();

  static Notifier? _instance;
  static Notifier get instance => _instance ??= Notifier._();
  static bool get inBuild => instance._notifyData != null;

  NotifyData? _notifyData;

  void add(VoidCallback listener) {
    _notifyData?.disposers.add(listener);
  }

  void read(ListNotifierMixin updaters) {
    final listener = _notifyData?.updater;
    if (listener != null && !updaters.containsListener(listener)) {
      updaters.addListener(listener);
      add(() => updaters.removeListener(listener));
    }
  }

  T append<T>(NotifyData data, T Function() builder) {
    _notifyData = data;
    final result = builder();
    if (data.disposers.isEmpty && data.throwException) {
      throw const ObxError();
    }
    _notifyData = null;
    return result;
  }

  T observe<T>(T Function() builder) {
    if (_notifyData == null) return builder();
    final previousData = _notifyData;
    final base = OneShot<T>();
    final debouncer = Debouncer(delay: const Duration(milliseconds: 15));
    _notifyData = NotifyData(
        updater: () => debouncer(() => base.value = builder()),
        disposers: [builder]);
    final result = builder();
    _notifyData = previousData;
    base.value = result;
    return base.value;
  }

  T silent<T>(T Function() builder) {
    final previousData = _notifyData;
    _notifyData = null;
    final result = builder();
    _notifyData = previousData;
    return result;
  }
}

class NotifyData {
  const NotifyData(
      {required this.updater,
      required this.disposers,
      this.throwException = true});
  final StateUpdate updater;
  final List<VoidCallback> disposers;
  final bool throwException;
}

class ObxError {
  const ObxError();
  @override
  String toString() {
    return """
      [Get] the improper use of a GetX has been detected. 
      You should only use GetX or Obx for the specific widget that will be updated.
      If you are seeing this error, you probably did not insert any observable variables into GetX/Obx 
      or insert them outside the scope that GetX considers suitable for an update 
      (example: GetX => HeavyWidget => variableObservable).
      If you need to update a parent widget and a child widget, wrap each one in an Obx/GetX.
      """;
  }
}

class OneShotDual<T, S, V> extends OneShot<T> {
  OneShotDual(Rx<S> e1, Rx<V> e2, T Function(S e1, V e2) callback)
      : super(callback(e1.static, e2.static)) {
    e1.listen((e1) {
      callback(e1, e2.static);
    });
    e2.listen((e2) {
      callback(e1.static, e2);
    });
  }
}

abstract class StreamBindable<T> {
  void bindStream(Stream<T> stream);
}

/// This class is internal to the package
/// It's used to get value that refresh themselves
/// For usage examples check in rx_iterable
class OneShot<T> extends Reactive<T> implements StreamBindable {
  OneShot(super.val);

  static OneShot<T> fromMap<E, T>(
    Rx<E> parent,
    T Function(E e) transform,
  ) =>
      OneShot(parent.hasValue ? transform(parent.static) : null)
        ..bindStream(parent.stream.map(transform));

  // static OneShot<T> fromMap2<E, V, T>(
  //   Rx<E> parent1,
  //   Rx<V> parent2,
  //   T Function(E e1, V e2) transform,
  // ) =>
  //     OneShot(parent1.hasValue || parent2.hasValue
  //         ? transform(parent1.static, parent2.static)
  //         : null)
  //       // TODO: find a way to map this properli
  //       ..bindStream(parent1.stream.map(transform));

  // TODO: implement proper cleaning
  @override
  void _notify() {
    super._notify();
    dispose();
  }

  @override
  void bindStream(Stream stream) {
    // TODO: implement bindStream
  }
}

class DualShot<T> extends Reactive<T> {
  DualShot([super.val]);

  @override
  set value(T value) {
    if (!hasValue) {
      _value = value;
      return;
    }
    super.value = value;
  }

  @override
  void _notify() {
    super._notify();
    dispose();
  }
}

/// This is the mos basic reactive component
class Reactive<T> extends ListNotifier implements ValueListenable<T> {
  Reactive(T? val) : _value = val;

  bool get hasValue => null is T || _value != null;

  T? _value;

  @override
  T get value {
    if (!hasValue) {
      throw FlutterError(
          '''Trying to access `value` for Rx<$T> but it's not initialized.
Make sure to initialize it first or use `ValueOrNull` instead.''');
    }
    reportRead();
    return _value as T;
  }

  set value(T newValue) {
    if (_value == newValue) {
      return;
    }
    _value = newValue;
    _notify();
  }
}

/// This class is the foundation for all reactive (Rx) classes that makes Get
/// so powerful.
/// This interface is the contract that [_RxImpl]<T> uses in all it's
/// subclass.

class RxImpl<T> extends Reactive<T> {
  RxImpl(super.val, {bool distinct = true})
      : _distinct = T == Null ? false : distinct;

  final _subbed = <VoidCallback>[];

  final bool _distinct;
  bool get isDistinct => _distinct;

  T? get valueOrNull => hasValue ? value : null;

  StreamController<T>? _controller;

  void _initController() {
    _controller = StreamController<T>.broadcast();
    _stream = _controller!.stream;
  }

  StreamController<T> get subject {
    if (_controller == null) {
      _initController();
    }
    return _controller!;
  }

  Stream<T>? _stream;

  Stream<T> get stream {
    if (_controller == null) {
      _initController();
    }
    return _stream!;
  }

  /// Trigger update with a new value
  /// Update the value, force notify listeners and update Widgets
  void trigger(T v) {
    _controller?.add(v);
    _value = v;
    _notify();
  }

  /// Trigger update with current value
  /// Force notify listeners and update Widgets
  void emit() {
    if (hasValue) {
      trigger(_value as T);
    }
  }

  /// Silent update
  /// Update value without updating widgets and listeners
  /// This means that piped object won't recieve the update
  void silent(T v) {
    _value = v;
  }

  @override
  @mustCallSuper
  void dispose() {
    assert(_debugAssertNotDisposed());
    detatch();
    _controller?.close();
    super.dispose();
  }

  /// This method allow to remove all incoming subs
  /// This will detatched this obs from stream listenable other piped obs
  void detatch() {
    for (VoidCallback callbak in _subbed) {
      callbak();
    }
    _subbed.clear();
  }

  /// This is used to get a non moving value
  T get static {
    if (!hasValue) {
      if (!hasValue) {
        throw FlutterError(
            '''Trying to access `static` for Rx<$T> but it's not initialized.
Make sure to initialize it first or use `StaticOrNull` instead.''');
      }
    }
    return _value as T;
  }

  T? get staticOrNull => hasValue ? _value : null;

  /// Called without a value it will refesh the ui
  /// Called with a value it will refresh the ui and update value
  void refresh([T? v]) {
    if (v != null) {
      if (!isDistinct || v != _value) {
        _controller?.add(v);
      }
      _value = v;
    }
    _notify();
  }

  @override
  set value(T newValue) {
    if (_value == newValue) {
      if (!isDistinct) {
        _controller?.add(_value as T);
        _notify();
      }
      return;
    }
    _controller?.add(newValue);
    _value = newValue;
    _notify();
  }

  T? call([T? v]) {
    if (v != null) {
      value = v;
    }
    return valueOrNull;
  }

  /// Allow to listen to the observable
  StreamSubscription<T> listen(
    void Function(T e)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return stream.listen(
      onData,
      onError: onError,

      /// Implement cleanUp of the controller if there is no more streams
      onDone: onDone,
      cancelOnError: cancelOnError ?? false,
    );
  }

  /// Same as listen but is also called now
  StreamSubscription<T> listenNow(
    void Function(T e)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    if (hasValue) {
      onData?.call(_value as T);
    }
    return listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError ?? false,
    );
  }

  VoidCallback bindRx(Rx<T> rx, [Stream<T>? stream]) {
    final sub = stream == null
        ? rx.listen((e) {
            value = e;
          })
        : stream.listen(
            (e) {
              value = e;
            },
            cancelOnError: false,
            // TODO: implement some cleanup
            // onDone: rx._checkClean,
          );
    _subbed.add(sub.cancel);
    // ignore: prefer_function_declarations_over_variables
    final clean = () {
      _subbed.remove(sub.cancel);
      sub.cancel();
    };
    sub.onDone(clean);
    return clean;
  }

  /// Binds an existing `ValueListenable<T>` this might be a `ValueNotifier<T>`
  /// Keeping this Rx<T> values in sync.
  /// You can bind multiple sources to update the value.
  /// It's impossible to know when a ValueListenable is Done
  /// You will have to clean it up yourself
  /// For that you can call the provided callback
  VoidCallback bindListenable(ValueListenable<T> listenable) {
    // ignore: prefer_function_declarations_over_variables
    final closure = () {
      value = listenable.value;
    };
    listenable.addListener(closure);
    // ignore: prefer_function_declarations_over_variables
    final cancel = () => listenable.removeListener(closure);
    _subbed.add(cancel);

    return () {
      _subbed.remove(cancel);
      cancel();
    };
  }

  @override
  String toString() => value.toString();
}

bool isSubtype<S, T>() => <S>[] is List<T>;
