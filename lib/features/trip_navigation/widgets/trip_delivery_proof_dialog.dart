import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/delivery_proof_pin.dart';

/// Solicita o PIN de prova de entrega (ultimos 4 digitos do telefone do cliente).
Future<String?> showTripDeliveryProofDialog(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Confirmar entrega'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Solicite ao cliente os 4 ultimos digitos do telefone cadastrado no pedido.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: DeliveryProofPin.length,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'PIN do cliente',
                hintText: '0000',
                counterText: '',
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
            onPressed: () {
              final pin = DeliveryProofPin.normalize(controller.text);
              if (!DeliveryProofPin.isValidFormat(pin)) return;
              Navigator.of(dialogContext).pop(pin);
            },
            child: const Text('Confirmar entrega'),
          ),
        ],
      );
    },
  );
}
