import '../bloc/bloc_player.dart';

class PlayerData {
  final PlayerState state;
  final dynamic vCtr;
  final double aspectRatio;
  final bool fullscreen;
  final bool showControls;
  final bool pop;
  final double progress;
  final bool isTrial;

  const PlayerData(
      {this.state = PlayerState.LOADING,
      this.vCtr,
      this.aspectRatio = 1.28,
      this.fullscreen = false,
      this.showControls = false,
      this.pop = false,
      this.progress = 0,
      this.isTrial = true});

  PlayerData copyWith(
      {bool? fullscreen,
      bool? showControls,
      bool? pop,
      double? aspectRatio,
      double? progress,
      PlayerState? state,
      bool? isTrial}) {
    return PlayerData(
        state: state ?? this.state,
        vCtr: vCtr,
        aspectRatio: aspectRatio ?? this.aspectRatio,
        fullscreen: fullscreen ?? this.fullscreen,
        showControls: showControls ?? this.showControls,
        pop: pop ?? this.pop,
        progress: progress ?? this.progress,
        isTrial: isTrial ?? this.isTrial);
  }

  @override
  String toString() {
    return 'PlayerData{state: $state, vCtr: $vCtr, aspectRatio: $aspectRatio, fullscreen: $fullscreen, showControls: $showControls, pop: $pop, progress: $progress, isTrial: $isTrial}';
  }
}
