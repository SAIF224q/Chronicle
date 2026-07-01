import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronicle_app/src/application/services/vibe_check_service.dart';

class _FakeRandom implements Random {
  final int value;
  _FakeRandom(this.value);

  @override
  int nextInt(int max) => value % max;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0.0;
}

void main() {
  group('VibeCheckService', () {
    test('getFollowUpPrompt selects correct mood prompt', () {
      final service = VibeCheckService(random: _FakeRandom(0));
      final prompt = service.getFollowUpPrompt('hype');
      expect(prompt, VibeCheckService.moodPrompts['hype']![0]);
    });

    test('getFollowUpPrompt falls back to none if mood not found', () {
      final service = VibeCheckService(random: _FakeRandom(1));
      final prompt = service.getFollowUpPrompt('invalid_mood');
      expect(prompt, VibeCheckService.moodPrompts['none']![1]);
    });

    test('getFinalSupportResponse returns correct supportive responses', () {
      final service = VibeCheckService();
      expect(service.getFinalSupportResponse('hype').contains('winning'), true);
      expect(service.getFinalSupportResponse('chill').contains('downtime') || service.getFinalSupportResponse('chill').contains('relaxing'), true);
      expect(service.getFinalSupportResponse('stressed').contains('calm'), true);
      expect(service.getFinalSupportResponse('none').contains('checking in'), true);
    });
  });
}
