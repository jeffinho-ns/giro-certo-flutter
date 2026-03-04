import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/social_event.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import '../../utils/social_formatters.dart';

/// Ecrã de eventos da rede social (para pins no mapa e lista).
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<SocialEvent> _events = [];
  bool _loading = true;
  String? _error;

  Future<void> _loadEvents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ApiService.getEvents(limit: 50);
      if (mounted) {
        setState(() {
          _events = list.map((e) => SocialEvent.fromJson(e)).toList();
          _events.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar eventos.';
          _loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loadEvents,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _events.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.calendarOff,
                            size: 64,
                            color: theme.iconTheme.color?.withOpacity(0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum evento',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadEvents,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _events.length,
                        itemBuilder: (context, i) {
                          final e = _events[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.racingOrange.withOpacity(0.2),
                                child: const Icon(
                                  LucideIcons.calendar,
                                  color: AppColors.racingOrange,
                                ),
                              ),
                              title: Text(
                                e.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (e.description.isNotEmpty)
                                    Text(
                                      e.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    SocialFormatters.timeAgo(e.dateTime),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                                    ),
                                  ),
                                  if (e.address != null && e.address!.isNotEmpty)
                                    Text(
                                      e.address!,
                                      style: theme.textTheme.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
