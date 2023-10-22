import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:obx/obx.dart';

typedef Response<T, E> = FutureOr<Result<T, E>>;

sealed class Result<T, E> {}

abstract class RxStore {}

class Success<T, E> extends Result<T, E> {
  T data;
  Success(this.data);
}

class Failure<T, E> extends Result<T, E> {
  E err;
  Failure(this.err);
}

class DuplicateEventHandlerException implements Exception {
  final String message;
  DuplicateEventHandlerException(this.message);
}

typedef StateEmitter<S> = void Function(S);

typedef EventHandler<E extends Event, S extends Object> = void Function(
  E event,
  StateEmitter<S> emit,
);

@immutable
class Event extends Notification {
  @override
  // ignore: avoid_renaming_method_parameters
  void dispatch(BuildContext? context) {
    super.dispatch(context);
  }
}

abstract class Bloc<E extends Event, S extends Object> {
  Rx<E> createEvent() => Rx<E>.indistinct();
  late final _eventChannel = createEvent();
  final _childEventChannels = <Rx<E>>[];

  S get initialState;
  Rx<S> createState(S initialState) => Rx<S>(initialState);
  late final _stateChannel = createState(initialState);
  S get state => _stateChannel.data;

  List<Rx> get dependencies => <Rx>[];

  @protected
  @nonVirtual
  void on<T extends E>(EventHandler<T, S> handler,
      {RxTransformer<T>? transformer}) {
    assert(() {
      if (_childEventChannels.any((e) => e is Rx<T>)) {
        throw DuplicateEventHandlerException(
            'on<$E> was called multiple times. '
            'Duplicate registration for event handler of type ${T.toString()}');
      }
      return true;
    }());
    _childEventChannels.add(_eventChannel.pipe<T>((e) =>
        transformer == null ? e.whereType<T>() : transformer(e.whereType<T>()))
      ..listen((v) => handler(v, _stateChannel.add)));
  }
}

class InheritedState<S extends Object> extends InheritedWidget {
  final Rx<S> _stateChannel;
  const InheritedState(
      {super.key, required super.child, required Rx<S> stateChannel})
      : _stateChannel = stateChannel,
        super();

  @override
  bool updateShouldNotify(covariant InheritedState<S> oldWidget) =>
      oldWidget._stateChannel != _stateChannel;
}

class BlocAdapter<E extends Event, S extends Object> extends StatefulWidget {
  final Bloc<E, S> Function(BuildContext) create;
  final Widget child;

  const BlocAdapter({super.key, required this.create, required this.child});

  BlocAdapter.builder(
      {super.key,
      required this.create,
      required Widget Function(BuildContext context) builder})
      : child = Builder(builder: builder);

  BlocAdapter.consumer(
      {super.key,
      required this.create,
      required Widget Function(BuildContext context, S state) builder})
      : child = Consumer(builder);

  @override
  State<BlocAdapter<E, S>> createState() => _BlocAdapterState<E, S>();
}

class _BlocAdapterState<E extends Event, S extends Object>
    extends State<BlocAdapter<E, S>> {
  late final Bloc<E, S> bloc = widget.create(context);

  bool _handle(E e) {
    bloc._eventChannel.data = e;
    return true;
  }

  @override
  Widget build(BuildContext context) => NotificationListener<E>(
        onNotification: _handle,
        child: InheritedState<S>(
          stateChannel: bloc._stateChannel,
          child: widget.child,
        ),
      );
}

class Consumer<S extends Object> extends Widget {
  final Widget Function(BuildContext context, S state) builder;
  const Consumer(this.builder, {super.key});

  @override
  InheritedStateElement<S> createElement() => InheritedStateElement<S>(this);
}

class InheritedStateElement<S extends Object> extends ComponentElement {
  S? state;
  RxSubscription<S>? _sub;

  InheritedStateElement(super.widget);

  @override
  void attachNotificationTree() {
    super.attachNotificationTree();
    final channel =
        dependOnInheritedWidgetOfExactType<InheritedState<S>>()!._stateChannel;
    state = channel.data;
    _sub?.syncCancel();
    _sub = channel.listen((value) {
      state = value;
      markNeedsBuild();
    });
  }

  @override
  void unmount() {
    super.unmount();
    _sub?.syncCancel();
    state = null;
  }

  @override
  Widget build() => (widget as Consumer<S>).builder(this, state!);
}

abstract class Dep {
  static final Map<Type, dynamic Function()> _factories = {};
  static final Map<Type, dynamic> _instances = {};

  static T find<T>() => _instances[T] ?? _factories[T]!();
  static void lazy<T>(T Function() builder) => _factories[T] = builder;
  static T remove<T>() => _instances.remove(T);
  static T put<T>(T Function() builder) =>
      _instances[T] = (_factories[T] = builder)();
}
