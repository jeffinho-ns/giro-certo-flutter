import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/moment.dart';
import 'api_service.dart';

/// Serviço responsável pelos vídeos "Momentos" (Reels do Giro Certo).
///
/// Persistência:
/// - Tenta usar a API quando disponível.
/// - Sempre cacheia em `SharedPreferences` para que o usuário continue a ver
///   os seus próprios uploads mesmo se a API falhar (paridade com o resto do
///   app, que tem fallback consistente).
class MomentsService {
  static const _localStoreKey = 'moments_local_store_v1';
  static const _commentsStoreKey = 'moments_comments_v1';
  static const maxDuration = Duration(minutes: 2);

  static List<Moment> _memCache = const [];
  static final Map<String, List<MomentComment>> _commentsCache = {};

  /// Carrega o feed global de Momentos.
  static Future<List<Moment>> getFeed({String? currentUserId}) async {
    final remote = await _tryFetchRemoteFeed(currentUserId: currentUserId);
    final local = await _readLocal();
    final combined = <String, Moment>{};
    for (final m in [...remote, ...local]) {
      combined[m.id] = m;
    }
    final list = combined.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _memCache = list;
    return list;
  }

  /// Carrega apenas os Momentos de um usuário específico (para a aba Momentos
  /// do perfil dele).
  static Future<List<Moment>> getByUserId(String userId,
      {String? currentUserId}) async {
    final feed = await getFeed(currentUserId: currentUserId);
    return feed.where((m) => m.userId == userId).toList();
  }

  static Future<List<Moment>> _tryFetchRemoteFeed(
      {String? currentUserId}) async {
    try {
      // O backend ainda não expõe endpoint `/moments`. Quando expuser,
      // basta trocar este bloco por uma chamada real.
      // ignore: unused_local_variable
      final headers = await ApiService.jsonHeadersWithAuth();
      return const <Moment>[];
    } catch (_) {
      return const <Moment>[];
    }
  }

  /// Publica um novo Moment.
  /// [videoPath] aponta para um ficheiro local (vídeo gravado/escolhido).
  /// Caso o backend ainda não suporte upload de vídeos, persistimos local.
  static Future<Moment> publishMoment({
    required String userId,
    required String userName,
    String? userAvatarUrl,
    String? userPilotProfile,
    required String videoPath,
    String? thumbnailPath,
    required String caption,
    required Duration duration,
    List<String> hashtags = const [],
  }) async {
    if (duration > maxDuration) {
      throw Exception(
          'O vídeo precisa ter no máximo ${maxDuration.inMinutes} minutos.');
    }

    String videoUrl = videoPath;
    String? thumbnailUrl = thumbnailPath;
    try {
      // Quando houver endpoint, faria upload aqui.
      // videoUrl = await ApiService.uploadMomentVideo(videoPath, userId);
      // if (thumbnailPath != null) thumbnailUrl = await ApiService.uploadImage(...);
    } catch (_) {
      // mantém o caminho local
    }

    final moment = Moment(
      id: 'mm_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      userPilotProfile: userPilotProfile,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      caption: caption,
      hashtags: hashtags,
      createdAt: DateTime.now(),
      duration: duration,
    );

    final list = [..._memCache, moment];
    _memCache = list;
    await _saveLocal(list);
    return moment;
  }

  /// Alterna like e devolve o Moment atualizado (otimisticamente).
  static Future<Moment> toggleLike(Moment moment) async {
    final updated = moment.copyWith(
      likedByMe: !moment.likedByMe,
      likes: moment.likedByMe ? moment.likes - 1 : moment.likes + 1,
    );
    _replaceInCache(updated);
    await _saveLocal(_memCache);
    return updated;
  }

