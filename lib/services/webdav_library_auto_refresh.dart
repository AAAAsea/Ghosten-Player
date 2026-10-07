import 'package:api/api.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef LibraryQuery = Future<List<Library>> Function(LibraryType type);
typedef ScheduleTaskQuery = Future<List<ScheduleTask>> Function();
typedef LibraryRefresh = Future<void> Function(dynamic id, bool incremental);

class WebDavLibraryAutoRefresh {
  WebDavLibraryAutoRefresh({
    required this.prefs,
    LibraryQuery? queryLibraries,
    ScheduleTaskQuery? queryTasks,
    LibraryRefresh? refreshLibrary,
    DateTime Function()? now,
    Future<void> Function(Duration)? delay,
    this.cooldown = const Duration(minutes: 1),
    this.pollInterval = const Duration(seconds: 1),
    this.waitTimeout = const Duration(seconds: 30),
  }) : _queryLibraries = queryLibraries ?? Api.libraryQueryAll,
       _queryTasks = queryTasks ?? Api.scheduleTaskQueryByAll,
       _refreshLibrary = refreshLibrary ?? Api.libraryRefreshById,
       _now = now ?? DateTime.now,
       _delay = delay ?? Future<void>.delayed;

  static const lastAttemptPreference = 'library.webdavAutoRefresh.lastAttempt';
  static const lastSuccessPreference = 'library.webdavAutoRefresh.lastSuccess';

  final SharedPreferences prefs;
  final LibraryQuery _queryLibraries;
  final ScheduleTaskQuery _queryTasks;
  final LibraryRefresh _refreshLibrary;
  final DateTime Function() _now;
  final Future<void> Function(Duration) _delay;
  final Duration cooldown;
  final Duration pollInterval;
  final Duration waitTimeout;

  bool _refreshing = false;

  Future<bool> refreshIfDue({bool force = false}) async {
    if (_refreshing || (!force && !_isDue())) return false;

    _refreshing = true;
    await prefs.setString(lastAttemptPreference, _now().toIso8601String());
    try {
      final libraries = await _queryLibraries(LibraryType.movie);
      final targets = libraries.where((library) => library.driverType == DriverType.webdav).toList();
      if (targets.isEmpty) return false;

      final tasks = await _queryTasks();
      final blockedRids =
          tasks
              .where(
                (task) =>
                    task.type == ScheduleTaskType.syncLibrary &&
                    (task.status == ScheduleTaskStatus.idle ||
                        task.status == ScheduleTaskStatus.running ||
                        task.status == ScheduleTaskStatus.paused),
              )
              .map((task) => task.rid)
              .toSet();
      final waitingRids = <int>{};
      var shouldReload = false;

      for (final library in targets) {
        final rid = _asInt(library.id);
        if (rid == null) continue;
        if (blockedRids.contains(rid)) {
          if (tasks.any(
            (task) =>
                task.rid == rid &&
                task.type == ScheduleTaskType.syncLibrary &&
                (task.status == ScheduleTaskStatus.idle || task.status == ScheduleTaskStatus.running),
          )) {
            waitingRids.add(rid);
            shouldReload = true;
          }
          continue;
        }

        await _refreshLibrary(library.id, true);
        waitingRids.add(rid);
        shouldReload = true;
      }

      if (!shouldReload) return false;
      await _waitForSyncTasks(waitingRids);
      await prefs.setString(lastSuccessPreference, _now().toIso8601String());
      return true;
    } catch (error, stackTrace) {
      debugPrint('WebDAV movie auto-refresh failed: $error\n$stackTrace');
      return false;
    } finally {
      _refreshing = false;
    }
  }

  bool _isDue() {
    final lastAttempt = DateTime.tryParse(prefs.getString(lastAttemptPreference) ?? '');
    return lastAttempt == null || _now().difference(lastAttempt) >= cooldown;
  }

  Future<void> _waitForSyncTasks(Set<int> rids) async {
    if (rids.isEmpty || waitTimeout <= Duration.zero) return;
    final deadline = _now().add(waitTimeout);
    while (_now().isBefore(deadline)) {
      await _delay(pollInterval);
      final active = (await _queryTasks()).any(
        (task) =>
            rids.contains(task.rid) &&
            task.type == ScheduleTaskType.syncLibrary &&
            (task.status == ScheduleTaskStatus.idle || task.status == ScheduleTaskStatus.running),
      );
      if (!active) return;
    }
  }

  int? _asInt(dynamic value) => value is int ? value : int.tryParse(value.toString());
}
