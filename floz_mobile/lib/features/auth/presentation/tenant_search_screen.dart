import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/floz_button.dart';
import '../../../shared/widgets/floz_input.dart';
import '../../../shared/widgets/floz_card.dart';

class TenantSearchScreen extends ConsumerStatefulWidget {
  const TenantSearchScreen({super.key});

  @override
  ConsumerState<TenantSearchScreen> createState() => _TenantSearchScreenState();
}

class _TenantSearchScreenState extends ConsumerState<TenantSearchScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _error = null;
      _results = [];
    });

    try {
      final results = await ref
          .read(authRepositoryProvider)
          .searchTenants(query);
      setState(() {
        _results = results;
        if (results.isEmpty) {
          _error = 'No schools found matching "$query"';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to search schools. Please try again.';
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _selectTenant(Map<String, dynamic> tenant) async {
    await ref.read(authProvider.notifier).selectTenant(tenant);
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.space24),
              // Header
              Center(
                child: Column(
                  children: [
                    Container(
                      height: 64,
                      width: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.school,
                        size: 32,
                        color: AppColors.primary600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space16),
                    Text(
                      'Find Your School',
                      style: AppTypography.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    Text(
                      'Enter your school name to proceed',
                      style: AppTypography.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space32),

              // Search Input
              FlozInput(
                label: 'School Name',
                hint: 'e.g. SMA Negeri 1',
                controller: _searchController,
                prefixIcon: Icons.search,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _search,
                ),
              ),
              const SizedBox(height: AppSpacing.space16),
              FlozButton(
                text: 'Search',
                onPressed: _search,
                isLoading: _isSearching,
              ),

              const SizedBox(height: AppSpacing.space24),

              // Results
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger50,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                  ),
                  child: Text(
                    _error!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.danger700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              Expanded(
                child: ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.space12),
                  itemBuilder: (context, index) {
                    final tenant = _results[index];
                    return FlozCard(
                      onTap: () => _selectTenant(tenant),
                      child: Row(
                        children: [
                          Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: AppColors.slate100,
                              shape: BoxShape.circle,
                            ),
                            child: tenant['logo_url'] != null
                                ? ClipOval(
                                    child: Image.network(tenant['logo_url']),
                                  )
                                : const Icon(
                                    Icons.school,
                                    color: AppColors.slate500,
                                  ),
                          ),
                          const SizedBox(width: AppSpacing.space16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tenant['name'] ?? 'Unknown School',
                                  style: AppTypography.titleMedium,
                                ),
                                Text(
                                  tenant['domain'] ?? '',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.slate400,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
