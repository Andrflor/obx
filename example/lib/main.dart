import 'package:flutter/material.dart';
import 'package:obx/obx.dart';

void main() => runApp(MaterialApp(home: Test()));

class Test extends StatelessWidget {
  Test() {
    // print(display.isDistinct);
    // print(display2.isDistinct);
  }

  final cond = false.obs
    ..listen((e) {
      print(e);
    });

  late final iCond = cond.distinct();

  late final display = iCond
      .pipe(
        (e) => e.map((event) => "Yes"),
        init: (e) => "Yes",
        distinct: true,
      )
      .distinct()
    ..listenNow((e) => print("Got called with $e"));

  final plep = false.obs;

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

        Obx(
          () {
            print("Building 2");
            return Text("$iCond");
          },
        ),
        ElevatedButton(onPressed: () => iCond(iCond()), child: Text("Toggle")),
      ],
    );
  }
}
