import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:obx/obx.dart';

void main() => runApp(MaterialApp(home: Test()));

class Valuer<T> extends ValueListenable<T> {
  Valuer(T value) : _value = value;

  T _value;

  @override
  void addListener(VoidCallback listener) {
    // TODO: implement addListener
  }

  @override
  void removeListener(VoidCallback listener) {
    // TODO: implement removeListener
  }

  @override
  // TODO: implement value
  T get value => _value;

  set value(T val) => _value = val;
}

class Test extends StatelessWidget {
  Test() {
    final lel = Valuer(3);
    print(Valuer(4).hashCode);
    print(lel.hashCode);
    lel.value = 5;
    print(lel.hashCode);
    // print(display.isDistinct);
    // print(display2.isDistinct);

    // final test = false.obs;
    // final noti = ValueNotifier<bool>(false).obs;
    // print(noti.runtimeType);

    // final behav = BehaviorSubject<bool>.seeded(false).obs;
    // print(behav.runtimeType);
    final test = RxSet(<int>{});

    test.trigger({});
    print(test.runtimeType);
    print(test.length);
    test.refresh();

    final emit = Emitter()
      ..listen((e) {
        print("This is emiting");
      })
      ..emit();
  }

  final cond = false.obs
    ..listen((e) {
      print("updated $e");
    });
  final plep = false.obs;

  late final iCond = cond.dupe();
  late final display = cond.pipe(
      (e) => (e.map((event) => event ? "Yes" : "No")),
      init: (e) => e ? "Yes" : "No");

  // late final display2 = cond.pipe(
  //   (e) => e.map((event) => "No").where((event) => event == "No").skip(2),
  //   init: (e) => "No",
  //   distinct: true,
  // )..listenNow((e) => print("Got called with $e"));

  @override
  Widget build(context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ObxValue((data) {
        //   print("Building ObxValue");
        //   return Text(data.toString());
        // }, false.obs),
        // Obx(
        //   () {
        //     print("Building 1");
        //     return Text("$iCond");
        //   },
        // ),
        Obx(
          () {
            print("Building 2");
            return Column(
              children: [
                Text("$iCond"),
              ],
            );
          },
        ),
        ElevatedButton(onPressed: () => cond(!cond()), child: Text("Toggle")),
      ],
    );
  }
}