  /// Reposta o Moment: cria uma cópia atribuída ao usuário atual, marcando o
  /// autor original. Também incrementa o contador de reposts do original.
  static Future<Moment> repost({
    required Moment original,
    required String currentUserId,
    required String currentUserName,
    String? currentUserAvatarUrl,
    String? currentUserPilotProfile,
  }) async {
    if (original.repostedByMe) {
      return original;
    }
    final updatedOriginal = original.copyWith(
      reposts: original.reposts + 1,
      repostedByMe: true,
    );
    _replaceInCache(updatedOriginal);

    final repostMoment = Moment(
      id: 'mm_rp_${DateTime.now().millisecondsSinceEpoch}',
      userId: currentUserId,
      userName: currentUserName,
      userAvatarUrl: currentUserAvatarUrl,
      userPilotProfile: currentUserPilotProfile,
      videoUrl: original.videoUrl,
      thumbnailUrl: original.thumbnailUrl,
      caption: original.caption,
      hashtags: original.hashtags,
      createdAt: DateTime.now(),
      duration: original.duration,
      originalAuthorName: original.userName,
    );

    _memCache = [..._memCache, repostMoment];
    await _saveLocal(_memCache);
    return updatedOriginal;
  }

  /// Lista comentários (com fallback local).
  static Future<List<MomentComment>> getComments(String momentId) async {
    if (_commentsCache.containsKey(momentId)) {
      return List.from(_commentsCache[momentId]!);
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_commentsStoreKey:$momentId');
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((j) => MomentComment(
              id: j['id'] as String,
              userId: j['userId'] as String,
              userName: j['userName'] as String,
              userAvatarUrl: j['userAvatarUrl'] as String?,
              text: j['text'] as String,
              createdAt: DateTime.parse(j['createdAt'] as String),
            ))
        .toList();
    _commentsCache[momentId] = list;
    return list;
  }

  /// Adiciona comentário e devolve a nova lista.
  static Future<List<MomentComment>> addComment({
    required String momentId,
    required String userId,
    required String userName,
    String? userAvatarUrl,
    required String text,
  }) async {
    final current = await getComments(momentId);
    final comment = MomentComment(
      id: 'mc_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      text: text,
      createdAt: DateTime.now(),
    );
    final updated = [...current, comment];
    _commentsCache[momentId] = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_commentsStoreKey:$momentId',
      jsonEncode(updated
          .map((c) => {
                'id': c.id,
                'userId': c.userId,
                'userName': c.userName,
                'userAvatarUrl': c.userAvatarUrl,
                'text': c.text,
                'createdAt': c.createdAt.toIso8601String(),
              })
          .toList()),
    );

    // Atualiza contador de comentários no Moment correspondente.
    final idx = _memCache.indexWhere((m) => m.id == momentId);
    if (idx >= 0) {
      final m = _memCache[idx];
      final newMoment = m.copyWith(comments: m.comments + 1);
      _replaceInCache(newMoment);
      await _saveLocal(_memCache);
    }
    return updated;
  }

  /// Exclui um Moment (apenas se for do usuário atual).
  static Future<bool> deleteMoment(
      {required String momentId, required String currentUserId}) async {
    final idx = _memCache.indexWhere(
        (m) => m.id == momentId && m.userId == currentUserId);
    if (idx < 0) return false;
    _memCache = List.from(_memCache)..removeAt(idx);
    await _saveLocal(_memCache);
    return true;
  }

  static void _replaceInCache(Moment moment) {
    final idx = _memCache.indexWhere((m) => m.id == moment.id);
    if (idx >= 0) {
      final next = List<Moment>.from(_memCache);
      next[idx] = moment;
      _memCache = next;
    } else {
      _memCache = [..._memCache, moment];
    }
  }

  static Future<List<Moment>> _readLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localStoreKey);
    if (raw == null) return const [];
    try {
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((j) => Moment.fromJson(j as Map<String, dynamic>))
          .toList();
      return list;
    } catch (_) {
      return const [];
    }
  }

  static Future<void> _saveLocal(List<Moment> list) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(list.map((m) => m.toJson()).toList());
    await prefs.setString(_localStoreKey, raw);
  }
}
