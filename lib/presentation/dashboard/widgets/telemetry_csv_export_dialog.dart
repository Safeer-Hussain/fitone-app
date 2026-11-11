import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/telemetry_csv_exporter.dart';
import '../../../domain/entities/ring_telemetry.dart';
import '../stores/dashboard_store.dart';

/// Modal sheet for exporting smart-ring biometric telemetry to RFC-4180 CSV
class TelemetryCsvExportDialog extends StatefulWidget {
  final DashboardStore store;

  const TelemetryCsvExportDialog({super.key, required this.store});

  static void show(BuildContext context, DashboardStore store) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TelemetryCsvExportDialog(store: store),
    );
  }

  @override
  State<TelemetryCsvExportDialog> createState() =>
      _TelemetryCsvExportDialogState();
}

class _TelemetryCsvExportDialogState extends State<TelemetryCsvExportDialog> {
  bool _useFullHistory = true;
  bool _includeEcgSamples = true;

  @override
  void initState() {
    super.initState();
    // Ensure historical data is populated
    if (widget.store.historicalPackets.isEmpty) {
      widget.store.loadHistoricalTelemetry();
    }
  }

  List<RingTelemetry> _resolveSelectedPackets() {
    final store = widget.store;
    final packets = _useFullHistory
        ? store.historicalPackets
        : store.recentPackets;

    if (packets.isNotEmpty) {
      return packets;
    }

    if (store.activeTelemetry != null) {
      return [store.activeTelemetry!];
    }

    return const [];
  }

  void _copyToClipboard(
    BuildContext context,
    List<RingTelemetry> packets,
    String csvText,
  ) {
    Clipboard.setData(ClipboardData(text: csvText));
    AppFeedback.showSuccess(
      context,
      'Biometric CSV copied to clipboard (${packets.length} packets)',
    );
  }

  Future<void> _exportToFile(
    BuildContext context,
    List<RingTelemetry> packets,
  ) async {
    try {
      final file = await widget.store.exportTelemetryCsv(
        includeEcg: _includeEcgSamples,
        fullHistory: _useFullHistory,
      );
      if (context.mounted) {
        final fileName = file.path.split(RegExp(r'[\\/]')).last;
        AppFeedback.showSuccess(
          context,
          'Telemetry exported to $fileName (${packets.length} records)',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showError(context, 'Failed to export CSV: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Observer(
      builder: (_) {
        final packets = _resolveSelectedPackets();
        final metadata = TelemetryCsvExporter.getExportMetadataSummary(packets);
        final csvPreview = TelemetryCsvExporter.generateCsv(
          packets.take(4).toList(),
          includeEcgSamples: _includeEcgSamples,
        );

        final totalPackets = metadata['totalPackets'] as int;
        final timeSpan = metadata['timeSpanFormatted'] as String;
        final avgHr = metadata['avgHeartRate'] as int;
        final minHr = metadata['minHeartRate'] as int;
        final maxHr = metadata['maxHeartRate'] as int;
        final avgSpo2 = metadata['avgSpo2'] as double;
        final avgHrv = metadata['avgHrv'] as int;
        final dominantStage = metadata['dominantSleepStage'] as String;
        final fileName = metadata['fileName'] as String;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.90,
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.table_chart_rounded,
                              color: colorScheme.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Export Biometric Telemetry',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Sports Science RFC-4180 Dataset',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: colorScheme.outlineVariant, height: 1),
                  const SizedBox(height: 12),

                  Flexible(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Scope Selection ChoiceChips
                          Text(
                            'DATASET SCOPE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              ChoiceChip(
                                label: Text(
                                  '24-Hour Timeline (${widget.store.historicalPackets.length} packets)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _useFullHistory
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                                selected: _useFullHistory,
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() => _useFullHistory = true);
                                  }
                                },
                              ),
                              ChoiceChip(
                                label: Text(
                                  'Live Session Buffer (${widget.store.recentPackets.length} packets)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: !_useFullHistory
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                                selected: !_useFullHistory,
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() => _useFullHistory = false);
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Summary Statistics Grid
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'DATASET METRICS',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      fileName,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMetricTile(
                                        label: 'Total Packets',
                                        value: '$totalPackets',
                                        colorScheme: colorScheme,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildMetricTile(
                                        label: 'Timeline Span',
                                        value: timeSpan,
                                        colorScheme: colorScheme,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMetricTile(
                                        label: 'Heart Rate (Mean / Min-Max)',
                                        value: '$avgHr BPM ($minHr-$maxHr)',
                                        colorScheme: colorScheme,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildMetricTile(
                                        label: 'SpO2 / HRV Mean',
                                        value: '$avgSpo2% • ${avgHrv}ms',
                                        colorScheme: colorScheme,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMetricTile(
                                        label: 'Dominant Stage',
                                        value: dominantStage,
                                        colorScheme: colorScheme,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildMetricTile(
                                        label: 'Format Specification',
                                        value: 'RFC-4180 Standard',
                                        colorScheme: colorScheme,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Toggle for raw ECG samples
                          Material(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            clipBehavior: Clip.antiAlias,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                ),
                              ),
                              child: SwitchListTile(
                                title: Text(
                                  'Include Raw PPG/ECG Waveform Samples',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                subtitle: Text(
                                  'Appends semicolon-delimited voltage mV arrays per packet',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                value: _includeEcgSamples,
                                activeColor: colorScheme.primary,
                                onChanged: (val) {
                                  setState(() => _includeEcgSamples = val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // CSV Live Preview
                          Text(
                            'CSV FORMAT PREVIEW',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SelectableText(
                                csvPreview,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const ValueKey('copy_csv_clipboard_button'),
                          onPressed: () {
                            final fullCsv = TelemetryCsvExporter.generateCsv(
                              packets,
                              includeEcgSamples: _includeEcgSamples,
                            );
                            _copyToClipboard(context, packets, fullCsv);
                          },
                          icon: const Icon(
                            Icons.content_copy_rounded,
                            size: 16,
                          ),
                          label: const Text('Copy CSV'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          key: const ValueKey('save_csv_file_button'),
                          onPressed: () => _exportToFile(context, packets),
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label: const Text('Export File'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
