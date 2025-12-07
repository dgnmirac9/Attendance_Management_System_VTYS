import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/services/user_service.dart';
import '../../auth/providers/auth_controller.dart';
import 'classroom_provider.dart';



// 1. Raw Classes Stream
final userClassesStreamProvider = StreamProvider.autoDispose<QuerySnapshot>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;
  
  if (user == null) return const Stream.empty();
  
  return Stream.fromFuture(ref.read(userServiceProvider).getUserRole(user.uid)).asyncExpand((role) {
    final service = ref.read(classroomServiceProvider);
    return service.getUserClasses(user.uid, role ?? 'student');
  });
});

// 2. User Data Stream (for Order)
final userDataStreamProvider = StreamProvider.autoDispose<DocumentSnapshot>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;
  
  if (user == null) return const Stream.empty();
  return ref.read(userServiceProvider).getUserStream(user.uid);
});

// 3. Sorted Classes Provider
final sortedClassesProvider = Provider.autoDispose<AsyncValue<List<QueryDocumentSnapshot>>>((ref) {
  final classesAsync = ref.watch(userClassesStreamProvider);
  final userDataAsync = ref.watch(userDataStreamProvider);

  if (classesAsync.isLoading || userDataAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (classesAsync.hasError) return AsyncValue.error(classesAsync.error!, classesAsync.stackTrace!);
  
  final classes = classesAsync.value?.docs ?? [];
  final userData = userDataAsync.value?.data() as Map<String, dynamic>?;
  final orderList = (userData?['classOrder'] as List<dynamic>?)?.cast<String>() ?? [];

  if (orderList.isEmpty) {
    return AsyncValue.data(classes);
  }

  // Sort based on orderList (which contains class codes or IDs? Source used 'code'. Mirac uses 'joinCode' or doc ID?)
  // Source used 'code'. Mirac has 'joinCode'. Let's assume 'joinCode' is the unique identifier visible to users,
  // but doc ID is safer. The source used 'code' which was the join code.
  // Let's assume we sort by 'joinCode' if that's what we save.
  // Wait, in HomeScreen migration I should decide what to save. I'll save 'joinCode' or Doc ID.
  // Doc ID is better.
  
  final sorted = List<QueryDocumentSnapshot>.from(classes);
  sorted.sort((a, b) {
    // Try to match by ID first, then joinCode
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
