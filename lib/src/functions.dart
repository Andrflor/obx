import 'dart:async';

import 'package:flutter/foundation.dart';

import './rx/rx_impl/rx_mixins.dart';
import '../obx.dart';
import 'notifier.dart';

/// Observes the results of any combinaison of [Rx] variables
///
/// This function is the refined state(less) control by excellence
/// You can call it with any closure containing any combinaison of [Rx]
/// The UI will rebuild only if the value of the result changes
///  Example with [RxDouble] data1 and [RxDouble] data2:
///     Obx(
///       () => Text(observe(() =>
///           data2.toStringAsFixed(0) == data2.toStringAsFixed(0)
///               ? "Equals"
///               : "Different")),
///     ),
/// Will only rebuild when the result String ("Equals" or "Different") changes
///
/// [observe] is smart, it knows where it's called
/// In fact, you can call it anywhere
/// Furthermore calling it outside of a reactive widget has zero cost**
/// This especially pratical to make getters
/// **The exact cost is just a boolean check
///
/// With complex structures you may endup with [observe] inside [observe]
/// Again, it has zero cost and you should feel free to do so
///
/// You may have a lot of [Rx] updating at the same time
/// Or even [Rx] updating way more often that once a frame
/// [observe] will make sure that your closure is evaluated only when needed
///
/// Since you give a closure, you may want to update [Rx] values inside it
/// This is generaly a bad practice but you can still try it
/// [obsreve] will prevent most infinite loop sceniarios
/// Be aware that re-building an [Obx] requires to call [obsreve] again
/// So you may end up with those changes done twice
/// This is the reason why i wouldn't recommend it
T observe<T>(T Function() builder) {
  return Notifier.inBuild ? Notifier.instance.observe(builder) : builder();
}

/// Run a calback each time the observable [Object] changes
///
/// Takes an observable parameter that can be either
/// [Rx<T>] or [Stream<T>] or [ValueListenable<T>] or [T Function()]
/// [ever] provides an harmonized interface for all of those types
/// onData is the [Function(T value)] callback to apply
/// You can also specify standard stream subscription parameters
/// onError, onDone, cancelOnError
/// It will return a [StreamSubscription<T>]
///
/// By default [ever] will respect the distinct rule of the incoming observable
/// To enforce [ever] to be distinct you can use the enforceDistinct parameter
///
/// Passing a [T Function()] is practicaly usefull
/// Like [observe] the callback will fire only when the result changes
/// Examples with [RxDouble] data1 and [RxDouble] data2:
/// ever(data1, (bool value) => // Some work here);
/// ever(data2, someBooleanHandler);
/// ever(
///     () => data1.toStringAsFixed(0) == data2.toStringAsFixed(0)
///         ? "Equals"
///         : "Different",
///     someStringHandler);
///
/// Since [observe] is zero cost ouside a proper build context
/// We can also do other things like:
/// bool get equals => observe(() => data1 == data2);
/// void displayOnEquals(bool equality) {
///   if (equality) {
///      print("I've got an equality");
///   }
/// }
/// ever(() => equals, displayEqual);
///
/// [ever] is a reactive callback handler
/// Like [observe] it will only evaluate your closure when really needed
/// Used with [Rx<T>], [Stream<T>] or [ValueListenable<T>]
/// It simply acts as a stream listener
///
/// The filter parameter is intended for advanced users
/// It takes a [StreamFilter<T>] aka [Stream<T> Function(Stream<T>)]
/// It allows you to make any stream filtering operation
/// Example: (stream) => stream.skip(1).skipWhile(//someCondition).take(5)
StreamSubscription<T> ever<T>(
  Object observable,
  Function(T value) onData, {
  StreamFilter<T>? filter,
  void Function()? onDone,
  Function? onError,
  bool? cancelOnError,
  bool forceDistinct = false,
}) {
  if (observable is T Function()) {
    return Notifier.instance.listen(observable).listen(
          onData,
          onDone: onDone,
          cancelOnError: cancelOnError,
          onError: onError,
          filter: filter,
        );
  }
  if (observable is Rx<T>) {
    return (forceDistinct && !observable.isDistinct
            ? observable.distinct()
            : observable)
        .listen(
      onData,
      onDone: onDone,
      cancelOnError: cancelOnError,
      onError: onError,
      filter: filter,
    );
  }
  if (observable is Stream<T>) {
    observable = forceDistinct ? observable.distinct() : observable;
    return (filter == null ? observable : filter(observable)).listen(
      onData,
      onDone: onDone,
      cancelOnError: cancelOnError ?? false,
      onError: onError,
    );
  }
  if (observable is ValueListenable<T>) {
    final obs = Rx.fromValueListenable(observable, distinct: forceDistinct);
    obs.subject.onCancel = obs.dispose;
    return obs.listen(
      onData,
      onDone: onDone,
      cancelOnError: cancelOnError ?? false,
      onError: onError,
      filter: filter,
    );
  }

  _debugAssertObservableType(observable, T, 'ever');
  return EmptyStreamSubscription<T>();
}

