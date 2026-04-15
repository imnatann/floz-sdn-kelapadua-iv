import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/floz_card.dart';
import '../providers/assignment_providers.dart';
import '../domain/assignment_models.dart';

class AssignmentsScreen extends ConsumerStatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: Text(
          'Daftar Tugas',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.neutral800,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary600,
          unselectedLabelColor: AppColors.neutral500,
          indicatorColor: AppColors.primary600,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Mendatang'),
            Tab(text: 'Selesai'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAssignmentList(ref.watch(upcomingAssignmentsProvider), true),
          _buildAssignmentList(ref.watch(completedAssignmentsProvider), false),
        ],
      ),
    );
  }

  Widget _buildAssignmentList(
    AsyncValue<List<AssignmentItem>> asyncValue,
    bool isUpcoming,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        if (isUpcoming) {
          ref.invalidate(upcomingAssignmentsProvider);
        } else {
          ref.invalidate(completedAssignmentsProvider);
        }
      },
      child: asyncValue.when(
        data: (assignments) {
          if (assignments.isEmpty) {
            return ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HeroIcon(
                          isUpcoming
                              ? HeroIcons.clipboardDocumentList
                              : HeroIcons.clipboardDocumentCheck,
                          size: 48,
                          color: AppColors.neutral300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isUpcoming
                              ? 'Tidak ada tugas mendatang'
                              : 'Belum ada tugas yang diselesaikan',
                          style: GoogleFonts.inter(color: AppColors.neutral500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: assignments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              return FlozCard(
                onTap: () => context.push('/assignments/${assignment.id}'),
                padding: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              assignment.subject,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary600,
                              ),
                            ),
                          ),
                          if (assignment.dueDate != null)
                            Row(
                              children: [
                                const HeroIcon(
                                  HeroIcons.clock,
                                  size: 14,
                                  color: AppColors.neutral400,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat(
                                    'dd MMM yy, HH:mm',
                                  ).format(assignment.dueDate!),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.neutral600,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        assignment.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.neutral800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        assignment.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.neutral500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const HeroIcon(
                            HeroIcons.userCircle,
                            size: 16,
                            color: AppColors.neutral400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            assignment.teacher,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.neutral600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Gagal memuat: $err')),
      ),
    );
  }
}
