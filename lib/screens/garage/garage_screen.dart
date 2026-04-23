import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../utils/colors.dart';
import '../../widgets/modern_header.dart';
import '../../services/api_service.dart';
import '../../models/pilot_profile.dart';
import '../../models/bike.dart';

class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  Map<String, dynamic>? _deliveryRegistration;
  final _kmController = TextEditingController();
  final _oilController = TextEditingController();
  final _frontController = TextEditingController();
  final _rearController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _styleController = TextEditingController();
  final _colorController = TextEditingController();
  final _upgradeController = TextEditingController();
  final _accessoriesController = TextEditingController();
  bool _didInitForm = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  List<Map<String, dynamic>> _maintenanceLogs = const [];
  bool _isTimelineLoading = false;
  String? _timelineError;
  String? _timelineBikeId;
  final _quickPartController = TextEditingController();
  final _quickIntervalController = TextEditingController(text: '5000');
  String _quickCategory = 'OLEO';
  String _quickStatus = 'OK';
  bool _isCreatingTimelineEvent = false;

  @override
  void initState() {
    super.initState();
    _loadDeliveryRegistrationIfNeeded();
  }

  @override
  void dispose() {
    _kmController.dispose();
    _oilController.dispose();
    _frontController.dispose();
    _rearController.dispose();
    _nicknameController.dispose();
    _styleController.dispose();
    _colorController.dispose();
    _upgradeController.dispose();
    _accessoriesController.dispose();
    _quickPartController.dispose();
    _quickIntervalController.dispose();
    super.dispose();
  }

  void _syncFormFromBike(Bike bike) {
    if (_didInitForm) return;
    _didInitForm = true;
    _kmController.text = bike.currentKm.toString();
    _oilController.text = bike.oilType;
    _frontController.text = bike.frontTirePressure.toString();
    _rearController.text = bike.rearTirePressure.toString();
    _nicknameController.text = bike.nickname ?? '';
    _styleController.text = bike.ridingStyle ?? '';
    _colorController.text = bike.preferredColor ?? '';
    _upgradeController.text = bike.nextUpgrade ?? '';
    _accessoriesController.text = bike.accessories.join(', ');
  }

  Future<void> _saveBikePremiumData(Bike bike) async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final persistedBike = await _ensurePersistedBike(bike);
      final parsedKm = int.tryParse(_kmController.text.trim());
      final parsedFront = double.tryParse(_frontController.text.trim());
      final parsedRear = double.tryParse(_rearController.text.trim());
      final accessories = _accessoriesController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final updated = await ApiService.updateBike(
        persistedBike.id,
        currentKm: parsedKm,
        oilType: _oilController.text.trim().isEmpty ? null : _oilController.text.trim(),
        frontTirePressure: parsedFront,
        rearTirePressure: parsedRear,
        nickname: _nicknameController.text.trim().isEmpty ? null : _nicknameController.text.trim(),
        ridingStyle: _styleController.text.trim().isEmpty ? null : _styleController.text.trim(),
        accessories: accessories,
        nextUpgrade: _upgradeController.text.trim().isEmpty ? null : _upgradeController.text.trim(),
        preferredColor: _colorController.text.trim().isEmpty ? null : _colorController.text.trim(),
      );
      appState.setBike(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Garagem atualizada com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao salvar garagem: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _addPhotoToGarage(Bike bike) async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final user = appState.user;
    if (user == null || _isUploadingPhoto) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final persistedBike = await _ensurePersistedBike(bike);
      final uploadedUrl = await ApiService.uploadUserScopedImage(user.id, picked.path);
      final gallery = <String>{
        ...persistedBike.additionalPhotos,
        uploadedUrl,
      }.toList();
      final updated = await ApiService.updateBike(
        persistedBike.id,
        photoUrl: persistedBike.photoUrl ?? uploadedUrl,
        galleryUrls: gallery,
      );
      appState.setBike(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto adicionada na sua garagem.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao enviar foto: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<Bike> _ensurePersistedBike(Bike bike) async {
    if (bike.id.isNotEmpty && !bike.id.startsWith('bike-')) return bike;
    final created = await ApiService.createBike(
      model: bike.model,
      brand: bike.brand,
      plate: bike.plate,
      currentKm: bike.currentKm,
      oilType: bike.oilType,
      frontTirePressure: bike.frontTirePressure,
      rearTirePressure: bike.rearTirePressure,
      photoUrl: bike.photoUrl,
      nickname: bike.nickname,
      ridingStyle: bike.ridingStyle,
      accessories: bike.accessories,
      nextUpgrade: bike.nextUpgrade,
      preferredColor: bike.preferredColor,
      galleryUrls: bike.additionalPhotos,
    );
    if (!mounted) return created;
    Provider.of<AppStateProvider>(context, listen: false).setBike(created);
    return created;
  }

  Future<void> _loadDeliveryRegistrationIfNeeded() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final user = appState.user;
    if (user == null || user.pilotProfile.toUpperCase() != 'TRABALHO') return;
    try {
      final reg = await ApiService.getDeliveryRegistrationStatus();
      if (mounted) setState(() => _deliveryRegistration = reg);
    } catch (_) {}
  }

  void _ensureTimelineLoaded(Bike bike) {
    if (_timelineBikeId == bike.id || _isTimelineLoading) return;
    _timelineBikeId = bike.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadBikeTimeline(bike.id);
    });
  }

  Future<void> _loadBikeTimeline(String bikeId) async {
    setState(() {
      _isTimelineLoading = true;
      _timelineError = null;
    });
    try {
      final logs = await ApiService.getBikeMaintenanceLogs(bikeId);
      if (!mounted) return;
      setState(() {
        _maintenanceLogs = logs;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _timelineError = 'Não foi possível carregar a timeline.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isTimelineLoading = false;
        });
      }
    }
  }

  Future<void> _createQuickTimelineEvent(Bike bike) async {
    if (_isCreatingTimelineEvent) return;
    final part = _quickPartController.text.trim();
    final interval = int.tryParse(_quickIntervalController.text.trim());
    if (part.isEmpty || interval == null || interval <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha peça e intervalo em km corretamente.')),
      );
      return;
    }

    setState(() => _isCreatingTimelineEvent = true);
    try {
      final persistedBike = await _ensurePersistedBike(bike);
      final currentKm = bike.currentKm;
      final lastChangeKm = currentKm;
      final recommendedKm = currentKm + interval;
      await ApiService.createBikeMaintenanceLog(
        persistedBike.id,
        partName: part,
        category: _quickCategory,
        lastChangeKm: lastChangeKm,
        recommendedChangeKm: recommendedKm,
        currentKm: currentKm,
        status: _quickStatus,
      );
      if (!mounted) return;
      _quickPartController.clear();
      await _loadBikeTimeline(persistedBike.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento adicionado na timeline.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao registrar evento: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreatingTimelineEvent = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final bike = appState.bike;
    final theme = Theme.of(context);
    final pilotType = appState.pilotProfileType;
    final pilotLabel = _pilotTypeLabel(pilotType);
    final profileTheme = _profileTheme(pilotType);
    final pilotAccent = profileTheme.accent;

    // Se não houver bike, mostrar mensagem
    if (bike == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ModernHeader(
                title: 'Garagem',
                showBackButton: true,
                onBackPressed: () {
                  Provider.of<NavigationProvider>(context, listen: false).navigateTo(2);
                },
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.bike,
                        size: 64,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma moto cadastrada ainda',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cadastre sua moto para liberar a experiência premium da sua garagem.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final gallery = <String>{
      if (bike.photoUrl != null && bike.photoUrl!.isNotEmpty) bike.photoUrl!,
      ...bike.additionalPhotos.where((p) => p.trim().isNotEmpty),
    }.toList();
    final health = _bikeHealthScore(bike);
    _syncFormFromBike(bike);
    _ensureTimelineLoaded(bike);

    return Scaffold(
      backgroundColor: profileTheme.background,
      body: SafeArea(
        bottom: false,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                profileTheme.surface,
                profileTheme.background,
                profileTheme.background,
              ],
            ),
          ),
          child: Column(
            children: [
            // Header
            ModernHeader(
              title: 'Garagem',
              showBackButton: true,
              onBackPressed: () {
                Provider.of<NavigationProvider>(context, listen: false).navigateTo(2);
              },
            ),
            
            // Conteúdo
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero da moto (imagem no topo + badge de perfil)
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            pilotAccent.withOpacity(0.18),
                            pilotAccent.withOpacity(0.04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: pilotAccent.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: pilotAccent.withOpacity(0.18),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(26),
                              child: _buildBikeImage(
                                imagePath: gallery.isNotEmpty
                                    ? gallery.first
                                    : 'assets/images/moto-black.png',
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(26),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.08),
                                    Colors.black.withOpacity(0.20),
                                    theme.scaffoldBackgroundColor.withOpacity(0.95),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 14,
                            left: 14,
                            child: _buildPill(
                              icon: _pilotTypeIcon(pilotType),
                              text: 'Perfil: $pilotLabel • ${profileTheme.mood}',
                              color: profileTheme.accentStrong,
                            ),
                          ),
                          Positioned(
                            top: 14,
                            right: 14,
                            child: _buildPill(
                              icon: LucideIcons.hash,
                              text: bike.plate,
                              color: profileTheme.accentStrong,
                            ),
                          ),
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: 18,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bike.nickname?.isNotEmpty == true
                                      ? bike.nickname!
                                      : '${bike.brand} ${bike.model}',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${bike.brand} • ${bike.model}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.92),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildSectionTitle(context, 'Visão rápida da moto'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            context: context,
                            theme: theme,
                            icon: LucideIcons.gauge,
                            label: 'Quilometragem',
                            value:
                                '${bike.currentKm.toString().replaceAllMapped(RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))'), (Match m) => '${m[1]}.')} km',
                            color: pilotAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            context: context,
                            theme: theme,
                            icon: LucideIcons.droplet,
                            label: 'Tipo de Óleo',
                            value: bike.oilType,
                            color: AppColors.racingOrangeLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context: context,
                      theme: theme,
                      icon: LucideIcons.heartPulse,
                      label: 'Saúde estimada da moto',
                      value: '${health.$1}% • ${health.$2}',
                      color: health.$1 >= 80
                          ? AppColors.statusOk
                          : (health.$1 >= 60 ? AppColors.racingOrange : Colors.redAccent),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            context: context,
                            theme: theme,
                            icon: LucideIcons.circleDot,
                            label: 'Pneu Dianteiro',
                            value: '${bike.frontTirePressure} bar',
                            color: AppColors.statusOk,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            context: context,
                            theme: theme,
                            icon: LucideIcons.circleDot,
                            label: 'Pneu Traseiro',
                            value: '${bike.rearTirePressure} bar',
                            color: AppColors.statusOk,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Identidade Premium'),
                    const SizedBox(height: 14),
                    _buildInfoCard(
                      context: context,
                      theme: theme,
                              icon: LucideIcons.user,
                      label: 'Apelido da moto',
                      value: bike.nickname?.isNotEmpty == true
                          ? bike.nickname!
                          : 'Sem apelido definido',
                      color: pilotAccent,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context: context,
                      theme: theme,
                      icon: _pilotTypeIcon(pilotType),
                      label: 'Estilo de pilotagem',
                      value: bike.ridingStyle?.isNotEmpty == true
                          ? bike.ridingStyle!
                          : pilotLabel,
                      color: pilotAccent,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context: context,
                      theme: theme,
                      icon: LucideIcons.palette,
                      label: 'Cor preferida da moto',
                      value: bike.preferredColor?.isNotEmpty == true
                          ? bike.preferredColor!
                          : 'Não informada',
                      color: AppColors.racingOrangeLight,
                    ),

                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Acessórios e upgrades'),
                    const SizedBox(height: 12),
                    if (bike.accessories.isEmpty)
                      Text(
                        'Nenhum acessório cadastrado ainda.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: bike.accessories
                            .map(
                              (a) => Chip(
                                avatar: Icon(
                                  LucideIcons.wrench,
                                  size: 16,
                                  color: pilotAccent,
                                ),
                                label: Text(a),
                                side: BorderSide(color: pilotAccent.withOpacity(0.25)),
                                backgroundColor: pilotAccent.withOpacity(0.09),
                              ),
                            )
                            .toList(),
                      ),
                    if (bike.nextUpgrade?.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context: context,
                        theme: theme,
                        icon: LucideIcons.sparkles,
                        label: 'Próximo upgrade planejado',
                        value: bike.nextUpgrade!,
                        color: AppColors.statusOk,
                      ),
                    ],

                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Timeline da moto'),
                    const SizedBox(height: 12),
                    _buildTimelineSection(theme, bike, pilotAccent),
                    const SizedBox(height: 16),
                    _buildQuickTimelineForm(theme, bike, profileTheme),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Galeria da moto'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isUploadingPhoto ? null : () => _addPhotoToGarage(bike),
                            icon: _isUploadingPhoto
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(LucideIcons.imagePlus),
                            label: Text(
                              _isUploadingPhoto ? 'Enviando foto...' : 'Adicionar foto',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (gallery.isEmpty)
                      _buildInfoCard(
                        context: context,
                        theme: theme,
                        icon: LucideIcons.image,
                        label: 'Fotos',
                        value: 'Nenhuma foto disponível ainda.',
                        color: pilotAccent,
                      )
                    else
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: gallery.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (_, i) {
                            final p = gallery[i];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 150,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: pilotAccent.withOpacity(0.25),
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: _buildBikeImage(imagePath: p),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Editar dados da garagem'),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: _kmController,
                      label: 'Quilometragem atual',
                      icon: LucideIcons.gauge,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    _buildInputField(
                      controller: _oilController,
                      label: 'Óleo',
                      icon: LucideIcons.droplet,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            controller: _frontController,
                            label: 'Pneu dianteiro',
                            icon: LucideIcons.circleDot,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildInputField(
                            controller: _rearController,
                            label: 'Pneu traseiro',
                            icon: LucideIcons.circleDot,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildInputField(
                      controller: _nicknameController,
                      label: 'Apelido da moto',
                      icon: LucideIcons.user,
                    ),
                    const SizedBox(height: 10),
                    _buildInputField(
                      controller: _styleController,
                      label: 'Estilo de pilotagem',
                      icon: _pilotTypeIcon(pilotType),
                    ),
                    const SizedBox(height: 10),
                    _buildInputField(
                      controller: _colorController,
                      label: 'Cor preferida',
                      icon: LucideIcons.palette,
                    ),
                    const SizedBox(height: 10),
                    _buildInputField(
                      controller: _accessoriesController,
                      label: 'Acessórios (separe por vírgula)',
                      icon: LucideIcons.wrench,
                    ),
                    const SizedBox(height: 10),
                    _buildInputField(
                      controller: _upgradeController,
                      label: 'Próximo upgrade',
                      icon: LucideIcons.sparkles,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : () => _saveBikePremiumData(bike),
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(LucideIcons.save),
                            label: Text(_isSaving ? 'Salvando...' : 'Salvar alterações'),
                          ),
                        ),
                      ],
                    ),
                    if (_deliveryRegistration != null) ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle(context, 'Dados de entregador'),
                      const SizedBox(height: 16),
                      _buildDeliveryExtraSection(context, theme),
                    ],
                  ],
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildBikeImage({required String imagePath}) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/moto-black.png',
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/moto-black.png',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildPill({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _pilotTypeLabel(PilotProfileType? type) {
    if (type == null) return 'Piloto';
    switch (type) {
      case PilotProfileType.casual:
        return 'Casual';
      case PilotProfileType.diario:
        return 'Diário';
      case PilotProfileType.racing:
        return 'Racing';
      case PilotProfileType.delivery:
        return 'Delivery';
    }
  }

  IconData _pilotTypeIcon(PilotProfileType? type) {
    switch (type) {
      case PilotProfileType.casual:
        return LucideIcons.sun;
      case PilotProfileType.diario:
        return LucideIcons.mapPin;
      case PilotProfileType.racing:
        return LucideIcons.trophy;
      case PilotProfileType.delivery:
        return LucideIcons.package;
      case null:
        return LucideIcons.user;
    }
  }

  _GarageVisualTheme _profileTheme(PilotProfileType? type) {
    switch (type) {
      case PilotProfileType.casual:
        return const _GarageVisualTheme(
          accent: Color(0xFF3B82F6),
          accentStrong: Color(0xFF2563EB),
          surface: Color(0xFFEEF5FF),
          background: Color(0xFFF7FAFF),
          mood: 'Ride leve',
        );
      case PilotProfileType.diario:
        return const _GarageVisualTheme(
          accent: Color(0xFFF97316),
          accentStrong: Color(0xFFEA580C),
          surface: Color(0xFFFFF4E8),
          background: Color(0xFFFFFAF5),
          mood: 'Rotina urbana',
        );
      case PilotProfileType.racing:
        return const _GarageVisualTheme(
          accent: Color(0xFFEF4444),
          accentStrong: Color(0xFFDC2626),
          surface: Color(0xFFFFEDEE),
          background: Color(0xFFFFF8F8),
          mood: 'Alta performance',
        );
      case PilotProfileType.delivery:
        return const _GarageVisualTheme(
          accent: Color(0xFF10B981),
          accentStrong: Color(0xFF059669),
          surface: Color(0xFFEFFCF6),
          background: Color(0xFFF7FFFB),
          mood: 'Operação ativa',
        );
      case null:
        return const _GarageVisualTheme(
          accent: Color(0xFFF97316),
          accentStrong: Color(0xFFEA580C),
          surface: Color(0xFFFFF4E8),
          background: Color(0xFFFFFAF5),
          mood: 'Piloto',
        );
    }
  }

  (int, String) _bikeHealthScore(Bike bike) {
    var score = 100;
    final frontDiff = (bike.frontTirePressure - 2.5).abs();
    final rearDiff = (bike.rearTirePressure - 2.8).abs();
    score -= (frontDiff * 12).round();
    score -= (rearDiff * 12).round();
    if (bike.currentKm > 40000) score -= 10;
    if (bike.currentKm > 70000) score -= 8;
    if (bike.oilType.trim().isEmpty) score -= 8;
    if (bike.nextUpgrade?.trim().isNotEmpty == true) score += 3;
    score = score.clamp(35, 100);
    final status = score >= 80
        ? 'Excelente'
        : (score >= 65 ? 'Boa' : 'Atenção preventiva');
    return (score, status);
  }

  Widget _buildTimelineSection(ThemeData theme, Bike bike, Color accent) {
    if (_isTimelineLoading) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }

    if (_timelineError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            context: context,
            theme: theme,
            icon: LucideIcons.alertCircle,
            label: 'Timeline indisponível',
            value: _timelineError!,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _loadBikeTimeline(bike.id),
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Tentar novamente'),
            ),
          ),
        ],
      );
    }

    if (_maintenanceLogs.isEmpty) {
      return _buildInfoCard(
        context: context,
        theme: theme,
        icon: LucideIcons.clock3,
        label: 'Sem eventos por enquanto',
        value: 'Registre revisões e trocas para montar o histórico completo da sua moto.',
        color: accent,
      );
    }

    final events = _maintenanceLogs
        .map(_timelineEventFromLog)
        .toList()
      ..sort((a, b) => b.when.compareTo(a.when));

    return Column(
      children: [
        Row(
          children: [
            Text(
              '${events.length} evento(s) recente(s)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Atualizar timeline',
              onPressed: () => _loadBikeTimeline(bike.id),
              icon: const Icon(LucideIcons.refreshCw, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...events.take(8).map((e) => _buildTimelineTile(theme, e)),
      ],
    );
  }

  _GarageTimelineEvent _timelineEventFromLog(Map<String, dynamic> log) {
    final categoryRaw = (log['category'] ?? '').toString().toUpperCase();
    final statusRaw = (log['status'] ?? '').toString().toUpperCase();
    final partName = (log['partName'] ?? 'Item').toString();
    final currentKm = (log['currentKm'] as num?)?.toInt();
    final recommendedKm = (log['recommendedChangeKm'] as num?)?.toInt();
    final createdAt = DateTime.tryParse((log['createdAt'] ?? '').toString()) ?? DateTime.now();

    var detail = _maintenanceStatusLabel(statusRaw);
    if (currentKm != null && recommendedKm != null) {
      final remaining = (recommendedKm - currentKm);
      if (remaining >= 0) {
        detail = '$detail • faltam $remaining km';
      } else {
        detail = '$detail • atrasado ${remaining.abs()} km';
      }
    }

    return _GarageTimelineEvent(
      title: '${_maintenanceCategoryLabel(categoryRaw)} • $partName',
      subtitle: detail,
      when: createdAt,
      icon: _maintenanceCategoryIcon(categoryRaw),
      color: _maintenanceStatusColor(statusRaw),
      statusLabel: _maintenanceStatusLabel(statusRaw),
    );
  }

  Widget _buildTimelineTile(ThemeData theme, _GarageTimelineEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: event.color.withOpacity(0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: event.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(event.icon, color: event.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  event.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('dd/MM/yyyy').format(event.when),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.75),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: event.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  event.statusLabel,
                  style: TextStyle(
                    color: event.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTimelineForm(
    ThemeData theme,
    Bike bike,
    _GarageVisualTheme visualTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: visualTheme.accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Registrar evento rápido',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Crie um evento na timeline sem sair da garagem.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 10),
          _buildInputField(
            controller: _quickPartController,
            label: 'Peça/serviço (ex: troca de óleo)',
            icon: LucideIcons.wrench,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _quickCategory,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(LucideIcons.filter),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'OLEO', child: Text('Óleo')),
                    DropdownMenuItem(value: 'PNEUS', child: Text('Pneus')),
                    DropdownMenuItem(value: 'TRAVOES', child: Text('Freios')),
                    DropdownMenuItem(value: 'FILTROS', child: Text('Filtros')),
                    DropdownMenuItem(value: 'TRANSMISSAO', child: Text('Transmissão')),
                  ],
                  onChanged: (v) => setState(() => _quickCategory = v ?? 'OLEO'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _quickStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(LucideIcons.activity),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'OK', child: Text('OK')),
                    DropdownMenuItem(value: 'ATENCAO', child: Text('Atenção')),
                    DropdownMenuItem(value: 'CRITICO', child: Text('Crítico')),
                  ],
                  onChanged: (v) => setState(() => _quickStatus = v ?? 'OK'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _quickIntervalController,
                  label: 'Próxima revisão em (km)',
                  icon: LucideIcons.gauge,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInfoCard(
                  context: context,
                  theme: theme,
                  icon: LucideIcons.mapPin,
                  label: 'KM atual base',
                  value: '${bike.currentKm} km',
                  color: visualTheme.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isCreatingTimelineEvent
                      ? null
                      : () => _createQuickTimelineEvent(bike),
                  icon: _isCreatingTimelineEvent
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.plus),
                  label: Text(
                    _isCreatingTimelineEvent ? 'Registrando...' : 'Adicionar à timeline',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _maintenanceCategoryLabel(String category) {
    switch (category) {
      case 'OLEO':
        return 'Óleo';
      case 'PNEUS':
        return 'Pneus';
      case 'TRAVOES':
        return 'Freios';
      case 'FILTROS':
        return 'Filtros';
      case 'TRANSMISSAO':
        return 'Transmissão';
      default:
        return 'Revisão';
    }
  }

  String _maintenanceStatusLabel(String status) {
    switch (status) {
      case 'OK':
        return 'OK';
      case 'ATENCAO':
        return 'Atenção';
      case 'CRITICO':
        return 'Crítico';
      default:
        return 'Registrado';
    }
  }

  Color _maintenanceStatusColor(String status) {
    switch (status) {
      case 'OK':
        return AppColors.statusOk;
      case 'ATENCAO':
        return AppColors.racingOrange;
      case 'CRITICO':
        return Colors.redAccent;
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _maintenanceCategoryIcon(String category) {
    switch (category) {
      case 'OLEO':
        return LucideIcons.droplet;
      case 'PNEUS':
        return LucideIcons.circleDot;
      case 'TRAVOES':
        return LucideIcons.shield;
      case 'FILTROS':
        return LucideIcons.filter;
      case 'TRANSMISSAO':
        return LucideIcons.cog;
      default:
        return LucideIcons.wrench;
    }
  }

  Widget _buildDeliveryExtraSection(BuildContext context, ThemeData theme) {
    final reg = _deliveryRegistration!;
    final lastOil = reg['lastOilChangeDate'] != null || reg['lastOilChangeKm'] != null;
    final lastOilDate = reg['lastOilChangeDate'] as String?;
    final lastOilKm = reg['lastOilChangeKm'] as int?;
    final emergencyPhone = reg['emergencyPhone'] as String?;
    final parts = <Widget>[];
    if (lastOil) {
      final text = [
        if (lastOilDate != null) 'Última troca: $lastOilDate',
        if (lastOilKm != null) '${lastOilKm.toString()} km',
      ].join(' • ');
      parts.add(
        _buildInfoCard(
          context: context,
          theme: theme,
          icon: LucideIcons.droplet,
          label: 'Última troca de óleo',
          value: text.isNotEmpty ? text : '--',
          color: AppColors.racingOrangeLight,
        ),
      );
      parts.add(const SizedBox(height: 12));
    }
    if (emergencyPhone != null && emergencyPhone.isNotEmpty) {
      parts.add(
        _buildInfoCard(
          context: context,
          theme: theme,
          icon: LucideIcons.phone,
          label: 'Telefone de emergência',
          value: emergencyPhone,
          color: AppColors.statusOk,
        ),
      );
    }
    if (parts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: parts,
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _GarageTimelineEvent {
  final String title;
  final String subtitle;
  final DateTime when;
  final IconData icon;
  final Color color;
  final String statusLabel;

  _GarageTimelineEvent({
    required this.title,
    required this.subtitle,
    required this.when,
    required this.icon,
    required this.color,
    required this.statusLabel,
  });
}

class _GarageVisualTheme {
  final Color accent;
  final Color accentStrong;
  final Color surface;
  final Color background;
  final String mood;

  const _GarageVisualTheme({
    required this.accent,
    required this.accentStrong,
    required this.surface,
    required this.background,
    required this.mood,
  });
}
