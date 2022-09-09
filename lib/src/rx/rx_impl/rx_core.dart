import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../equality.dart';
import '../../orchestrator.dart';
import 'package:collection/collection.dart';
import 'rx_types.dart';
import 'rx_impl.dart';

/// Rx is the class for all your reactive need
///
/// [Rx<T>] implements [ValueListenable<T>] to dispatch event to the view
/// [Rx<T>] has a lazy loaded stream to suit your listen needs
/// Don't use any [StreamFilter<T>] when you listen and NO stream will be created
/// To use a [Rx<T>] just wrap data with Rx():
/// ```dart
/// final rxBool = Rx(false);
/// final rxUser = Rx(User());
/// final rxList = Rx(List<int>.generate(10, (i) => i + 1));
/// ```
/// To register callbacks use the [ever] funtion:
/// ```dart
/// ever(rxList, (List<int> value) => _validateList(rxList));
/// ever(() => rxUser.isValid, (bool value)=> rxBool(value));
/// ```
/// To use it wrap any in your view inside an Obx widget (it's sateless)
/// ``` dart
/// Obx(() => Text(rxUser.name));
/// ```
/// To implement extensions on you custom classes see README.md
class Rx<T> extends Reactive<T> {
  Rx._({super.initial, super.equalizer});

  /// Creates and Instance of the [Rx<T>] class with specified Equality
  ///
  /// This is usefull if you want to override the equality behavior
  /// For example you could pass `const SetEquality()` to have set equality
  /// You can use any Equality from the 'collection' package.
  /// If you want you can also create you own custom equality
  /// Either by extending any [Equality] class or implementing [Equality]
  Rx.withEq({super.equalizer, T? init}) : super(initial: init);

  /// Creates and Instance of the [Rx<T>] class
  ///
  /// Type [T] will be infered from the initial parameter
  /// If you want the paramater to bee null you will have to type your [Rx]
  /// You can just use `Rx<T>()` or use the provided typedef
  ///
  /// You should avoid creating [Rx<dynamic>] or [Rx<void>]
  /// You should avoid creating [Rx<Null>] use [Emitter] instead
  ///
  /// See also:
  /// - [Rx]
  /// - [Emmiter]
  Rx([T? initial]) : super(initial: initial);

  /// Creates an indistinct [Rx<T>]
  ///
  /// The contructed [Rx] will emit change everytime it's value changes
  /// Even if the value is the same as last time
  /// This is particuliry usefull in some scenarios
  Rx.indistinct([T? initial])
      : super(initial: initial, equalizer: const NeverEquality());

  /// Creates a [Rx<T>] from any [Stream<T>]
  ///
  /// [Stream<T>] do not hold a value but you may still want to init your [Rx<T>]
  /// If you want a starting value you can provide the `init` parameter
  ///
  /// Finally, by default the [Rx<T>] will be distinct if you want it indistinct
  /// you can set `distinct` to false.
  Rx.fromStream(
    Stream<T> stream, {
    T? init,
    Equality? equalizer,
    bool? distinct,
  }) : super(
            initial: init,
            equalizer: equalizer ??
                (distinct == null
                    ? const BaseEquality()
                    : distinct
                        ? const BaseEquality()
                        : const NeverEquality())) {
    bindStream(stream);
  }

  /// Creates a [Rx<T>] from any [Listenable]
  ///
  /// If your [Listenable] is [ValueListenable<T>] use [fromValueListenable] instead
  /// You need to provide a `onEvent` callback as [T Function()]
  /// This callback will be use to provide values to the [Rx<T>]
  ///
  /// [Listenable] do not hold a value but you may still want to init your [Rx<T>]
  /// If you want a starting value you can provide the `init` parameter
  /// You can also generate the first value with the callback by setting
  /// `callbackInit` parameter to true
  ///
  /// Finally, by default the [Rx<T>] will be distinct if you want it indistinct
  /// you can set `distinct` to false.
  Rx.fromListenable(Listenable listenable,
      {required T Function() onEvent,
      T? init,
      bool? distinct,
      Equality? equalizer,
      bool callbackInit = false})
      : super(
            initial: callbackInit ? onEvent() : init,
            equalizer: equalizer ??
                (distinct == null
                    ? const BaseEquality()
                    : distinct
                        ? const BaseEquality()
                        : const NeverEquality())) {
    bindListenable(listenable, onEvent: onEvent);
  }

