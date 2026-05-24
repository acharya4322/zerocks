import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../../../providers/app_providers.dart';

// ── Filter state ─────────────────────────────────────────
enum QueueFilter { all, active, completed, cancelled }

class QueueFilterNotifier extends Notifier<QueueFilter> {
  @override
  QueueFilter build() => QueueFilter.all;

  void setFilter(QueueFilter filter) {
    state = filter;
  }
}

final queueFilterProvider =
    NotifierProvider<QueueFilterNotifier, QueueFilter>(QueueFilterNotifier.new);

// ── Stream of all jobs for a shop ────────────────────────
final shopJobsProvider =
    StreamProvider.family<List<PrintJobModel>, String>((ref, shopId) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.streamJobsByShop(shopId);
});

// ── Active jobs only (for queue management) ──────────────
final activeJobsProvider =
    StreamProvider.family<List<PrintJobModel>, String>((ref, shopId) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.streamActiveJobsByShop(shopId);
});

// ── Filtered jobs ────────────────────────────────────────
final filteredJobsProvider =
    Provider.family<AsyncValue<List<PrintJobModel>>, String>((ref, shopId) {
  final jobsAsync = ref.watch(shopJobsProvider(shopId));
  final filter = ref.watch(queueFilterProvider);

  return jobsAsync.whenData((jobs) {
    switch (filter) {
      case QueueFilter.all:
        return jobs;
      case QueueFilter.active:
        return jobs.where((j) => j.isActive).toList();
      case QueueFilter.completed:
        return jobs
            .where((j) => j.status == PrintJobStatus.completed)
            .toList();
      case QueueFilter.cancelled:
        return jobs
            .where((j) => j.status == PrintJobStatus.cancelled)
            .toList();
    }
  });
});

// ── Queue Stats ──────────────────────────────────────────
final queueStatsProvider =
    Provider.family<_QueueStats, String>((ref, shopId) {
  final jobsAsync = ref.watch(shopJobsProvider(shopId));
  return jobsAsync.when(
    data: (jobs) {
      final active = jobs.where((j) => j.isActive).length;
      final completed =
          jobs.where((j) => j.status == PrintJobStatus.completed).length;
      final today = jobs
          .where((j) => ZDateUtils.isToday(j.createdAt))
          .length;
      return _QueueStats(
        activeJobs: active,
        completedJobs: completed,
        todayJobs: today,
        totalJobs: jobs.length,
      );
    },
    loading: () => const _QueueStats(),
    error: (_, __) => const _QueueStats(),
  );
});

class _QueueStats {
  final int activeJobs;
  final int completedJobs;
  final int todayJobs;
  final int totalJobs;

  const _QueueStats({
    this.activeJobs = 0,
    this.completedJobs = 0,
    this.todayJobs = 0,
    this.totalJobs = 0,
  });
}
