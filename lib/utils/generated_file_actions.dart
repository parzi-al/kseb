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
      builder: (dialogContext) => _GeneratedFileDialog(
        title: title,
        fileName: fileName,
        onCancel: () => Navigator.of(dialogContext).pop(),
        onOpen: () =>
            Navigator.of(dialogContext).pop(_GeneratedFileAction.open),
        onShare: () =>
            Navigator.of(dialogContext).pop(_GeneratedFileAction.share),
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

class _GeneratedFileDialog extends StatelessWidget {
  const _GeneratedFileDialog({
    required this.title,
    required this.fileName,
    required this.onCancel,
    required this.onOpen,
    required this.onShare,
  });

  final String title;
  final String fileName;
  final VoidCallback onCancel;
  final VoidCallback onOpen;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 380;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.base : AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: EdgeInsets.all(compact ? AppSpacing.base : AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: compact ? 36 : 42,
                    height: compact ? 36 : 42,
                    decoration: BoxDecoration(
                      color: AppColors.primaryWithLowOpacity,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.insert_drive_file_rounded,
                      color: AppColors.primary,
                      size: compact ? 20 : 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.subheadingStyle.copyWith(
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.base),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: Text(
                  fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionStyle.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Open'),
                  ),
                  ElevatedButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.ios_share_rounded, size: 18),
                    label: const Text('Share'),
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
