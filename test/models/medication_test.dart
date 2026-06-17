import 'package:flutter_test/flutter_test.dart';
import 'package:ilac_takip/models/medication.dart';
import 'package:ilac_takip/models/dosage.dart';

void main() {
  group('Medication', () {
    final baseMedication = Medication(
      id: 'test-id',
      name: 'Paracetamol 500mg',
      currentStock: 30,
      startDate: DateTime(2024, 1, 1),
      dosage: const Dosage(
        pillsPerDose: 1,
        dosesPerDay: 3,
        frequencyType: FrequencyType.daily,
      ),
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    test('estimatedDaysLeft calculates correctly', () {
      expect(baseMedication.estimatedDaysLeft, 10);
    });

    test('isLowStock returns true when stock is at or below threshold', () {
      final lowStockMedication = baseMedication.copyWith(currentStock: 5);
      expect(lowStockMedication.isLowStock, true);

      final normalStockMedication = baseMedication.copyWith(currentStock: 6);
      expect(normalStockMedication.isLowStock, false);
    });

    test('shouldShowRunoutWarning returns true when days left <= warning days', () {
      final warningMedication = baseMedication.copyWith(currentStock: 15);
      expect(warningMedication.shouldShowRunoutWarning, true);

      final safeMedication = baseMedication.copyWith(currentStock: 30);
      expect(safeMedication.shouldShowRunoutWarning, false);
    });

    test('isExpired returns true when expiration date has passed', () {
      final expiredMedication = baseMedication.copyWith(
        expirationDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(expiredMedication.isExpired, true);

      final validMedication = baseMedication.copyWith(
        expirationDate: DateTime.now().add(const Duration(days: 30)),
      );
      expect(validMedication.isExpired, false);
    });

    test('toMap and fromMap preserve values', () {
      final map = baseMedication.toMap();
      final restoredMedication = Medication.fromMap(map);

      expect(restoredMedication.id, baseMedication.id);
      expect(restoredMedication.name, baseMedication.name);
      expect(restoredMedication.currentStock, baseMedication.currentStock);
      expect(restoredMedication.dosage.pillsPerDose, baseMedication.dosage.pillsPerDose);
      expect(restoredMedication.dosage.dosesPerDay, baseMedication.dosage.dosesPerDay);
      expect(restoredMedication.dosage.frequencyType, baseMedication.dosage.frequencyType);
    });

    test('copyWith updates values without mutating original', () {
      final updatedMedication = baseMedication.copyWith(
        currentStock: 50,
        notes: 'Updated notes',
      );

      expect(updatedMedication.currentStock, 50);
      expect(updatedMedication.notes, 'Updated notes');
      expect(baseMedication.currentStock, 30);
      expect(baseMedication.notes, null);
    });
  });
}
