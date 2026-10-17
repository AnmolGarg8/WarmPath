import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/app_exception.dart';
import '../../../core/theme/tokens.dart';
import '../safety_providers.dart';

Future<bool?> showBlockDialog(
  BuildContext context, {
  required String targetUserId,
  String? targetName,
  VoidCallback? onBlocked,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => Consumer(
      builder: (context, ref, _) {
        return _BlockDialogContent(
          targetUserId: targetUserId,
          targetName: targetName,
          onBlocked: onBlocked,
        );
      },
    ),
  );
}

class _BlockDialogContent extends ConsumerStatefulWidget {
  final String targetUserId;
  final String? targetName;
  final VoidCallback? onBlocked;

  const _BlockDialogContent({
    required this.targetUserId,
    this.targetName,
    this.onBlocked,
  });

  @override
  ConsumerState<_BlockDialogContent> createState() => _BlockDialogContentState();
}

class _BlockDialogContentState extends ConsumerState<_BlockDialogContent> {
  bool _isLoading = false;

  Future<void> _confirmBlock() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(safetyRepositoryProvider);
      await repo.blockUser(blockedUserId: widget.targetUserId);

      if (mounted) {
        Navigator.of(context).pop(true);
        widget.onBlocked?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.targetName ?? "User"} has been blocked.'),
          ),
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to block: ${e.message}')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to block user. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.targetName ?? 'this user';

    return AlertDialog(
      title: Text('Block $name?'),
      content: Text(
        'Blocking is bidirectional. You will never be matched with $name, '
        'and neither of you will be able to send requests or messages to each other.',
        style: const TextStyle(fontSize: 14, color: AppColors.slate, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel', style: TextStyle(color: AppColors.slate)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: _isLoading ? null : _confirmBlock,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Block User'),
        ),
      ],
    );
  }
}
