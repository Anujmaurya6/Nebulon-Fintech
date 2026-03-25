class ApiConstants {
  ApiConstants._();

  // Insforge Backend
  static const String baseUrl = 'https://mttjvyj6.us-east.insforge.app';
  static const String apiKey = 'ik_818b6b6dd19e16e9d768afbba191726d';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3OC0xMjM0LTU2NzgtOTBhYi1jZGVmMTIzNDU2NzgiLCJlbWFpbCI6ImFub25AaW5zZm9yZ2UuY29tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0MTU2MTB9.A2Jj83_xTKadjREnNYxf0x5XzvQJIIzARkUOWBnflC4';


  // Auth Endpoints
  static const String signUp = '/api/auth/users';
  static const String signIn = '/api/auth/sessions';
  static const String signOut = '/api/auth/logout';
  static const String currentUser = '/api/auth/sessions/current';

  // OAuth Endpoints (PKCE)
  static String oauthInitiate(String provider) => '/api/auth/oauth/$provider';
  static const String oauthExchange = '/api/auth/oauth/exchange';

  // Database Endpoints
  static String records(String table) => '/api/database/records/$table';

  // AI Endpoints
  static const String aiChat = '/api/ai/chat/completions';
  static const String aiModels = '/api/ai/models';
  static const String aiConfigs = '/api/ai/configurations';

  // Health
  static const String health = '/api/health';

  // Table Names
  static const String transactionsTable = 'transactions';
  static const String userProfilesTable = 'user_profiles';
  static const String financialGoalsTable = 'financial_goals';
  static const String aiHistoryTable = 'ai_history';
  static const String bankAccountsTable = 'bank_accounts';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Cache Keys
  static const String tokenKey = 'auth_token';
  static const String userEmailKey = 'user_email';
  static const String dashboardCacheKey = 'dashboard_cache';
  static const String transactionsCacheKey = 'transactions_cache';
}
