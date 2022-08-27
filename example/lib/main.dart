import 'package:flutter/material.dart';
import 'package:obx/obx.dart';
import 'package:rxdart/rxdart.dart';

void main() => runApp(MaterialApp(home: Test()));

class Test extends StatelessWidget {
  final behav = BehaviorSubject<bool>.seeded(false);
  late final cond = false.iobs..bind(false.obs);
  late final display = cond.pipe((e) => e ? "Good" : "Bad");

  @override
  Widget build(context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(() {
          print("Building");
          return Text(display());
        }),
        ElevatedButton(
            onPressed: () => behav.add(behav.value), child: Text("Toggle")),
      ],
    );
  }
}
