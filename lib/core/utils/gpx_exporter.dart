import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/run_record.dart';

class GpxExporter {
  static Directory? overrideExportDirectory;

  static String escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static String generateGpx(RunRecord record, {bool includeHeartRate = true}) {
    final buffer = StringBuffer();
    final startTimeIso = record.startTime.toUtc().toIso8601String();
    final escapedTitle = escapeXml(record.title);

    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
      '<gpx version="1.1" creator="Fitone Mobile Wearable Ecosystem" '
      'xmlns="http://www.topografix.com/GPX/1/1" '
      'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
      'xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1" '
      'xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd '
      'http://www.garmin.com/xmlschemas/TrackPointExtension/v1 http://www.garmin.com/xmlschemas/TrackPointExtensionv1.xsd">',
    );

    // Metadata
    buffer.writeln('  <metadata>');
    buffer.writeln('    <name>$escapedTitle</name>');
    buffer.writeln(
      '    <desc>Fitone GPS Outdoor Run: ${record.distanceKm.toStringAsFixed(2)} km, '
      '${record.durationFormatted}, ${record.paceFormatted} avg pace, '
      '${record.avgHeartRate} BPM avg HR, +${record.elevationGainM.toStringAsFixed(1)}m elevation</desc>',
    );
    buffer.writeln('    <time>$startTimeIso</time>');
    buffer.writeln('  </metadata>');

    // Track
    buffer.writeln('  <trk>');
    buffer.writeln('    <name>$escapedTitle</name>');
    buffer.writeln('    <type>running</type>');
    buffer.writeln('    <trkseg>');

    final coords = record.coordinates;
    final totalCoords = coords.length;

    for (var i = 0; i < totalCoords; i++) {
      final coord = coords[i];
      final latStr = coord.lat.toStringAsFixed(6);
      final lonStr = coord.lng.toStringAsFixed(6);

      // Elevation calculation: coordinate elevation or interpolated
      final ele =
          coord.elevation ??
          (215.0 +
              (totalCoords > 1
                  ? (i / (totalCoords - 1)) * record.elevationGainM
                  : 0.0));

      // Timestamp calculation: coordinate timestamp or distributed across duration
      final timeUtc =
          coord.timestamp?.toUtc() ??
          record.startTime
              .add(
                Duration(
                  seconds: totalCoords > 1
                      ? ((i / (totalCoords - 1)) * record.durationSeconds)
                            .round()
                      : 0,
                ),
              )
              .toUtc();
      final timeStr = timeUtc.toIso8601String();

      // Heart rate telemetry
      final hr = coord.heartRate ?? record.avgHeartRate;

      buffer.writeln('      <trkpt lat="$latStr" lon="$lonStr">');
      buffer.writeln('        <ele>${ele.toStringAsFixed(1)}</ele>');
      buffer.writeln('        <time>$timeStr</time>');

      if (includeHeartRate && hr > 0) {
        buffer.writeln('        <extensions>');
        buffer.writeln('          <gpxtpx:TrackPointExtension>');
        buffer.writeln('            <gpxtpx:hr>$hr</gpxtpx:hr>');
        buffer.writeln('          </gpxtpx:TrackPointExtension>');
        buffer.writeln('        </extensions>');
      }

      buffer.writeln('      </trkpt>');
    }

    buffer.writeln('    </trkseg>');
    buffer.writeln('  </trk>');
    buffer.writeln('</gpx>');

    return buffer.toString();
  }

  static String getCleanFileName(RunRecord record) {
    final dateFormat = DateFormat('yyyyMMdd_HHmmss');
    final dateStr = dateFormat.format(record.startTime.toLocal());
    final cleanTitle = record.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return 'fitone_${cleanTitle.isNotEmpty ? cleanTitle : 'run'}_$dateStr.gpx';
  }

  static Future<File> writeGpxToFile(
    RunRecord record, {
    Directory? directory,
  }) async {
    Directory targetDir;
    if (directory != null) {
      targetDir = directory;
    } else if (overrideExportDirectory != null) {
      targetDir = overrideExportDirectory!;
    } else {
      try {
        targetDir = await getApplicationDocumentsDirectory().timeout(
          const Duration(milliseconds: 300),
        );
      } catch (_) {
        targetDir = Directory.systemTemp;
      }
    }

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final filename = getCleanFileName(record);
    final filePath = p.join(targetDir.path, filename);
    final gpxXml = generateGpx(record);

    final file = File(filePath);
    await file.writeAsString(gpxXml);
    return file;
  }

  static Map<String, dynamic> getGpxMetadataSummary(RunRecord record) {
    final gpxXml = generateGpx(record);
    final sizeBytes = gpxXml.length;
    return {
      'fileName': getCleanFileName(record),
      'trackpoints': record.coordinates.length,
      'duration': record.durationFormatted,
      'distanceKm': record.distanceKm,
      'elevationGainM': record.elevationGainM,
      'fileSizeBytes': sizeBytes,
      'fileSizeKb': (sizeBytes / 1024).toStringAsFixed(1),
    };
  }
}
