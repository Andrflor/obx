import 'package:example/impl.dart';
import 'package:flutter/material.dart';
import 'package:obx/obx.dart';

void main() {
  Dep.lazy(UserStore.new);
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: BlocAdapter(
          bloc: ProfileBloc(),
          child: Builder(builder: (context) {
            return Column(
              children: [
                Consumer<ProfileState>((ctx, state) => switch (state) {
                      ProfileLoading() => const CircularProgressIndicator(),
                      ProfileSuccess(user: User user) => Text(
                          'You are ${user.name} and you are ${user.age} years old'),
                      ProfileError(error: String error) =>
                        Text('Error $error happended'),
                    }),
                TextFormField(),
                TextFormField(),
                ElevatedButton(
                    onPressed: () {
                      NameChange().dispatch(context);
                    },
                    child: Text('Create User')),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class User {
  final String name;
  final int age;

  User({required this.name, required this.age});
}

class UserStore extends Store {
  final userChannel = Rx<User>();
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

class NameChange extends ProfileEvent {}

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final _userChannel = Dep.find<UserStore>().userChannel;

  @override
  List<Rx> get dependencies => [_userChannel];

  @override
  ProfileState get initialState => _userChannel.hasValue
      ? ProfileSuccess(user: _userChannel.data)
      : ProfileLoading();
}
