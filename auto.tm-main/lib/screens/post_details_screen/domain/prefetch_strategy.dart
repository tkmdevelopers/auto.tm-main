import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';

/// Context data used to inform adaptive prefetch decisions.
class PrefetchContext {
  final bool networkSlow;
  final int consecutiveForwardSwipes;
  final bool isFastSwipe; // fast velocity (<300ms between swipes)

  const PrefetchContext({
    required this.networkSlow,
    required this.consecutiveForwardSwipes,
    required this.isFastSwipe,
  });
}

/// Strategy interface for computing indices to prefetch around current index.
abstract class PrefetchStrategy {
  Set<int> computeTargets({
    required int currentIndex,
    required int lastPrefetchIndex,
    required List<Photo> photos,
    required PrefetchContext ctx,
  });
}

/// Default strategy replicating existing adaptive logic (forward/backward radius rules).
class DefaultAdaptiveStrategy implements PrefetchStrategy {
  @override
  Set<int> computeTargets({
    required int currentIndex,
    required int lastPrefetchIndex,
    required List<Photo> photos,
    required PrefetchContext ctx,
  }) {
    final isForward = currentIndex > lastPrefetchIndex;

    // Determine momentum/velocity flags
    final hasForwardMomentum = ctx.consecutiveForwardSwipes >= 2 && isForward;

    int forwardRadius = 1;
    int backwardRadius = 1;

    if (hasForwardMomentum && ctx.isFastSwipe) {
      forwardRadius = 3;
      backwardRadius = 1;
    } else if (ctx.isFastSwipe) {
      forwardRadius = 2;
      backwardRadius = 2;
    } else if (hasForwardMomentum) {
      forwardRadius = 2;
      backwardRadius = 1;
    }

    // Network slow reduction (preserve some momentum benefit)
    if (ctx.networkSlow) {
      if (hasForwardMomentum) {
        forwardRadius = forwardRadius > 2 ? 2 : forwardRadius;
        backwardRadius = 1;
      } else {
        forwardRadius = (forwardRadius / 2).ceil();
        backwardRadius = (backwardRadius / 2).ceil();
        if (forwardRadius < 1) forwardRadius = 1;
        if (backwardRadius < 1) backwardRadius = 1;
      }
    }

    final targets = <int>{};
    for (int i = 1; i <= forwardRadius; i++) {
      final t = currentIndex + i;
      if (t < photos.length) targets.add(t);
    }
    for (int i = 1; i <= backwardRadius; i++) {
      final t = currentIndex - i;
      if (t >= 0) targets.add(t);
    }
    return targets;
  }
}
