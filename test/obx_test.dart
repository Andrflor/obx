import 'package:flutter_test/flutter_test.dart';

import 'package:obx/obx.dart';

Rx<bool> obs = false.obs;
Rx<bool?> nobs = false.nobs;
Rx<bool> iobs = false.iobs;
Rx<bool?> inobs = false.inobs;

void init() {
  obs = false.obs;
  nobs = false.nobs;
  iobs = false.iobs;
  inobs = false.inobs;
}

void main() {
  group('Rx', () {
    group('listen', () {
      group('base', () {
        init();
        boolListen('obs', obs, false);
        boolListen('nobs', nobs, false);
        boolListen('iobs', iobs, true);
        boolListen('inobs', inobs, true);
      });

      group('clone', () {
        init();
        boolListen('obs', obs, false, obs.clone(), false);
        boolListen('nobs', nobs, false, nobs.clone(), false);
        boolListen('iobs', iobs, false, iobs.clone(), false);
        boolListen('inobs', inobs, false, inobs.clone(), false);
      });

      group('dupe', () {
        init();
        boolListen('obs', obs, false, obs.dupe());
        boolListen('nobs', nobs, false, nobs.dupe());
        boolListen('iobs', iobs, true, iobs.dupe());
        boolListen('inobs', inobs, true, inobs.dupe());
      });

      group('distinct', () {
        init();
        boolListen('obs', obs, false, obs.distinct());
        boolListen('nobs', nobs, false, nobs.distinct());
        boolListen('iobs', iobs, false, iobs.distinct());
        boolListen('inobs', inobs, false, inobs.distinct());
      });

      group('indistinct', () {
        init();
        boolListen('obs', obs, false, obs.indistinct());
        boolListen('nobs', nobs, false, nobs.indistinct());
        boolListen('iobs', iobs, true, iobs.indistinct());
        boolListen('inobs', inobs, true, inobs.indistinct());
      });

      group('pipe', () {
        group('where', () {
          init();
          boolListen('obs', obs, false,
              obs.pipe((e) => e.where((e) => e == false)), false);
          boolListen('nobs', nobs, false,
              nobs.pipe((e) => e.where((e) => e == false)), false);
          boolListen('iobs', iobs, true,
              iobs.pipe((e) => e.where((e) => e == false)), false);
          boolListen('inobs', inobs, true,
              inobs.pipe((e) => e.where((e) => e == false)), false);
        });

        group('map', () {
          init();
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

      group('trigger', () {
        init();
        boolTriggerListen('obs', obs);
        boolTriggerListen('nobs', nobs);
        boolTriggerListen('iobs', iobs);
        boolTriggerListen('inobs', inobs);
      });

      group('refresh', () {
        init();
        boolRefreshListen('obs', obs);
        boolRefreshListen('nobs', nobs);
        boolRefreshListen('iobs', iobs);
        boolRefreshListen('inobs', inobs);
      });

      group('silent', () {
        init();
        boolSilentListen('obs', obs);
        boolSilentListen('nobs', nobs);
        boolSilentListen('iobs', iobs);
        boolSilentListen('inobs', inobs);
      });
    });
  });
}

void boolListen(String name, Rx<bool?> rxBool, bool shouldFire,
    [Rx? child, bool? shouldSecondFire]) {
  return test(name, () async {
    bool fired = false;
    (child ?? rxBool).stream.listen((e) {
      fired = true;
    });
    rxBool(rxBool());
    await Future.delayed(Duration.zero);
    expect(fired, shouldFire, reason: "same failed");
    fired = false;
    rxBool(!rxBool()!);
    await Future.delayed(Duration.zero);
    expect(fired, shouldSecondFire ?? true, reason: "diff failed");
  });
}

void boolRefreshListen(String name, Rx<bool?> rxBool, [bool stream = false]) {
  return test(name, () async {
    bool fired = false;
    (stream ? rxBool.subject.stream : rxBool.stream).listen((e) {
      fired = true;
    });
    rxBool.refresh(rxBool());
    await Future.delayed(Duration.zero);
    expect(fired, stream ? stream : !rxBool.isDistinct, reason: "same failed");
    fired = false;
    rxBool.refresh(!rxBool()!);
    await Future.delayed(Duration.zero);
    expect(fired, true, reason: "diff failed");
  });
}

void boolTriggerListen(String name, Rx<bool?> rxBool, [bool stream = false]) {
  return test(name, () async {
    bool fired = false;
    (stream ? rxBool.subject.stream : rxBool.stream).listen((e) {
      fired = true;
    });
    rxBool.trigger(rxBool());
    await Future.delayed(Duration.zero);
    expect(fired, true, reason: "same failed");
    fired = false;
    rxBool.trigger(!rxBool()!);
    await Future.delayed(Duration.zero);
    expect(fired, true, reason: "diff failed");
  });
}

void boolSilentListen(String name, Rx<bool?> rxBool, [bool stream = false]) {
  return test(name, () async {
    bool fired = false;
    (stream ? rxBool.subject.stream : rxBool.stream).listen((e) {
      fired = true;
    });
    rxBool.silent(rxBool());
    await Future.delayed(Duration.zero);
    expect(fired, false, reason: "same failed");
    fired = false;
    rxBool.silent(!rxBool()!);
    await Future.delayed(Duration.zero);
    expect(fired, false, reason: "diff failed");
  });
}
