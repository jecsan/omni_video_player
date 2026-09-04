import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/src/_youtube/youtube_webview_controller.dart';
import 'package:omni_video_player/src/_youtube/youtube_webview_event_handler.dart';

VideoPlayerConfiguration _config({required bool autoPlay}) =>
    VideoPlayerConfiguration(
      videoSourceConfiguration: VideoSourceConfiguration.youtube(
        videoUrl: Uri.parse('https://youtu.be/abc'),
      ).copyWith(autoPlay: autoPlay),
    );

YouTubeWebViewController _youtube({
  required bool autoPlay,
  Duration duration = Duration.zero,
}) => YouTubeWebViewController.fromVideoId(
  videoId: 'abc',
  duration: duration,
  isLive: false,
  size: const Size(640, 360),
  callbacks: const VideoPlayerCallbacks(),
  options: _config(autoPlay: autoPlay),
  globalController: null,
  globalKeyPlayer: GlobalKey<OmniVideoPlayerInitializerState>(),
);

void main() {
  test(
    'Ready handler cues chrome-on podcast without play, autoplay reels still play',
    () {
      final src = File(
        'lib/src/_youtube/youtube_webview_controller.dart',
      ).readAsStringSync();
      expect(src, contains('if (!options.videoSourceConfiguration.autoPlay)'));
      expect(src, contains('await cueVideoById(videoId: videoId!)'));
      expect(
        src.contains(
          '_isLoadedVideo = true;\n          play(useGlobalController: false);',
        ),
        isFalse,
        reason:
            'Unconditional Ready play() then init pause() dumps iOS to white unstarted',
      );
      expect(src, contains('play(useGlobalController: false)'));
    },
  );

  test('WebView background is transparent only when chrome is off', () {
    final src = File(
      'lib/src/_youtube/youtube_webview_player_view.dart',
    ).readAsStringSync();
    expect(src, contains('transparentBackground: chromeOff'));
    expect(src, isNot(contains('transparentBackground: true')));
  });

  test('isReady duration gate applies only to autoplay', () {
    final src = File(
      'lib/src/_youtube/youtube_webview_event_handler.dart',
    ).readAsStringSync();
    expect(
      src,
      contains(
        '!configuration.videoSourceConfiguration.autoPlay || !_isDurationUnset',
      ),
    );
  });

  test(
    'chrome-on podcast is ready on state change once duration is known',
    () async {
      final c = _youtube(
        autoPlay: false,
        duration: const Duration(seconds: 100),
      );
      final handler = YouTubeWebViewEventHandler(
        c,
        c.options,
        const VideoPlayerCallbacks(),
      );

      await handler.handleStateChange(-1);
      expect(c.isReady, isTrue);
      c.dispose();
    },
  );

  test('autoplay reels become ready once a real duration is known', () async {
    final c = _youtube(autoPlay: true, duration: const Duration(seconds: 100));
    final handler = YouTubeWebViewEventHandler(
      c,
      c.options,
      const VideoPlayerCallbacks(),
    );

    await handler.handleStateChange(1);
    expect(c.isReady, isTrue);
    c.dispose();
  });

  test('chrome-on init does not pause before duration is known', () {
    final src = File(
      'lib/src/_youtube/youtube_webview_event_handler.dart',
    ).readAsStringSync();
    expect(
      src.contains(
        'Pausing here dumps YouTube back to its white unstarted chrome',
      ),
      isFalse,
      reason:
          'Early pause after loadVideoById dumps iOS YouTube to white unstarted',
    );
  });

  test('trusts ggpht.com so iOS does not cancel YouTube thumbnail TLS', () {
    final src = File(
      'lib/src/_youtube/youtube_webview_player_view.dart',
    ).readAsStringSync();
    expect(src, contains("'ggpht.com'"));
  });

  test('html cueById cues without playVideo', () {
    final html = File('assets/youtube_player.html').readAsStringSync();
    expect(html, contains('function cueById'));
    expect(html, contains('player.cueVideoById'));
  });
}
