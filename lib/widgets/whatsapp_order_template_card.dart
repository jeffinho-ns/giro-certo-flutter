import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/api_service.dart';
import '../utils/colors.dart';

/// Card para o lojista copiar o modelo de pedido WhatsApp.
class WhatsAppOrderTemplateCard extends StatefulWidget {
  const WhatsAppOrderTemplateCard({super.key});

  @override
  State<WhatsAppOrderTemplateCard> createState() =>
      _WhatsAppOrderTemplateCardState();
}

class _WhatsAppOrderTemplateCardState extends State<WhatsAppOrderTemplateCard> {
  bool _loading = true;
  String? _template;
  String? _webhookUrl;
  bool _cloudConfigured = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getWhatsAppOrderTemplate();
      if (!mounted) return;
      setState(() {
        _template = data['template'] as String?;
        _webhookUrl = data['webhookUrl'] as String?;
        _cloudConfigured = data['cloudConfigured'] == true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _copyTemplate() async {
    final t = _template;
    if (t == null || t.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: t));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Mensagem copiada. Cole no WhatsApp do cliente e peça para responder preenchido.',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.messageCircle, color: AppColors.racingOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pedidos pelo WhatsApp',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Envie o modelo ao cliente e peça para responder sem mudar os nomes dos campos. '
              'Quando ele preencher no formato, o sistema '
              'capta o pedido e manda o link de pagamento automaticamente '
              '(requer WhatsApp Business API configurado).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
              ),
            ),
            if (_loading) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(minHeight: 2),
            ] else if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ] else ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    _cloudConfigured ? Icons.check_circle : Icons.warning_amber,
                    size: 18,
                    color: _cloudConfigured ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _cloudConfigured
                          ? 'API WhatsApp configurada no servidor'
                          : 'Servidor ainda sem token WhatsApp — só cópia manual',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              if (_webhookUrl != null && _webhookUrl!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Webhook: $_webhookUrl',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _template ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _template == null ? null : () => _copyTemplate(),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copiar mensagem para o cliente'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.racingOrangeDark,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
