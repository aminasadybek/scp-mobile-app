import 'package:flutter/material.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is String) {
      return error;
    }

    final errorString = error.toString();

    // API errors
    if (errorString.contains('404')) {
      return 'Resource not found';
    }
    if (errorString.contains('401')) {
      return 'Unauthorized - please login again';
    }
    if (errorString.contains('403')) {
      return 'Access denied';
    }
    if (errorString.contains('500')) {
      return 'Server error - please try again later';
    }
    if (errorString.contains('Connection refused')) {
      return 'Cannot connect to server - check your internet connection';
    }
    if (errorString.contains('SocketException')) {
      return 'Network error - please check your connection';
    }
    if (errorString.contains('TimeoutException')) {
      return 'Request timeout - please try again';
    }

    // Form validation errors
    if (errorString.contains('email')) {
      return 'Invalid email address';
    }
    if (errorString.contains('password')) {
      return 'Password must be at least 6 characters';
    }
    if (errorString.contains('match')) {
      return 'Passwords do not match';
    }
    if (errorString.contains('required')) {
      return 'This field is required';
    }

    return errorString.replaceAll('Exception: ', '');
  }

  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final message = getErrorMessage(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue[600],
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