  /// Creates a [Rx<T>] from any [ValueListenable<T>]
  ///
  /// If you want another value than the current value that is hold by the
  /// [ValueListenable<T>] you can provide the `init` parameter
  ///
  /// This function is practicaly usefull to create [Rx<T>] from
  /// a [ValueNotifier<T>] since it implements [ValueListenable<T>]
  ///
  /// Finally, by default the [Rx<T>] will be distinct if you want it indistinct
  /// you can set `distinct` to false.
  Rx.fromValueListenable(ValueListenable<T> listenable,
      {T? init, bool? distinct, Equality? equalizer})
      : super(
            initial: init ?? listenable.value,
            equalizer: equalizer ??
                (distinct == null
                    ? const BaseEquality()
                    : distinct
                        ? const BaseEquality()
                        : const NeverEquality())) {
    bindValueListenable(listenable);
  }

  /// Creates a [Rx<T>] from the result of any combinaison of [Rx]
  ///
  /// Pass a `callback` as [T Function()] containing your [Rx] transforms
  /// Example:
  /// ```dart
  /// // Creating average .2f RxString from two RxDouble
  /// final rxDouble = Rx(10.222222);
  /// final rxDouble2 = Rx(12.449382);
  /// final rxFuse = Rx.fuse(() => ((rxDouble() + rxDouble2())/2).toStringAsFixed(2));
  /// ```
  /// You should only use fuse for long lived Rx combinaisons
  /// Most of the time you sould favor using functions for [Rx] combinaisons
  /// See also:
  /// - [ever]
  /// - [observe]
  /// - [Rx]
  factory Rx.fuse(T Function() callback) => Orchestrator.fuse(callback);

  Rx<S> _clone<S>(
          {bool? distinct, S Function(T e)? convert, Equality? equalizer}) =>
      Rx._(
          initial: hasValue
              ? (convert?.call(staticOrNull as T) ?? staticOrNull as S)
              : null,
          equalizer: equalizer ??
              (distinct == null
                  ? this.equalizer
                  : distinct
                      ? const BaseEquality()
                      : const NeverEquality()));

  /// Creates a new [Rx<S>] based on [StreamTransformation<S,T>] of this [Rx<T>]
  ///
  /// The provided `transformer` will be used to tranform the incoming stream
  /// If you want to change the `distinct` property on the result [Rx<S>]
  /// Provide the [bool] paramterer `distinct`
  ///
  /// Avoid chaining this operator
  /// If you have a common operation to do,
  /// See also:
  /// - [pipeMap]
  /// - [pipeWhere]
  /// - [pipeMapWhere]
  Rx<S> pipe<S>(StreamTransformation<S, T> transformer,
          {S Function(T e)? init, bool? distinct}) =>
      _clone(
        convert: init,
        distinct: distinct,
      )..bindStream(transformer(_autoInitStream));

  /// Maps this [Rx<T>] into a new [Rx<S>]
  ///
  /// The provided `transfrom` parameter will be applied to each element
  /// If you want to change the `distinct` property on the result [Rx<S>]
  /// Provide the [bool] paramterer `distinct`
  /// [pipeMap] is a lightWeight operator since it does not need stream
  ///
  /// If you have more complex operation to do, use [pipe] instead
  Rx<S> pipeMap<S>(S Function(T e) transform,
      {bool? distinct, Equality? equalizer}) {
    final res =
        _clone(distinct: distinct, convert: transform, equalizer: equalizer);
    res.disposers.add(subscribe((T data) => res.value = transform(data)));
    return res;
  }

  /// Create a [Rx<T>] from this [Rx<T>] discarding elements based on a `test`
  ///
  /// Provided `test` parameter will be applied to each element to filter them
  /// If you want to change the `distinct` property on the result [Rx<T>]
  /// Provide the [bool] paramterer `distinct`
  ///
  /// If you have more complex operation to do, use [pipe] instead
  Rx<T> pipeWhere(bool Function(T e) test,
      {bool? distinct, Equality? equalizer}) {
    final res = _clone<T>(distinct: distinct, equalizer: equalizer);
    res.disposers.add(subscribe((T data) {
      if (test(data)) {
        res.value = data;
      }
    }));
    return res;
  }

