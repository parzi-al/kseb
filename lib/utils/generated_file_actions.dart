import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_toast.dart';
import 'app_typography.dart';
import 'generated_file_opener_stub.dart'
    if (dart.library.io) 'generated_file_opener_io.dart';

class GeneratedFileActions {
  const GeneratedFileActions._();

  static Future<bool> saveOrShowActions({
    required BuildContext context,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required XTypeGroup typeGroup,
    required String title,
  }) async {
    if (_shouldShowMobileActions) {
      final path = await writeGeneratedFileForOpen(
        bytes: bytes,
        fileName: fileName,
      );
      if (!context.mounted) return false;
      return _showGeneratedFileDialog(
        context: context,
        path: path,
        fileName: fileName,
        mimeType: mimeType,
        title: title,
      );
    }

    final saveLocation = await getSaveLocation(
      suggestedName: fileName,
      acceptedTypeGroups: [typeGroup],
    );
    if (saveLocation == null) {
      if (context.mounted) {
        AppToast.showError(context, 'Export cancelled.');
      }
      return false;
    }

    await XFile.fromData(
      bytes,
      name: fileName,
      mimeType: mimeType,
    ).saveTo(saveLocation.path);
    return true;
  }

  static bool get _shouldShowMobileActions {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  static Future<bool> _showGeneratedFileDialog({
    required BuildContext context,
    required String path,
    required String fileName,
    required String mimeType,
    required String title,
  }) async {
    final action = await showDialog<_GeneratedFileAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryWithLowOpacity,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.insert_drive_file_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: AppTypography.subheadingStyle,
              ),
            ),
          ],
        ),
        content: Text(
          fileName,
          style: AppTypography.bodyStyle.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_GeneratedFileAction.open),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Open'),
          ),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_GeneratedFileAction.share),
            icon: const Icon(Icons.ios_share_rounded),
            label: const Text('Share'),
          ),
        ],
      ),
    );

    if (action == null) return false;

    if (action == _GeneratedFileAction.open) {
      final opened = await openGeneratedFile(path: path, mimeType: mimeType);
      if (!opened && context.mounted) {
        AppToast.showError(context, 'No app found to open this file.');
      }
      return opened;
    }

    if (!context.mounted) return false;
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        title: title,
        files: [XFile(path, mimeType: mimeType, name: fileName)],
        sharePositionOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
    return true;
  }
}

enum _GeneratedFileAction { open, share }
