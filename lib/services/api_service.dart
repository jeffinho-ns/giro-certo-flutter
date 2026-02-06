import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../models/user.dart';
import '../models/delivery_order.dart';
import '../models/partner.dart';

class ApiService {
  // TODO: Configurar via variável de ambiente
  static const String baseUrl = 'https://giro-certo-api.onrender.com/api';

  // Cache do token
  static String? _cachedToken;

  // Obter token armazenado
  static Future<String?> _getToken() async {
    if (_cachedToken != null) {
      print(
          '✅ Token recuperado do cache: ${_cachedToken!.substring(0, 20)}...');
      return _cachedToken;
    }

    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('auth_token');

    if (_cachedToken != null) {
      print(
          '✅ Token recuperado de SharedPreferences: ${_cachedToken!.substring(0, 20)}...');
    } else {
      print('❌ Nenhum token encontrado em SharedPreferences');
    }

    return _cachedToken;
  }

  // Salvar token
  static Future<void> _saveToken(String token) async {
    print('💾 Salvando token no SharedPreferences...');
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    print('✅ Token salvo com sucesso: ${token.substring(0, 20)}...');
  }

  // Remover token (logout)
  static Future<void> _removeToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
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
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _getHeaders(includeAuth: false),
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    _handleError(response);

    final data = json.decode(response.body);
    print('🔐 Login response recebido: $data');

    // Salvar token
    if (data['token'] != null) {
      print(
          '✅ Token encontrado na resposta: ${(data['token'] as String).substring(0, 20)}...');
      await _saveToken(data['token'] as String);
    } else {
      print(
          '❌ Nenhum token na resposta de login. Chaves disponíveis: ${data.keys.toList()}');
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
    print('🔐 Register response recebido: $data');

    // Salvar token
    if (data['token'] != null) {
      print(
          '✅ Token encontrado na resposta: ${(data['token'] as String).substring(0, 20)}...');
      await _saveToken(data['token'] as String);
    } else {
      print(
          '❌ Nenhum token na resposta de registro. Chaves disponíveis: ${data.keys.toList()}');
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

  /// Obter usuário atual
  static Future<User> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me/profile'),
      headers: await _getHeaders(),
    );

    _handleError(response);

    final data = json.decode(response.body);

    // A API retorna { user: {...} }
    if (data['user'] == null) {
      throw Exception('Resposta da API não contém dados do usuário');
    }

    return User.fromJson(data['user']);
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
      if (response.statusCode == 404) {
        print('⚠️ Endpoint /users/me/onboarding não disponível (opcional)');
        return;
      }

      _handleError(response);
    } catch (e) {
      // Ignorar erros de atualização de onboarding (não são críticos)
      print('⚠️ Erro ao atualizar onboarding status: $e');
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

    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );

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

    if (response.statusCode >= 400) {
      print('❌ API create order: ${response.statusCode} ${response.body}');
    }
    _handleError(response);

    try {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final orderJson = data['order'] as Map<String, dynamic>? ?? data;
      return _deliveryOrderFromJson(orderJson);
    } catch (e) {
      print('❌ Parse create order response: $e');
      print('Response body: ${response.body}');
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
  // USERS
  // ============================================

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
      print('❌ Nenhum token disponível para autenticação');
      throw Exception('Você precisa estar autenticado. Faça login novamente.');
    }

    print(
        '✅ Token disponível para criação de registro: ${token.substring(0, 20)}...');

    // Helper para converter arquivo para base64
    Future<String?> fileToBase64(String? filePath) async {
      if (filePath == null || filePath.isEmpty) return null;
      try {
        final bytes = await File(filePath).readAsBytes();
        return base64Encode(bytes);
      } catch (e) {
        print('Erro ao converter arquivo para base64: $e');
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
}
