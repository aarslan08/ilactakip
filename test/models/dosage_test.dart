import 'package:flutter_test/flutter_test.dart';
import 'package:ilac_takip/models/dosage.dart';

void main() {
  group('Dosage', () {
    test('perDayConsumption returns pillsPerDose * dosesPerDay', () {
      const dosage = Dosage(
        pillsPerDose: 2,
        dosesPerDay: 3,
      );

      expect(dosage.perDayConsumption, 6);
    });

    test('dailyConsumptionRate for daily frequency equals perDayConsumption', () {
      const dosage = Dosage(
        pillsPerDose: 1,
        dosesPerDay: 2,
        frequencyType: FrequencyType.daily,
      );

      expect(dosage.dailyConsumptionRate, 2.0);
    });

    test('dailyConsumptionRate for weekly frequency averages correctly', () {
      const dosage = Dosage(
        pillsPerDose: 1,
        dosesPerDay: 1,
        frequencyType: FrequencyType.weekly,
        weeklyDays: [1, 3, 5],
      );

      expect(dosage.dailyConsumptionRate, closeTo(0.428, 0.001));
    });

    test('isDueToday returns true for daily frequency', () {
      const dosage = Dosage(
        pillsPerDose: 1,
        dosesPerDay: 1,
        frequencyType: FrequencyType.daily,
      );

      expect(dosage.isDueToday(), true);
    });

    test('isDueToday returns true only on scheduled weekday', () {
      const dosage = Dosage(
        pillsPerDose: 1,
        dosesPerDay: 1,
        frequencyType: FrequencyType.weekly,
        weeklyDays: [DateTime.monday],
      );

      final monday = DateTime(2024, 1, 1); // Monday
      final tuesday = DateTime(2024, 1, 2); // Tuesday

      expect(dosage.isDueToday(monday), true);
      expect(dosage.isDueToday(tuesday), false);
    });

    test('copyWith creates a new instance with updated values', () {
      const dosage = Dosage(
        pillsPerDose: 1,
        dosesPerDay: 1,
        scheduleTimes: ['08:00'],
      );

      final updated = dosage.copyWith(
        pillsPerDose: 2,
        dosesPerDay: 3,
      );

      expect(updated.pillsPerDose, 2);
      expect(updated.dosesPerDay, 3);
      expect(updated.scheduleTimes, ['08:00']);
    });
  });
}
