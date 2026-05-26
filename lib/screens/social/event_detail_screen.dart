import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/social_event.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/colors.dart';
import '../../widgets/modern_header.dart';

/// Detalhe de um evento social com botão de RSVP (presente/talvez/ausente).
class EventDetailScreen extends StatefulWidget {
  final SocialEvent event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

enum _Rsvp { unset, going, maybe, declined }

class _EventDetailScreenState extends State<EventDetailScreen> {
  _Rsvp _rsvp = _Rsvp.unset;
  bool _saving = false;

  String _rsvpKey(String userId) => 'event_rsvp:${widget.event.id}:$userId';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRsvp());
  }

  Future<void> _loadRsvp() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final userId = appState.user?.id;
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_rsvpKey(userId));
    if (raw == null) return;
    if (!mounted) return;
    setState(() {
      _rsvp = _Rsvp.values.firstWhere(
        (r) => r.name == raw,
        orElse: () => _Rsvp.unset,
      );
    });
  }

  Future<void> _setRsvp(_Rsvp r) async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final userId = appState.user?.id;
    if (userId == null) return;
    setState(() {
      _saving = true;
      _rsvp = r;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rsvpKey(userId), r.name);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_rsvpLabel(r)),
      ),
    );
  }

  String _rsvpLabel(_Rsvp r) {
    switch (r) {
      case _Rsvp.going:
        return 'Presença confirmada.';
      case _Rsvp.maybe:
        return 'Marcado como talvez.';
      case _Rsvp.declined:
        return 'Não comparecerá.';
      case _Rsvp.unset:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = widget.event;
    final dateFmt = DateFormat('EEEE, dd \'de\' MMMM \'de\' yyyy', 'pt_BR');
    final timeFmt = DateFormat('HH:mm', 'pt_BR');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ModernHeader(
              title: 'Evento',
              showBackButton: true,
              onBackPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(LucideIcons.calendar,
                            size: 16, color: AppColors.racingOrange),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${dateFmt.format(e.dateTime)} • ${timeFmt.format(e.dateTime)}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    if (e.address != null && e.address!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(LucideIcons.mapPin,
                              size: 16, color: AppColors.racingOrange),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              e.address!,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (e.createdByName != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(LucideIcons.user,
                              size: 16, color: AppColors.racingOrange),
                          const SizedBox(width: 6),
                          Text(
                            'Organizado por ${e.createdByName}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                    if (e.lat != null && e.lng != null) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 180,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(e.lat!, e.lng!),
                              initialZoom: 14,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.girocerto.app',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(e.lat!, e.lng!),
                                    width: 36,
                                    height: 36,
                                    child: Icon(
                                      LucideIcons.mapPin,
                                      color: AppColors.racingOrange,
                                      size: 32,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text('Sobre',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 6),
                    Text(
                      e.description.isEmpty
                          ? 'Este evento ainda não tem descrição.'
                          : e.description,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Vou participar?',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _rsvpButton(
                            label: 'Vou',
                            icon: LucideIcons.checkCircle,
                            color: AppColors.statusOk,
                            selected: _rsvp == _Rsvp.going,
                            onTap: () => _setRsvp(_Rsvp.going),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _rsvpButton(
                            label: 'Talvez',
                            icon: LucideIcons.helpCircle,
                            color: AppColors.statusWarning,
                            selected: _rsvp == _Rsvp.maybe,
                            onTap: () => _setRsvp(_Rsvp.maybe),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _rsvpButton(
                            label: 'Não vou',
                            icon: LucideIcons.xCircle,
                            color: AppColors.alertRed,
                            selected: _rsvp == _Rsvp.declined,
                            onTap: () => _setRsvp(_Rsvp.declined),
                          ),
                        ),
                      ],
                    ),
                    if (_saving)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rsvpButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? color.withOpacity(0.18) : Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : Theme.of(context).dividerColor,
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? color : null,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
