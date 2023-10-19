import 'package:example/impl.dart';
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
                  LelState2(data: String data) => data,
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

sealed class ProfileState {}

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

sealed class LelState {}

class LelState1 extends LelState {}

class LelState2 extends LelState {
  final String data;

  LelState2({required this.data});
}

abstract class Intent extends Event implements Command {}

abstract interface class Command<T, E extends Error> {
  Response<T, E> excecute();
}

class LelBloc extends Bloc<ProfileEvent, LelState> {
  @override
  LelState get initialState => LelState2(data: 'iw');
}
