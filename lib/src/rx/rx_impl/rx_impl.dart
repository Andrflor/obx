part of '../../orchestrator.dart';

class RxImpl<T> extends Reactive<T> {
  RxImpl({super.initial, super.eq});

  Rx<S> _clone<S>({bool? distinct, S Function(T e)? convert, Equality? eq}) =>
      Rx.withEq(
          init: hasValue ? (convert?.call(_data as T) ?? _data as S) : null,
          eq: eq ??
              (distinct == null
                  ? _eq
                  : distinct
                      ? const Equality()
                      : const NeverEquality()));

  /// Creates a new [Rx<S>] based on [StreamTransformation<S,T>] of this [Rx<T>]
  ///
  /// The provided `transformer` will be used to tranform the incoming stream
  /// If you want to change the `distinct` property on the result [Rx<S>]
  /// Provide the [bool] paramterer `distinct`
  ///
  /// Avoid chaining this operator
  /// To do common operation, prefer the other `pipe` operators
  /// See also:
  /// - [pipeMap]
  /// - [pipeWhere]
  /// - [pipeMapWhere]
  Rx<S> pipe<S>(StreamTransformation<S, T> transformer,
          {S Function(T e)? init, bool? distinct, Equality? eq}) =>
      _clone(
        convert: init,
        eq: eq,
        distinct: distinct,
      )..bindStream(transformer(stream));

  /// Maps this [Rx<T>] into a new [Rx<S>]
  ///
  /// The provided `transfrom` parameter will be applied to each element
  /// If you want to change the `distinct` property on the result [Rx<S>]
  /// Provide the [bool] paramterer `distinct`
  /// [pipeMap] is a lightWeight operator since it does not need stream
  ///
  /// If you have more complex operation to do, use [pipe] instead
  Rx<S> pipeMap<S>(S Function(T e) transform, {bool? distinct, Equality? eq}) =>
      pipe<S>(
        (e) => e.map(transform),
        init: transform,
        distinct: distinct,
        eq: eq,
      );

  /// Create a [Rx<T>] from this [Rx<T>] discarding elements based on a `test`
  ///
  /// Provided `test` parameter will be applied to each element to filter them
  /// If you want to change the `distinct` property on the result [Rx<T>]
  /// Provide the [bool] paramterer `distinct`
  /// [pipeWhere] is a lightWeight operator since it does not need stream
  ///
  /// If you have more complex operation to do, use [pipe] instead
  Rx<T> pipeWhere(bool Function(T e) test, {bool? distinct, Equality? eq}) =>
      pipe<T>(
        (e) => e.where(test),
        init: hasValue && test(_data as T) ? (e) => e : null,
        distinct: distinct,
        eq: eq,
      );

  /// Maps this [Rx<T>] into [Rx<T>] discarding elements based on a `test`
  ///
  /// The provided `transfrom` parameter will be applied to each element
  /// Provided `test` parameter will be applied to each element to filter them
  /// If you want to change the `distinct` property on the result [Rx<S>]
  /// Provide the [bool] paramterer `distinct`
  /// [pipeMapWhere] is a lightWeight operator since it does not need stream
  ///
  /// If you have more complex operation to do, use [pipe] instead
  Rx<S> pipeMapWhere<S>(S Function(T e) transform, bool Function(T e) test,
          {bool? distinct, Equality? eq}) =>
      pipe<S>(
        (e) => e.where(test).map(transform),
        init: hasValue && test(_data as T) ? transform : null,
        distinct: distinct,
        eq: eq,
      );

  /// Create an exact copy of the [Rx<T>]
  ///
  /// The copy will receive all events comming from the original
  Rx<T> dupe({Equality? eq}) =>
      Rx.withEq(init: _data, eq: eq ?? _eq)..bindRx(this);

  /// Create an exact copy of the [Rx<T>] but distinct enforced
  ///
  /// The copy will receive all events comming from the original
  /// Events that are indistinct will be skipped
  Rx<T> distinct() => dupe(eq: const Equality());

  /// Create an exact copy of the [Rx<T>] but indistinct enforced
  ///
  /// The copy will receive all events comming from the original
  /// Be aware that even if this observable is indistinct
  /// The value it recieves from the parent will match parent policy
  Rx<T> indistinct() => dupe(eq: const NeverEquality());

  @override
  String toString() => data.toString();

  // We check if we have a distinct observable
  bool get isDistinct => equalizer is! NeverEquality;

