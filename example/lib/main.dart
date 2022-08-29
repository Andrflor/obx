import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:obx/obx.dart';

void main() => runApp(MaterialApp(home: Test()));

class Test extends StatelessWidget {
  Test() {
    // print(display.isDistinct);
    // print(display2.isDistinct);

    // final test = false.obs;
    // final noti = ValueNotifier<bool>(false).obs;
    // print(noti.runtimeType);
    // TODO: check how to add methods depending on the user
    // TODO: add only behaviorSubject and other rx object transfrom
    // TODO: if the package is installed
    // final behav = BehaviorSubject<bool>.seeded(false).obs;
    // print(behav.runtimeType);

    // Fix dispose
  }

  final cond = false.obs;
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
          () => iCond()
              ? Obx(
                  () {
                    print("Building 2");
                    return Column(
                      children: [
                        Text("$display"),
                      ],
                    );
                  },
                )
              : Container(),
        ),
        ElevatedButton(onPressed: () => cond(!cond()), child: Text("Toggle")),
      ],
    );
  }
}
