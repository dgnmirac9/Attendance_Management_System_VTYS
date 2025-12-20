
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Mock Provider to simulate Data Source
final mockDataProvider = StateProvider<String>((ref) => "Initial Data");

// Mock Derived Provider to simulate Screen Data
final screenDataProvider = Provider<String>((ref) {
  return ref.watch(mockDataProvider);
});

void main() {
  group('Synchronization Logic (State Management) Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Invalidating provider triggers update in listeners', () {
      // 1. Initial State
      expect(container.read(screenDataProvider), "Initial Data");

      // 2. Update Data Source
      container.read(mockDataProvider.notifier).state = "New Updated Data";

      // 3. Verify screenDataProvider reflects change automatically (Riverpod logic)
      expect(container.read(screenDataProvider), "New Updated Data");
    });

    test('Explicit Invalidation forces refresh (simulating manual ref.invalidate)', () {
      // 1. Setup a counter provider to verify auto-dispose/refresh behavior
      int buildCount = 0;
      final counterProvider = Provider<int>((ref) {
        buildCount++;
        return buildCount;
      });

      expect(container.read(counterProvider), 1);
      
      // 2. Force Invalidate
      container.invalidate(counterProvider);
      
      // 3. Next read should trigger rebuild
      expect(container.read(counterProvider), 2);
    });
  });
}
