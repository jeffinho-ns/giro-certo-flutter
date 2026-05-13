import 'package:flutter/material.dart';

/// Coleta o codigo de retirada sem revelar o valor esperado ao entregador.
Future<String?> showTripPickupCodeDialog(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Confirmar retirada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Solicite o codigo de retirada ao lojista e digite abaixo para iniciar a entrega.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Codigo de retirada',
                hintText: 'Informe o codigo da loja',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(
              controller.text.trim().toUpperCase(),
            ),
            child: const Text('Confirmar'),
          ),
        ],
      );
    },
  );
}
