import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/utils/app_feedback.dart';
import '../stores/dashboard_store.dart';
import 'telemetry_csv_export_dialog.dart';

class DeviceManagerSheet extends StatelessWidget {
  final DashboardStore store;

  const DeviceManagerSheet({super.key, required this.store});

  static void show(BuildContext context, DashboardStore store) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DeviceManagerSheet(store: store),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Wearable Ecosystem Hub',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Dual Native BLE Bridges (Kotlin / Swift)',
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
                      IconButton(
                        onPressed: () => store.scanDevices(),
                        icon: Icon(
                          Icons.refresh_rounded,
                          color: colorScheme.primary,
                        ),
                        tooltip: 'Rescan BLE Devices',
                      ),
                    ],
                  ),
                ),
                Divider(color: colorScheme.outlineVariant),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DISCOVERED SMART RINGS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Observer(
                          builder: (_) {
                            final devices = store.scannedDevices;
                            if (devices.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    'Scanning for BLE advertisement packets...',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return Column(
                              children: devices.map((device) {
                                final isAura = device.sdk == 'SDK_A';
                                final imagePath = isAura
                                    ? AppAssets.ringAura
                                    : AppAssets.ringKinetix;
                                final isConnected =
                                    store.connectedDevice?.id == device.id;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isConnected
                                          ? colorScheme.primary
                                          : colorScheme.outlineVariant,
                                      width: isConnected ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.asset(
                                          imagePath,
                                          width: 58,
                                          height: 58,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                                width: 58,
                                                height: 58,
                                                color: colorScheme
                                                    .surfaceContainer,
                                                child: Icon(
                                                  Icons.ring_volume,
                                                  color: colorScheme.primary,
                                                ),
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    device.name,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 14,
                                                      color:
                                                          colorScheme.onSurface,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (isConnected) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: colorScheme.primary
                                                          .withValues(
                                                            alpha: 0.18,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'ACTIVE',
                                                      style: TextStyle(
                                                        color:
                                                            colorScheme.primary,
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Protocol: ${device.sdk} • FW: ${device.firmware}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Battery: ${device.battery}% • RSSI: ${device.rssi} dBm',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: colorScheme
                                                    .onSurfaceVariant
                                                    .withValues(alpha: 0.7),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: isConnected
                                            ? () {
                                                store.disconnectDevice();
                                                AppFeedback.showWarning(
                                                  context,
                                                  'Smart-Ring disconnected. Switched to offline telemetry.',
                                                );
                                              }
                                            : () {
                                                store.connectDevice(
                                                  device.id,
                                                  device.sdk,
                                                );
                                                AppFeedback.showSuccess(
                                                  context,
                                                  '${device.name} paired successfully.',
                                                );
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isConnected
                                              ? colorScheme.surfaceContainer
                                              : colorScheme.primary,
                                          foregroundColor: isConnected
                                              ? colorScheme.onSurface
                                              : colorScheme.onPrimary,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          isConnected
                                              ? 'Disconnect'
                                              : 'Connect',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'HARDWARE DIAGNOSTICS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: colorScheme.primary,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => store.runDiagnostics(),
                              icon: const Icon(
                                Icons.play_arrow_rounded,
                                size: 16,
                              ),
                              label: const Text(
                                'Run Diagnostics',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Observer(
                          builder: (_) {
                            final diag = store.diagnostics;
                            if (diag == null) {
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Text(
                                  'Tap Run Diagnostics to interrogate optical PPG, IMU, and BLE transceivers.',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                ),
                              ),
                              child: Column(
                                children: [
                                  _DiagRow(
                                    sensor: 'Optical PPG Array',
                                    result: diag.opticalPPG,
                                  ),
                                  Divider(
                                    color: colorScheme.outlineVariant,
                                    height: 16,
                                  ),
                                  _DiagRow(
                                    sensor: 'Temperature Sensor',
                                    result: diag.temperatureSensor,
                                  ),
                                  Divider(
                                    color: colorScheme.outlineVariant,
                                    height: 16,
                                  ),
                                  _DiagRow(
                                    sensor: '6-Axis IMU Sensor',
                                    result: diag.sixAxisIMU,
                                  ),
                                  Divider(
                                    color: colorScheme.outlineVariant,
                                    height: 16,
                                  ),
                                  _DiagRow(
                                    sensor: 'BLE 5.3 Transceiver',
                                    result: diag.bleTransceiver,
                                  ),
                                  Divider(
                                    color: colorScheme.outlineVariant,
                                    height: 16,
                                  ),
                                  _DiagRow(
                                    sensor: 'Battery Retained Cap.',
                                    result: diag.batteryHealth,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'EVENTCHANNEL NATIVE PACKET LOG',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Observer(
                          builder: (_) {
                            final packets = store.recentPackets;
                            if (packets.isEmpty) {
                              return Text(
                                'Listening to native EventChannel stream...',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              );
                            }
                            return Column(
                              children: packets.take(5).map((p) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainer,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '#${p.packetId} • HR: ${p.heartRate} BPM • SpO2: ${p.spo2}%',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                            color: colorScheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'CRC: ${p.checksum}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'SPORTS SCIENCE DATA EXPORT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.table_chart_rounded,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Export RFC-4180 Biometric Dataset',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Export multi-hour smart-ring telemetry (Heart Rate, SpO2, HRV, Skin Temp, Sleep Stages, and ECG samples) into CSV for researcher and sports science analysis.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  key: const ValueKey(
                                    'device_sheet_export_csv_button',
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    TelemetryCsvExportDialog.show(
                                      context,
                                      store,
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.download_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Configure & Export CSV'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiagRow extends StatelessWidget {
  final String sensor;
  final String result;

  const _DiagRow({required this.sensor, required this.result});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            sensor,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          result,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
