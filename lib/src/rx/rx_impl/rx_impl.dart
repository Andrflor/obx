import '../../notifier.dart';
import 'rx_mixins.dart';

/// Basic implementation of the Rx
/// We have put a lot in the mixer (mixins)
class RxImpl<T> extends Reactive<T>
    with
        Actionable<T>,
        Descriptible<T>,
        DisposersTrackable<T>,
        StreamCapable<T>,
        BroadCastStreamCapable<T>,
        StreamBindable<T>,
        Distinguishable<T> {
  RxImpl(super.val, {bool distinct = true})
      : _distinct = T == Null ? false : distinct;

  @override
  bool get isDistinct => _distinct;
  final bool _distinct;
}
