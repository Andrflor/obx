import '../../notifier.dart';
import 'rx_mixins.dart';

/// Complete implementation of Rx
class RxImpl<T> extends RxBase<T>
    with Actionable<T>, Distinguishable<T>, StreamBindable<T> {
  RxImpl(super.val, {bool distinct = true}) : _distinct = distinct;

  @override
  bool get isDistinct => _distinct;
  final bool _distinct;
}

/// Basic implementation of the Rx
/// We have put a lot in the mixer (mixins)
class RxBase<T> extends Reactive<T>
    with
        Descriptible<T>,
        DisposersTrackable<T>,
        StreamCapable<T>,
        BroadCastStreamCapable<T> {
  RxBase(super.val);
}
