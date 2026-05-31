A robust Dio interceptor for Flutter that queues failed network requests offline using SQLite and automatically retries them when connectivity is restored. Never lose a user's data submission just because they lost cell service.

## Features

* 📡 **Offline Queueing:** Automatically intercepts `DioExceptionType.connectionError` and `connectionTimeout`.
* 💾 **Persistent Storage:** Saves POST, PUT, and DELETE requests to a local SQLite database. The queue survives app restarts!
* 🔄 **Smart Retries:** Listens to network changes via `connectivity_plus` and silently resends queued requests the exact moment the device comes back online.
* 🛡️ **GET Request Safe:** Intelligently ignores `GET` requests, ensuring your app doesn't fetch stale data when coming back online.
* ⚡ **Plug & Play:** Zero boilerplate. Just add the interceptor to your Dio instance and let it handle the rest.

## Getting started

Add the package to your `pubspec.yaml` file:

```yaml
dependencies:
  offline_retry_interceptor: ^0.0.1
  dio: ^5.0.0
```

Or install it via the terminal:

```bash
flutter pub add offline_retry_interceptor
```

## Usage

Using this package is as simple as adding a single line to your Dio setup.

```dart
import 'package:dio/dio.dart';
import 'package:offline_retry_interceptor/offline_retry_interceptor.dart';

void main() async {
  final dio = Dio();
  
  // 1. Add the interceptor
  dio.interceptors.add(OfflineRetryInterceptor());

  // 2. Make your requests as normal!
  try {
    final response = await dio.post(
      '[https://api.example.com/submit-data](https://api.example.com/submit-data)', 
      data: {'username': 'flutter_dev', 'status': 'awesome'},
    );
    print('Success: ${response.statusCode}');
    
  } on DioException catch (e) {
    // If the device is completely offline, the interceptor catches the error,
    // saves the request to SQLite, and returns a custom 202 response to prevent crashes.
    
    if (e.response?.statusCode == 202) {
      print('Device is offline. Request queued securely and will be sent later!');
    } else {
      print('A different error occurred: ${e.message}');
    }
  }
}
```

## Additional information

**How it Works Under the Hood:**
1. When Dio throws a connection error, `OfflineRetryInterceptor` checks the HTTP method.
2. If it's a modifying request (POST, PUT, DELETE, PATCH), it serializes the URL, body, and headers, and inserts them into an `OfflineQueueDb` (SQLite).
3. It resolves the error with a `202 Accepted` status so your app's UI doesn't crash.
4. In the background, `RetryManager` listens for network restoration. When a connection is detected, it pulls the oldest requests from the database, rebuilds the Dio request, sends it, and deletes it from the queue upon success.

**Contributing & Issues:**
If you encounter any problems, feel free to open an issue on the GitHub repository. If you feel the library is missing a feature, please raise a ticket and I'll look into it. Pull requests are always welcome!