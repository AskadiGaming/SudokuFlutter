import 'package:flutter/material.dart';

import '../../ads/application/show_ad_before_round_use_case.dart';
import '../../ads/domain/ad_policy.dart';
import '../../ads/domain/ad_timing_mode.dart';
import '../../ads/infrastructure/debug_analytics_service.dart';
import '../../ads/infrastructure/shared_prefs_ad_round_counter_store.dart';
import '../../ads/infrastructure/unity_ads_config.dart';
import '../../ads/infrastructure/unity_ads_service.dart';
import '../../sudoku/domain/sudoku_round_config.dart';
import '../../sudoku/presentation/play_sudoku_page.dart';

class QuickmatchRoundStarter {
  QuickmatchRoundStarter({ShowAdBeforeRoundUseCase? showAdBeforeRoundUseCase})
    : _showAdBeforeRoundUseCase =
          showAdBeforeRoundUseCase ??
          ShowAdBeforeRoundUseCase(
            adService: UnityAdsService(
              config: UnityAdsConfig.fromEnvironment(),
            ),
            analyticsService: DebugAnalyticsService(),
            roundCounterStore: SharedPrefsAdRoundCounterStore(),
            policy: const AdPolicy(
              timingMode: AdTimingMode.beforeRoundStart,
              minRoundsBetweenAds: 10,
            ),
          );

  final ShowAdBeforeRoundUseCase _showAdBeforeRoundUseCase;
  bool _isStartingRound = false;

  bool get isStartingRound => _isStartingRound;

  Future<void> startRound({
    required BuildContext context,
    required SudokuRoundConfig roundConfig,
    bool replaceCurrentRoute = false,
  }) async {
    if (_isStartingRound) {
      return;
    }

    _isStartingRound = true;
    try {
      await _showAdBeforeRoundUseCase.execute();
    } finally {
      _isStartingRound = false;
    }

    if (!context.mounted) {
      return;
    }

    final MaterialPageRoute<void> route = MaterialPageRoute<void>(
      builder:
          (BuildContext routeContext) => PlaySudokuPage(
            roundConfig: roundConfig,
            onReplayRoundRequested:
                (BuildContext replayContext, SudokuRoundConfig replayConfig) =>
                    startRound(
                      context: replayContext,
                      roundConfig: replayConfig,
                      replaceCurrentRoute: true,
                    ),
          ),
    );

    if (replaceCurrentRoute) {
      await Navigator.of(context).pushReplacement(route);
      return;
    }
    await Navigator.of(context).push(route);
  }
}
