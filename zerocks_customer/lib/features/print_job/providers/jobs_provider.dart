import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../../../providers/app_providers.dart';

/// Streams all print jobs for the current user, ordered by creation date.
final userJobsProvider = StreamProvider<List<PrintJobModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamJobsByUser(user.uid);
});

/// Streams a single print job by ID for real-time tracking.
final jobStreamProvider =
    StreamProvider.family<PrintJobModel?, String>((ref, jobId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamJob(jobId);
});
