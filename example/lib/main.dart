import 'package:example/impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:obx/obx.dart';

void main() {
  Dep.lazy(UserStore.new);
  runApp(const App());
}

class App extends HookWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController();
    final ageController = useTextEditingController();
    print("built");
    return MaterialApp(
      home: Scaffold(
        body: BlocAdapter.builder(
          create: (_) => ProfileBloc(),
          builder: (context) => Column(
            children: [
              Consumer<ProfileState>((ctx, state) => switch (state) {
                    ProfileLoading() => const CircularProgressIndicator(),
                    ProfileSuccess(user: User user) => Text(
                        'You are ${user.name} and you are ${user.age} years old'),
                    ProfileError(error: String error) => Text(error),
                  }),
              TextFormField(
                controller: nameController,
              ),
              TextFormField(controller: ageController),
              ElevatedButton(
                  onPressed: () {
                    UserChanged(
                            name: nameController.text, age: ageController.text)
                        .dispatch(context);
                  },
                  child: Text('Create User')),
            ],
          ),
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

class UserStore extends RxStore {
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

class UserChanged extends ProfileEvent {
  final String name;
  final String age;

  UserChanged({required this.name, required this.age});
}

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final _userChannel = Dep.find<UserStore>().userChannel;

  @override
  List<Rx> get dependencies => [_userChannel];

  @override
  ProfileState get initialState => _userChannel.hasValue
      ? ProfileSuccess(user: _userChannel.data)
      : ProfileLoading();

  ProfileBloc() {
    on<UserChanged>(_handleUserChanged);
  }

  void _handleUserChanged(UserChanged event, StateEmitter<ProfileState> emit) {
    final age = int.tryParse(event.age);
    if (age == null) {
      emit(ProfileError(error: 'Please enter a valid age'));
    } else {
      emit(ProfileSuccess(user: User(name: event.name, age: age)));
    }
  }
}
