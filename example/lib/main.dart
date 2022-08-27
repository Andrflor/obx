import 'package:flutter/material.dart';
import 'package:obx/obx.dart';

void main() => runApp(MaterialApp(home: Test()));

class Test extends StatelessWidget {
  Test() {
    // print(display.isDistinct);
    // print(display2.isDistinct);
  }

  late final cond = false.nobs.indistinct().dupe();

  late final display = cond
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
        Obctx(
          (context) {
            print("Building 1");
            return Text("$display");
          },
        ),
        Obctx(
          (context) {
            print("Building 2");
            return Text("$cond");
          },
        ),
        ElevatedButton(onPressed: () => cond(cond()!), child: Text("Toggle")),
      ],
    );
  }
}