  /// Simple listen to an [Rx]
  ///
  /// Allow to pass a StreamFilter to modify the stream
  /// If no [StreamFilter] is provided no [Stream] will be used
  /// Thus resulting in up to 90x faster results
  /// So only use a StreamFilter if you really need it
  ///
  /// Returns a [VoidCallback] to dispose the listener

  /// Binds an existing `Stream<T>` to this Rx<T> to keep the values in sync.
  ///
  /// You can bind multiple sources to update the value.
  /// Once a stream closes the subscription will cancel itself
  /// You can also cancel the sub with the provided callback
  StreamSubscription<T> bindStream(Stream<T> stream,
          [StreamFilter<T>? filter]) =>
      (filter?.call(stream) ?? stream).listen(
        add,
        onError: addError,
        cancelOnError: false,
      );

  /// Binding to this [Rx<T>] to any other [Rx<T>]
  ///
  /// Binds an existing [ValueListenable<T>] this might be a [ValueNotifier<T>]
  /// Keeping this [Rx<T>] values in sync.
  /// You can bind multiple sources to update the value.
  /// It's impossible to know when a [ValueListenable] is done
  /// You will have to clean it up yourself
  /// For that you can call the provided [Disposer]
  StreamSubscription<T> bindRx(RxImpl<T> rx, [StreamFilter<T>? filter]) =>
      (filter?.call(rx.stream) ?? rx.stream).listen(
        add,
        onError: addError,
        cancelOnError: false,
      );

  /// Binding to any listener with callback
  ///
  /// Binds an existing [ValueListenable<T>] this might be a [ValueNotifier<T>]
  /// Keeping this [Rx<T>] values in sync.
  /// You can bind multiple sources to update the value.
  /// It's impossible to know when a [ValueListenable] is done
  /// You will have to clean it up yourself
  /// For that you can call the provided [Disposer]
  RxSubscription<T> bindValueListenable(
    ValueListenable<T> listenable,
  ) {
    closure() {
      data = listenable.value;
    }

    listenable.addListener(closure);

    return listen(null, onDone: () {
      listenable.removeListener(closure);
    });
  }

  /// Binding to any listener with provided `onEvent` callback
  ///
  /// Binds an existing [Listenable]
  /// Keeping this [Rx<T>] values in sync.
  /// You can bind multiple sources to update the value.
  /// It's impossible to know when a [Listenable] is done
  /// You will have to clean it up yourself
  /// For that you can call the provided [Disposer]
  RxSubscription<T> bindListenable(Listenable listenable,
      {required T Function() onEvent}) {
    closure() => data = onEvent();
    listenable.addListener(closure);

    return listen(null, onDone: () {
      listenable.removeListener(closure);
    });
  }
}

/// This is an internal class
///
/// It's the basic class for the [observe] function
/// It's name comes from the fact that it is set up
/// Then it fire once, and then it dies
/// So it really has a "single shot"
class SingleShot<T> extends Reactive<T> {
  final VoidCallback update = Orchestrator.element!.markNeedsBuild;

  @override
  set data(T val) {
    if (_data != val) {
      update();
    }
  }
}

/// Simple emitter for when you don't care about the value
///
/// Example:
/// ```dart
/// final emitter = Emitter();
/// emitter.emit(); \\ Will emit a null value
/// ```
/// This null emit will be forwareded to Listeners
//ignore: prefer_void_to_null
class Emitter extends Reactive<Null> {
  Emitter() : super(eq: const NeverEquality());

  /// Creates an emitter that emits from an Interval
  factory Emitter.fromInterval(
    Duration delay,
  ) =>
      Emitter()..emitEvery(delay);

  /// Cancel the emitter from auto emitting
  void cancel() {
    close();
  }

  /// Will emit after `delay`
  void emitIn(Duration delay) {
    listen(null,
        onDone: Timer.periodic(delay, (_) {
          emit();
        }).cancel);
  }

  /// Will emit every `delay`
  void emitEvery(Duration delay) {
    listen(null,
        onDone: Timer(delay, () {
          emit();
        }).cancel);
  }

  @override
  //ignore: prefer_void_to_null
  set data(Null value) => emit();

  @override
  Null get data {
    if (!Orchestrator.notInBuild) _reportRead();
    return null;
  }

  /// Bundle a [T] with this emitter
  ///
  /// This allow to pass the emitter inside the UI
  /// Example:
  /// ```dart
  /// Obx(() => Text(emiter.bundle(myVariable)));
  /// ```
  T bundle<T>(T value) {
    if (!Orchestrator.notInBuild) _reportRead();
    return value;
  }
}
