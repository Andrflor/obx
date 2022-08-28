import 'package:flutter/material.dart';
import 'package:obx/obx.dart';

void main() => runApp(MaterialApp(home: Test()));

class Test extends StatelessWidget {
  Test() {
    // print(display.isDistinct);
    // print(display2.isDistinct);

    print(iCond.isDistinct);
    // Fix dispose
  }

  final cond = (false.iobs..listen((e) => print("initital: $e")));
  late final iCond = cond.indistinct()..listen((e) => print("dupe: $e"));
  final plep = false.obs;

  final display = "data".obs;

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
            return Text("$display");
          },
        ),
        ElevatedButton(onPressed: () => cond(cond()!), child: Text("Toggle")),
      ],
    );
  }
}
