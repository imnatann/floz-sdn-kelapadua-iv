import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/error_state.dart';
import '../../../../../shared/widgets/floz_button.dart';
import '../../../../../shared/widgets/floz_card.dart';
import '../../../../../shared/widgets/staggered_entry.dart';
import '../../domain/entities/grade_roster.dart';
import '../../providers/grade_input_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Local state model
// ─────────────────────────────────────────────────────────────────────────────

class _GradeEntry {
  double? daily;
  double? mid;
  double? finalScore;

  _GradeEntry({this.daily, this.mid, this.finalScore});
}

enum _ScoreTab { daily, mid, finalScore }

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class GradeInputScreen extends ConsumerStatefulWidget {
  const GradeInputScreen({
    super.key,
    required this.taId,
    required this.subjectName,
    required this.className,
  });

  final int taId;
  final String subjectName;
  final String className;

  @override
  ConsumerState<GradeInputScreen> createState() => _GradeInputScreenState();
}

class _GradeInputScreenState extends ConsumerState<GradeInputScreen> {
  _ScoreTab _activeTab = _ScoreTab.daily;
  final Map<int, _GradeEntry> _entries = {};

  void _initFromRoster(GradeRoster roster) {
    for (final s in roster.students) {
      if (!_entries.containsKey(s.id)) {
        _entries[s.id] = _GradeEntry(
          daily: s.dailyTestAvg,
          mid: s.midTest,
          finalScore: s.finalTest,
        );
      }
    }
  }

  List<Map<String, dynamic>> _buildPayload() {
    return _entries.entries.map((e) {
      return <String, dynamic>{
        'student_id': e.key,
        if (e.value.daily != null) 'daily_test_avg': e.value.daily,
        if (e.value.mid != null) 'mid_test': e.value.mid,
        if (e.value.finalScore != null) 'final_test': e.value.finalScore,
      };
    }).toList();
  }

  Future<void> _submit() async {
    final success = await ref
        .read(gradeSubmitControllerProvider.notifier)
        .submit(taId: widget.taId, entries: _buildPayload());

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nilai berhasil disimpan'),
          backgroundColor: AppColors.success500,
        ),
      );
      Navigator.of(context).pop();
    } else {
      final submitState = ref.read(gradeSubmitControllerProvider);
      final errorMsg = submitState.hasError
          ? (submitState.error is Failure
              ? (submitState.error as Failure).message
              : 'Gagal menyimpan nilai')
          : 'Gagal menyimpan nilai';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.danger500,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rosterAsync = ref.watch(gradeRosterProvider(widget.taId));
    final submitState = ref.watch(gradeSubmitControllerProvider);
    final isSubmitting = submitState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate900,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.slate200,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subjectName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.slate900,
              ),
            ),
            Text(
              widget.className,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.slate500,
              ),
            ),
          ],
        ),
      ),
      body: rosterAsync.when(
        data: (roster) {
          _initFromRoster(roster);
          return Column(
            children: [
              // Tab chips
              _TabChips(
                active: _activeTab,
                onChanged: (tab) => setState(() => _activeTab = tab),
              ),

              // Student list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: roster.students.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final student = roster.students[i];
                    final entry = _entries[student.id] ?? _GradeEntry();
                    return StaggeredEntry(
                      index: i,
                      child: _StudentScoreRow(
                        index: i,
                        student: student,
                        activeTab: _activeTab,
                        entry: entry,
                        onChanged: (value) {
                          setState(() {
                            final e = _entries[student.id] ??= _GradeEntry();
                            switch (_activeTab) {
                              case _ScoreTab.daily:
                                e.daily = value;
                              case _ScoreTab.mid:
                                e.mid = value;
                              case _ScoreTab.finalScore:
                                e.finalScore = value;
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),

              // Sticky bottom bar
              _BottomBar(
                isSubmitting: isSubmitting,
                onSubmit: isSubmitting ? null : _submit,
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary600),
        ),
        error: (err, _) => ErrorState(
          message: err is Failure ? err.message : 'Gagal memuat data nilai',
          onRetry: () => ref.refresh(gradeRosterProvider(widget.taId)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab chips row
// ─────────────────────────────────────────────────────────────────────────────

class _TabChips extends StatelessWidget {
  const _TabChips({required this.active, required this.onChanged});

  final _ScoreTab active;
  final ValueChanged<_ScoreTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _Chip(
            label: 'Harian',
            selected: active == _ScoreTab.daily,
            onTap: () => onChanged(_ScoreTab.daily),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'UTS',
            selected: active == _ScoreTab.mid,
            onTap: () => onChanged(_ScoreTab.mid),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'UAS',
            selected: active == _ScoreTab.finalScore,
            onTap: () => onChanged(_ScoreTab.finalScore),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary600 : AppColors.slate100,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.slate600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Student score row
// ─────────────────────────────────────────────────────────────────────────────

class _StudentScoreRow extends StatefulWidget {
  const _StudentScoreRow({
    required this.index,
    required this.student,
    required this.activeTab,
    required this.entry,
    required this.onChanged,
  });

  final int index;
  final StudentGrade student;
  final _ScoreTab activeTab;
  final _GradeEntry entry;
  final ValueChanged<double?> onChanged;

  @override
  State<_StudentScoreRow> createState() => _StudentScoreRowState();
}

class _StudentScoreRowState extends State<_StudentScoreRow> {
  late final TextEditingController _dailyCtrl;
  late final TextEditingController _midCtrl;
  late final TextEditingController _finalCtrl;

  @override
  void initState() {
    super.initState();
    _dailyCtrl = TextEditingController(
      text: widget.entry.daily != null ? _fmt(widget.entry.daily!) : '',
    );
    _midCtrl = TextEditingController(
      text: widget.entry.mid != null ? _fmt(widget.entry.mid!) : '',
    );
    _finalCtrl = TextEditingController(
      text: widget.entry.finalScore != null
          ? _fmt(widget.entry.finalScore!)
          : '',
    );
  }

  @override
  void dispose() {
    _dailyCtrl.dispose();
    _midCtrl.dispose();
    _finalCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toString();

  TextEditingController get _activeCtrl {
    return switch (widget.activeTab) {
      _ScoreTab.daily => _dailyCtrl,
      _ScoreTab.mid => _midCtrl,
      _ScoreTab.finalScore => _finalCtrl,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FlozCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Index circle
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.slate100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${widget.index + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Name + NIS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.student.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.slate900,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.student.nis,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.slate500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Score input
          SizedBox(
            width: 72,
            child: TextFormField(
              controller: _activeCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                LengthLimitingTextInputFormatter(6),
              ],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.slate900,
              ),
              decoration: InputDecoration(
                hintText: '0-100',
                hintStyle: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.slate400),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                  borderSide: const BorderSide(color: AppColors.primary400),
                ),
              ),
              onChanged: (text) {
                final parsed = double.tryParse(text);
                widget.onChanged(parsed);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom bar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.isSubmitting, required this.onSubmit});

  final bool isSubmitting;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.slate200)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: FlozButton(
        text: 'Simpan Nilai',
        onPressed: onSubmit,
        isLoading: isSubmitting,
      ),
    );
  }
}
