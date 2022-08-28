library obx;

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'dart:collection';

typedef ValueBuilderUpdateCallback<T> = void Function(T snapshot);
typedef ValueBuilderBuilder<T> = Widget Function(
    T snapshot, ValueBuilderUpdateCallback<T> updater);

class ObxElement = StatelessElement with StatelessObserverComponent;

class Obc extends ObxWidget {
  final WidgetBuilder builder;

  const Obc(this.builder, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => builder(context);
}

/// A StatelessWidget than can listen reactive changes.
abstract class ObxWidget extends StatelessWidget {
  /// Initializes [key] for subclasses.
  const ObxWidget({Key? key}) : super(key: key);
  @override
  StatelessElement createElement() => ObxElement(this);
}

/// a Component that can track changes in a reactive variable
mixin StatelessObserverComponent on StatelessElement {
  List<Disposer>? disposers = <Disposer>[];

  void getUpdate() {
    if (disposers != null) {
      scheduleMicrotask(markNeedsBuild);
    }
  }

  @override
  Widget build() {
    return Notifier.instance.append(
        NotifyData(disposers: disposers!, updater: getUpdate), super.build);
  }

  @override
  void unmount() {
    super.unmount();
    for (final disposer in disposers!) {
      disposer();
    }
    disposers!.clear();
    disposers = null;
  }
}

typedef WidgetCallback = Widget Function();

/// The [ObxWidget] is the base for all GetX reactive widgets
///
/// See also:
/// - [Obx]
/// - [ObxValue]

/// The simplest reactive widget in GetX.
///
/// Just pass your Rx variable in the root scope of the callback to have it
/// automatically registered for changes.
///
/// final _name = "GetX".obs;
/// Obx(() => Text( _name.value )),... ;
class Obx extends ObxWidget {
  final WidgetCallback builder;

  const Obx(this.builder);

  @override
  Widget build(BuildContext context) {
    return builder();
  }
}

/// Similar to Obx, but manages a local state.
/// Pass the initial data in constructor.
/// Useful for simple local states, like toggles, visibility, themes,
/// button states, etc.
///  Sample:
///    ObxValue((data) => Switch(
///      value: data.value,
///      onChanged: (flag) => data.value = flag,
///    ),
///    false.obs,
///   ),
// class ObxValue<T extends RxInteface> extends ObxWidget {

class ObxValue<T extends Object> extends ObxWidget {
  final Widget Function(T) builder;
  final T data;

