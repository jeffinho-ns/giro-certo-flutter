import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/delivery_order.dart';
import '../models/partner.dart';

class ApiService {
  // TODO: Configurar via variável de ambiente
  static const String baseUrl = 'https://giro-certo-api.onrender.com/api';

  /// Timeout para requisições HTTP (evita travamentos em rede instável)
  static const Duration _requestTimeout = Duration(seconds: 25);

  // Cache do token
  static String? _cachedToken;

  // Obter token armazenado (sem logs em produção - evita spam com 500k+ usuários)
  static Future<String?> _getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('auth_token');
    return _cachedToken;
  }

  // Salvar token
  static Future<void> _saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Remover token (logout)
  static Future<void> _removeToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  /// Headers apenas com auth (para imagens - sem Content-Type json)
  static Future<Map<String, String>> getImageHeaders() async {
    final token = await _getToken();
    if (token == null) return {};
    return {'Authorization': 'Bearer $token'};
  }

  /// Carrega bytes de uma imagem (com auth se necessário)
  static Future<http.Response?> fetchImage(String url) async {
    if (url.isEmpty || url.startsWith('assets/')) return null;
    try {
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme) return null;
      final headers = await getImageHeaders();
      final response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Timeout'),
      );
      if (response.statusCode >= 400) return null;
      return response;
    } catch (_) {
      return null;
    }
  }

  // Headers padrão com autenticação
  static Future<Map<String, String>> _getHeaders({
    bool includeAuth = true,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      ...?extraHeaders,
    };

    if (includeAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Tratamento de erros HTTP
  static void _handleError(http.Response response) {
    if (response.statusCode >= 400) {
      try {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Erro na requisição');
      } catch (e) {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    }
  }

  // ============================================
  // AUTENTICAÇÃO
  // ============================================

  /// Login
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: await _getHeaders(includeAuth: false),
          body: json.encode({
            'email': email,
            'password': password,
          }),
        )
        .timeout(_requestTimeout, onTimeout: () {
          throw Exception('Tempo esgotado. Verifique sua conexão.');
        });

    _handleError(response);

    final data = json.decode(response.body);

    // Salvar token
    if (data['token'] != null) {
      await _saveToken(data['token'] as String);
    }

    return data;
  }

  /// Registro
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required int age,
    String? pilotProfile,
    String? photoUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: await _getHeaders(includeAuth: false),
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
        'age': age,
        if (pilotProfile != null) 'pilotProfile': pilotProfile,
        if (photoUrl != null) 'photoUrl': photoUrl,
      }),
    );

    _handleError(response);

    final data = json.decode(response.body);

    // Salvar token
    if (data['token'] != null) {
      await _saveToken(data['token'] as String);
    }

    return data;
  }

  /// Logout
  static Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: await _getHeaders(),
      );
    } catch (e) {
      // Ignorar erro, mas remover token localmente
    } finally {
      await _removeToken();
    }
  }

  /// Registar token FCM para notificações push (telemóvel bloqueado)
  static Future<void> registerFcmToken(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/me/fcm-token'),
      headers: await _getHeaders(),
      body: json.encode({'token': token}),
    );
    if (response.statusCode >= 400) return;
  }

  /// Obter usuário atual
  static Future<User> getCurrentUser() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/users/me/profile'),
          headers: await _getHeaders(),
        )
        .timeout(_requestTimeout, onTimeout: () {
          throw Exception('Tempo esgotado. Verifique sua conexão.');
        });

    _handleError(response);

    final data = json.decode(response.body);

    // A API retorna { user: {...} }
    if (data['user'] == null) {
      throw Exception('Resposta da API não contém dados do usuário');
    }

    return User.fromJson(data['user']);
  }

  /// Atualizar perfil (photoUrl, coverUrl)
  static Future<User> updateUserProfile({
    String? name,
    String? photoUrl,
    String? coverUrl,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (photoUrl != null) body['photoUrl'] = photoUrl;
    if (coverUrl != null) body['coverUrl'] = coverUrl;

    final response = await http.patch(
      Uri.parse('$baseUrl/users/me/profile'),
      headers: await _getHeaders(),
      body: json.encode(body),
    );

    _handleError(response);

    final data = json.decode(response.body) as Map<String, dynamic>;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    return user;
  }

  /// Upload de imagem para perfil (avatar ou capa). Retorna URL completa.
  /// Usa bytes + Content-Type (image/*) para o servidor aceitar. Lança exceção em falha.
  static Future<String> uploadProfileImage(String filePath, {String type = 'avatar'}) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Sessão expirada. Faz login novamente.');
    }

    final path = filePath.replaceFirst(RegExp(r'^file://'), '');
    List<int> bytes;
    String filename = 'image.jpg';
    try {
      final file = File(path);
      if (!file.existsSync()) {
        throw Exception('Ficheiro já não existe. Escolhe a imagem outra vez.');
      }
      bytes = await file.readAsBytes();
      final name = path.split(RegExp(r'[/\\]')).last;
      if (name.isNotEmpty) filename = name;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Não foi possível ler a imagem. Tenta outra.');
    }

    final contentType = _mediaTypeFromFilename(filename);
    final uri = Uri.parse('$baseUrl/users/me/upload-image');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['type'] = type;
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      bytes,
      filename: filename,
      contentType: contentType,
    ));

    final streamed = await request.send().timeout(
      _requestTimeout,
      onTimeout: () => throw Exception('Tempo esgotado. Verifica a ligação.'),
    );
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode >= 400) {
      String msg = 'Falha ao enviar a imagem (${response.statusCode}).';
      try {
        final body = json.decode(response.body) as Map<String, dynamic>?;
        final err = body?['error']?.toString();
        if (err != null && err.isNotEmpty) msg = err;
      } catch (_) {}
      throw Exception(msg);
    }

    final data = json.decode(response.body) as Map<String, dynamic>?;
    final url = data?['url'] as String? ?? data?['imageUrl'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Resposta do servidor sem URL. Tenta novamente.');
    }
    if (url.startsWith('http')) return url;
    final origin = Uri.parse(baseUrl).origin;
    return '$origin${url.startsWith('/') ? url : '/$url'}';
  }

  /// Obter perfil público de um utilizador por ID (nome, foto, capa, motos)
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 404) return null;
      _handleError(response);
      final data = json.decode(response.body) as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>?;
      return user;
    } catch (_) {
      return null;
    }
  }

  /// Buscar utilizadores por nome ou handle (ex: @jeff)
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final q = query.trim().replaceFirst(RegExp(r'^@'), '');
    if (q.isEmpty) return [];

    try {
      final uri = Uri.parse('$baseUrl/users/search').replace(
        queryParameters: {'q': q, 'limit': '20'},
      );

      final response = await http
          .get(uri, headers: await _getHeaders())
          .timeout(_requestTimeout, onTimeout: () => throw Exception('Tempo esgotado'));

      if (response.statusCode == 404) return [];

      _handleError(response);

      final data = json.decode(response.body) as Map<String, dynamic>;
      final list = data['users'] as List<dynamic>? ?? data['results'] as List<dynamic>? ?? [];
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  /// Enviar pedido de seguimento
  static Future<bool> sendFollowRequest(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/follow-request'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 404 || response.statusCode == 501) return false;
      _handleError(response);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// IDs de utilizadores a quem já enviei pedido de seguimento (pendentes)
  static Future<List<String>> getSentFollowRequestTargetIds() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me/follow-requests/sent'),
        headers: await _getHeaders(),
      );
      _handleError(response);
      final data = json.decode(response.body) as Map<String, dynamic>;
      final list = data['targetIds'] as List<dynamic>? ?? [];
      return list.map((e) => e as String).toList();
    } catch (_) {
      return [];
    }
  }

  /// Listar pedidos de seguimento recebidos (pendentes)
  static Future<List<Map<String, dynamic>>> getFollowRequests() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me/follow-requests'),
        headers: await _getHeaders(),
      );
      _handleError(response);
      final data = json.decode(response.body) as Map<String, dynamic>;
      final list = data['requests'] as List<dynamic>? ?? [];
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  /// Aceitar pedido de seguimento (e opcionalmente seguir de volta)
  static Future<bool> acceptFollowRequest(String requestId, {bool followBack = false}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/me/follow-requests/$requestId/accept'),
        headers: await _getHeaders(),
        body: json.encode({'followBack': followBack}),
      );
      if (response.statusCode == 404) return false;
      _handleError(response);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Rejeitar pedido de seguimento
  static Future<bool> rejectFollowRequest(String requestId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/me/follow-requests/$requestId/reject'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 404) return false;
      _handleError(response);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Seguir utilizador (direto, ex. após aceitar)
  static Future<bool> followUser(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/follow'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 404) return false;
      _handleError(response);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Deixar de seguir
  static Future<bool> unfollowUser(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId/follow'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 404) return false;
      _handleError(response);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Lista de seguidores de um utilizador
  static Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/followers'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 404) return [];
      _handleError(response);
      final data = json.decode(response.body) as Map<String, dynamic>;
      final list = data['followers'] as List<dynamic>? ?? [];
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  /// Lista de quem um utilizador segue
  static Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/following'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 404) return [];
      _handleError(response);
      final data = json.decode(response.body) as Map<String, dynamic>;
      final list = data['following'] as List<dynamic>? ?? [];
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  /// IDs dos utilizadores que o utilizador logado segue
  static Future<List<String>> getFollowingIds() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me/following'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 404) return [];
      _handleError(response);
      final data = json.decode(response.body) as Map<String, dynamic>;
      final list = data['followingIds'] as List<dynamic>? ??
          data['ids'] as List<dynamic>? ??
          (data['users'] as List<dynamic>?)?.map((u) => (u as Map)['id']).toList() ??
          [];
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  // ============================================
  // ONBOARDING
  // ============================================

  static Future<Map<String, dynamic>> getOnboardingStatus() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me/onboarding'),
      headers: await _getHeaders(),
    );

    _handleError(response);
    return json.decode(response.body) as Map<String, dynamic>;
  }

  static Future<void> updateOnboardingStatus({
    bool? completed,
    int? step,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/me/onboarding'),
        headers: await _getHeaders(),
        body: json.encode({
          if (completed != null) 'onboardingCompleted': completed,
          if (step != null) 'onboardingStep': step,
        }),
      );

      // Ignorar erro 404 silenciosamente (endpoint opcional)
      if (response.statusCode == 404) return;

      _handleError(response);
    } catch (_) {
      // Ignorar erros de atualização de onboarding (não são críticos)
    }
  }

  // ============================================
  // DELIVERY ORDERS
  // ============================================

  /// Listar pedidos
  static Future<List<DeliveryOrder>> getDeliveryOrders({
    String? status,
    String? storeId,
    String? riderId,
    int? limit,
  }) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (storeId != null) queryParams['storeId'] = storeId;
    if (riderId != null) queryParams['riderId'] = riderId;
    if (limit != null) queryParams['limit'] = limit.toString();

    final uri = Uri.parse('$baseUrl/delivery').replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final response = await http
        .get(uri, headers: await _getHeaders())
        .timeout(_requestTimeout, onTimeout: () {
          throw Exception('Tempo esgotado. Verifique sua conexão.');
        });

    _handleError(response);

    final data = json.decode(response.body);
    final List<dynamic> orders = data is List ? data : (data['orders'] ?? []);

    return orders.map((json) => _deliveryOrderFromJson(json)).toList();
  }

  /// Criar pedido (lojista)
  static Future<DeliveryOrder> createDeliveryOrder({
    required String storeId,
    required String storeName,
    required String storeAddress,
    required double storeLatitude,
    required double storeLongitude,
    required String deliveryAddress,
    required double deliveryLatitude,
    required double deliveryLongitude,
    String? recipientName,
    String? recipientPhone,
    String? notes,
    required double value,
    required double deliveryFee,
    String? priority,
  }) async {
    final response = await http
        .post(
      Uri.parse('$baseUrl/delivery'),
      headers: await _getHeaders(),
      body: json.encode({
        'storeId': storeId,
        'storeName': storeName,
        'storeAddress': storeAddress,
        'storeLatitude': storeLatitude,
        'storeLongitude': storeLongitude,
        'deliveryAddress': deliveryAddress,
        'deliveryLatitude': deliveryLatitude,
        'deliveryLongitude': deliveryLongitude,
        if (recipientName != null) 'recipientName': recipientName,
        if (recipientPhone != null) 'recipientPhone': recipientPhone,
        if (notes != null) 'notes': notes,
        'value': value,
        'deliveryFee': deliveryFee,
        if (priority != null) 'priority': priority,
      }),
    )
        .timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw Exception(
            'Tempo esgotado. Verifique a conexão e tente novamente.');
      },
    );

    _handleError(response);

    try {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final orderJson = data['order'] as Map<String, dynamic>? ?? data;
      return _deliveryOrderFromJson(orderJson);
    } catch (e) {
      rethrow;
    }
  }

  /// Aceitar corrida (motociclista)
  static Future<DeliveryOrder> acceptOrder(String orderId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/delivery/$orderId/accept'),
      headers: await _getHeaders(),
    );

    _handleError(response);

    final data = json.decode(response.body);
    return _deliveryOrderFromJson(data);
  }

  /// Concluir corrida
  static Future<DeliveryOrder> completeOrder(String orderId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/delivery/$orderId/status'),
      headers: await _getHeaders(),
      body: json.encode({'status': 'completed'}),
    );

    _handleError(response);

    final data = json.decode(response.body);
    return _deliveryOrderFromJson(data);
  }

  /// Obter detalhes do pedido
  static Future<DeliveryOrder> getDeliveryOrder(String orderId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/delivery/$orderId'),
      headers: await _getHeaders(),
    );

    _handleError(response);

    final data = json.decode(response.body);
    return _deliveryOrderFromJson(data);
  }

  // Converter JSON da API para DeliveryOrder
  static DeliveryOrder _deliveryOrderFromJson(Map<String, dynamic> json) {
    return DeliveryOrder(
      id: json['id'] as String,
      storeId: json['storeId'] as String,
      storeName: json['storeName'] as String,
      storeAddress: json['storeAddress'] as String,
      storeLatitude: (json['storeLatitude'] as num).toDouble(),
      storeLongitude: (json['storeLongitude'] as num).toDouble(),
      deliveryAddress: json['deliveryAddress'] as String,
      deliveryLatitude: (json['deliveryLatitude'] as num).toDouble(),
      deliveryLongitude: (json['deliveryLongitude'] as num).toDouble(),
      recipientName: json['recipientName'] as String?,
      recipientPhone: json['recipientPhone'] as String?,
      notes: json['notes'] as String?,
      value: (json['value'] as num).toDouble(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      status: _parseDeliveryStatus(json['status'] as String),
      priority: _parseDeliveryPriority(json['priority'] as String? ?? 'normal'),
      createdAt: DateTime.parse(json['createdAt'] as String),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      riderId: json['riderId'] as String?,
      riderName: json['riderName'] as String?,
      distance: json['distance'] != null
          ? (json['distance'] as num).toDouble()
          : null,
      estimatedTime: json['estimatedTime'] != null
          ? (json['estimatedTime'] as num).toInt()
          : null,
    );
  }

  static DeliveryStatus _parseDeliveryStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return DeliveryStatus.pending;
      case 'accepted':
        return DeliveryStatus.accepted;
      case 'inprogress':
        return DeliveryStatus.inProgress;
      case 'completed':
        return DeliveryStatus.completed;
      case 'cancelled':
        return DeliveryStatus.cancelled;
      default:
        return DeliveryStatus.pending;
    }
  }

  static DeliveryPriority _parseDeliveryPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return DeliveryPriority.low;
      case 'normal':
        return DeliveryPriority.normal;
      case 'high':
        return DeliveryPriority.high;
      case 'urgent':
        return DeliveryPriority.urgent;
      default:
        return DeliveryPriority.normal;
    }
  }

  // ============================================
  // PARTNERS
  // ============================================

  /// Listar parceiros
  static Future<List<Partner>> getPartners({
    String? type,
  }) async {
    final queryParams = <String, String>{};
    if (type != null) queryParams['type'] = type;

    final uri = Uri.parse('$baseUrl/partners').replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );

    _handleError(response);

    final data = json.decode(response.body);
    final List<dynamic> partners =
        data is List ? data : (data['partners'] ?? []);

    return partners.map((json) => _partnerFromJson(json)).toList();
  }

  /// Obter parceiro por ID
  static Future<Partner> getPartner(String partnerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/partners/$partnerId'),
      headers: await _getHeaders(),
    );

    _handleError(response);

    final data = json.decode(response.body);
    return _partnerFromJson(data);
  }

  /// Obter própria loja (para lojistas)
  static Future<Partner> getMyPartner() async {
    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/partners/me'),
        headers: await _getHeaders(),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Tempo de espera esgotado ao buscar loja');
        },
      );

      _handleError(response);

      final data = json.decode(response.body);
      if (data['partner'] == null) {
        throw Exception('Resposta da API não contém dados da loja');
      }
      return _partnerFromJson(data['partner']);
    } catch (e) {
      // Re-throw com mensagem mais clara
      if (e.toString().contains('403') || e.toString().contains('restrito')) {
        throw Exception(
            'Acesso negado. A rota /partners/me pode não estar disponível ainda.');
      }
      rethrow;
    }
  }

  // Converter JSON da API para Partner
  static Partner _partnerFromJson(Map<String, dynamic> json) {
    return Partner(
      id: json['id'] as String,
      name: json['name'] as String,
      type: _parsePartnerType(json['type'] as String),
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isTrusted: json['isTrusted'] as bool? ?? false,
      specialties: (json['specialties'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      activePromotions: [], // TODO: Implementar quando a API retornar
    );
  }

  static PartnerType _parsePartnerType(String type) {
    switch (type.toUpperCase()) {
      case 'MECHANIC':
        return PartnerType.mechanic;
      case 'STORE':
      default:
        return PartnerType.store;
    }
  }

  // ============================================
  // USERS / BIKES (para verificar setup completo)
  // ============================================

  /// Verifica se o utilizador tem pelo menos uma moto/bike (garagem preenchida).
  static Future<bool> userHasBikes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bikes/me/bikes'),
        headers: await _getHeaders(),
      );
      _handleError(response);
      final data = json.decode(response.body) as Map<String, dynamic>;
      final list = data['bikes'] as List<dynamic>? ?? [];
      return list.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Atualizar localização do usuário
  static Future<void> updateUserLocation({
    required double latitude,
    required double longitude,
    bool? isOnline,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/me/location'),
      headers: await _getHeaders(),
      body: json.encode({
        'latitude': latitude,
        'longitude': longitude,
        if (isOnline != null) 'isOnline': isOnline,
      }),
    );

    _handleError(response);
  }

  // ============================================
  // COURIER DOCUMENTS
  // ============================================

  static Future<Map<String, dynamic>> uploadCourierDocument({
    required String documentType,
    required String filePath,
    DateTime? expirationDate,
  }) async {
    final uri = Uri.parse('$baseUrl/courier-documents/upload');
    final token = await _getToken();

    final request = http.MultipartRequest('POST', uri);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.fields['documentType'] = documentType;
    if (expirationDate != null) {
      request.fields['expirationDate'] = expirationDate.toIso8601String();
    }
    request.files.add(await http.MultipartFile.fromPath('document', filePath));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    if (response.statusCode >= 400) {
      throw Exception(
          responseBody.isNotEmpty ? responseBody : 'Erro ao enviar documento');
    }
    return json.decode(responseBody) as Map<String, dynamic>;
  }

  // ============================================
  // DELIVERY REGISTRATION
  // ============================================

  /// Criar novo registro de delivery (entregador)
  static Future<Map<String, dynamic>> createDeliveryRegistration({
    required String documentId,
    required String plateLicense,
    required int currentKilometers,
    DateTime? lastOilChangeDate,
    int? lastOilChangeKm,
    String? emergencyPhone,
    bool consentImages = true,
    // Caminhos dos arquivos (serão convertidos para base64)
    String? selfieWithDocPath,
    String? motoWithPlatePath,
    String? platePlateCloseupPath,
    String? cnhPhotoPath,
    String? crlvPhotoPath,
  }) async {
    final uri = Uri.parse('$baseUrl/delivery-registration');
    final token = await _getToken();

    // Validar se token está disponível
    if (token == null || token.isEmpty) {
      throw Exception('Você precisa estar autenticado. Faça login novamente.');
    }

    // Helper para converter arquivo para base64
    Future<String?> fileToBase64(String? filePath) async {
      if (filePath == null || filePath.isEmpty) return null;
      try {
        final bytes = await File(filePath).readAsBytes();
        return base64Encode(bytes);
      } catch (_) {
        return null;
      }
    }

    try {
      // Converter todos os arquivos para base64
      final [selfieBase64, motoBase64, plateBase64, cnhBase64, crlvBase64] =
          await Future.wait([
        fileToBase64(selfieWithDocPath),
        fileToBase64(motoWithPlatePath),
        fileToBase64(platePlateCloseupPath),
        fileToBase64(cnhPhotoPath),
        fileToBase64(crlvPhotoPath),
      ]);

      final body = {
        'documentId': documentId,
        'plateLicense': plateLicense,
        'currentKilometers': currentKilometers,
        'consentImages': consentImages,
        if (lastOilChangeDate != null)
          'lastOilChangeDate': lastOilChangeDate.toIso8601String(),
        if (lastOilChangeKm != null) 'lastOilChangeKm': lastOilChangeKm,
        if (emergencyPhone != null && emergencyPhone.isNotEmpty)
          'emergencyPhone': emergencyPhone,
        // Base64 das imagens
        if (selfieBase64 != null) 'selfieWithDocBase64': selfieBase64,
        if (motoBase64 != null) 'motoWithPlateBase64': motoBase64,
        if (plateBase64 != null) 'platePlateCloseupBase64': plateBase64,
        if (cnhBase64 != null) 'cnhPhotoBase64': cnhBase64,
        if (crlvBase64 != null) 'crlvPhotoBase64': crlvBase64,
      };

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode >= 400) {
        throw Exception(response.body.isNotEmpty
            ? response.body
            : 'Erro ao criar registro de delivery');
      }

      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Erro ao enviar registro: $e');
    }
  }

  /// Obter status do registro de delivery do usuário
  static Future<Map<String, dynamic>?> getDeliveryRegistrationStatus() async {
    final response = await http.get(
      Uri.parse('$baseUrl/delivery-registration/user/mine'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 404) {
      return null; // Sem registro
    }

    _handleError(response);

    final data = json.decode(response.body);
    final registrations = data['registrations'] as List?;

    if (registrations?.isNotEmpty == true) {
      return registrations?.first as Map<String, dynamic>;
    }
    return null;
  }

  // ============================================
  // ALERTS / NOTIFICATIONS
  // ============================================

  /// Listar alertas do usuário
  static Future<List<Map<String, dynamic>>> getAlerts({
    String? type,
    String? severity,
    bool? isRead,
    int? limit,
  }) async {
    final queryParams = <String, String>{};
    if (type != null) queryParams['type'] = type;
    if (severity != null) queryParams['severity'] = severity;
    if (isRead != null) queryParams['isRead'] = isRead.toString();
    if (limit != null) queryParams['limit'] = limit.toString();

    // Usar endpoint /me para buscar alertas do próprio usuário
    final uri = Uri.parse('$baseUrl/alerts/me').replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );

    _handleError(response);

    final data = json.decode(response.body);
    final List<dynamic> alerts = data is List ? data : (data['alerts'] ?? []);

    return alerts.map((alert) => alert as Map<String, dynamic>).toList();
  }

  /// Marcar alerta como lido
  static Future<void> markAlertAsRead(String alertId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/alerts/$alertId/read'),
      headers: await _getHeaders(),
    );

    _handleError(response);
  }

  /// Marcar todos os alertas como lidos
  static Future<void> markAllAlertsAsRead() async {
    final response = await http.put(
      Uri.parse('$baseUrl/alerts/read-all'),
      headers: await _getHeaders(),
    );

    _handleError(response);
  }

  /// Enviar notificação de broadcast (rede/comunidade)
  static Future<Map<String, dynamic>> postAlertBroadcast({
    required String target,
    required String type,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/alerts/broadcast'),
      headers: await _getHeaders(),
      body: json.encode({'target': target, 'type': type}),
    );

    _handleError(response);
    return json.decode(response.body) as Map<String, dynamic>;
  }

  // ============================================
  // POSTS (rede social)
  // ============================================

  /// Listar posts. Retorna lista bruta para mapeamento em SocialService.
  /// Se [userId] for fornecido, filtra posts desse utilizador (quando a API suportar).
  static Future<List<Map<String, dynamic>>> getPosts({
    int limit = 50,
    int offset = 0,
    String? userId,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (userId != null && userId.isNotEmpty) params['userId'] = userId;
    final uri = Uri.parse('$baseUrl/posts').replace(
      queryParameters: params,
    );

    final response = await http
        .get(uri, headers: await _getHeaders())
        .timeout(_requestTimeout, onTimeout: () {
          throw Exception('Tempo esgotado. Verifique sua conexão.');
        });

    _handleError(response);

    final data = json.decode(response.body) as Map<String, dynamic>;
    final list = data['posts'] as List<dynamic>? ?? [];
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  /// Upload de imagem para post. Retorna URL completa.
  /// Só retorna quando o upload for concluído com sucesso; em caso de falha lança exceção.
  /// Usa bytes + Content-Type (image/*) para o servidor aceitar o ficheiro.
  static Future<String> uploadPostImage(String filePath, String userId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Sessão expirada. Faz login novamente.');
    }

    final path = filePath.replaceFirst(RegExp(r'^file://'), '');
    List<int> bytes;
    String filename = 'image.jpg';
    try {
      final file = File(path);
      if (!file.existsSync()) {
        throw Exception('Ficheiro da imagem já não existe. Escolhe a imagem outra vez.');
      }
      bytes = await file.readAsBytes();
      final name = path.split(RegExp(r'[/\\]')).last;
      if (name.isNotEmpty) filename = name;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Não foi possível ler a imagem. Tenta escolher outra.');
    }

    final contentType = _mediaTypeFromFilename(filename);
    final uri = Uri.parse('$baseUrl/images/upload/post/$userId');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      bytes,
      filename: filename,
      contentType: contentType,
    ));

    final streamed = await request.send().timeout(
      _requestTimeout,
      onTimeout: () => throw Exception('Tempo esgotado. Verifica a ligação.'),
    );
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode >= 400) {
      String msg = 'Falha ao enviar a imagem (${response.statusCode}).';
      try {
        final body = json.decode(response.body) as Map<String, dynamic>?;
        final err = body?['error']?.toString();
        if (err != null && err.isNotEmpty) msg = err;
      } catch (_) {}
      throw Exception(msg);
    }

    final data = json.decode(response.body) as Map<String, dynamic>?;
    final relUrl = data?['image']?['url'] as String? ?? data?['url'] as String?;
    if (relUrl == null || relUrl.isEmpty) {
      throw Exception('Resposta do servidor sem URL da imagem. Tenta novamente.');
    }
    if (relUrl.startsWith('http')) return relUrl;
    final origin = Uri.parse(baseUrl).origin;
    return '$origin$relUrl';
  }

  /// Criar post
  static Future<Map<String, dynamic>> createPost({
    required String content,
    List<String>? images,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/posts'),
      headers: await _getHeaders(),
      body: json.encode({
        'content': content,
        if (images != null && images.isNotEmpty) 'images': images,
      }),
    );

    _handleError(response);

    final data = json.decode(response.body) as Map<String, dynamic>;
    return data['post'] as Map<String, dynamic>;
  }

  /// Toggle like no post. Retorna { liked: bool }.
  static Future<bool> togglePostLike(String postId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/posts/$postId/like'),
      headers: await _getHeaders(),
    );

    _handleError(response);

    final data = json.decode(response.body) as Map<String, dynamic>;
    return data['liked'] as bool? ?? false;
  }

  /// Listar comentários de um post
  static Future<List<Map<String, dynamic>>> getPostComments(String postId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/posts/$postId/comments'),
      headers: await _getHeaders(),
    );

    _handleError(response);

    final data = json.decode(response.body) as Map<String, dynamic>;
    final list = data['comments'] as List<dynamic>? ?? [];
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  /// Adicionar comentário
  static Future<Map<String, dynamic>> addPostComment(
    String postId, {
    required String content,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/posts/$postId/comments'),
      headers: await _getHeaders(),
      body: json.encode({'content': content}),
    );

    _handleError(response);

    final data = json.decode(response.body) as Map<String, dynamic>;
    return data['comment'] as Map<String, dynamic>;
  }

  /// Excluir post
  static Future<void> deletePost(String postId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/posts/$postId'),
      headers: await _getHeaders(),
    );

    _handleError(response);
  }

  /// Reportar post
  static Future<void> reportPost(String postId, String reason) async {
    final response = await http.post(
      Uri.parse('$baseUrl/posts/$postId/report'),
      headers: await _getHeaders(),
      body: json.encode({'reason': reason}),
    );
    _handleError(response);
  }

  // ============================================
  // STORIES
  // ============================================

  /// Listar stories (opcional: userId para filtrar por utilizador).
  static Future<List<Map<String, dynamic>>> getStories({String? userId}) async {
    try {
      final params = <String, String>{'limit': '100'};
      if (userId != null && userId.isNotEmpty) params['userId'] = userId;
      final uri = Uri.parse('$baseUrl/stories').replace(queryParameters: params);
      final response = await http.get(uri, headers: await _getHeaders());
      if (response.statusCode == 404 || response.statusCode == 501) return [];
      _handleError(response);
      final data = json.decode(response.body) as Map<String, dynamic>;
      final list = data['stories'] as List<dynamic>? ?? [];
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  /// Tipo MIME da imagem a partir da extensão do ficheiro (o servidor exige image/*).
  static MediaType _mediaTypeFromFilename(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      case 'heic':
        return MediaType('image', 'heic');
      case 'jpg':
      case 'jpeg':
      default:
        return MediaType('image', 'jpeg');
    }
  }

  /// Upload de imagem para story. Retorna URL completa.
  /// Lê o ficheiro como bytes para evitar falhas com paths temporários (ex.: após preview).
  static Future<String> uploadStoryImage(String filePath, String userId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Sessão expirada. Faz login novamente.');
    }

    final path = filePath.replaceFirst(RegExp(r'^file://'), '');
    List<int> bytes;
    String filename = 'image.jpg';
    try {
      final file = File(path);
      if (!file.existsSync()) {
        throw Exception('Ficheiro da imagem já não existe. Escolhe a imagem outra vez e publica de imediato.');
      }
      bytes = await file.readAsBytes();
      final name = path.split(RegExp(r'[/\\]')).last;
      if (name.isNotEmpty) filename = name;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Não foi possível ler a imagem. Tenta escolher outra.');
    }

    final contentType = _mediaTypeFromFilename(filename);

    final uri = Uri.parse('$baseUrl/images/upload/story/$userId');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      bytes,
      filename: filename,
      contentType: contentType,
    ));

    final streamed = await request.send().timeout(
      _requestTimeout,
      onTimeout: () => throw Exception('Tempo esgotado. Verifica a ligação.'),
    );
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode >= 400) {
      String msg = 'Falha ao enviar a imagem (${response.statusCode}).';
      try {
        final body = json.decode(response.body) as Map<String, dynamic>?;
        final err = body?['error']?.toString();
        if (err != null && err.isNotEmpty) msg = err;
      } catch (_) {}
      throw Exception(msg);
    }

    final data = json.decode(response.body) as Map<String, dynamic>?;
    final relUrl = data?['image']?['url'] as String? ?? data?['url'] as String?;
    if (relUrl == null || relUrl.isEmpty) {
      throw Exception('Resposta do servidor sem URL da imagem. Tenta novamente.');
    }
    if (relUrl.startsWith('http')) return relUrl;
    final origin = Uri.parse(baseUrl).origin;
    return '$origin$relUrl';
  }

  /// Criar story. [caption] é opcional.
  static Future<Map<String, dynamic>> createStory(String mediaUrl, {String? caption}) async {
    final body = <String, dynamic>{'mediaUrl': mediaUrl};
    if (caption != null && caption.isNotEmpty) body['caption'] = caption;
    final response = await http.post(
      Uri.parse('$baseUrl/stories'),
      headers: await _getHeaders(),
      body: json.encode(body),
    );
    _handleError(response);
    final data = json.decode(response.body) as Map<String, dynamic>;
    return data['story'] as Map<String, dynamic>;
  }

  /// Excluir story.
  static Future<void> deleteStory(String storyId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/stories/$storyId'),
      headers: await _getHeaders(),
    );
    _handleError(response);
  }

  // ============================================
  // CHAT
  // ============================================

  /// Listar conversas privadas.
  static Future<List<Map<String, dynamic>>> getChatConversations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chats'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 404 || response.statusCode == 501) return [];
      _handleError(response);
      final data = json.decode(response.body) as Map<String, dynamic>;
      final list = data['conversations'] as List<dynamic>? ?? [];
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  /// Obter ou criar conversa privada.
  static Future<Map<String, dynamic>> getOrCreatePrivateChat(String recipientId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chats/private'),
      headers: await _getHeaders(),
      body: json.encode({'recipientId': recipientId}),
    );
    _handleError(response);
    final data = json.decode(response.body) as Map<String, dynamic>;
    return data['conversation'] as Map<String, dynamic>;
  }

  /// Listar mensagens de uma conversa.
  static Future<List<Map<String, dynamic>>> getChatMessages(String chatId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chats/$chatId/messages'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 404) return [];
      _handleError(response);
      final data = json.decode(response.body) as Map<String, dynamic>;
      final list = data['messages'] as List<dynamic>? ?? [];
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  /// Enviar mensagem.
  static Future<Map<String, dynamic>> sendChatMessage(String chatId, String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chats/$chatId/messages'),
      headers: await _getHeaders(),
      body: json.encode({'text': text}),
    );
    _handleError(response);
    final data = json.decode(response.body) as Map<String, dynamic>;
    return data['message'] as Map<String, dynamic>;
  }
}
