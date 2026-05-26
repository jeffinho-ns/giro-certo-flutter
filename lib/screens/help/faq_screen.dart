import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../utils/colors.dart';
import '../../widgets/modern_header.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _faqs = <_Faq>[
    _Faq(
      'Como atualizo a quilometragem da minha moto?',
      'Vá em Menu > Manutenção. No topo do card da sua moto, toque em '
          '"Atualizar km" e informe a leitura atual do hodômetro. '
          'As manutenções recomendadas serão recalculadas automaticamente.',
    ),
    _Faq(
      'Como cadastro uma nova moto?',
      'Pelo menu lateral, abra "Minha Garagem" e toque em adicionar. '
          'Você poderá registrar modelo, placa, foto e km atual.',
    ),
    _Faq(
      'Como o sistema sabe a hora de trocar uma peça?',
      'Cada item recomendado tem um ciclo médio em km. Quando você registra '
          'a troca de uma peça e mantém sua quilometragem atualizada, o app '
          'calcula o desgaste real e indica os itens em Atenção/Crítico.',
    ),
    _Faq(
      'Como publico um Momento?',
      'Toque na aba "Momentos" no menu inferior e use o botão "+" no canto '
          'superior direito para escolher um vídeo da galeria ou gravar um '
          'novo (até 2 minutos).',
    ),
    _Faq(
      'O que é o Mapa Desbravado em Rotas?',
      'Para pilotos lazer, mostramos as áreas onde você já passou de moto. '
          'Quanto mais você explora, mais o "nevoeiro" se desfaz. Para perfil '
          'Delivery, mostramos um mapa de calor das suas regiões de entrega.',
    ),
    _Faq(
      'Sou Delivery — como entro no modo trabalho?',
      'Pelo menu, abra "Corridas" e toque em "Entrar em Corridas". Você passará '
          'a receber ofertas de pedidos das lojas parceiras próximas.',
    ),
    _Faq(
      'Sou Lojista — como crio um pedido?',
      'No menu, toque em "Novo Pedido" ou abra "Pedidos" e use o botão "+ Criar '
          'Pedido". Você poderá informar endereço, valor e prioridade.',
    ),
    _Faq(
      'Como resgato uma promoção em um parceiro?',
      'Na tela Parceiros, escolha uma loja/oficina, abra a promoção desejada '
          'e toque em "Ver Oferta" para gerar o cupom (apresente o código '
          'no balcão).',
    ),
    _Faq(
      'Como reporto um problema?',
      'Em Ajuda, toque em "Chat" para falar com o suporte ou "Contactar '
          'suporte" para enviar um e-mail.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ModernHeader(
              title: 'Perguntas frequentes',
              showBackButton: true,
              onBackPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: _faqs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final f = _faqs[i];
                  return _FaqTile(faq: f);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Faq {
  final String question;
  final String answer;
  const _Faq(this.question, this.answer);
}

class _FaqTile extends StatefulWidget {
  final _Faq faq;
  const _FaqTile({required this.faq});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.helpCircle,
                      color: AppColors.racingOrange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.faq.question,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    color: theme.iconTheme.color?.withOpacity(0.5),
                    size: 18,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 10),
                Text(
                  widget.faq.answer,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        theme.textTheme.bodyMedium?.color?.withOpacity(0.85),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
