import 'package:flutter_test/flutter_test.dart';
import 'package:ghosten_player/utils/media_library_index.dart';

void main() {
  group('MediaLibraryIndex', () {
    test('uses pinyin initials as the alphabet key', () {
      expect(MediaLibraryIndex.alphabetKey('老友记'), 'L');
      expect(MediaLibraryIndex.alphabetKey('权力的游戏'), 'Q');
      expect(MediaLibraryIndex.alphabetKey('Avatar'), 'A');
      expect(MediaLibraryIndex.alphabetKey('2001太空漫游'), '#');
    });

    test('sorts Chinese titles by pinyin', () {
      final titles = ['纸牌屋', '老友记', '权力的游戏'];
      titles.sort(MediaLibraryIndex.compareTitles);
      expect(titles, ['老友记', '权力的游戏', '纸牌屋']);
    });

    test('matches full pinyin, initials, and fuzzy subsequences', () {
      expect(MediaLibraryIndex.matchesTitle('老友记', 'laoyouji'), isTrue);
      expect(MediaLibraryIndex.matchesTitle('老友记', 'lyj'), isTrue);
      expect(MediaLibraryIndex.matchesTitle('权力的游戏', 'qldy'), isTrue);
      expect(MediaLibraryIndex.matchesTitle('老友记', 'gqwy'), isFalse);
    });
  });
}
