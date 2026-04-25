import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/pilot_profile.dart';
import '../../models/vehicle_type.dart';
import '../../providers/app_state_provider.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import '../../utils/delivery_constants.dart';
import '../../utils/validators.dart';
import '../../widgets/onboarding_form_widgets.dart';

class DeliveryRegistrationDetails {
  final String documentId;
  final List<String> equipments;
  final String plateLicense;
  final int currentKilometers;
  final DateTime? lastOilChangeDate;
  final int? lastOilChangeKm;
  final String? emergencyPhone;
  final bool consentImages;
  final String? vehiclePhotoUrl;
  final bool isBicycle;

  const DeliveryRegistrationDetails({
    required this.documentId,
    required this.equipments,
    required this.plateLicense,
    required this.currentKilometers,
    this.lastOilChangeDate,
    this.lastOilChangeKm,
    this.emergencyPhone,
    required this.consentImages,
    this.vehiclePhotoUrl,
    this.isBicycle = false,
  });
}

class DeliveryRegistrationScreen extends StatefulWidget {
  final PilotProfileType pilotType;
  final bool isBicycleCourier;
  final ValueChanged<DeliveryRegistrationDetails> onSubmit;
  final VoidCallback? onBack;

  const DeliveryRegistrationScreen({
    super.key,
    required this.pilotType,
    this.isBicycleCourier = false,
    required this.onSubmit,
    this.onBack,
  });

  @override
  State<DeliveryRegistrationScreen> createState() =>
      _DeliveryRegistrationScreenState();
}

