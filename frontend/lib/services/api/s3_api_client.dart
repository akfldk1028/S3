import 'package:dio/dio.dart';

import '../../constants/api_endpoints.dart';

/// S3 API Client — centralised Dio wrapper for Cloudflare Workers REST API.
///
/// ## Response Envelope
///
/// Every Workers endpoint returns the following shape:
/// ```json
/// {
///   "success": true,
///   "data": <payload>,
///   "error": null,
///   "meta": { "request_id": "...", "timestamp": "..." }
/// }
/// ```
///
/// The [_S3EnvelopeInterceptor] unwraps this envelope so callers receive the
/// `data` payload directly.
///
/// ## Rules Response Shape
///
/// After envelope-unwrapping:
///
/// | Endpoint           | Unwrapped shape              |
/// |--------------------|------------------------------|
/// | GET  /rules        | `{ "rules": [...] }`         |
/// | GET  /rules/:id    | `{ "rule": {...} }`          |
/// | POST /rules        | `{ "rule": {...} }`          |
/// | PUT  /rules/:id    | `{ "rule": {...} }`          |
/// | DELETE /rules/:id  | `{ "id": "...", "deleted": true }` |
///
/// **Important**: `GET /rules/:id` returns `data.rule` (an object nested under
/// the `rule` key), NOT the rule object directly. This matches the `ok({ rule })`
/// response pattern introduced in `rules.route.ts`.

class S3ApiClient {
  late final Dio _dio;

  S3ApiClient({String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(_S3EnvelopeInterceptor());
  }

  /// The underlying [Dio] instance (after interceptors are applied).
  Dio get dio => _dio;

  // ── Rules API ─────────────────────────────────────────────────────────────

  /// GET /rules — list all rules for the authenticated user.
  ///
  /// Returns the `rules` array from the unwrapped envelope, i.e. `data.rules`.
  Future<List<Map<String, dynamic>>> getRules({
    required String authToken,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.rules,
      options: Options(headers: {'Authorization': 'Bearer $authToken'}),
    );
    final data = response.data as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(data['rules'] as List<dynamic>);
  }

  /// GET /rules/:id — fetch a single rule by ID.
  ///
  /// The backend wraps the rule under the `rule` key (`ok({ rule })`), so
  /// this method reads `data['rule']`, not `data` directly.
  ///
  /// Old shape (before backend update): `data = { id, user_id, name, ... }`
  /// New shape (current):               `data = { rule: { id, user_id, ... } }`
  Future<Map<String, dynamic>> getRuleById(
    String id, {
    required String authToken,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.ruleById(id),
      options: Options(headers: {'Authorization': 'Bearer $authToken'}),
    );
    // Envelope interceptor has already extracted body['data'].
    // data = { "rule": { id, user_id, name, ... } }
    final data = response.data as Map<String, dynamic>;
    return data['rule'] as Map<String, dynamic>;
  }

  /// POST /rules — create a new rule.
  ///
  /// Returns `data.rule` (the created rule object).
  Future<Map<String, dynamic>> createRule(
    Map<String, dynamic> body, {
    required String authToken,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.rules,
      data: body,
      options: Options(headers: {'Authorization': 'Bearer $authToken'}),
    );
    final data = response.data as Map<String, dynamic>;
    return data['rule'] as Map<String, dynamic>;
  }

  /// PUT /rules/:id — update an existing rule.
  ///
  /// Returns `data.rule` (the updated rule object).
  Future<Map<String, dynamic>> updateRule(
    String id,
    Map<String, dynamic> body, {
    required String authToken,
  }) async {
    final response = await _dio.put(
      ApiEndpoints.ruleById(id),
      data: body,
      options: Options(headers: {'Authorization': 'Bearer $authToken'}),
    );
    final data = response.data as Map<String, dynamic>;
    return data['rule'] as Map<String, dynamic>;
  }

  /// DELETE /rules/:id — delete a rule.
  ///
  /// Returns `{ id, deleted: true }` from `data`.
  Future<Map<String, dynamic>> deleteRule(
    String id, {
    required String authToken,
  }) async {
    final response = await _dio.delete(
      ApiEndpoints.ruleById(id),
      options: Options(headers: {'Authorization': 'Bearer $authToken'}),
    );
    return response.data as Map<String, dynamic>;
  }
}

/// Interceptor that unwraps the Workers API success envelope.
///
/// Input:  `{ success: true, data: <payload>, error: null, meta: { ... } }`
/// Output: `<payload>` (replaces `response.data` with `body['data']`)
///
/// On error responses the original body is preserved for error handling.
class _S3EnvelopeInterceptor extends Interceptor {
  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final body = response.data;
    if (body is Map<String, dynamic> && body.containsKey('data')) {
      response.data = body['data'];
    }
    handler.next(response);
  }
}
