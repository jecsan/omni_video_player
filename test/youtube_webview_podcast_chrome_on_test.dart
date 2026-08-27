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
}) =>
    YouTubeWebViewController.fromVideoId(
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
  test('Ready handler still loadVideoById for chrome-on podcast, not autoplay reels', () {
    final src = File('lib/src/_youtube/youtube_webview_controller.dart').readAsStringSync();
    expect(src, contains('if (!options.videoSourceConfiguration.autoPlay)'));
    expect(src, contains('await loadVideoById(videoId: videoId!)'));
  });

  test('WebView background is transparent only when chrome is off', () {
    final src = File('lib/src/_youtube/youtube_webview_player_view.dart').readAsStringSync();
    expect(src, contains('transparentBackground: chromeOff'));
    expect(src, isNot(contains('transparentBackground: true')));
  });

  test('isReady duration gate applies only to autoplay', () {
    final src = File('lib/src/_youtube/youtube_webview_event_handler.dart').readAsStringSync();
    expect(
      src,
      contains(
        '!configuration.videoSourceConfiguration.autoPlay || !_isDurationUnset',
      ),
    );
  });

  test('chrome-on podcast is ready on state change once duration is known', () async {
    final c = _youtube(autoPlay: false, duration: const Duration(seconds: 100));
    final handler = YouTubeWebViewEventHandler(
      c,
      c.options,
      const VideoPlayerCallbacks(),
    );

    await handler.handleStateChange(-1);
    expect(c.isReady, isTrue);
    c.dispose();
  });

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
}
