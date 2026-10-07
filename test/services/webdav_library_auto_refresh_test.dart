import 'package:api/api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghosten_player/services/webdav_library_auto_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('incrementally refreshes only WebDAV movie libraries', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final calls = <(dynamic, bool)>[];
    final refresher = WebDavLibraryAutoRefresh(
      prefs: prefs,
      queryLibraries:
          (_) async => [_library(id: 1, driverType: DriverType.webdav), _library(id: 2, driverType: DriverType.quark)],
      queryTasks: () async => [],
      refreshLibrary: (id, incremental) async => calls.add((id, incremental)),
      waitTimeout: Duration.zero,
    );

    expect(await refresher.refreshIfDue(), isTrue);
    expect(calls, [(1, true)]);
    expect(prefs.getString(WebDavLibraryAutoRefresh.lastSuccessPreference), isNotNull);
  });

  test('cooldown prevents repeated scans across instances', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime(2026, 10, 7, 12);
    var calls = 0;

    WebDavLibraryAutoRefresh build() => WebDavLibraryAutoRefresh(
      prefs: prefs,
      now: () => now,
      queryLibraries: (_) async => [_library(id: 1, driverType: DriverType.webdav)],
      queryTasks: () async => [],
      refreshLibrary: (_, _) async => calls++,
      waitTimeout: Duration.zero,
    );

    expect(await build().refreshIfDue(), isTrue);
    expect(await build().refreshIfDue(), isFalse);
    expect(calls, 1);
  });

  test('does not enqueue a duplicate running sync task', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var calls = 0;
    final refresher = WebDavLibraryAutoRefresh(
      prefs: prefs,
      queryLibraries: (_) async => [_library(id: 7, driverType: DriverType.webdav)],
      queryTasks:
          () async => [
            ScheduleTask.fromJson([
              10,
              7,
              null,
              ScheduleTaskType.syncLibrary.index,
              ScheduleTaskStatus.running.index,
              null,
            ]),
          ],
      refreshLibrary: (_, _) async => calls++,
      waitTimeout: Duration.zero,
    );

    expect(await refresher.refreshIfDue(), isTrue);
    expect(calls, 0);
  });
}

Library _library({required int id, required DriverType driverType}) {
  return Library.fromJson([id, 'driver', driverType.index, null, null, 1, null, 'Movies', LibraryType.movie.index]);
}
