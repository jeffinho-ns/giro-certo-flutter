import 'package:flutter_test/flutter_test.dart';
import 'package:giro_certo/utils/image_url.dart';

void main() {
  group('resolveImageUrl', () {
    test('URL absoluta Firebase retorna igual', () {
      const url =
          'https://firebasestorage.googleapis.com/v0/b/agilizaiapp-img.firebasestorage.app/o/giro-certo%2Fposts%2Fabc.jpg?alt=media&token=xxx';
      expect(resolveImageUrl(url), url);
    });

    test('URL absoluta API retorna igual', () {
      const url = 'https://giro-certo-api.onrender.com/api/images/img123';
      expect(resolveImageUrl(url), url);
    });

    test('URL relativa /api/images/xxx converte para absoluta', () {
      final result = resolveImageUrl('/api/images/img123');
      expect(result, contains('giro-certo-api.onrender.com'));
      expect(result, contains('/api/images/img123'));
      expect(result, startsWith('https://'));
    });

    test('string vazia retorna vazia', () {
      expect(resolveImageUrl(''), '');
      expect(resolveImageUrl(null), '');
    });

    test('assets/ retorna igual', () {
      expect(resolveImageUrl('assets/images/placeholder.png'),
          'assets/images/placeholder.png');
    });
  });
}
