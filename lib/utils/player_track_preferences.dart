import 'dart:convert';

import 'package:api/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/player.dart';

class PlayerTrackPreferences {
  PlayerTrackPreferences._();

  static const _prefix = 'playerTrackPreference.v1';
  static const _disabled = '__disabled__';
  static final Set<String> _applied = {};
  static final Map<String, String> _lastSelections = {};

  static Future<void> remember(
    PlayerController<dynamic> controller,
    String type,
    String? id,
    List<MediaTrack> tracks,
  ) async {
    final preference =
        id == null ? _disabled : jsonEncode(_trackSignature(tracks.firstWhere((track) => track.id == id)));
    final prefs = await SharedPreferences.getInstance();
    final mediaKey = _mediaKey(controller.currentItem?.source);
    await prefs.setString('$_prefix.global.$type', preference);
    if (mediaKey != null) await prefs.setString('$_prefix.$mediaKey.$type', preference);
    _applied.add(_restoreKey(controller, type));
  }

  static Future<void> restore(PlayerController<dynamic> controller) async {
    final group = controller.trackGroup.value;
    if (controller.currentItem == null || (group.audio.isEmpty && group.sub.isEmpty)) return;
    await Future.wait([_restoreType(controller, 'audio', group.audio), _restoreType(controller, 'sub', group.sub)]);
  }

  static Future<void> onTracksChanged(PlayerController<dynamic> controller) async {
    await restore(controller);
    final group = controller.trackGroup.value;
    await Future.wait([
      _rememberSelectionChange(controller, 'audio', group.selectedAudio, group.audio),
      _rememberSelectionChange(controller, 'sub', group.selectedSub, group.sub),
    ]);
  }

  static void resetForMediaChange(PlayerController<dynamic> controller) {
    final prefix = '${identityHashCode(controller)}:';
    _applied.removeWhere((key) => key.startsWith(prefix));
    _lastSelections.removeWhere((key, _) => key.startsWith(prefix));
  }

  static void disposeController(PlayerController<dynamic> controller) {
    final prefix = '${identityHashCode(controller)}:';
    _applied.removeWhere((key) => key.startsWith(prefix));
    _lastSelections.removeWhere((key, _) => key.startsWith(prefix));
  }

  static Future<void> _rememberSelectionChange(
    PlayerController<dynamic> controller,
    String type,
    String? selected,
    List<MediaTrack> tracks,
  ) async {
    if (tracks.isEmpty) return;
    final key = _restoreKey(controller, type);
    final value = selected ?? _disabled;
    final previous = _lastSelections[key];
    _lastSelections[key] = value;
    if (previous != null && previous != value) {
      await remember(controller, type, selected, tracks);
    }
  }

  static Future<void> _restoreType(PlayerController<dynamic> controller, String type, List<MediaTrack> tracks) async {
    if (tracks.isEmpty) return;
    final restoreKey = _restoreKey(controller, type);
    if (_applied.contains(restoreKey)) return;

    final prefs = await SharedPreferences.getInstance();
    final mediaKey = _mediaKey(controller.currentItem?.source);
    final value =
        (mediaKey == null ? null : prefs.getString('$_prefix.$mediaKey.$type')) ??
        prefs.getString('$_prefix.global.$type');
    if (value == null) {
      _applied.add(restoreKey);
      return;
    }
    if (value == _disabled) {
      _applied.add(restoreKey);
      await controller.setTrack(type, null);
      return;
    }

    final preferred = (jsonDecode(value) as Map).cast<String, dynamic>();
    final match = _bestTrackMatch(preferred, tracks);
    if (match != null) {
      _applied.add(restoreKey);
      await controller.setTrack(type, match.id);
    }
  }

  static MediaTrack? _bestTrackMatch(Map<String, dynamic> preferred, List<MediaTrack> tracks) {
    MediaTrack? best;
    var bestScore = 0;
    for (final track in tracks.where((track) => track.supported)) {
      final current = _trackSignature(track);
      var score = 0;
      for (final key in const ['name', 'label', 'mimeType', 'id']) {
        final value = preferred[key] as String?;
        if (value != null && value.isNotEmpty && value == current[key]) {
          score += switch (key) {
            'mimeType' => 1,
            'id' => 2,
            _ => 4,
          };
        }
      }
      if (score > bestScore) {
        bestScore = score;
        best = track;
      }
    }
    return bestScore >= 2 ? best : null;
  }

  static Map<String, dynamic> _trackSignature(MediaTrack track) => {
    'id': _normalized(track.id),
    'name': _normalized(track.name),
    'label': _normalized(track.label),
    'mimeType': _normalized(track.mimeType),
  };

  static String _normalized(String? value) => value?.trim().toLowerCase() ?? '';

  static String _restoreKey(PlayerController<dynamic> controller, String type) =>
      '${identityHashCode(controller)}:${_mediaKey(controller.currentItem?.source) ?? 'unknown'}:$type';

  static String? _mediaKey(dynamic source) => switch (source) {
    final Movie movie => 'movie:${movie.id}',
    final TVEpisode episode => 'series:${episode.seriesId}',
    _ => null,
  };
}
