import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/social_service.dart';
import '../../utils/colors.dart';

class ReportPostSheet extends StatefulWidget {
  final String postId;

  const ReportPostSheet({super.key, required this.postId});

  @override
  State<ReportPostSheet> createState() => _ReportPostSheetState();
}

class _ReportPostSheetState extends State<ReportPostSheet> {
  String? _selectedReason;
  bool _sending = false;

  static const List<Map<String, String>> reasons = [
    {'id': 'spam', 'label': 'Spam'},
    {'id': 'inappropriate', 'label': 'Conteúdo inapropriado'},
    {'id': 'harassment', 'label': 'Assédio'},
    {'id': 'other', 'label': 'Outro'},
  ];

  Future<void> _submit() async {
    if (_selectedReason == null) return;
    setState(() => _sending = true);
    await SocialService.reportPost(widget.postId, _selectedReason!);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Reportar publicação',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.dividerColor.withOpacity(0.3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...reasons.map((r) => RadioListTile<String>(
                  title: Text(
                    r['label']!,
                    style: theme.textTheme.bodyLarge,
                  ),
                  value: r['id']!,
                  groupValue: _selectedReason,
                  activeColor: AppColors.racingOrange,
                  onChanged: (v) => setState(() => _selectedReason = v),
                )),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _sending ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.racingOrange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _sending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Enviar reporte'),
            ),
          ],
        ),
      ),
    );
  }
}
