import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/error_state.dart';
import '../../../../../shared/widgets/floz_card.dart';
import '../../../../../shared/widgets/staggered_entry.dart';
import '../../domain/entities/assignment.dart';
import '../../providers/assignment_providers.dart';
import 'assignment_detail_screen.dart';

class AssignmentsListScreen extends ConsumerStatefulWidget {
  const AssignmentsListScreen({super.key});

  @override
  ConsumerState<AssignmentsListScreen> createState() =>
      _AssignmentsListScreenState();
}

class _AssignmentsListScreenState
    extends ConsumerState<AssignmentsListScreen> {
  String _activeFilter = 'upcoming';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignmentListNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              activeFilter: _activeFilter,
              onFilterChanged: (f) async {
                setState(() => _activeFilter = f);
                await ref
                    .read(assignmentListNotifierProvider.notifier)
                    .switchFilter(f);
              },
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary600,
                backgroundColor: Colors.white,
                strokeWidth: 2.5,
                onRefresh: () =>
                    ref.read(assignmentListNotifierProvider.notifier).refresh(),
                child: state.when(
                  data: (assignments) =>
                      _AssignmentList(assignments: assignments),
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary600),
                  ),
                  error: (err, _) => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      ErrorState(
                        message: err is Failure
                            ? err.message
                            : 'Gagal memuat tugas',
                        onRetry: () => ref
                            .read(assignmentListNotifierProvider.notifier)
                            .refresh(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.activeFilter,
    required this.onFilterChanged,
  });

  final String activeFilter;
  final void Function(String) onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tugas',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _FilterChip(
                label: 'Belum Dikerjakan',
                isActive: activeFilter == 'upcoming',
                onTap: () => onFilterChanged('upcoming'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Sudah Dikerjakan',
                isActive: activeFilter == 'completed',
                onTap: () => onFilterChanged('completed'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary500 : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
          border: Border.all(
            color: isActive ? AppColors.primary500 : AppColors.slate200,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary500.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.slate600,
          ),
        ),
      ),
    );
  }
}

class _AssignmentList extends StatelessWidget {
  const _AssignmentList({required this.assignments});
  final List<AssignmentSummary> assignments;

  @override
  Widget build(BuildContext context) {
    if (assignments.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          Column(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusLG),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  size: 36,
                  color: AppColors.primary600,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Belum ada tugas',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tugas akan muncul setelah guru\nmenambahkan tugas baru.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.slate500,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: assignments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        return StaggeredEntry(
          index: i,
          child: _AssignmentCard(assignment: assignments[i]),
        );
      },
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.assignment});
  final AssignmentSummary assignment;

  Color get _accentColor {
    if (assignment.isOverdue) return AppColors.danger500;
    return AppColors.primary500; // upcoming = orange
  }

  @override
  Widget build(BuildContext context) {
    final a = assignment;
    final df = DateFormat('d MMM yyyy');

    return FlozCard(
      padding: EdgeInsets.zero,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AssignmentDetailScreen(
              assignmentId: a.id,
              subject: a.subject,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent bar
              Container(width: 5, color: _accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject name
                      Text(
                        a.subject,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate800,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      // Title
                      Text(
                        a.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.slate700,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Due date row
                      if (a.dueDate != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: AppColors.slate400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              df.format(a.dueDate!),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.slate500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (a.isOverdue) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.danger50,
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusSM),
                                ),
                                child: const Text(
                                  'Terlambat',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.danger600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      const SizedBox(height: 4),
                      // Teacher name
                      Text(
                        a.teacher,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Chevron
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Center(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.slate400,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
