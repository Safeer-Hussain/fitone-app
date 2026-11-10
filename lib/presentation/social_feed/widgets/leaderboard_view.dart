import 'package:flutter/material.dart';

import '../../../core/utils/app_feedback.dart';

class LeaderboardView extends StatefulWidget {
  const LeaderboardView({super.key});

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView> {
  String _selectedCategory = 'All Cohorts';
  final List<String> _categories = const [
    'All Cohorts',
    'Tonnage',
    'Distance',
    'Readiness',
  ];

  final List<Map<String, dynamic>> _allAthletes = const [
    {
      'id': 'a1',
      'name': 'Safeer Hussain',
      'handle': '@safeer_h',
      'volume': '18,450 kg',
      'distance': '42.8 km',
      'readiness': '94',
      'volumeKg': 18450,
      'distanceKm': 42.8,
      'readinessScore': 94,
      'isUser': true,
    },
    {
      'id': 'a2',
      'name': 'Zainab Tariq',
      'handle': '@zainab_runs',
      'volume': '14,200 kg',
      'distance': '58.4 km',
      'readiness': '91',
      'volumeKg': 14200,
      'distanceKm': 58.4,
      'readinessScore': 91,
      'isUser': false,
    },
    {
      'id': 'a3',
      'name': 'Liam O Connor',
      'handle': '@liam_athletics',
      'volume': '16,800 kg',
      'distance': '31.2 km',
      'readiness': '88',
      'volumeKg': 16800,
      'distanceKm': 31.2,
      'readinessScore': 88,
      'isUser': false,
    },
    {
      'id': 'a4',
      'name': 'Marcus Vance',
      'handle': '@mvance_fit',
      'volume': '12,900 kg',
      'distance': '28.0 km',
      'readiness': '85',
      'volumeKg': 12900,
      'distanceKm': 28.0,
      'readinessScore': 85,
      'isUser': false,
    },
    {
      'id': 'a5',
      'name': 'Elena Rostova',
      'handle': '@elena_lift',
      'volume': '15,100 kg',
      'distance': '22.5 km',
      'readiness': '96',
      'volumeKg': 15100,
      'distanceKm': 22.5,
      'readinessScore': 96,
      'isUser': false,
    },
  ];

  List<Map<String, dynamic>> _getFilteredAthletes() {
    final list = List<Map<String, dynamic>>.from(_allAthletes);
    if (_selectedCategory == 'Tonnage') {
      list.sort(
        (a, b) => (b['volumeKg'] as num).compareTo(a['volumeKg'] as num),
      );
    } else if (_selectedCategory == 'Distance') {
      list.sort(
        (a, b) => (b['distanceKm'] as num).compareTo(a['distanceKm'] as num),
      );
    } else if (_selectedCategory == 'Readiness') {
      list.sort(
        (a, b) =>
            (b['readinessScore'] as num).compareTo(a['readinessScore'] as num),
      );
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final athletes = _getFilteredAthletes();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.military_tech_outlined,
                color: colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Global Tonnage & Distance League',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Weekly cohort resetting in 2 days 14 hours',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = cat);
                      AppFeedback.showInfo(
                        context,
                        'Leaderboard filtered by $cat',
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        ...athletes.asMap().entries.map((entry) {
          final index = entry.key;
          final a = entry.value;
          final isUser = a['isUser'] as bool;
          final rank = index + 1;

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              AppFeedback.showInfo(
                context,
                '${a['name']} (${a['handle']}): ${a['volume']} tonnage, ${a['distance']} distance',
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? colorScheme.primary.withValues(alpha: 0.12)
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUser
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  width: isUser ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: rank == 1
                          ? const Color(0xFFEAB308)
                          : (rank == 2
                                ? const Color(0xFF94A3B8)
                                : (rank == 3
                                      ? const Color(0xFFB45309)
                                      : colorScheme.surfaceContainerHighest)),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: rank <= 3 ? Colors.black : colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                a['name'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (isUser) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'YOU',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          a['handle'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _selectedCategory == 'Distance'
                            ? (a['distance'] as String)
                            : (_selectedCategory == 'Readiness'
                                  ? 'Score: ${a['readiness']}'
                                  : (a['volume'] as String)),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        _selectedCategory == 'Distance'
                            ? (a['volume'] as String)
                            : (a['distance'] as String),
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
