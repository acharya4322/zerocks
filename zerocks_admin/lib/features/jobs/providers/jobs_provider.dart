import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../../../providers/app_providers.dart';

enum JobFilter { all, active, completed }

class JobFilterNotifier extends Notifier<JobFilter> {
  @override
  JobFilter build() => JobFilter.all;

  void setFilter(JobFilter filter) {
    state = filter;
  }
}

final jobFilterProvider =
    NotifierProvider<JobFilterNotifier, JobFilter>(JobFilterNotifier.new);

// Stream all jobs
final allJobsProvider = StreamProvider<List<PrintJobModel>>((ref) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.getAllJobs();
});

// Filtered jobs
final filteredJobsProvider = Provider<AsyncValue<List<PrintJobModel>>>((ref) {
  final jobsAsync = ref.watch(allJobsProvider);
  final filter = ref.watch(jobFilterProvider);

  return jobsAsync.whenData((jobs) {
    switch (filter) {
      case JobFilter.all:
        return jobs;
      case JobFilter.active:
        return jobs.where((j) => j.isActive).toList();
      case JobFilter.completed:
        return jobs.where((j) => !j.isActive).toList();
    }
  });
});
