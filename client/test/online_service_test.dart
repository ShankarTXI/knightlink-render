import 'package:flutter_test/flutter_test.dart';
import 'package:knightlink/features/online/online_service.dart';

void main() {
  group('OnlineService.normalizeBaseUrl', () {
    final service = OnlineService();

    test('uses the hosted server by default', () {
      expect(service.normalizeBaseUrl(''), OnlineService.defaultServerUrl);
    });

    test('keeps hosted urls on https', () {
      expect(
        service.normalizeBaseUrl('knightlink-server.onrender.com'),
        'https://knightlink-server.onrender.com',
      );
    });

    test('keeps local emulator urls on http', () {
      expect(service.normalizeBaseUrl('10.0.2.2:3000'), 'http://10.0.2.2:3000');
    });

    test('repairs repeated schemes from pasted input', () {
      expect(
        service.normalizeBaseUrl(
          'http://https://knightlink-server.onrender.com',
        ),
        'https://knightlink-server.onrender.com',
      );
    });
  });
}