/// Runs a calback each time the observable [Object] changes and now
///
/// Like the [ever] function but the callback will also fire now
/// For complete docuementation see [ever]
///
/// See also:
/// - [onceNow]
/// - [debounceNow]
/// - [ever]
StreamSubscription<T> everNow<T>(
  Object observable,
  Function(T value) onData, {
  StreamFilter<T>? filter,
  Function? onError,
  void Function()? onDone,
  bool? cancelOnError,
  bool forceDistinct = false,
}) {
  if (observable is T Function()) {
    return Notifier.instance.listen(observable).listenNow(
          onData,
          onDone: onDone,
          cancelOnError: cancelOnError,
          onError: onError,
          filter: filter,
        );
  }
  if (observable is Rx<T>) {
    return (forceDistinct && !observable.isDistinct
            ? observable.distinct()
            : observable)
        .listenNow(
      onData,
      onDone: onDone,
      cancelOnError: cancelOnError,
      onError: onError,
      filter: filter,
    );
  }
  if (observable is Stream<T>) {
    observable = forceDistinct ? observable.distinct() : observable;
    return (filter == null ? observable : filter(observable)).listen(
      onData,
      onDone: onDone,
      cancelOnError: cancelOnError ?? false,
      onError: onError,
    );
  }
  if (observable is ValueListenable<T>) {
    final obs = Rx.fromValueListenable(observable, distinct: forceDistinct);
    obs.subject.onCancel = obs.dispose;
    return obs.listenNow(
      onData,
      onDone: onDone,
      cancelOnError: cancelOnError ?? false,
      onError: onError,
      filter: filter,
    );
  }
  _debugAssertObservableType(observable, T, 'everNow');
  return EmptyStreamSubscription<T>();
}

void _debugAssertObservableType<S>(S value, Type inner, String name) {
  assert(() {
    throw FlutterError(
        '''The type ${value.runtimeType} is not respecting the type constraints in [$name]
it should [Rx<$inner>], [Stream<$inner>] or [ValueListenable<$inner>] or [$inner Function()]
or you may have wrongly typed $inner in the onData [Function($inner value)] function''');
  }());
}

/// Runs a calback once the observable [Object] changes
///
/// Like the [ever] function but the callback is only run once
/// For complete docuementation see [ever]
///
/// See also:
/// - [ever]
/// - [debounce]
/// - [onceNow]
StreamSubscription<T> once<T>(
  Object observable,
  Function(T value) onData, {
  Function? onError,
  void Function()? onDone,
  bool? cancelOnError,
}) =>
    ever(
      observable,
      onData,
      filter: (stream) => stream.take(1),
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );

/// Runs a calback once the observable [Object] changes and now
///
/// Like the [ever] function but the callback runs only once and now
/// Like the [once] function but the callback also fires now
/// For complete docuementation see [ever]
///
/// See also:
/// - [once]
/// - [everNow]
/// - [debounceNow]
StreamSubscription<T> onceNow<T>(
  Object observable,
  Function(T value) onData, {
  Function? onError,
  void Function()? onDone,
  bool? cancelOnError,
  bool forceDistinct = false,
}) =>
    everNow(
      observable,
      onData,
      filter: (stream) => stream.take(1),
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
      forceDistinct: forceDistinct,
    );

/// Runs a calback with debounce dalay when the observable [Object] changes
///
/// Like the [ever] function but the callback has a debouncer
/// This is convenient to prevent the user from blasting an API
/// For complete docuementation see [ever]
///
/// Be aware, since it returns a StreamSubscription<T> you could change the
/// onData callback, but then you would loose the debounce property
///
/// See also:
/// - [ever]
/// - [once]
/// - [debounceNow]
StreamSubscription<T> debounce<T>(
  Object observable,
  Function(T value) onData, {
  StreamFilter<T>? filter,
  Duration delay = const Duration(milliseconds: 800),
  Function? onError,
  void Function()? onDone,
  bool? cancelOnError,
  bool forceDistinct = false,
}) {
  final debouncer = Debouncer(delay: delay);
  return ever(
    observable,
    (value) {
      debouncer(() {
        onData(value);
      });
    },
    filter: filter,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
    forceDistinct: forceDistinct,
  );
}

/// Runs a calback with debounce dalay when observable [Object] changes and now
///
/// Like the [ever] function but the callback has a debouncer
/// Like the [debounce] function but the callback also fires now
/// This is convenient to prevent the user from blasting an API
/// For complete docuementation see [ever]
///
/// Be aware, since it returns a StreamSubscription<T> you could change the
/// onData callback, but then you would loose the debounce property
///
/// See also:
/// - [everNow]
/// - [onceNow]
/// - [debounce]
StreamSubscription<T> debounceNow<T>(
  Object observable,
  Function(T value) onData, {
  StreamFilter<T>? filter,
  Duration delay = const Duration(milliseconds: 800),
  Function? onError,
  void Function()? onDone,
  bool? cancelOnError,
  bool forceDistinct = false,
}) {
  final debouncer = Debouncer(delay: delay);
  return everNow(
    observable,
    (value) {
      debouncer(() {
        onData(value);
      });
    },
    filter: filter,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
    forceDistinct: forceDistinct,
  );
}
