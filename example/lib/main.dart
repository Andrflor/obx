import 'dart:async';

import 'package:flutter/material.dart';
import 'package:obx/obx.dart';

void main() => runApp(const App());

class AppConfig {}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocBuilder(
        bloc: LelBloc(),
        child: Builder(builder: (context) {
          return Text(() {
            ProfileEvent1().dispatch(context);
            return "lel";
          }());
        }),
      ),
    );
  }
}

class User {
  final String name;
  final int age;

  User({required this.name, required this.age});
}

abstract class Store {}

class UserStore extends Store {
  final user = Rx<User>();
}

sealed class ProfileState extends State {}

class ProfileSuccess extends ProfileState {
  final User user;

  ProfileSuccess({required this.user});
}

class ProfileLoading extends ProfileState {}

class ProfileError extends ProfileState {
  final String error;

  ProfileError({required this.error});
}

sealed class ProfileEvent extends Event {}

class ProfileEvent1 extends ProfileEvent {}

class OtherEvent extends Event {}

@immutable
class Event extends Notification {
  @override
  // ignore: avoid_renaming_method_parameters
  void dispatch(BuildContext? context) {
    super.dispatch(context);
  }
}

@immutable
abstract class State {}

class LelState extends State {}

abstract class Intent extends Event implements Command {}

typedef Response<T, E extends Error> = FutureOr<Result<T, E>>;

abstract interface class Command<T, E extends Error> {
  Response<T, E> excecute();
}

abstract class Bloc<E extends Event, S extends State> {
  Rx<E> createEvent() => Rx<E>.indistinct();
  late final _eventChannel = createEvent();

  S get initialState;
  late final _stateChannel = Rx<S>(initialState);
}

class LelBloc extends Bloc<ProfileEvent, LelState> {
  @override
  LelState get initialState => LelState();
}

typedef EventHandler<E extends Event, S extends State> = S Function(
  E event,
);

class DuplicateEventHandlerException implements Exception {
  final String message;
  DuplicateEventHandlerException(this.message);
}

abstract class Compositor<S extends State, E extends Event> {
  Rx<E> createEvent() => Rx<E>.indistinct();

  late final _eventChannel = createEvent();
  final _childEventChannels = <Rx<E>>[];

  @mustCallSuper
  void dispose() {
    _eventChannel.close();
    for (final childEventChannel in _childEventChannels) {
      childEventChannel.close();
    }
  }

  void _consume(E e) => _eventChannel(e);

  (EventHandler<T, S> handler, RxTransformer<T>? transformer)
      handle<T extends E>(E e);

  // @protected
  // @nonVirtual
  // void on<T extends E>(
  //     {required EventHandler<T, S> handler, RxTransformer<T>? transformer}) {
  //   if (_childEventChannels.any((e) => e is Rx<T>)) {
  //     throw DuplicateEventHandlerException(
  //         "Duplicate registration for event handler of type ${T.toString()}");
  //   }
  //   _childEventChannels.add(_eventChannel.pipe<T>((e) =>
  //       transformer == null ? e.whereType<T>() : transformer(e.whereType<T>()))
  //     ..listen(handler(v)));
  // }
}

sealed class EventTest extends Event {}

class EventA extends EventTest {}

class EventB extends EventTest {}

void test() {
  final res = show(0);
  final b = switch (res) { Success() => 2, Failure() => 2 };

  print(b);
}

Result<String, String> show(int num) {
  if (num % 2 == 0) {
    return Success("Wow");
  } else {
    return Failure("yioh");
  }
}

sealed class Result<T, E> {}

class Success<T, E> extends Result<T, E> {
  T data;
  Success(this.data);
}

class Failure<T, E> extends Result<T, E> {
  E err;
  Failure(this.err);
}

class InheritedState<S extends State> extends InheritedWidget {
  final Rx<S> _stateChannel;
  const InheritedState(
      {super.key, required super.child, required Rx<S> stateChannel})
      : _stateChannel = stateChannel,
        super();

  @override
  bool updateShouldNotify(covariant InheritedState<S> oldWidget) =>
      oldWidget._stateChannel != _stateChannel;
}

class BlocBuilder<E extends Event, S extends State>
    extends NotificationListener<E> {
  final Bloc<E, S> bloc;

  @override
  NotificationListenerCallback<E> get onNotification {
    return (E e) {
      print("got $e");
      return true;
    };
  }

  const BlocBuilder({required super.child, required this.bloc, super.key});

  @override
  Widget build(BuildContext context) {
    return InheritedState<S>(
      stateChannel: bloc._stateChannel,
      child: child,
    );
  }
}
