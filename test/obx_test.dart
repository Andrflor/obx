import 'package:flutter_test/flutter_test.dart';

import 'package:obx/obx.dart';

void main() {
  group('Rx', () {
    group('listen', () {
      final obs = false.obs;
      final nobs = false.nobs;
      final iobs = false.iobs;
      final inobs = false.inobs;

      group('base', () {
        boolListen('obs', obs, false);
        boolListen('nobs', nobs, false);
        boolListen('iobs', iobs, true);
        boolListen('inobs', inobs, true);
      });

      group('stream', () {
        boolStreamListen('obs', obs);
        boolStreamListen('nobs', nobs);
        boolStreamListen('iobs', iobs);
        boolStreamListen('inobs', inobs);
      });

      group('clone', () {
        boolListen('obs', obs, false, obs.clone(), false);
        boolListen('nobs', nobs, false, nobs.clone(), false);
        boolListen('iobs', iobs, false, iobs.clone(), false);
        boolListen('inobs', inobs, false, inobs.clone(), false);
      });

      group('dupe', () {
        boolListen('obs', obs, false, obs.dupe());
        boolListen('nobs', nobs, false, nobs.dupe());
        boolListen('iobs', iobs, true, iobs.dupe());
        boolListen('inobs', inobs, true, inobs.dupe());
      });

      group('distinct', () {
        boolListen('obs', obs, false, obs.distinct());
        boolListen('nobs', nobs, false, nobs.distinct());
        boolListen('iobs', iobs, false, iobs.distinct());
        boolListen('inobs', inobs, false, inobs.distinct());
      });

      group('indistinct', () {
        boolListen('obs', obs, true, obs.indistinct());
        boolListen('nobs', nobs, true, nobs.indistinct());
        boolListen('iobs', iobs, true, iobs.indistinct());
        boolListen('inobs', inobs, true, inobs.indistinct());
      });

      group('pipe', () {
        group('where', () {
          boolListen('obs', obs, false,
              obs.pipe((e) => e.where((e) => e == false)), false);
          boolListen('nobs', nobs, false,
              nobs.pipe((e) => e.where((e) => e == false)), false);
          boolListen(
              'iobs', iobs, true, iobs.pipe((e) => e.where((e) => e == false)));
          boolListen('inobs', inobs, true,
              inobs.pipe((e) => e.where((e) => e == false)));
        });

        group('map', () {
          boolListen('obs', obs, false,
              obs.pipe((e) => e.map((e) => ""), init: (e) => ""), false);
          boolListen('nobs', nobs, false,
              nobs.pipe((e) => e.map((e) => ""), init: (e) => ""), false);
          boolListen('iobs', iobs, true,
              iobs.pipe((e) => e.map((e) => ""), init: (e) => ""));
          boolListen('inobs', inobs, true,
              inobs.pipe((e) => e.map((e) => ""), init: (e) => ""));
        });
      });
    });
  });
}

void boolListen(String name, Rx<bool?> rxBool, bool shouldFire,
    [Rx? child, bool? shouldSecondFire]) {
  final value = rxBool.value;
  return test(name, () async {
    bool fired = false;
    final sub = (child ?? rxBool).stream.listen((e) {
      fired = true;
    });
    rxBool(rxBool());
    await Future.delayed(Duration.zero);
    expect(fired, shouldFire, reason: "same failed");
    fired = false;
    rxBool(!rxBool()!);
    await Future.delayed(Duration.zero);
    expect(fired, shouldSecondFire ?? true, reason: "diff failed");
    rxBool(value);
  });
}

void boolStreamListen(String name, Rx<bool?> rxBool) {
  final value = rxBool.value;
  return test(name, () async {
    bool fired = false;
    final sub = rxBool.subject.stream.listen((e) {
      fired = true;
    });
    rxBool(rxBool());
    await Future.delayed(Duration.zero);
    expect(fired, true, reason: "same failed");
    fired = false;
    rxBool(!rxBool()!);
    await Future.delayed(Duration.zero);
    expect(fired, true, reason: "diff failed");
    rxBool(value);
  });
}
