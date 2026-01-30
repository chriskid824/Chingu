import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/favorite_service.dart';

void main() {
  late FavoriteService favoriteService;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    favoriteService = FavoriteService(firestore: fakeFirestore);
  });

  group('FavoriteService', () {
    const userId = 'user1';
    const targetId = 'target1';

    test('toggleFavorite adds favorite if not exists', () async {
      final result = await favoriteService.toggleFavorite(userId, targetId);
      expect(result, true);

      final isFav = await favoriteService.isFavorite(userId, targetId);
      expect(isFav, true);
    });

    test('toggleFavorite removes favorite if exists', () async {
      // Add first
      await favoriteService.toggleFavorite(userId, targetId);

      // Toggle again
      final result = await favoriteService.toggleFavorite(userId, targetId);
      expect(result, false);

      final isFav = await favoriteService.isFavorite(userId, targetId);
      expect(isFav, false);
    });

    test('getFavoritesStream returns correct IDs', () async {
      await favoriteService.toggleFavorite(userId, 'target1');
      await favoriteService.toggleFavorite(userId, 'target2');

      final stream = favoriteService.getFavoritesStream(userId);

      expect(stream, emitsInOrder([
        unorderedEquals(['target1', 'target2']),
      ]));
    });
  });
}
