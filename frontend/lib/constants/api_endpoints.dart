class ApiEndpoints {
  ApiEndpoints._();

  // Base URL
  static const String baseUrl = 'http://localhost:8000/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Users
  static const String me = '/users/me';
  static const String users = '/users';
  static String user(String id) => '/users/$id';

  // AI
  static const String chat = '/ai/chat';
  static const String analyze = '/ai/analyze';
  static const String recommend = '/ai/recommend';
}