class _DeliveryRegistrationScreenState
    extends State<DeliveryRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _documentController = TextEditingController();
  final _plateController = TextEditingController();
  final _kilometersController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _lastOilChangeKmController = TextEditingController();
  final _imagePicker = ImagePicker();
  final Set<String> _selectedEquipments = {};

  // Estado
  bool _isSubmitting = false;
  bool _consentImages = false;
  DateTime? _lastOilChangeDate;

  // Documento fotos
  XFile? _cnhFile;
  XFile? _crlvFile;
  XFile? _selfieWithDocFile;

  // Moto fotos
  XFile? _motoWithPlateFile;
  XFile? _platePlateCloseupFile;
  /// Nota fiscal / canhoto (só bike, opcional)
  XFile? _optionalBikeReceiptFile;

  static const List<String> _equipmentMoto = [
    'Bau',
    'Mochila',
    'Bau termico',
    'Suporte celular',
    'Capa de chuva',
  ];
  static const List<String> _equipmentBike = [
    'Mochila',
    'Mochila termica',
    'Suporte celular',
    'Capa de chuva',
  ];

  @override
  void dispose() {
    _documentController.dispose();
    _plateController.dispose();
    _kilometersController.dispose();
    _emergencyPhoneController.dispose();
    _lastOilChangeKmController.dispose();
    super.dispose();
  }

  bool get _isBike => widget.isBicycleCourier;

  bool _validateRequiredUploads() {
    final missingDocs = <String>[];
    if (_isBike) {
      if (_selfieWithDocFile == null) {
        missingDocs.add('Selfie com documento (ou doc. da bike)');
      }
      if (_motoWithPlateFile == null) missingDocs.add('Foto da bicicleta');
      if (_platePlateCloseupFile == null) {
        missingDocs.add('Selfie com a bicicleta');
      }
      if (_cnhFile == null) missingDocs.add('Foto do CPF');
      if (_crlvFile == null) missingDocs.add('Selfie com o CPF');
    } else {
      if (_cnhFile == null) missingDocs.add('CNH');
      if (_crlvFile == null) missingDocs.add('CRLV');
      if (_selfieWithDocFile == null) missingDocs.add('Selfie com documento');
      if (_motoWithPlateFile == null) missingDocs.add('Foto da moto com placa');
      if (_platePlateCloseupFile == null) {
        missingDocs.add('Foto da placa (close-up)');
      }
    }

    if (missingDocs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Faltam documentos: ${missingDocs.join(", ")}'),
          duration: const Duration(seconds: 3),
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) return;

    if (!_validateRequiredUploads()) return;

    if (!_consentImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você deve consentir o uso de imagens para continuar.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final kmText = _kilometersController.text.trim();
      final km = _isBike
          ? (kmText.isEmpty ? 0 : int.parse(kmText))
          : int.parse(kmText);

      await ApiService.createDeliveryRegistration(
        documentId:
            DocumentValidators.normalizeDigits(_documentController.text),
        plateLicense: _plateController.text.trim().toUpperCase(),
        currentKilometers: km,
        registrationVehicleType:
            _isBike ? AppVehicleType.bicycle : AppVehicleType.motorcycle,
        equipments: _selectedEquipments.toList(),
        lastOilChangeDate: _lastOilChangeDate,
        lastOilChangeKm: _lastOilChangeKmController.text.isNotEmpty
            ? int.parse(_lastOilChangeKmController.text.trim())
            : null,
        emergencyPhone: _emergencyPhoneController.text.trim().isEmpty
            ? null
            : _emergencyPhoneController.text.trim(),
        consentImages: _consentImages,
        selfieWithDocPath: _selfieWithDocFile?.path,
        motoWithPlatePath: _motoWithPlateFile?.path,
        platePlateCloseupPath: _platePlateCloseupFile?.path,
        cnhPhotoPath: _cnhFile?.path,
        crlvPhotoPath: _crlvFile?.path,
        bikeOptionalReceiptPath: _optionalBikeReceiptFile?.path,
      );

      String? vehiclePhotoUrl;
      final uid = Provider.of<AppStateProvider>(context, listen: false).user?.id;
      if (uid != null && _motoWithPlateFile != null) {
        vehiclePhotoUrl = await ApiService.uploadUserScopedImage(
          uid,
          _motoWithPlateFile!.path,
        );
      }

      await _showPendingFeedback();
      if (!mounted) return;

      widget.onSubmit(
        DeliveryRegistrationDetails(
          documentId:
              DocumentValidators.normalizeDigits(_documentController.text),
          equipments: _selectedEquipments.toList(),
          plateLicense: _plateController.text.trim().toUpperCase(),
          currentKilometers: km,
          lastOilChangeDate: _lastOilChangeDate,
          lastOilChangeKm: _lastOilChangeKmController.text.trim().isEmpty
              ? null
              : int.parse(_lastOilChangeKmController.text.trim()),
          emergencyPhone: _emergencyPhoneController.text.trim().isEmpty
              ? null
              : _emergencyPhoneController.text.trim(),
          consentImages: _consentImages,
          vehiclePhotoUrl: vehiclePhotoUrl,
          isBicycle: _isBike,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao enviar documentos: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _showPendingFeedback() async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _StatusDialog(
        title: 'Perfil em analise',
        status: 'PENDING',
        subtitle: 'Seus documentos serao avaliados em breve.',
        icon: LucideIcons.clock,
        iconColor: AppColors.statusWarning,
      ),
    );
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickDocument({
    required bool isCnh,
    required ImageSource source,
  }) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (file == null) return;
      setState(() {
        if (isCnh) {
          _cnhFile = file;
        } else {
          _crlvFile = file;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar arquivo: $e')),
        );
      }
    }
  }

  Future<void> _pickImage({
    required Function(XFile) onFilePicked,
    required ImageSource source,
  }) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (file == null) return;
      setState(() {
        onFilePicked(file);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar arquivo: $e')),
        );
      }
    }
  }

  Future<void> _showSourcePicker({
    required Function(ImageSource) onSourceSelected,
  }) async {
    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.camera),
                title: const Text('Usar câmera'),
                onTap: () {
                  Navigator.of(context).pop();
                  onSourceSelected(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.image),
                title: const Text('Escolher da galeria'),
                onTap: () {
                  Navigator.of(context).pop();
                  onSourceSelected(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showSourcePickerForDoc({required bool isCnh}) async {
    await _showSourcePicker(
      onSourceSelected: (source) {
        _pickDocument(isCnh: isCnh, source: source);
      },
    );
  }

  IconData _iconForPilotType(PilotProfileType type) {
    switch (type) {
      case PilotProfileType.casual:
        return LucideIcons.sun;
      case PilotProfileType.diario:
        return LucideIcons.mapPin;
      case PilotProfileType.racing:
        return LucideIcons.trophy;
      case PilotProfileType.delivery:
        return LucideIcons.package;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return WillPopScope(
      onWillPop: () async {
        if (widget.onBack != null) {
          widget.onBack!();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.arrowLeft),
                        onPressed: widget.onBack ??
                            () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 4),
                      Hero(
                        tag: widget.pilotType.heroTag,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _iconForPilotType(widget.pilotType),
                            size: 20,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Cadastro Delivery',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete as informacoes para validar seu perfil profissional.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Documento do piloto
                  OnboardingSectionCard(
                    title: 'Documento do piloto',
                    subtitle: _isBike
                        ? 'Informe seu CPF (11 digitos).'
                        : 'Informe CPF ou CNH para validacao.',
                    icon: LucideIcons.fileBadge,
                    accentColor: accent,
                    child: OnboardingTextField(
                      label: _isBike ? 'CPF' : 'CPF/CNH',
                      hint: '000.000.000-00',
                      icon: LucideIcons.fileText,
                      controller: _documentController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CpfCnhInputFormatter(),
                      ],
                      validator: _isBike
                          ? DocumentValidators.validateCpf
                          : DocumentValidators.validateCpfOrCnh,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Fotos de identificacao
                  OnboardingSectionCard(
                    title: 'Fotos de identificacao',
                    subtitle: 'Fotos que ligam voce ao veiculo.',
                    icon: LucideIcons.camera,
                    accentColor: accent,
                    child: Column(
                      children: [
                        _DocumentUploadCard(
                          label: 'Selfie com documento',
                          subtitle: _isBike
                              ? 'Voce com o documento (ou doc. da bike, se tiver)'
                              : 'Voce segurando seu documento',
                          icon: LucideIcons.user,
                          file: _selfieWithDocFile,
                          onTap: () => _showSourcePicker(
                            onSourceSelected: (source) {
                              _pickImage(
                                onFilePicked: (file) =>
                                    setState(() => _selfieWithDocFile = file),
                                source: source,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        _DocumentUploadCard(
                          label: _isBike
                              ? 'Foto da bicicleta'
                              : 'Foto da moto com placa',
                          subtitle: _isBike
                              ? 'Bike inteira, bem visivel'
                              : 'Voce ao lado da moto, mostrando a placa',
                          icon: LucideIcons.bike,
                          file: _motoWithPlateFile,
                          onTap: () => _showSourcePicker(
                            onSourceSelected: (source) {
                              _pickImage(
                                onFilePicked: (file) =>
                                    setState(() => _motoWithPlateFile = file),
                                source: source,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        _DocumentUploadCard(
                          label: _isBike
                              ? 'Selfie com a bicicleta'
                              : 'Foto da placa (close-up)',
                          subtitle: _isBike
                              ? 'Voce e a bike juntos'
                              : 'Placa legivel para validacao',
                          icon: LucideIcons.image,
                          file: _platePlateCloseupFile,
                          onTap: () => _showSourcePicker(
                            onSourceSelected: (source) {
                              _pickImage(
                                onFilePicked: (file) => setState(
                                    () => _platePlateCloseupFile = file),
                                source: source,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Documentos oficiais
                  OnboardingSectionCard(
                    title: 'Documentos oficiais',
                    subtitle: _isBike
                        ? 'CPF: foto legivel e selfie com o CPF em mao.'
                        : 'Envie CNH e CRLV para validacao.',
                    icon: LucideIcons.fileText,
                    accentColor: accent,
                    child: Column(
                      children: [
                        _DocumentUploadCard(
                          label: _isBike ? 'Foto do CPF' : 'Foto da CNH',
                          subtitle: _isBike
                              ? 'Frente do CPF, legivel'
                              : 'Documento de habilitacao',
                          icon: LucideIcons.fileBadge,
                          file: _cnhFile,
                          onTap: () => _showSourcePickerForDoc(isCnh: true),
                        ),
                        if (!_isBike) const SizedBox(height: 12),
                        if (!_isBike)
                          _DocumentUploadCard(
                            label: 'Foto do CRLV',
                            subtitle: 'Documento do veiculo',
                            icon: LucideIcons.fileText,
                            file: _crlvFile,
                            onTap: () => _showSourcePickerForDoc(isCnh: false),
                          ),
                        if (_isBike) const SizedBox(height: 12),
                        if (_isBike)
                          _DocumentUploadCard(
                            label: 'Selfie com o CPF',
                            subtitle: 'Segurando o CPF aberto (frente e verso se necessario)',
                            icon: LucideIcons.user,
                            file: _crlvFile,
                            onTap: () => _showSourcePickerForDoc(isCnh: false),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Informacoes do veiculo
                  OnboardingSectionCard(
                    title: _isBike
                        ? 'Informacoes da bike'
                        : 'Informacoes da moto',
                    subtitle: _isBike
                        ? 'Numero de serie e km se souber (opcional o km).'
                        : 'Dados essenciais do seu veiculo.',
                    icon: LucideIcons.bike,
                    accentColor: accent,
                    child: Column(
                      children: [
                        OnboardingTextField(
                          label: _isBike
                              ? 'Numero de serie (quadro/motor elétrico)'
                              : 'Placa',
                          hint: _isBike
                              ? 'ex.: chassi ou serie do fabricante'
                              : 'ABC-1234',
                          icon: LucideIcons.fileText,
                          controller: _plateController,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z0-9.\s-]'),
                            ),
                          ],
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return _isBike
                                  ? 'Informe o número de serie'
                                  : 'Informe a placa';
                            }
                            if (!_isBike && value!.length < 7) {
                              return 'Placa invalida';
                            }
                            if (_isBike && (value?.trim().length ?? 0) < 3) {
                              return 'Dados muito curtos';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        OnboardingTextField(
                          label: _isBike
                              ? 'Quilometragem (se tiver)'
                              : 'Quilometragem atual',
                          hint: _isBike
                              ? 'Pode deixar em branco (0 se nao souber)'
                              : 'Ex: 12500',
                          icon: LucideIcons.gauge,
                          controller: _kilometersController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (_isBike) {
                              if (value == null || value.isEmpty) {
                                return null;
                              }
                            } else if (value?.isEmpty ?? true) {
                              return 'Informe a quilometragem';
                            }
                            if (value != null &&
                                value.isNotEmpty &&
                                (int.tryParse(value) == null ||
                                    int.parse(value) < 0)) {
                              return 'Quilometragem invalida';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Manutencao
                  OnboardingSectionCard(
                    title: _isBike
                        ? 'Manutencao da bike'
                        : 'Manutencao da moto',
                    subtitle: _isBike
                        ? 'Ultima manutencao (corrente, freio, pressao, etc.)'
                        : 'Informacoes sobre a ultima troca de oleo.',
                    icon: LucideIcons.wrench,
                    accentColor: accent,
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(
                            _isBike
                                ? 'Data da ultima manutencao'
                                : 'Data da ultima troca de oleo',
                          ),
                          trailing: (_lastOilChangeDate == null
                              ? const Text('Selecionar')
                              : Text(
                                  '${_lastOilChangeDate?.day}/${_lastOilChangeDate?.month}/${_lastOilChangeDate?.year}',
                                  style: theme.textTheme.bodyMedium,
                                )),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _lastOilChangeDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _lastOilChangeDate = picked);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        OnboardingTextField(
                          label: _isBike
                              ? 'Km (se tiver) na manutencao acima'
                              : 'Quilometragem da ultima troca',
                          hint: 'Ex: 10000',
                          icon: LucideIcons.gauge,
                          controller: _lastOilChangeKmController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Equipamentos
                  OnboardingSectionCard(
                    title: 'Equipamentos',
                    subtitle: 'Selecione o que voce usa nas entregas.',
                    icon: LucideIcons.package,
                    accentColor: accent,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: (_isBike ? _equipmentBike : _equipmentMoto)
                          .map((item) {
                        final selected = _selectedEquipments.contains(item);
                        return FilterChip(
                          label: Text(item),
                          selected: selected,
                          selectedColor: accent.withOpacity(0.18),
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                _selectedEquipments.add(item);
                              } else {
                                _selectedEquipments.remove(item);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Contato de emergencia
                  OnboardingSectionCard(
                    title: 'Contato de emergencia',
                    subtitle: 'Telefone alternativo para contato.',
                    icon: LucideIcons.phone,
                    accentColor: accent,
                    child: OnboardingTextField(
                      label: 'Telefone de emergencia',
                      hint: '(11) 99999-9999',
                      icon: LucideIcons.phone,
                      controller: _emergencyPhoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                  if (_isBike) ...[
                    const SizedBox(height: 16),
                    OnboardingSectionCard(
                      title: 'Comprovante da bike (opcional)',
                      subtitle:
                          'Nota fiscal, canhoto da loja ou outro documento que comprove a posse.',
                      icon: LucideIcons.fileText,
                      accentColor: accent,
                      child: _DocumentUploadCard(
                        label: 'Anexar comprovante',
                        subtitle: 'Foto legivel; pode pular se nao tiver',
                        icon: LucideIcons.link2,
                        file: _optionalBikeReceiptFile,
                        onTap: () => _showSourcePicker(
                          onSourceSelected: (source) {
                            _pickImage(
                              onFilePicked: (file) => setState(
                                () => _optionalBikeReceiptFile = file,
                              ),
                              source: source,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  OnboardingSectionCard(
                    title: 'Checklist antes de sair',
                    subtitle: _isBike
                        ? 'Boa pratica para quem roda de bicicleta.'
                        : 'Lembrete rapido para rodar com seguranca.',
                    icon: LucideIcons.clipboardList,
                    accentColor: accent,
                    child: Builder(
                      builder: (context) {
                        final list = _isBike
                            ? PreRideChecklistBike.items
                            : PreRideChecklistMoto.items;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < list.length; i++) ...[
                              if (i > 0) const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    LucideIcons.checkCircle,
                                    size: 18,
                                    color: accent,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          list[i].title,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          list[i].hint,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme.textTheme.bodyMedium
                                                ?.color
                                                ?.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Consentimento / termos
                  OnboardingSectionCard(
                    title: 'Termos e consentimento',
                    subtitle: _isBike
                        ? 'Leitura e aceite para cadastro de entregador de bicicleta.'
                        : 'Autorizo o uso de imagens para verificacao.',
                    icon: LucideIcons.shield,
                    accentColor: accent,
                    child: CheckboxListTile(
                      value: _consentImages,
                      onChanged: (value) {
                        setState(() => _consentImages = value ?? false);
                      },
                      title: Text(
                        _isBike
                            ? 'Leio e concordo: autorizo o Giro Certo a usar minhas imagens, dados do veiculo (bike) e documentos enviados para analise de cadastro de entregador. Entendo que, em caso de rejeicao, posso reenviar documentos conforme orientacao da equipe. O uso de equipamentos (mochila, chuva, etc.) e de minha responsabilidade, seguindo as leis de transito. Para bike, a plataforma prioriza ofertas em ate ${DeliveryMatchRules.maxKmBicycle} km, conforme regras de matching.'
                            : 'Autorizo o uso de imagens para verificacao de identidade e validacao do cadastro de entregador (moto), conforme politica de privacidade do Giro Certo.',
                        style: const TextStyle(fontSize: 13),
                      ),
                      dense: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  OnboardingPrimaryButton(
                    label: 'Enviar para Analise',
                    icon: LucideIcons.send,
                    isLoading: _isSubmitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentUploadCard extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final XFile? file;

  const _DocumentUploadCard({
    required this.label,
    this.subtitle,
    required this.icon,
    required this.onTap,
    required this.file,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accent.withOpacity(0.3),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.6),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      file == null ? 'Selecionar arquivo' : file!.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodyMedium?.color
                            ?.withOpacity(0.65),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                file == null ? LucideIcons.upload : LucideIcons.checkCircle,
                size: 18,
                color: file == null ? accent : AppColors.statusOk,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final IconData icon;
  final Color iconColor;

  const _StatusDialog({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Status: $status',
              style: theme.textTheme.labelSmall?.copyWith(
                color: iconColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
