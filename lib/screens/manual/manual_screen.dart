import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/manual/beginner_guides.dart';
import '../../data/manual/curated_models.dart';
import '../../data/manual/manual_models.dart';
import '../../data/manual/parts_info.dart';
import '../../providers/app_state_provider.dart';
import '../../services/manual_content_service.dart';
import '../../utils/colors.dart';

class ManualScreen extends StatefulWidget {
  const ManualScreen({super.key});

  @override
  State<ManualScreen> createState() => _ManualScreenState();
}

class _ManualScreenState extends State<ManualScreen> {
  final ManualContentService _contentService = ManualContentService();

  String? _selectedPart;
  String? _selectedGuide;

  bool _loading = true;
  ManualBundle? _bundle;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final preferred = context.read<AppStateProvider>().bike;
      final bundle = await _contentService.loadBundle(
        preferredBike: preferred,
      );
      if (!mounted) return;
      setState(() {
        _bundle = bundle;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bundle = ManualBundle(
          bikeContent: ManualBikeContent.empty(),
          beginnerGuides: kBeginnerGuides,
          parts: kPartsInfo,
        );
        _loading = false;
      });
    }
  }

  Map<String, ManualGuideItem> get _guidesByKey {
    final list = _bundle?.beginnerGuides ?? const <ManualGuideItem>[];
    return {for (final g in list) g.key: g};
  }

  Map<String, ManualPartItem> get _partsByKey {
    final list = _bundle?.parts ?? const <ManualPartItem>[];
    return {for (final p in list) p.key: p};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_selectedGuide != null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: _buildGuideDetail(_selectedGuide!, theme),
      );
    }
    if (_selectedPart != null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: _buildPartDetail(_selectedPart!, theme),
      );
    }
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _buildMain(theme),
    );
  }

  Widget _buildMain(ThemeData theme) {
    final bike = _bundle?.bikeContent;
    final hasBike = bike?.hasBike == true;
    final label = bike?.bikeLabel;
    final headerTitle =
        hasBike && label != null && label.isNotEmpty
            ? 'Guia para a sua $label'
            : 'Guia do piloto';

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.racingOrange,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Manual',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.racingOrange),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHero(theme, headerTitle, hasBike),
                  const SizedBox(height: 28),
                  if (hasBike) ...[
                    _buildYourBikeSection(theme, bike!),
                    const SizedBox(height: 28),
                  ] else ...[
                    _buildNoBikePrompt(theme),
                    const SizedBox(height: 28),
                  ],
                  Text(
                    'Para iniciantes',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Equipamento, postura, freios, curvas e manutenção básica.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._guidesByKey.keys.map(
                    (key) => _buildGuideListItem(key, theme),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Partes da moto',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toque em uma parte para saber mais',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPartsDiagram(theme),
                  const SizedBox(height: 32),
                  Text(
                    'Todas as partes',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._partsByKey.keys.map(
                    (partKey) => _buildPartListItem(partKey, theme),
                  ),
                  const SizedBox(height: 28),
                  _buildDisclaimer(theme),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHero(ThemeData theme, String title, bool hasBike) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.racingOrange.withOpacity(0.12),
            AppColors.racingOrange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.racingOrange.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            hasBike
                ? 'Dicas e intervalos aproximados para a sua moto, além do guia básico.'
                : 'Comece pelo básico e explore as partes da moto',
            style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoBikePrompt(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.racingOrange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              LucideIcons.bike,
              color: AppColors.racingOrange,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cadastre sua moto',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Registre a moto na Garagem para ver dicas e intervalos aproximados do seu modelo. Enquanto isso, confira o guia para iniciantes abaixo.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYourBikeSection(ThemeData theme, ManualBikeContent bike) {
    final schedule = bike.schedule;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sua moto',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _matchLevelLabel(bike),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.calendarClock,
                    color: AppColors.racingOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Manutenção aproximada',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (schedule.isApproximate)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.racingOrange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Aprox.',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.racingOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _scheduleRow(theme, 'Óleo', schedule.oilInterval),
              _scheduleRow(theme, 'Corrente / transmissão', schedule.chainCare),
              _scheduleRow(theme, 'Pneus', schedule.tireCheck),
              _scheduleRow(theme, 'Freios', schedule.brakeCheck),
              if (schedule.otherNotes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  schedule.otherNotes,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.4,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.75),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (bike.modelTips.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.lightbulb,
                      color: AppColors.racingOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Para a sua moto',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...bike.modelTips.map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Icon(
                            LucideIcons.circle,
                            size: 6,
                            color: AppColors.racingOrange,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tip,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (bike.officialLinks.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Links oficiais',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Abre o site da fabricante. Não hospedamos manuais em PDF.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          ...bike.officialLinks.map((link) => _buildLinkTile(theme, link)),
        ],
      ],
    );
  }

  String _matchLevelLabel(ManualBikeContent bike) {
    switch (bike.matchLevel) {
      case ManualContentMatchLevel.exactModel:
        return 'Conteúdo curado para ${bike.bikeLabel}.';
      case ManualContentMatchLevel.brand:
        return 'Dicas da marca ${bike.brand} + classe aproximada.';
      case ManualContentMatchLevel.displacementClass:
        return 'Dicas pela classe da moto (cilindrada / tipo).';
      case ManualContentMatchLevel.generic:
        return 'Dicas gerais — confirme sempre no manual do fabricante.';
      case ManualContentMatchLevel.none:
        return '';
    }
  }

  Widget _scheduleRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.racingOrange,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile(ThemeData theme, ManualOfficialLink link) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openUrl(link.url),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.externalLink,
                  color: AppColors.racingOrange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (link.note != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          link.note!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  color: theme.iconTheme.color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o link.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o link.')),
        );
      }
    }
  }

  Widget _buildDisclaimer(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.info,
            size: 18,
            color: theme.iconTheme.color?.withOpacity(0.7),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              kManualDisclaimer,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartsDiagram(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.dividerColor,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          _buildPartButton('Pneus'),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPartButton('Freios'),
              _buildPartButton('Motor'),
              _buildPartButton('Suspensão'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPartButton('Transmissão'),
              _buildPartButton('Elétrica'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuideListItem(String key, ThemeData theme) {
    final info = _guidesByKey[key];
    if (info == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedGuide = key),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.dividerColor,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.racingOrange.withOpacity(0.2),
                        AppColors.racingOrange.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getIconForGuide(key),
                    color: AppColors.racingOrange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Toque para ver o guia',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  color: theme.iconTheme.color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPartButton(String part) {
    return GestureDetector(
      onTap: () => setState(() => _selectedPart = part),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.racingOrange.withOpacity(0.2),
              AppColors.racingOrange.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.racingOrange,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.racingOrange.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconForPart(part),
              color: AppColors.racingOrange,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              part,
              style: const TextStyle(
                color: AppColors.racingOrange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartListItem(String part, ThemeData theme) {
    final info = _partsByKey[part];
    if (info == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedPart = part),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.dividerColor,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.racingOrange.withOpacity(0.2),
                        AppColors.racingOrange.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getIconForPart(part),
                    color: AppColors.racingOrange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Toque para ver detalhes',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  color: theme.iconTheme.color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuideDetail(String key, ThemeData theme) {
    final info = _guidesByKey[key];
    if (info == null) {
      return const SizedBox.shrink();
    }
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 100,
          floating: false,
          pinned: true,
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => setState(() => _selectedGuide = null),
          ),
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              info.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            centerTitle: false,
            titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.racingOrange.withOpacity(0.15),
                      AppColors.racingOrange.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.racingOrange.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.racingOrange,
                            AppColors.racingOrangeLight,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForGuide(key),
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      info.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        height: 1.7,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Checklist rápido',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      info.tips,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildPartDetail(String part, ThemeData theme) {
    final info = _partsByKey[part];
    if (info == null) {
      return const SizedBox.shrink();
    }
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 100,
          floating: false,
          pinned: true,
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => setState(() => _selectedPart = null),
          ),
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              info.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            centerTitle: false,
            titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.racingOrange.withOpacity(0.15),
                      AppColors.racingOrange.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.racingOrange.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.racingOrange,
                            AppColors.racingOrangeLight,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForPart(part),
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      info.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        height: 1.7,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  IconData _getIconForGuide(String key) {
    switch (key) {
      case 'Equipamento':
        return LucideIcons.hardHat;
      case 'Postura':
        return LucideIcons.personStanding;
      case 'Freios':
        return LucideIcons.shield;
      case 'Curvas':
        return LucideIcons.cornerDownRight;
      case 'Manutenção básica':
        return LucideIcons.wrench;
      default:
        return LucideIcons.bookOpen;
    }
  }

  IconData _getIconForPart(String part) {
    switch (part) {
      case 'Motor':
        return LucideIcons.settings;
      case 'Suspensão':
        return LucideIcons.zap;
      case 'Elétrica':
        return LucideIcons.battery;
      case 'Freios':
        return LucideIcons.shield;
      case 'Transmissão':
        return LucideIcons.link;
      case 'Pneus':
        return LucideIcons.circle;
      default:
        return LucideIcons.wrench;
    }
  }
}
