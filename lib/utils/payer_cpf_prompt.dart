import 'package:flutter/material.dart';

import 'validators.dart';

/// CPF/CNPJ já salvo no pedido (somente dígitos).
String? payerCpfDigitsFromOrder(String? recipientCpf) {
  final d = DocumentValidators.normalizeDigits(recipientCpf ?? '');
  if (d.length == 11 || d.length == 14) return d;
  return null;
}

/// Pede CPF do pagador quando o pedido não tem (cobrança Asaas).
Future<String?> promptPayerCpfIfNeeded(
  BuildContext context, {
  String? existing,
}) async {
  final fromOrder = payerCpfDigitsFromOrder(existing);
  if (fromOrder != null) return fromOrder;

  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('CPF do cliente'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'CPF (obrigatório para cobrança)',
            hintText: 'Somente números',
          ),
          inputFormatters: [CpfCnhInputFormatter()],
          validator: DocumentValidators.validateCpf,
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState?.validate() != true) return;
            Navigator.pop(
              ctx,
              DocumentValidators.normalizeDigits(controller.text),
            );
          },
          child: const Text('Continuar'),
        ),
      ],
    ),
  );
}
