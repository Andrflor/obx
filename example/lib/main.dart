import 'package:flutter/material.dart';
import 'package:obx/obx.dart';

void main() => runApp(MaterialApp(home: Test()));

class Test extends StatelessWidget {
  Test() {
    print(display.isDistinct);
    print(display2.isDistinct);
  }

  late final cond = false.nobs;

  late final display = cond.pipe(
    (e) => e.map((event) => "Yes").where((event) => event == "Yes").skip(2),
    init: (e) => "Yes",
    distinct: false,
  )..listenNow((e) => print("Got called with $e"));

  late final display2 = cond.pipe(
    (e) => e.map((event) => "No").where((event) => event == "No").skip(2),
    init: (e) => "No",
    distinct: true,
  )..listenNow((e) => print("Got called with $e"));

  @override
  Widget build(context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ObxValue((Rx<bool> data) {
        //   print("Building ObxValue");
        //   return Text(cond().toString());
        // }, false.obs),
        Obx(
          () {
            print("Building Obx");
            return Text("$display");
          },
        ),
        ElevatedButton(onPressed: () => cond(!cond()!), child: Text("Toggle")),
      ],
    );
  }
}
