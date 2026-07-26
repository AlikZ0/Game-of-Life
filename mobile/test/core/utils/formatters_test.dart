import 'package:flutter_test/flutter_test.dart';
import 'package:life_quest/core/utils/formatters.dart';

void main() {
  group('Formatters.count / compact', () {
    test('groups thousands', () {
      expect(Formatters.count(1234), '1,234');
    });

    test('compacts millions', () {
      expect(Formatters.compact(1500000), '1.5M');
    });
  });

  group('Formatters.xp / gold', () {
    test('suffixes XP', () {
      expect(Formatters.xp(1500000), '1.5M XP');
    });

    test('suffixes gold', () {
      expect(Formatters.gold(250), '250 g');
    });
  });

  group('Formatters.percent', () {
    test('renders a 0..1 fraction as a rounded percentage', () {
      expect(Formatters.percent(0.95), '95%');
    });

    test('clamps above 1 to 100%', () {
      expect(Formatters.percent(1.5), '100%');
    });

    test('clamps below 0 to 0%', () {
      expect(Formatters.percent(-0.2), '0%');
    });
  });

  group('Formatters.countdown', () {
    test('days + hours', () {
      expect(
        Formatters.countdown(const Duration(days: 2, hours: 4, minutes: 9)),
        '2d 4h',
      );
    });

    test('hours + minutes', () {
      expect(
        Formatters.countdown(const Duration(hours: 3, minutes: 12)),
        '3h 12m',
      );
    });

    test('minutes only', () {
      expect(Formatters.countdown(const Duration(minutes: 45)), '45m');
    });

    test('negative durations read as Expired', () {
      expect(Formatters.countdown(const Duration(seconds: -1)), 'Expired');
    });
  });

  group('Formatters.enumLabel', () {
    test('title-cases a single token', () {
      expect(Formatters.enumLabel('WARRIOR'), 'Warrior');
    });

    test('title-cases a multi-token enum', () {
      expect(Formatters.enumLabel('QUESTS_COMPLETED'), 'Quests Completed');
    });
  });

  group('Formatters.relativeDay', () {
    test('labels today, tomorrow and yesterday', () {
      final now = DateTime.now();
      expect(Formatters.relativeDay(now), 'Today');
      expect(
        Formatters.relativeDay(now.add(const Duration(days: 1))),
        'Tomorrow',
      );
      expect(
        Formatters.relativeDay(now.subtract(const Duration(days: 1))),
        'Yesterday',
      );
    });
  });
}
