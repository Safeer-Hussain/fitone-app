import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/gpx_exporter.dart';
import '../../../domain/entities/run_record.dart';

class GpxExportDialog extends StatelessWidget {
  final RunRecord record;

  const GpxExportDialog({super.key, required this.record});

  static void show(BuildContext context, RunRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GpxExportDialog(record: record),
    );
  }

  void _copyGpxXml(BuildContext context, String gpxXml) {
    Clipboard.setData(ClipboardData(text: gpxXml));
    AppFeedback.showSuccess(context, 'GPX 1.1 XML copied to clipboard');
  }

  Future<void> _saveGpxFile(BuildContext context) async {
    try {
      final file = await GpxExporter.writeGpxToFile(record);
      if (context.mounted) {
        AppFeedback.showSuccess(
          context,
          'GPX exported to ${file.path.split(RegExp(r'[\\/]')).last}',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showError(context, 'Failed to save GPX file: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gpxXml = GpxExporter.generateGpx(record);
    final summary = GpxExporter.getGpxMetadataSummary(record);
    final fileName = summary['fileName'] as String;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
          ),
          padding: const EdgeInsets.all(20),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.share_location_rounded,
                          color: colorScheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Export GPX 1.1 Route',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                fileName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                  fontFamily: 'monospace',
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
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Metadata grid
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceAround,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _MetaBadge(
                      label: 'Points',
                      value: '${summary['trackpoints']}',
                      colorScheme: colorScheme,
                    ),
                    _MetaBadge(
                      label: 'Distance',
                      value: '${summary['distanceKm']} km',
                      colorScheme: colorScheme,
                    ),
                    _MetaBadge(
                      label: 'Duration',
                      value: '${summary['duration']}',
                      colorScheme: colorScheme,
                    ),
                    _MetaBadge(
                      label: 'Size',
                      value: '${summary['fileSizeKb']} KB',
                      colorScheme: colorScheme,
                    ),
                    _MetaBadge(
                      label: 'Schema',
                      value: 'GPX 1.1 + HR',
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'GPX 1.1 XML PREVIEW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),

              // Monospace XML preview container
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: SelectableText(
                      gpxXml,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10.5,
                        color: colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('copy_gpx_button'),
                      onPressed: () => _copyGpxXml(context, gpxXml),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copy GPX XML'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: colorScheme.outlineVariant),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      key: const ValueKey('save_gpx_button'),
                      onPressed: () => _saveGpxFile(context),
                      icon: const Icon(Icons.file_download_outlined, size: 18),
                      label: const Text('Save GPX File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
  }
}

class _MetaBadge extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme colorScheme;

  const _MetaBadge({
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
