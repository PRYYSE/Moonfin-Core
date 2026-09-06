import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../data/repositories/seerr_repository.dart';
import '../../../data/services/media_server_client_factory.dart';
import '../../../data/services/seerr/seerr_api_models.dart';
import '../catalogue/discovery_catalogue.dart';
import '../data/discovery_request_plan.dart';

typedef HomeLabDiscoveryPageFetcher =
    Future<SeerrDiscoverPage> Function(HomeLabDiscoveryQuery query, int page);

abstract interface class HomeLabDiscoveryBridge {
  Future<SeerrDiscoverPage> fetchPage(HomeLabDiscoveryQuery query, int page);
}

/// Narrow anti-corruption adapter between Home Lab Discovery and stock Moonfin.
///
/// Authentication/session ownership remains in the official [SeerrRepository].
/// Rich catalogue filters are sent through Moonbase's existing authenticated
/// catch-all Seerr proxy, which forwards the query string unchanged. This keeps
/// those custom filters out of Moonfin's core repository/client surface.
class MoonfinHomeLabDiscoveryBridge implements HomeLabDiscoveryBridge {
  final SeerrRepository repository;
  final MediaServerClientFactory clientFactory;
  final Dio _dio;

  MoonfinHomeLabDiscoveryBridge({
    required this.repository,
    required this.clientFactory,
    Dio? dio,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 30),
               receiveTimeout: const Duration(seconds: 30),
               sendTimeout: const Duration(seconds: 30),
               followRedirects: true,
               validateStatus: (_) => true,
             ),
           );

  @override
  Future<SeerrDiscoverPage> fetchPage(
    HomeLabDiscoveryQuery query,
    int page,
  ) async {
    final plan = HomeLabDiscoveryRequestPlan.fromQuery(query, page: page);
    if (plan == null) {
      throw UnsupportedError(
        'Discovery query requires server compilation or a specialised source',
      );
    }

    await repository.ensureInitialized();
    if (!repository.isAvailable) {
      throw StateError('Seerr is not available for the active Moonfin user');
    }

    final client = clientFactory.getActiveClient();
    final token = client.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('Active Moonfin server session has no access token');
    }

    final baseUrl = client.baseUrl.endsWith('/')
        ? client.baseUrl.substring(0, client.baseUrl.length - 1)
        : client.baseUrl;
    final response = await _dio.get<dynamic>(
      '$baseUrl/Moonfin/Seerr/Api/${plan.path}',
      queryParameters: plan.queryParameters,
      options: Options(
        headers: {'Authorization': 'MediaBrowser Token="$token"'},
      ),
    );

    if (response.statusCode == null ||
        response.statusCode! < 200 ||
        response.statusCode! > 299) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Discovery proxy returned HTTP ${response.statusCode}',
      );
    }

    final data = _unwrapProxyEnvelope(response.data);
    if (data is! Map) {
      throw const FormatException('Discovery proxy returned a non-object page');
    }
    return SeerrDiscoverPage.fromJson(Map<String, dynamic>.from(data));
  }

  dynamic _unwrapProxyEnvelope(dynamic data) {
    if (data is! Map) return data;
    final fileContents = data['FileContents'];
    if (fileContents is! String || fileContents.isEmpty) return data;
    try {
      return jsonDecode(utf8.decode(base64Decode(fileContents)));
    } catch (_) {
      throw const FormatException('Invalid Moonbase proxy response envelope');
    }
  }

  void close() => _dio.close();
}
