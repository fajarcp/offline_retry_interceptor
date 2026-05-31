import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:offline_retry_interceptor/offline_retry_interceptor.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: NetworkTestScreen(),
    );
  }
}

class NetworkTestScreen extends StatefulWidget {
  const NetworkTestScreen({super.key});

  @override
  State<NetworkTestScreen> createState() => _NetworkTestScreenState();
}

class _NetworkTestScreenState extends State<NetworkTestScreen> {
  late Dio _dio;
  String _statusText = "Press the button to test";

  @override
  void initState() {
    super.initState();
    _dio = Dio();

    final offlineInterceptor = OfflineRetryInterceptor();
    _dio.interceptors.add(offlineInterceptor);
  }

  Future<void> _sendData() async {
    setState(() => _statusText = "Sending...");
    try {
      // Simulate sending data to a dummy API
      final response = await _dio.post(
        'https://jsonplaceholder.typicode.com/posts',
        data: {'title': 'Test Post', 'body': 'This is a test'},
      );

      if (response.statusCode == 202) {
        setState(() => _statusText = "No Internet: Saved to Queue!");
      } else {
        setState(() => _statusText = "Success: Sent to Server!");
      }
    } catch (e) {
      setState(() => _statusText = "Error: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Retry Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_statusText, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendData,
              child: const Text('Send POST Request'),
            ),
          ],
        ),
      ),
    );
  }
}