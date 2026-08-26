import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final html = File('assets/youtube_player.html').readAsStringSync();

  test('YouTube embed constructs the player with a videoId, not an empty iframe', () {
    expect(html, contains('videoId: "<<videoId>>"'));
  });

  test('YouTube embed page stays black before the iframe paints', () {
    expect(html, contains('background: #000'));
    expect(html, contains('color-scheme: dark'));
  });
}
