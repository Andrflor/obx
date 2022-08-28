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

      group('stream', () {
        init();
        boolStreamListen('obs', obs);
        boolStreamListen('nobs', nobs);
        boolStreamListen('iobs', iobs);
        boolStreamListen('inobs', inobs);
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
        boolListen('obs', obs, true, obs.indistinct());
        boolListen('nobs', nobs, true, nobs.indistinct());
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
      group('invisible', () {
        group('base', () {
          init();
          boolInvListen('obs', obs);
          boolInvListen('nobs', nobs);
          boolInvListen('iobs', iobs);
          boolInvListen('inobs', inobs);
        });
        group('stream', () {
          init();
          boolInvListen('obs', obs, true);
          boolInvListen('nobs', nobs, true);
          boolInvListen('iobs', iobs, true);
          boolInvListen('inobs', inobs, true);
        });
      });

      group('trigger', () {
        group('base', () {
          init();
          boolTriggerListen('obs', obs);
          boolTriggerListen('nobs', nobs);
          boolTriggerListen('iobs', iobs);
          boolTriggerListen('inobs', inobs);
        });
        group('stream', () {
          init();
          boolTriggerListen('obs', obs, true);
          boolTriggerListen('nobs', nobs, true);
          boolTriggerListen('iobs', iobs, true);
          boolTriggerListen('inobs', inobs, true);
        });
      });

      group('refresh', () {
        group('base', () {
          init();
          boolRefreshListen('obs', obs);
          boolRefreshListen('nobs', nobs);
          boolRefreshListen('iobs', iobs);
          boolRefreshListen('inobs', inobs);
        });
        group('stream', () {
          init();
          boolRefreshListen('obs', obs, true);
          boolRefreshListen('nobs', nobs, true);
          boolRefreshListen('iobs', iobs, true);
          boolRefreshListen('inobs', inobs, true);
        });
      });

      group('silent', () {
        group('base', () {
          init();
          boolSilentListen('obs', obs);
          boolSilentListen('nobs', nobs);
          boolSilentListen('iobs', iobs);
          boolSilentListen('inobs', inobs);
        });
        group('stream', () {
          init();
          boolSilentListen('obs', obs, true);
          boolSilentListen('nobs', nobs, true);
          boolSilentListen('iobs', iobs, true);
          boolSilentListen('inobs', inobs, true);
        });
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

void boolStreamListen(String name, Rx<bool?> rxBool) {
  return test(name, () async {
    bool fired = false;
    rxBool.subject.stream.listen((e) {
      fired = true;
    });
    rxBool(rxBool());
    await Future.delayed(Duration.zero);
    expect(fired, true, reason: "same failed");
    fired = false;
    rxBool(!rxBool()!);
    await Future.delayed(Duration.zero);
    expect(fired, true, reason: "diff failed");
  });
}

void boolInvListen(String name, Rx<bool?> rxBool, [bool stream = false]) {
  return test(name, () async {
    bool fired = false;
    (stream ? rxBool.subject.stream : rxBool.stream).listen((e) {
      fired = true;
    });
    rxBool.invisible(rxBool());
    await Future.delayed(Duration.zero);
    expect(fired, false, reason: "same failed");
    fired = false;
    rxBool.invisible(!rxBool()!);
    await Future.delayed(Duration.zero);
    expect(fired, false, reason: "diff failed");
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
    expect(fired, stream ? stream : !rxBool.isDistinct, reason: "same failed");
    fired = false;
    rxBool.silent(!rxBool()!);
    await Future.delayed(Duration.zero);
    expect(fired, true, reason: "diff failed");
  });
}
