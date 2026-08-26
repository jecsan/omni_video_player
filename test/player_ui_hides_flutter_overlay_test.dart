import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';

void main() {
  test('default chrome does not hide the Flutter overlay', () {
    expect(const PlayerUIVisibilityOptions().hidesFlutterOverlay, isFalse);
  });

  test('reel-style chrome-off options hide the Flutter overlay', () {
    const opts = PlayerUIVisibilityOptions(
      showVideoBottomControlsBar: false,
      showPlayPauseReplayButton: false,
      showSeekBar: false,
      showMuteUnMuteButton: false,
      showFullScreenButton: false,
      showThumbnailAtStart: false,
      showReplayButton: false,
      showLoadingWidget: false,
      enableForwardGesture: false,
      enableBackwardGesture: false,
    );
    expect(opts.hidesFlutterOverlay, isTrue);
  });
}
