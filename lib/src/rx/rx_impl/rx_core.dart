import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../orchestrator.dart';
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
class Rx<T> extends RxImpl<T> {
  Rx._({T? initial, bool distinct = true}) : super(initial, distinct: distinct);

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
  Rx([T? initial]) : super(initial, distinct: true);

  /// Creates an indistinct [Rx<T>]
  ///
  /// The contructed [Rx] will emit change everytime it's value changes
  /// Even if the value is the same as last time
  /// This is particuliry usefull in some scenarios
  Rx.indistinct([T? initial]) : super(initial, distinct: false);

  /// Creates a [Rx<T>] from any [Stream<T>]
  ///
  /// [Stream<T>] do not hold a value but you may still want to init your [Rx<T>]
  /// If you want a starting value you can provide the `init` parameter
  ///
  /// Finally, by default the [Rx<T>] will be distinct if you want it indistinct
  /// you can set `distinct` to false.
  Rx.fromStream(Stream<T> stream, {T? init, super.distinct}) : super(init) {
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
      super.distinct,
      bool callbackInit = false})
      : super(callbackInit ? onEvent() : init) {
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
      {T? init, super.distinct})
      : super(init ?? listenable.value) {
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

  Rx<S> _clone<S>({bool? distinct, S Function(T e)? convert}) => Rx._(
      initial: hasValue ? (convert?.call(value) ?? value as S) : null,
      distinct: distinct ?? isDistinct);
  Rx<T> _dupe({bool? distinct}) =>
      Rx._(initial: staticOrNull, distinct: distinct ?? isDistinct)
        ..bindRx(this);

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
      )..bindStream(transformer(stream));

  /// Maps this [Rx<T>] into a new [Rx<S>]
  ///
  /// The provided `transfrom` parameter will be applied to each element
  /// If you want to change the `distinct` property on the result [Rx<S>]
  /// Provide the [bool] paramterer `distinct`
  /// [pipeMap] is a lightWeight operator since it does not need stream
  ///
  /// Avoid chaining this operator
  /// If you have more complex operation to do, use [pipe] instead
  Rx<S> pipeMap<S>(S Function(T e) transform, {bool? distinct}) {
    final res = _clone(distinct: distinct, convert: transform);
    res.disposers?.add(listen((T data) => res.value = transform(data)));
    return res;
  }

  /// Create a [Rx<T>] from this [Rx<T>] discarding elements based on a `test`
  ///
  /// Provided `test` parameter will be applied to each element to filter them
  /// If you want to change the `distinct` property on the result [Rx<T>]
  /// Provide the [bool] paramterer `distinct`
  ///
  /// Avoid chaining this operator
  /// If you have more complex operation to do, use [pipe] instead
  Rx<T> pipeWhere(bool Function(T e) test, {bool? distinct}) =>
      pipe((e) => e.where(test), distinct: distinct);

  /// Maps this [Rx<T>] into [Rx<T>] discarding elements based on a `test`
  ///
  /// The provided `transfrom` parameter will be applied to each element
  /// Provided `test` parameter will be applied to each element to filter them
  /// If you want to change the `distinct` property on the result [Rx<S>]
  /// Provide the [bool] paramterer `distinct`
  ///
  /// Avoid chaining this operator
  /// If you have more complex operation to do, use [pipe] instead
  Rx<S> pipeMapWhere<S>(S Function(T e) transform, bool Function(T e) test,
          {bool? distinct}) =>
      pipe((e) => e.where(test).map(transform),
          init: transform, distinct: distinct);

  /// Create an exact copy of the [Rx<T>]
  ///
  /// The copy will receive all events comming from the original
  Rx<T> dupe() => _dupe();

  /// Create an exact copy of the [Rx<T>] but distinct enforced
  ///
  /// The copy will receive all events comming from the original
  /// Events that are indistinct will be skipped
  Rx<T> distinct() => _dupe(distinct: true);

  /// Create an exact copy of the [Rx<T>] but indistinct enforced
  ///
  /// The copy will receive all events comming from the original
  /// Be aware that even if this observable is indistinct
  /// The value it recieves from the parent will match parent policy
  Rx<T> indistinct() => _dupe(distinct: false);
}
