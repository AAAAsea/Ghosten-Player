import 'package:api/api.dart';
import 'package:lpinyin/lpinyin.dart';

/// A small in-memory index used by the TV UI for pinyin search and alphabet
/// browsing. The server search remains available for the other media types.
class MediaLibraryIndex {
  MediaLibraryIndex._();

  static const _cacheLifetime = Duration(minutes: 5);
  static Future<List<Movie>>? _moviesFuture;
  static Future<List<TVSeries>>? _seriesFuture;
  static DateTime? _moviesCachedAt;
  static DateTime? _seriesCachedAt;

  static Future<List<Movie>> movies() {
    if (_moviesFuture == null || _isExpired(_moviesCachedAt)) {
      _moviesCachedAt = DateTime.now();
      _moviesFuture = _loadAll<Movie>(Api.movieQueryAll);
    }
    return _moviesFuture!;
  }

  static Future<List<TVSeries>> series() {
    if (_seriesFuture == null || _isExpired(_seriesCachedAt)) {
      _seriesCachedAt = DateTime.now();
      _seriesFuture = _loadAll<TVSeries>(Api.tvSeriesQueryAll);
    }
    return _seriesFuture!;
  }

  static Future<List<Movie>> searchMovies(
    String query, {
    List<dynamic> genres = const [],
    List<dynamic> studios = const [],
    List<dynamic> keywords = const [],
    List<dynamic> mediaCast = const [],
    List<dynamic> mediaCrew = const [],
    bool? watched,
    bool? favorite,
  }) async {
    final data = await movies();
    return _search(
      data.where(
        (item) => _matchesFilters(
          item,
          genres: genres,
          studios: studios,
          keywords: keywords,
          mediaCast: mediaCast,
          mediaCrew: mediaCrew,
          watched: watched,
          favorite: favorite,
        ),
      ),
      query,
      (item) => [item.title, item.originalTitle],
    );
  }

  static Future<List<TVSeries>> searchSeries(
    String query, {
    List<dynamic> genres = const [],
    List<dynamic> studios = const [],
    List<dynamic> keywords = const [],
    List<dynamic> mediaCast = const [],
    List<dynamic> mediaCrew = const [],
    bool? watched,
    bool? favorite,
  }) async {
    final data = await series();
    return _search(
      data.where(
        (item) => _matchesFilters(
          item,
          genres: genres,
          studios: studios,
          keywords: keywords,
          mediaCast: mediaCast,
          mediaCrew: mediaCrew,
          watched: watched,
          favorite: favorite,
        ),
      ),
      query,
      (item) => [item.title, item.originalTitle],
    );
  }

  static String alphabetKey(String title) {
    final key = _pinyin(title);
    if (key.isEmpty) return '#';
    final first = key.substring(0, 1).toUpperCase();
    return RegExp(r'[A-Z]').hasMatch(first) ? first : '#';
  }

  static int compareTitles(String a, String b) => _pinyin(a).compareTo(_pinyin(b));

  static bool matchesTitle(String title, String query) {
    final needle = _normalize(query);
    return needle.isEmpty || _searchKeys(title).any((candidate) => _score(candidate, needle) < 1 << 30);
  }

  static bool _isExpired(DateTime? cachedAt) =>
      cachedAt == null || DateTime.now().difference(cachedAt) > _cacheLifetime;

  static Future<List<T>> _loadAll<T>(Future<PageData<T>> Function(MediaSearchQuery) query) async {
    const limit = 100;
    final first = await query(
      const MediaSearchQuery(
        limit: limit,
        offset: 0,
        sort: SortConfig(type: SortType.title, direction: SortDirection.asc),
      ),
    );
    final items = [...first.data];
    if (items.length < first.count) {
      final pages = <Future<PageData<T>>>[];
      for (var offset = limit; offset < first.count; offset += limit) {
        pages.add(
          query(
            MediaSearchQuery(
              limit: limit,
              offset: offset,
              sort: const SortConfig(type: SortType.title, direction: SortDirection.asc),
            ),
          ),
        );
      }
      for (final page in await Future.wait(pages)) {
        items.addAll(page.data);
      }
    }
    return items;
  }

