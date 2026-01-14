import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/services/moment_service.dart';

void main() {
  group('MomentService', () {
    test('Should verify MomentService methods exist', () {
      final service = MomentService();

      expect(service, isNotNull);
      expect(service.toggleLike, isNotNull);
      expect(service.getCommentsStream, isNotNull);
      expect(service.addComment, isNotNull);
    });
  });
}
