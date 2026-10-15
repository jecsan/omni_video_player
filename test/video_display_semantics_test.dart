import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:video_player/video_player.dart' show DurationRange;
import 'package:visibility_detector/visibility_detector.dart';
import 'package:omni_video_player/src/_core/omni_video_player_view.dart';

/// Only what [OmniVideoPlayerView] and its overlay read while loading and once ready.
class _FakeController extends OmniPlaybackController {
  bool ready = false;
  bool started = false;

  void becomeReady() {
    ready = true;
    notifyListeners();
  }

  void start() {
    started = true;
    notifyListeners();
  }

  @override
  final ValueNotifier<Widget?> sharedPlayerNotifier = ValueNotifier(
    Semantics(label: 'video surface', child: const SizedBox.expand()),
  );

  @override
  bool get isReady => ready;
  @override
  bool get isDisposed => false;
  @override
  bool get isFullScreen => false;
  @override
  bool get hasStarted => started;
  @override
  bool get isFinished => false;
  @override
  bool get isPlaying => false;
  @override
  bool get isBuffering => false;
  @override
  bool get isLive => false;
  @override
  bool get hasError => false;
  @override
  bool get isMuted => false;
  @override
  bool get isSeeking => false;
  @override
  Size get size => const Size(640, 360);
  @override
  Duration get duration => const Duration(minutes: 25);
  @override
  Duration get currentPosition => Duration.zero;
  @override
  double get volume => 1;
  @override
  double get playbackSpeed => 1;
  @override
  int get rotationCorrection => 0;
  @override
  List<DurationRange> get buffered => const [];
  @override
  VideoSourceType get videoSourceType => VideoSourceType.youtube;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets('the video keeps its semantics node when the loader and thumbnail leave', (tester) async {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    final semantics = tester.ensureSemantics();
    final controller = _FakeController();
    final configuration = VideoPlayerConfiguration(
      videoSourceConfiguration: VideoSourceConfiguration.youtube(videoUrl: Uri.parse('https://youtu.be/abc')),
      customPlayerWidgets: CustomPlayerWidgets(thumbnail: MemoryImage(_transparentPixel)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OmniVideoPlayerTheme(
          data: const OmniVideoPlayerThemeData(),
          child: Scaffold(
            body: OmniVideoPlayerView(
              controller: controller,
              configuration: configuration,
              callbacks: const VideoPlayerCallbacks(),
            ),
          ),
        ),
      ),
    );
    final before = tester.getSemantics(find.bySemanticsLabel('video surface'));

    controller.becomeReady();
    await tester.pump();

    final afterLoader = tester.getSemantics(find.bySemanticsLabel('video surface'));
    expect(afterLoader.parent?.id, before.parent?.id, reason: 'The loader left');

    controller.start();
    await tester.pump();

    final afterThumbnail = tester.getSemantics(find.bySemanticsLabel('video surface'));
    expect(afterThumbnail.parent?.id, before.parent?.id, reason: 'The thumbnail left on first play');
    semantics.dispose();
  });
}

final _transparentPixel = Uint8List.fromList(const [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);
