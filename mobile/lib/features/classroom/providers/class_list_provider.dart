import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_controller.dart';
import 'classroom_provider.dart';
import '../models/class_model.dart';

// Sorted Classes Provider (consumes future provider from classroom_provider)
final sortedClassesProvider = Provider.autoDispose<AsyncValue<List<ClassModel>>>((ref) {
  final classesAsync = ref.watch(userClassesFutureProvider);
  final user = ref.watch(currentUserProvider);

  if (classesAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (classesAsync.hasError) return AsyncValue.error(classesAsync.error!, classesAsync.stackTrace!);
  
  final classes = classesAsync.value ?? [];
  final orderList = user?.classOrder ?? [];

  if (orderList.isEmpty) {
    return AsyncValue.data(classes);
  }

  // Sort based on orderList (IDs)
  final sorted = List<ClassModel>.from(classes);
  sorted.sort((a, b) {
    String idA = a.id;
    String idB = b.id;
    
    int indexA = orderList.indexOf(idA);
    int indexB = orderList.indexOf(idB);

    if (indexA == -1) indexA = 9999;
    if (indexB == -1) indexB = 9999;
    
    return indexA.compareTo(indexB);
  });

  return AsyncValue.data(sorted);
});