  /// Maps this [Rx<T>] into [Rx<T>] discarding elements based on a `test`
  ///
  /// The provided `transfrom` parameter will be applied to each element
  /// Provided `test` parameter will be applied to each element to filter them
  /// If you want to change the `distinct` property on the result [Rx<S>]
  /// Provide the [bool] paramterer `distinct`
  ///
  /// If you have more complex operation to do, use [pipe] instead
  Rx<S> pipeMapWhere<S>(S Function(T e) transform, bool Function(T e) test,
      {bool? distinct, Equality? equalizer}) {
    final res =
        _clone(distinct: distinct, equalizer: equalizer, convert: transform);
    res.disposers.add(subscribe((T data) {
      if (test(data)) {
        res.value = transform(data);
      }
    }));
    return res;
  }

  /// Create an exact copy of the [Rx<T>]
  ///
  /// The copy will receive all events comming from the original
  Rx<T> dupe({Equality? equalizer}) =>
      Rx._(initial: staticOrNull, equalizer: equalizer ?? this.equalizer)
        ..bindRx(this);

  /// Create an exact copy of the [Rx<T>] but distinct enforced
  ///
  /// The copy will receive all events comming from the original
  /// Events that are indistinct will be skipped
  Rx<T> distinct() => dupe(equalizer: const BaseEquality());

  /// Create an exact copy of the [Rx<T>] but indistinct enforced
  ///
  /// The copy will receive all events comming from the original
  /// Be aware that even if this observable is indistinct
  /// The value it recieves from the parent will match parent policy
  Rx<T> indistinct() => dupe(equalizer: const NeverEquality());

  StreamController<T>? _controller;

  Stream<T>? _stream;
  Stream<T> get _autoInitStream {
    if (_stream != null) return _stream!;
    _controller = StreamController<T>.broadcast();
    addListener(_streamSub);
    _controller!.onCancel = () {
      if (!_controller!.hasListener) {
        removeListener(_streamSub);
        _controller!.close();
      }
    };
    return _controller!.stream;
  }

  void _streamSub(T e) => _controller?.add(e);

  @override
  VoidCallback subscribe(Function(T value) callback,
          {StreamFilter<T>? filter}) =>
      filter?.call(_autoInitStream).listen(callback).cancel ??
      super.subscribe(callback);

  @override
  VoidCallback subNow(Function(T value) callback, {StreamFilter<T>? filter}) {
    callback(staticOrNull as T);
    return filter?.call(_autoInitStream).listen(callback).cancel ??
        super.subscribe(callback);
  }

  @override
  VoidCallback subDiff(Function(T last, T current) callback,
      {StreamFilter<T>? filter}) {
    if (filter != null) {
      T oldVal = staticOrNull as T;
      listener(T value) {
        callback(oldVal, value);
        oldVal = staticOrNull as T;
      }

      return filter(_autoInitStream).listen(listener).cancel;
    }
    return super.subDiff(callback);
  }

  @override
  @mustCallSuper
  void dispose() {
    detatch();
    _controller?.close();
    super.dispose();
  }

  /// Binds an existing `Stream<T>` to this Rx<T> to keep the values in sync.
  ///
  /// You can bind multiple sources to update the value.
  /// Once a stream closes the subscription will cancel itself
  /// You can also cancel the sub with the provided callback
  Disposer bindStream(Stream<T> stream, [StreamFilter<T>? filter]) {
    final sub = (filter?.call(stream) ?? stream).listen((e) {
      value = e;
    }, cancelOnError: false);
    disposers.add(sub.cancel);
    clean() {
      disposers.remove(sub.cancel);
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
  Disposer bindRx(Rx<T> rx, [StreamFilter<T>? filter]) {
    final sub = rx.subscribe(
      (e) {
        value = e;
      },
      filter: filter,
    );
    disposers.add(sub);
    clean() {
      disposers.remove(sub);
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
    disposers.add(cancel);

    return () {
      disposers.remove(cancel);
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
    disposers.add(cancel);

    return () {
      disposers.remove(cancel);
      cancel();
    };
  }
}
