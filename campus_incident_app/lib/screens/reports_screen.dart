import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/incident.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/incident_style.dart';
import '../widgets/report_card.dart';
import 'incident_details_screen.dart';

/// Students see their own reports. Staff see all of them
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showCategorySheet() async {
    final provider = context.read<IncidentProvider>();

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter by category',
                style: Theme.of(sheetContext).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All categories'),
                    selected: provider.categoryFilter == null,
                    onSelected: (_) {
                      provider.setCategoryFilter(null);
                      Navigator.pop(sheetContext);
                    },
                  ),
                  for (final category in IncidentCategory.values)
                    ChoiceChip(
                      avatar: Icon(categoryIcon(category), size: 18),
                      label: Text(category.label),
                      selected: provider.categoryFilter == category,
                      onSelected: (_) {
                        provider.setCategoryFilter(category);
                        Navigator.pop(sheetContext);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = context.select<AuthProvider, bool>((auth) => auth.isStaff);
    final incidents = context.watch<IncidentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(isStaff ? 'All Reports' : 'My Reports'),
        actions: [
          IconButton(
            tooltip: 'Filter by category',
            icon: Icon(
              incidents.categoryFilter == null
                  ? Icons.filter_list
                  : Icons.filter_alt,
            ),
            onPressed: _showCategorySheet,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(incidents),
          _buildStatusChips(incidents),
          if (incidents.categoryFilter != null)
            _buildCategoryChip(incidents, incidents.categoryFilter!),
          Expanded(child: _buildList(incidents, isStaff)),
        ],
      ),
    );
  }

  Widget _buildSearchField(IncidentProvider incidents) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by title, place or category',
          prefixIcon: const Icon(Icons.search),
          // Show the clear button only when there is something to clear.
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    incidents.setSearchQuery('');
                  },
                ),
        ),
        onChanged: incidents.setSearchQuery,
      ),
    );
  }

  /// All, Submitted, In Progress, Resolved in a row that scrolls sideways
  Widget _buildStatusChips(IncidentProvider incidents) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _statusChip(incidents, 'All', null),
          for (final status in IncidentStatus.values)
            _statusChip(incidents, status.label, status),
        ],
      ),
    );
  }

  Widget _statusChip(
    IncidentProvider incidents,
    String label,
    IncidentStatus? status,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: incidents.statusFilter == status,
        onSelected: (_) => incidents.setStatusFilter(status),
      ),
    );
  }

  /// Shown only while a category filter is on. The x removes it.
  Widget _buildCategoryChip(
    IncidentProvider incidents,
    IncidentCategory category,
  ) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: InputChip(
          avatar: Icon(categoryIcon(category), size: 18),
          label: Text('Category: ${category.label}'),
          onDeleted: () => incidents.setCategoryFilter(null),
        ),
      ),
    );
  }

  Widget _buildList(IncidentProvider incidents, bool isStaff) {
    if (incidents.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (incidents.errorMessage != null) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        message: incidents.errorMessage!,
      );
    }

    final reports = incidents.filteredIncidents;

    if (reports.isEmpty) {
      // Two different empty states: nothing exists, or nothing matches
      final noReportsAtAll = incidents.incidents.isEmpty;
      return EmptyState(
        icon: noReportsAtAll ? Icons.inbox_outlined : Icons.search_off,
        message: noReportsAtAll
            ? (isStaff
                  ? 'No reports have been submitted yet.'
                  : 'You have not sent any reports yet.')
            : 'No reports match your search or filters.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final incident = reports[index];
        return ReportCard(
          incident: incident,
          showReporter: isStaff,
          onTap: () => IncidentDetailsScreen.open(context, incident.id),
        );
      },
    );
  }
}