  static List<T> _search<T>(Iterable<T> source, String query, List<String?> Function(T) titleOf) {
    final needle = _normalize(query);
    if (needle.isEmpty) return source.toList();

    final matches = <(T, int, String)>[];
    for (final item in source) {
      final titles = titleOf(item).whereType<String>().where((title) => title.trim().isNotEmpty);
      var score = 1 << 30;
      var sortTitle = '';
      for (final title in titles) {
        sortTitle = sortTitle.isEmpty ? title : sortTitle;
        for (final candidate in _searchKeys(title)) {
          final candidateScore = _score(candidate, needle);
          if (candidateScore < score) score = candidateScore;
        }
      }
      if (score < 1 << 30) matches.add((item, score, sortTitle));
    }

    matches.sort((a, b) {
      final score = a.$2.compareTo(b.$2);
      return score != 0 ? score : compareTitles(a.$3, b.$3);
    });
    return matches.map((match) => match.$1).toList();
  }

  static Iterable<String> _searchKeys(String title) sync* {
    final normalized = _normalize(title);
    if (normalized.isNotEmpty) yield normalized;
    final fullPinyin = _pinyin(title);
    if (fullPinyin.isNotEmpty && fullPinyin != normalized) yield fullPinyin;
    final shortPinyin = _shortPinyin(title);
    if (shortPinyin.isNotEmpty && shortPinyin != normalized) yield shortPinyin;
  }

  static int _score(String candidate, String query) {
    if (candidate == query) return 0;
    if (candidate.startsWith(query)) return 10 + candidate.length - query.length;
    final containsAt = candidate.indexOf(query);
    if (containsAt >= 0) return 100 + containsAt * 2 + candidate.length - query.length;

    var queryIndex = 0;
    var gap = 0;
    var lastMatch = -1;
    for (var i = 0; i < candidate.length && queryIndex < query.length; i++) {
      if (candidate.codeUnitAt(i) == query.codeUnitAt(queryIndex)) {
        if (lastMatch >= 0) gap += i - lastMatch - 1;
        lastMatch = i;
        queryIndex++;
      }
    }
    return queryIndex == query.length ? 500 + gap * 8 + candidate.length - query.length : 1 << 30;
  }

  static bool _matchesFilters(
    Media item, {
    required List<dynamic> genres,
    required List<dynamic> studios,
    required List<dynamic> keywords,
    required List<dynamic> mediaCast,
    required List<dynamic> mediaCrew,
    required bool? watched,
    required bool? favorite,
  }) {
    final itemGenres = switch (item) {
      final Movie value => value.genres,
      final TVSeries value => value.genres,
      _ => const <Genre>[],
    };
    final itemStudios = switch (item) {
      final Movie value => value.studios,
      final TVSeries value => value.studios,
      _ => const <Studio>[],
    };
    final itemKeywords = switch (item) {
      final Movie value => value.keywords,
      final TVSeries value => value.keywords,
      _ => const <Keyword>[],
    };

    return (watched == null || item.watched == watched) &&
        (favorite == null || item.favorite == favorite) &&
        _containsAll(itemGenres.map((value) => value.id), genres) &&
        _containsAll(itemStudios.map((value) => value.id), studios) &&
        _containsAll(itemKeywords.map((value) => value.id), keywords) &&
        _containsAll(item.mediaCast.map((value) => value.id), mediaCast) &&
        _containsAll(item.mediaCrew.map((value) => value.id), mediaCrew);
  }

  static bool _containsAll(Iterable<dynamic> values, List<dynamic> selected) {
    if (selected.isEmpty) return true;
    final valueSet = values.toSet();
    return selected.every(valueSet.contains);
  }

  static String _normalize(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fff]'), '');

  static String _pinyin(String value) {
    try {
      return _normalize(PinyinHelper.getPinyinE(value, separator: '', defPinyin: ''));
    } catch (_) {
      return _normalize(value);
    }
  }

  static String _shortPinyin(String value) {
    try {
      return _normalize(PinyinHelper.getShortPinyin(value));
    } catch (_) {
      return '';
    }
  }
}
