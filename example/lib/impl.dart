import 'dart:async';

import 'package:flutter/material.dart';
import 'package:obx/obx.dart';

typedef Response<T, E> = FutureOr<Result<T, E>>;

sealed class Result<T, E> {}

abstract class Store {}

class Success<T, E> extends Result<T, E> {
  T data;
  Success(this.data);
}

class Failure<T, E> extends Result<T, E> {
  E err;
  Failure(this.err);
}

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
  S get initialState;
  late final _stateChannel = Rx<S>(initialState);
  emit<T extends S>(T state) => _stateChannel.data = state;
  S get state => _stateChannel.data;

  List<Rx> get dependencies => <Rx>[];
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

class BlocAdapter<E extends Event, S extends Object> extends StatelessWidget {
  final Bloc<E, S> bloc;
  final Widget child;

  const BlocAdapter({super.key, required this.bloc, required this.child});

  bool _handle(E e) {
    bloc._eventChannel.data = e;
    return true;
  }

  @override
  Widget build(BuildContext context) => NotificationListener<E>(
        onNotification: _handle,
        child: InheritedState<S>(
          stateChannel: bloc._stateChannel,
          child: child,
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

  static T put<T>(T Function() builder) => _instances[T] = builder();
  static T find<T>() => _instances[T] ?? put<T>(_factories[T] as T Function());
  static void lazy<T>(T Function() builder) => _factories[T] = builder;
  static T remove<T>() => _instances.remove(T);
}
