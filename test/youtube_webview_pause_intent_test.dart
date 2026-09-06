import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/src/_youtube/youtube_webview_controller.dart';
import 'package:omni_video_player/src/_youtube/youtube_webview_event_handler.dart';

VideoPlayerConfiguration _config() => VideoPlayerConfiguration(
  videoSourceConfiguration: VideoSourceConfiguration.youtube(
    videoUrl: Uri.parse('https://youtu.be/abc'),
  ),
);

YouTubeWebViewController _youtube({
  Duration duration = const Duration(seconds: 100),
}) => YouTubeWebViewController.fromVideoId(
  videoId: 'abc',
  duration: duration,
  isLive: false,
  size: const Size(640, 360),
  callbacks: const VideoPlayerCallbacks(),
  options: _config(),
  globalController: null,
  globalKeyPlayer: GlobalKey<OmniVideoPlayerInitializerState>(),
);

YouTubeWebViewEventHandler _handler(YouTubeWebViewController c) =>
    YouTubeWebViewEventHandler(c, c.options, const VideoPlayerCallbacks());

void main() {
  test(
    'explicit pause during seek must not auto-resume on the PAUSED echo',
    () async {
      final c = _youtube();
      addTearDown(c.dispose);
      c
        ..isReady = true
        ..isPlaying = true
        ..hasStarted = true;
      await c.seekTo(const Duration(seconds: 20));
      expect(c.wasPlayingBeforeSeek, isTrue);
      expect(c.isSeeking, isTrue);

      await c.pause();
      await _handler(c).handleStateChange(2);

      expect(c.wasPlayingBeforeSeek, isFalse);
      expect(c.isPlaying, isFalse);
    },
  );

  test('seek fallback timer must not resume after an explicit pause', () {
    fakeAsync((async) {
      final c = _youtube();
      c
        ..isReady = true
        ..isPlaying = true
        ..hasStarted = true;
      c.seekTo(const Duration(seconds: 20));
      async.flushMicrotasks();
      expect(c.wasPlayingBeforeSeek, isTrue);

      c.pause();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 4));

      expect(c.isPlaying, isFalse);
      c.dispose();
    });
  });

  testWidgets('fullscreen recovery must not undo a later explicit pause', (
    tester,
  ) async {
    final c = _youtube();
    addTearDown(c.dispose);
    c
      ..isReady = true
      ..isPlaying = true
      ..hasStarted = true;
    late BuildContext inline;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            inline = context;
            return const Scaffold(body: Text('INLINE'));
          },
        ),
      ),
    );

    final route = c.switchFullScreenMode(
      inline,
      pageBuilder: (_) => const Scaffold(body: Text('FULLSCREEN')),
    );
    await tester.pumpAndSettle();
    expect(c.wasPlayingBeforeGoOnFullScreen, isTrue);

    await c.pause();
    await _handler(c).handleStateChange(2);

    expect(c.wasPlayingBeforeGoOnFullScreen, isNull);
    expect(c.isPlaying, isFalse);

    Navigator.of(tester.element(find.text('FULLSCREEN'))).pop();
    await tester.pumpAndSettle();
    await route;
  });

  testWidgets('leaving fullscreen expires unused transition recovery', (
    tester,
  ) async {
    final c = _youtube();
    addTearDown(c.dispose);
    c
      ..isReady = true
      ..isPlaying = true
      ..hasStarted = true;
    late BuildContext inline;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            inline = context;
            return const Scaffold(body: Text('INLINE'));
          },
        ),
      ),
    );

    final route = c.switchFullScreenMode(
      inline,
      pageBuilder: (_) => const Scaffold(body: Text('FULLSCREEN')),
    );
    await tester.pumpAndSettle();
    expect(c.wasPlayingBeforeGoOnFullScreen, isTrue);

    await c.switchFullScreenMode(
      tester.element(find.text('FULLSCREEN')),
      pageBuilder: null,
    );
    await tester.pumpAndSettle();
    await route;

    expect(c.wasPlayingBeforeGoOnFullScreen, isNull);

    await c.pause();
    await _handler(c).handleStateChange(2);
    expect(c.isPlaying, isFalse);
  });
}
