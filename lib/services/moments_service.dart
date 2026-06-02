import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/moment.dart';
import 'api_service.dart';
import '../utils/image_url.dart';

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

  static const String _momentHashtag = 'momento';

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
      final posts = await ApiService.getPosts(
        limit: 80,
        offset: 0,
        hashtag: _momentHashtag,
      );
      return posts
          .map((raw) => _momentFromPost(raw, currentUserId: currentUserId))
          .whereType<Moment>()
          .toList();
    } catch (_) {
      return const <Moment>[];
    }
  }

  /// Publica um novo Moment.
  /// [videoPath] aponta para um ficheiro local (vídeo gravado/escolhido).
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

    final normalizedCaption = caption.trim();
    final captionWithTag = normalizedCaption.isEmpty
        ? '#$_momentHashtag'
        : (normalizedCaption.contains('#$_momentHashtag')
            ? normalizedCaption
            : '$normalizedCaption #$_momentHashtag');

    String videoUrl = videoPath;
    if (!videoPath.startsWith('http')) {
      videoUrl = await ApiService.uploadPostImage(videoPath, userId);
    }

    final serverHashtags = <String>{
      _momentHashtag,
      ...hashtags
          .map((h) => h.replaceFirst('#', '').trim())
          .where((h) => h.isNotEmpty),
    }.toList();

    final created = await ApiService.createPost(
      content: captionWithTag,
      images: [videoUrl],
      hashtags: serverHashtags,
    );

    final moment = _momentFromPost(created, currentUserId: userId) ??
        Moment(
          id: 'mm_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          userName: userName,
          userAvatarUrl: userAvatarUrl,
          userPilotProfile: userPilotProfile,
          videoUrl: resolveImageUrl(videoUrl),
          thumbnailUrl: thumbnailPath,
          caption: normalizedCaption,
          hashtags: serverHashtags,
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
    final liked = await ApiService.togglePostLike(moment.id);
    final updated = moment.copyWith(
      likedByMe: liked,
      likes:
          liked ? moment.likes + 1 : (moment.likes > 0 ? moment.likes - 1 : 0),
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

    final repostContent =
        '[REPOST:@${original.userName}] ${original.caption.isEmpty ? '' : '\n${original.caption}'}';
    final repostPost = await ApiService.createPost(
      content: repostContent,
      images: [original.videoUrl],
      hashtags: <String>{_momentHashtag, ...original.hashtags}.toList(),
    );
    final repostMoment =
        _momentFromPost(repostPost, currentUserId: currentUserId) ??
            Moment(
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
    try {
      final rows = await ApiService.getPostComments(momentId);
      final remote = rows
          .map((j) => MomentComment(
                id: (j['id'] as String?) ?? '',
                userId:
                    (j['user'] as Map<String, dynamic>?)?['id'] as String? ??
                        '',
                userName:
                    (j['user'] as Map<String, dynamic>?)?['name'] as String? ??
                        '',
                userAvatarUrl: resolveImageUrl(
                  ((j['user'] as Map<String, dynamic>?)?['photoUrl']
                          as String?) ??
                      '',
                ),
                text: (j['content'] as String?) ?? '',
                createdAt: j['createdAt'] != null
                    ? DateTime.parse(j['createdAt'] as String)
                    : DateTime.now(),
              ))
          .where((c) => c.id.isNotEmpty)
          .toList();
      _commentsCache[momentId] = remote;
      return remote;
    } catch (_) {}

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
    try {
      await ApiService.addPostComment(momentId, content: text);
      final updated = await getComments(momentId);
      final idx = _memCache.indexWhere((m) => m.id == momentId);
      if (idx >= 0) {
        final m = _memCache[idx];
        _replaceInCache(m.copyWith(comments: m.comments + 1));
        await _saveLocal(_memCache);
      }
      return updated;
    } catch (_) {}

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
    try {
      await ApiService.deletePost(momentId);
      _memCache = List.from(_memCache)
        ..removeWhere((m) => m.id == momentId && m.userId == currentUserId);
      await _saveLocal(_memCache);
      return true;
    } catch (_) {}

    final idx = _memCache
        .indexWhere((m) => m.id == momentId && m.userId == currentUserId);
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
      final decoded = jsonDecode(raw) as List<dynamic>;
      final list = <Moment>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;
        try {
          list.add(Moment.fromJson(item));
        } catch (_) {
          // Ignora item corrompido e mantém o restante do feed.
        }
      }
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

  static Moment? _momentFromPost(
    Map<String, dynamic> raw, {
    String? currentUserId,
  }) {
    final images = _parseImages(raw);
    if (images.isEmpty) return null;
    final firstMedia = resolveImageUrl(images.first);
    if (!_looksLikeVideo(firstMedia)) return null;

    final user = raw['user'] as Map<String, dynamic>?;
    final hashtags = _parseHashtags(raw);
    final rawContent = (raw['content'] as String?) ?? '';
    final parsedRepostAuthor = _extractRepostAuthor(rawContent);
    final cleanedCaption = _stripRepostPrefix(rawContent).trim();
    final likesCount =
        (raw['likesCount'] as int?) ?? ((raw['likes'] as List?)?.length ?? 0);
    final commentsCount = (raw['commentsCount'] as int?) ?? 0;
    final likedByMe = currentUserId != null &&
        ((raw['likes'] as List<dynamic>?)?.any(
              (e) => (e as Map<String, dynamic>)['userId'] == currentUserId,
            ) ??
            false);

    return Moment(
      id: (raw['id'] as String?) ?? '',
      userId: (raw['userId'] as String?) ?? '',
      userName: (user?['name'] as String?) ?? '',
      userAvatarUrl: resolveImageUrl((user?['photoUrl'] as String?) ?? ''),
      userPilotProfile: (user?['pilotProfile'] as String?) ??
          raw['userPilotProfile'] as String?,
      videoUrl: firstMedia,
      thumbnailUrl: null,
      caption: cleanedCaption.replaceAll('#$_momentHashtag', '').trim(),
      hashtags: hashtags,
      createdAt: raw['createdAt'] != null
          ? DateTime.parse(raw['createdAt'] as String)
          : DateTime.now(),
      likes: likesCount,
      comments: commentsCount,
      reposts: ((raw['reposts'] as num?)?.toInt()) ?? 0,
      likedByMe: likedByMe,
      repostedByMe: false,
      duration: Duration.zero,
      originalAuthorName: parsedRepostAuthor,
    );
  }

  static List<String> _parseImages(Map<String, dynamic> raw) {
    final dynamic v = raw['images'];
    if (v is List) {
      return v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    if (v is String && v.startsWith('{') && v.endsWith('}')) {
      final body = v.substring(1, v.length - 1);
      if (body.trim().isEmpty) return const [];
      return body
          .split(',')
          .map((e) => e.trim().replaceAll(RegExp(r'^"|"$'), ''))
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static List<String> _parseHashtags(Map<String, dynamic> raw) {
    final v = raw['hashtags'];
    if (v is List) {
      return v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    final c = (raw['content'] as String?) ?? '';
    return RegExp(r'#(\w+)')
        .allMatches(c)
        .map((m) => m.group(1) ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static bool _looksLikeVideo(String url) {
    final u = url.toLowerCase();
    return u.endsWith('.mp4') ||
        u.endsWith('.mov') ||
        u.endsWith('.m4v') ||
        u.endsWith('.webm');
  }

  static String? _extractRepostAuthor(String content) {
    final m = RegExp(r'^\[REPOST:@([^\]]+)\]').firstMatch(content);
    return m?.group(1);
  }

  static String _stripRepostPrefix(String content) {
    return content.replaceFirst(RegExp(r'^\[REPOST:@[^\]]+\]\s*'), '');
  }
}
