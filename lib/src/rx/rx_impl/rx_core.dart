import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../equality.dart';
import '../../orchestrator.dart';
import 'package:collection/collection.dart';
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
  /// Creates and Instance of the [Rx<T>] class with specified Equality
  ///
  /// This is usefull if you want to override the equality behavior
  /// For example you could pass `const SetEquality()` to have set equality
  /// You can use any Equality from the 'collection' package.
  /// If you want you can also create you own custom equality
  /// Either by extending any [Equality] class or implementing [Equality]
  Rx.withEq({super.eq, T? init}) : super(initial: init);

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
      : super(initial: initial, eq: const NeverEquality());

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
    Equality? eq,
    bool? distinct,
  }) : super(
            initial: init,
            eq: eq ??
                (distinct == null
                    ? const Equality()
                    : distinct
                        ? const Equality()
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
      Equality? eq,
      bool callbackInit = false})
      : super(
            initial: callbackInit ? onEvent() : init,
            eq: eq ??
                (distinct == null
                    ? const Equality()
                    : distinct
                        ? const Equality()
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
      {T? init, bool? distinct, Equality? eq})
      : super(
            initial: init ?? listenable.value,
            eq: eq ??
                (distinct == null
                    ? const Equality()
                    : distinct
                        ? const Equality()
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
}
