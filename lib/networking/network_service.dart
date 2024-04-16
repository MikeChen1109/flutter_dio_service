import 'package:dio/dio.dart';

import 'network_request.dart';
import 'network_response.dart';

class PreparedNetworkRequest<Model> {
  const PreparedNetworkRequest(
    this.request,
    this.parser,
    this.dio,
    this.headers,
    this.onSendProgress,
    this.onReceiveProgress,
  );
  final NetworkRequest request;
  final Model Function(Map<String, dynamic>) parser;
  final Dio dio;
  final Map<String, dynamic> headers;
  final ProgressCallback? onSendProgress;
  final ProgressCallback? onReceiveProgress;
}

Future<NetworkResponse<Model>> executeRequest<Model>(
  PreparedNetworkRequest<Model> request,
) async {
  try {
    dynamic body = request.request.data.whenOrNull(
      json: (data) => data,
      text: (data) => data,
    );
    final response = await request.dio.request(
      request.request.path,
      data: body,
      queryParameters: request.request.queryParams,
      options: Options(
        method: request.request.type.name,
        headers: request.headers,
      ),
      onSendProgress: request.onSendProgress,
      onReceiveProgress: request.onReceiveProgress,
    );

    return NetworkResponse.ok(request.parser(response.data));
  } on DioError catch (error) {
    final errorText = error.toString();
    if (error.requestOptions.cancelToken!.isCancelled) {
      return NetworkResponse.noData(errorText);
    }
    switch (error.response?.statusCode) {
      case 400:
        return NetworkResponse.badRequest(errorText);
      case 401:
        return NetworkResponse.noAuth(errorText);
      case 403:
        return NetworkResponse.noAccess(errorText);
      case 404:
        return NetworkResponse.notFound(errorText);
      case 409:
        return NetworkResponse.conflict(errorText);
      default:
        return NetworkResponse.noData(errorText);
    }
  } catch (error) {
    return NetworkResponse.noData(error.toString());
  }
}

class NetworkService {
  NetworkService({
    required this.baseUrl,
    dioClient,
    httpHeaders,
  })  : _dio = dioClient,
        _headers = httpHeaders ?? {};
  Dio? _dio;
  final String baseUrl;
  final Map<String, String> _headers;

  Future<Dio> _getDefaultDioClient() async {
    _headers['content-type'] = 'application/json; charset=utf-8';
    final dio = Dio()
      ..options.baseUrl = baseUrl
      ..options.headers = _headers
      ..options.connectTimeout = const Duration(seconds: 5) // 5 seconds
      ..options.receiveTimeout = const Duration(seconds: 3); // 3 seconds

    return dio;
  }

  void addBasicAuth(String accessToken) {
    _headers['Authorization'] = 'Bearer $accessToken';
  }

  Future<NetworkResponse<Model>> execute<Model>(
    NetworkRequest request,
    Model Function(Map<String, dynamic>) parser, {
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    _dio ??= await _getDefaultDioClient();
    final req = PreparedNetworkRequest<Model>(
      request,
      parser,
      _dio!,
      {..._headers, ...(request.headers ?? {})},
      onSendProgress,
      onReceiveProgress,
    );
    var result = await executeRequest<Model>(req);
    return result;
  }
}
