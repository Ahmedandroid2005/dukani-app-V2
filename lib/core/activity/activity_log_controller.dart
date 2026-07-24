import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_models.dart';
import '../organizations/org_controller.dart';
import '../offline/firestore_synced_list_notifier.dart';
import '../offline/local_db.dart';
import '../session/session_controller.dart';
import 'audit_context.dart';
import 'reason_prompt.dart';

/// Append-only activity feed. Starts empty — any module can call [log] to
/// record a real action here; this phase doesn't retrofit every existing
/// screen to call it, but the seam is ready for that.
class ActivityLogController extends FirestoreSyncedListNotifier<MockActivityEntry> {
  ActivityLogController(String? orgId)
      : super(
          box: LocalDb.activityLog,
          seed: const [],
          toJson: (e) => e.toJson(),
          fromJson: MockActivityEntry.fromJson,
          orgId: orgId,
          collectionName: 'activityLog',
        );

  void log(
    String action, {
    required String employeeName,
    required String category,
    bool sensitive = false,
    Uint8List? employeePhoto,
    String branch = '—',
    String device = '—',
    String ipStatus = '—',
    String reason = '',
    String? beforeSnapshot,
    String? afterSnapshot,
  }) {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    state = [
      MockActivityEntry(
        id: now.microsecondsSinceEpoch.toString(),
        action: action,
        employeeName: employeeName,
        category: category,
        time: '${two(now.hour)}:${two(now.minute)}',
        date: '${now.year}-${two(now.month)}-${two(now.day)}',
        timestamp: now,
        sensitive: sensitive,
        employeePhoto: employeePhoto,
        branch: branch,
        device: device,
        ipStatus: ipStatus,
        reason: reason,
        beforeSnapshot: beforeSnapshot,
        afterSnapshot: afterSnapshot,
      ),
      ...state,
    ];
  }
}

final activityLogProvider = StateNotifierProvider<ActivityLogController, List<MockActivityEntry>>(
  (ref) => ActivityLogController(ref.watch(currentOrgIdProvider).valueOrNull),
);

/// Gate for every sensitive delete/edit: prompts for a mandatory reason
/// first, and only if one is given does it record the full audit entry
/// (employee, photo, branch, device, connectivity status, reason, and an
/// optional before/after snapshot for edits) — then returns true so the
/// caller knows it's safe to actually perform the action. Returns false if
/// the employee backs out of the reason prompt, in which case the caller
/// must not proceed.
Future<bool> logSensitiveAction(
  BuildContext context,
  WidgetRef ref, {
  required String action,
  required String category,
  String? beforeSnapshot,
  String? afterSnapshot,
}) async {
  final reason = await promptForReason(context, title: 'سبب العملية');
  if (reason == null) return false;
  if (!context.mounted) return false;

  final employee = ref.read(sessionProvider);
  final ipStatus = await currentIpStatus();

  ref.read(activityLogProvider.notifier).log(
        action,
        employeeName: employee?.name ?? 'غير معروف',
        employeePhoto: employee?.photoBytes,
        branch: employee?.branch ?? '—',
        category: category,
        sensitive: true,
        device: currentDeviceLabel(),
        ipStatus: ipStatus,
        reason: reason,
        beforeSnapshot: beforeSnapshot,
        afterSnapshot: afterSnapshot,
      );
  return true;
}