  const ObxValue(this.builder, this.data, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => builder(data);
}

// This callback remove the listener on addListener function
typedef Disposer = void Function();

// replacing StateSetter, return if the Widget is mounted for extra validation.
// if it brings overhead the extra call,
typedef StateUpdate = void Function();

class ListNotifier extends Listenable
    with ListNotifierSingleMixin, ListNotifierGroupMixin {}

/// A Notifier with single listeners
class ListNotifierSingle = ListNotifier with ListNotifierSingleMixin;

/// A notifier with group of listeners identified by id
class ListNotifierGroup = ListNotifier with ListNotifierGroupMixin;

/// This mixin add to Listenable the addListener, removerListener and
/// containsListener implementation
mixin ListNotifierSingleMixin on Listenable {
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

mixin ListNotifierGroupMixin on Listenable {
  HashMap<Object?, ListNotifierSingleMixin>? _updatersGroupIds =
      HashMap<Object?, ListNotifierSingleMixin>();

  void _notifyGroupUpdate(Object id) {
    if (_updatersGroupIds!.containsKey(id)) {
      _updatersGroupIds![id]!._notifyUpdate();
    }
  }

  @protected
  void notifyGroupChildrens(Object id) {
    assert(_debugAssertNotDisposed());
    Notifier.instance.read(_updatersGroupIds![id]!);
  }

  bool containsId(Object id) {
    return _updatersGroupIds?.containsKey(id) ?? false;
  }

  @protected
  void refreshGroup(Object id) {
    assert(_debugAssertNotDisposed());
    _notifyGroupUpdate(id);
  }

  bool _debugAssertNotDisposed() {
    assert(() {
      if (_updatersGroupIds == null) {
        throw FlutterError('''A $runtimeType was used after being disposed.\n
'Once you have called dispose() on a $runtimeType, it can no longer be used.''');
      }
      return true;
    }());
    return true;
  }

  void removeListenerId(Object id, VoidCallback listener) {
    assert(_debugAssertNotDisposed());
    if (_updatersGroupIds!.containsKey(id)) {
      _updatersGroupIds![id]!.removeListener(listener);
    }
  }

  @mustCallSuper
  void dispose() {
    assert(_debugAssertNotDisposed());
    _updatersGroupIds?.forEach((key, value) => value.dispose());
    _updatersGroupIds = null;
  }

  Disposer addListenerId(Object? key, StateUpdate listener) {
    _updatersGroupIds![key] ??= ListNotifierSingle();
    return _updatersGroupIds![key]!.addListener(listener);
  }

  /// To dispose an [id] from future updates(), this ids are registered
  /// by `GetBuilder()` or similar, so is a way to unlink the state change with
  /// the Widget from the Controller.
  void disposeId(Object id) {
    _updatersGroupIds?[id]?.dispose();
    _updatersGroupIds!.remove(id);
  }
}

class Notifier {
  Notifier._();

  static Notifier? _instance;
  static Notifier get instance => _instance ??= Notifier._();

  NotifyData? _notifyData;

  void add(VoidCallback listener) {
    _notifyData?.disposers.add(listener);
  }

  void read(ListNotifierSingleMixin _updaters) {
    final listener = _notifyData?.updater;
    if (listener != null && !_updaters.containsListener(listener)) {
      _updaters.addListener(listener);
      add(() => _updaters.removeListener(listener));
    }
  }

  T append<T>(NotifyData data, T Function() builder) {
    _notifyData = data;
    final result = builder();
    if (data.disposers.isEmpty && data.throwException) {
      throw ObxError();
    }
    _notifyData = null;
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

class Rx<T> extends _RxImpl<T> {
  Rx(T initial, {bool distinct = true}) : super(initial, distinct: distinct);

  @override
  dynamic toJson() {
    try {
      return (value as dynamic)?.toJson();
    } on Exception catch (_) {
      throw '$T has not method [toJson]';
    }
  }
}

extension RxT<T> on T {
  /// Observable of the specified type
  Rx<T> get obs => Rx<T>(this);

  /// Observable of the nullbale type
  Rx<T?> get nobs => Rx<T?>(this);

  /// Indistinct observable of the specified type
  Rx<T> get iobs => Rx<T>(this, distinct: false);

  /// Indistinct observable of the nullable type
  Rx<T?> get inobs => Rx<T?>(this, distinct: false);
}

/// Base Rx class that manages all the stream logic for any Type.
abstract class _RxImpl<T> extends RxListenable<T> with RxObjectMixin<T> {
  _RxImpl(T initial, {bool distinct = true})
      : super(initial, distinct: distinct);

  void addError(Object error, [StackTrace? stackTrace]) {
    subject.addError(error, stackTrace);
  }

  /// Uses a callback to update [value] internally, similar to [refresh],
  /// but provides the current value as the argument.
  /// Makes sense for custom Rx types (like Models).

  void update(T Function(T? val) fn) {
    value = fn(value);
  }
}

/// This class is the foundation for all reactive (Rx) classes that makes Get
/// so powerful.
/// This interface is the contract that [_RxImpl]<T> uses in all it's
/// subclass.
abstract class RxInterface<T> extends Listenable {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const RxInterface();

  T get value;

  /// Calls `callback` with current value, when the value changes.
  StreamSubscription<T> listen(void Function(T event) onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError});
}

class RxListenable<T> extends ListNotifierSingle implements RxInterface<T> {
  RxListenable(T val, {bool distinct = true})
      : _distinct = distinct,
        _value = val;

  final bool _distinct;

  bool _triggered = false;

  bool get isDistinct => _distinct;

  StreamController<T>? _controller;

  void _initController() {
    final initVal = _value;
    bool firstCall = true;
    _controller =
        StreamController<T>.broadcast(onCancel: addListener(_streamListener));
    _stream = isDistinct
        ? _controller!.stream.distinct((i, e) {
            if (_triggered) {
              _triggered = false;
              return false;
            }
            return i == e;
          }).skipWhile((e) {
            if (firstCall) {
              firstCall = false;
              return e == initVal;
            }
            return false;
          })
        : _controller!.stream;
  }

  StreamController<T> get subject {
    if (_controller == null) {
      _initController();
    }
    return _controller!;
  }

  void _streamListener() {
    _controller?.add(_value);
  }

  Stream<T>? _stream;

  Stream<T> get stream {
    if (_controller == null) {
      _initController();
    }
    return _stream!;
  }

  /// Performs a trigger update
  /// Update the value, force notify listeners and update Widgets
  void trigger(T v) {
    if (!isDistinct || v != _value) {
      value = v;
      return;
    }
    _triggered = true;
    _controller?.add(v);
    _value = v;
    _notify();
  }

  /// Performs a silent update
  /// Update the value without updating widgets
  /// Listener won't be affected
  /// Piped observable wiil be notified
  void silent(T v) {
    _controller?.add(v);
    _value = v;
  }

  /// Same as silent but the listeners are not notified
  /// This means that piped object won't recieve the update
  void invisible(T v) {
    _value = v;
  }

  T _value;

  @override
  T get value {
    reportRead();
    return _value;
  }

  /// Called without a value it will refesh the ui
  /// Called with a value it will refresh the ui and update value
  void refresh([T? value]) {
    if (value != null) {
      if (_distinct && _value == value) {
        _controller?.add(value);
      } else {
        _value = value;
      }
    }
    _notify();
  }

  set value(T newValue) {
    if (_distinct && _value == newValue) {
      _controller?.add(newValue);
      return;
    }
    _value = newValue;
    _notify();
  }

  T? call([T? v]) {
    if (v != null) {
      value = v;
    }
    return value;
  }

  /// Allow to listen to the observable according to distinct
  @override
  StreamSubscription<T> listen(
    void Function(T e)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return stream.listen(
      onData,
      onError: onError,
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
    onData?.call(_value);
    return listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError ?? false,
    );
  }

  @override
  String toString() => value.toString();
}

mixin RxObjectMixin<T> on RxListenable<T> {
  @override
  T call([T? v]) {
    if (v != null) {
      value = v;
    }
    return value;
  }

  String get string => value.toString();

  @override
  String toString() => value.toString();

  /// Returns the json representation of `value`.
  dynamic toJson() => value;

  /// This equality override works for _RxImpl instances and the internal
  /// values.
  @override
  bool operator ==(Object o) {
    // Todo, find a common implementation for the hashCode of different Types.
    if (o is T) return value == o;
    if (o is RxObjectMixin<T>) return value == o.value;
    return false;
  }

  @override
  int get hashCode => value.hashCode;

  /// Updates the [value] and adds it to the stream, updating the observer
  /// Widget. Indistinct will always update whereas distinct (default) will only
  /// update when new value differs from the previous
  @override
  set value(T val) {
    if (isDisposed) return;
    super.value = val;
  }

  /// Binds an existing `Stream<T>` to this Rx<T> to keep the values in sync.
  /// You can bind multiple sources to update the value.
  /// Closing the subscription will happen automatically when the observer
  /// Widget (`ObxValue` or `Obx`) gets unmounted from the Widget tree.
  void bindStream(Stream<T> stream) {
    final sub = stream.listen((e) {
      value = e;
    });
    reportAdd(sub.cancel);
  }
}

extension RxOperators<T> on Rx<T> {
  Rx<S> _clone<S>({bool? distinct, S Function(T e)? convert}) =>
      Rx(convert?.call(_value) ?? _value as S,
          distinct: distinct ?? isDistinct);
  Rx<T> _dupe({bool? distinct}) =>
      _clone(distinct: distinct)..bindStream(subject.stream);

  /// Generate an obserable based on stream transformation observable
  Rx<S> pipe<S>(Stream<S> Function(Stream<T> e) transformer,
          {S Function(T e)? init, bool? distinct}) =>
      _clone(
        convert: init,
        distinct: distinct,
      )..bindStream(transformer(subject.stream));

  /// Create a standalone copy of the observale
  /// distinct parameter is used to enforce distinct or indistinct
  Rx<T> clone({bool? distinct}) => _clone(distinct: distinct);

  /// Create an exact copy with same stream of the observable
  Rx<T> dupe() => _dupe();

  /// Same as dupe but enforce distinct
  Rx<T> distinct() => _dupe(distinct: true);

  /// Same as dupe but enforce indistinct
  Rx<T> indistinct() => _dupe(distinct: false);

  /// This is used to get a non moving value
  T get static => clone()();

  /// Allow to bind to an object
  void bind<S extends Object>(S other) {
    if (other is Stream<T>) {
      return bindStream(other);
    }
    if (other is Rx<T>) {
      return bindStream(other.subject.stream);
    } else {
      try {
        bindStream((other as dynamic).stream);
      } catch (_) {
        throw '$T has not method [stream]';
      }
    }
  }
}
