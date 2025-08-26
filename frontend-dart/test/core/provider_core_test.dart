import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:music_room/core/provider_core.dart';

class TestProvider extends BaseProvider {
  Future<String> testAsyncOperation() async {
    return await executeAsync<String>(
      () async => 'success',
      successMessage: 'Operation completed',
    ) ?? '';
  }

  Future<bool> testBoolOperation() async {
    return await executeBool(
      () async => {},
      successMessage: 'Operation completed',
    );
  }

  Future<String> testFailingAsyncOperation() async {
    return await executeAsync<String>(
      () async => throw Exception('Test error'),
      errorMessage: 'Operation failed',
    ) ?? '';
  }

  Future<bool> testFailingBoolOperation() async {
    return await executeBool(
      () async => throw Exception('Test error'),
      errorMessage: 'Operation failed',
    );
  }

  Future<String> testDioErrorOperation(DioException error) async {
    return await executeAsync<String>(
      () async => throw error,
    ) ?? '';
  }
}

void main() {
  group('BaseProvider', () {
    late TestProvider provider;

    setUp(() {
      provider = TestProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    group('Initial State', () {
      test('should have correct initial values', () {
        expect(provider.isLoading, isFalse);
        expect(provider.errorMessage, isNull);
        expect(provider.successMessage, isNull);
        expect(provider.hasError, isFalse);
        expect(provider.hasSuccess, isFalse);
        expect(provider.isReady, isTrue);
      });
    });

    group('Loading State Management', () {
      test('should set loading state', () {
        bool notified = false;
        provider.addListener(() => notified = true);

        provider.setLoading(true);

        expect(provider.isLoading, isTrue);
        expect(provider.isReady, isFalse);
        expect(provider.errorMessage, isNull);
        expect(provider.successMessage, isNull);
        expect(notified, isTrue);
      });

      test('should clear messages when setting loading to true', () {
        provider.setError('Test error');
        provider.setSuccess('Test success');

        provider.setLoading(true);

        expect(provider.errorMessage, isNull);
        expect(provider.successMessage, isNull);
        expect(provider.isLoading, isTrue);
      });

      test('should stop loading', () {
        provider.setLoading(true);
        bool notified = false;
        provider.addListener(() => notified = true);

        provider.setLoading(false);

        expect(provider.isLoading, isFalse);
        expect(provider.isReady, isTrue);
        expect(notified, isTrue);
      });
    });

    group('Error State Management', () {
      test('should set error message', () {
        bool notified = false;
        provider.addListener(() => notified = true);

        provider.setError('Test error');

        expect(provider.errorMessage, 'Test error');
        expect(provider.hasError, isTrue);
        expect(provider.isLoading, isFalse);
        expect(provider.successMessage, isNull);
        expect(provider.isReady, isFalse);
        expect(notified, isTrue);
      });

      test('should clear success message when setting error', () {
        provider.setSuccess('Test success');

        provider.setError('Test error');

        expect(provider.successMessage, isNull);
        expect(provider.errorMessage, 'Test error');
      });
    });

    group('Success State Management', () {
      test('should set success message', () {
        bool notified = false;
        provider.addListener(() => notified = true);

        provider.setSuccess('Test success');

        expect(provider.successMessage, 'Test success');
        expect(provider.hasSuccess, isTrue);
        expect(provider.isLoading, isFalse);
        expect(provider.errorMessage, isNull);
        expect(provider.isReady, isTrue);
        expect(notified, isTrue);
      });

      test('should clear error message when setting success', () {
        provider.setError('Test error');

        provider.setSuccess('Test success');

        expect(provider.errorMessage, isNull);
        expect(provider.successMessage, 'Test success');
      });
    });

    group('Clear Messages', () {
      test('should clear all messages', () {
        provider.setError('Test error');
        provider.setSuccess('Test success');
        bool notified = false;
        provider.addListener(() => notified = true);

        provider.clearMessages();

        expect(provider.errorMessage, isNull);
        expect(provider.successMessage, isNull);
        expect(notified, isTrue);
      });
    });

    group('executeAsync', () {
      test('should execute successful async operation', () async {
        final result = await provider.testAsyncOperation();

        expect(result, 'success');
        expect(provider.successMessage, 'Operation completed');
        expect(provider.isLoading, isFalse);
        expect(provider.hasError, isFalse);
      });

      test('should handle async operation failure', () async {
        final result = await provider.testFailingAsyncOperation();

        expect(result, '');
        expect(provider.errorMessage, 'Operation failed');
        expect(provider.isLoading, isFalse);
        expect(provider.hasError, isTrue);
      });

      test('should set loading during async operation', () async {
        bool wasLoading = false;
        provider.addListener(() {
          if (provider.isLoading) wasLoading = true;
        });

        await provider.testAsyncOperation();

        expect(wasLoading, isTrue);
      });
    });

    group('executeBool', () {
      test('should execute successful bool operation', () async {
        final result = await provider.testBoolOperation();

        expect(result, isTrue);
        expect(provider.successMessage, 'Operation completed');
        expect(provider.isLoading, isFalse);
        expect(provider.hasError, isFalse);
      });

      test('should handle bool operation failure', () async {
        final result = await provider.testFailingBoolOperation();

        expect(result, isFalse);
        expect(provider.errorMessage, 'Operation failed');
        expect(provider.isLoading, isFalse);
        expect(provider.hasError, isTrue);
      });

      test('should set loading during bool operation', () async {
        bool wasLoading = false;
        provider.addListener(() {
          if (provider.isLoading) wasLoading = true;
        });

        await provider.testBoolOperation();

        expect(wasLoading, isTrue);
      });
    });

    group('DioException Error Handling', () {
      test('should handle connection timeout error', () async {
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionTimeout,
        );

        await provider.testDioErrorOperation(dioError);

        expect(provider.errorMessage, 'No connection to server. Please check your internet connection.');
      });

      test('should handle receive timeout error', () async {
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.receiveTimeout,
        );

        await provider.testDioErrorOperation(dioError);

        expect(provider.errorMessage, 'No connection to server. Please check your internet connection.');
      });

      test('should handle 401 unauthorized error', () async {
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 401,
          ),
        );

        await provider.testDioErrorOperation(dioError);

        expect(provider.errorMessage, 'Authentication required. Please log in again.');
      });

      test('should handle 403 forbidden error', () async {
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 403,
          ),
        );

        await provider.testDioErrorOperation(dioError);

        expect(provider.errorMessage, 'You do not have permission to perform this action.');
      });

      test('should handle 404 not found error', () async {
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 404,
          ),
        );

        await provider.testDioErrorOperation(dioError);

        expect(provider.errorMessage, 'The requested resource was not found.');
      });

      test('should handle 500 server error', () async {
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 500,
          ),
        );

        await provider.testDioErrorOperation(dioError);

        expect(provider.errorMessage, 'Server error. Please try again later.');
      });

      test('should extract detail from error response', () async {
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 400,
            data: {'detail': 'Detailed error message'},
          ),
        );

        await provider.testDioErrorOperation(dioError);

        expect(provider.errorMessage, 'Detailed error message');
      });

      test('should extract error from error response', () async {
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 400,
            data: {'error': 'Error message'},
          ),
        );

        await provider.testDioErrorOperation(dioError);

        expect(provider.errorMessage, 'Error message');
      });

      test('should extract message from error response', () async {
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 400,
            data: {'message': 'Message from server'},
          ),
        );

        await provider.testDioErrorOperation(dioError);

        expect(provider.errorMessage, 'Message from server');
      });

      test('should handle error list in response', () async {
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 400,
            data: {'error': ['Error 1', 'Error 2']},
          ),
        );

        await provider.testDioErrorOperation(dioError);

        expect(provider.errorMessage, 'Error 1\nError 2');
      });

      test('should handle field validation errors', () async {
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 400,
            data: {
              'username': ['This field is required'],
              'email': ['Invalid email format'],
            },
          ),
        );

        await provider.testDioErrorOperation(dioError);

        expect(provider.errorMessage, 'This field is required\nInvalid email format');
      });

      test('should handle string response data', () async {
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 400,
            data: 'String error message',
          ),
        );

        await provider.testDioErrorOperation(dioError);

        expect(provider.errorMessage, 'String error message');
      });

      test('should handle list response data', () async {
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 400,
            data: ['Error 1', 'Error 2'],
          ),
        );

        await provider.testDioErrorOperation(dioError);

        expect(provider.errorMessage, 'Error 1\nError 2');
      });

      test('should handle unknown status code', () async {
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 418,
          ),
        );

        await provider.testDioErrorOperation(dioError);

        expect(provider.errorMessage, 'An error occurred. Please try again.');
      });

      test('should handle non-DioException errors', () async {
        final error = Exception('Regular exception');
        
        final result = await provider.executeAsync<String>(
          () async => throw error,
        );

        expect(result, isNull);
        expect(provider.errorMessage, 'Exception: Regular exception');
      });
    });
  });
}