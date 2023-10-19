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
      home: BlocAdapter(
        bloc: LelBloc(),
        child: Builder(builder: (context) {
          return Column(
            children: [
              Consumer<LelState>(
                (ctx, state) => Text(switch (state) {
                  LelState1() => 'State 1',
                  LelState2() => 'State 2',
                }),
              ),
              ElevatedButton(
                  onPressed: () {
                    ProfileEvent1().dispatch(context);
                  },
                  child: Text('click')),
            ],
          );
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

sealed class LelState extends State {}

class LelState1 extends LelState {}

class LelState2 extends LelState {}

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
  emit<T extends S>(T state) => _stateChannel.data = state;
}

class LelBloc extends Bloc<ProfileEvent, LelState> {
  @override
  LelState get initialState => LelState2();

  LelBloc() {
    _eventChannel.listen((value) {
      print(value);
      if (value is ProfileEvent1) {
        print("Profile 1");
        _stateChannel.add(LelState1());
      }
    });
    _stateChannel.listen((value) => print("new state $value"));
  }
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

class BlocAdapter<E extends Event, S extends State> extends StatelessWidget {
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

class Consumer<S extends State> extends Widget {
  final Widget Function(BuildContext context, S state) builder;
  const Consumer(this.builder, {super.key});

  @override
  InheritedStateElement<S> createElement() => InheritedStateElement<S>(this);
}

class InheritedStateElement<S extends State> extends ComponentElement {
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
