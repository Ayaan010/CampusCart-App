import 'package:flutter/material.dart';

class NoInternetDialog extends StatelessWidget {
  final VoidCallback onRetry;
  final bool isRetrying;

  const NoInternetDialog({
    super.key,
    required this.onRetry,
    required this.isRetrying,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.signal_wifi_off,
              color: Color(0xFF2D3250),
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              'No Internet Connection',
              style: TextStyle(
                color: Color(0xFF2D3250),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please check your internet connection and try again.',
              style: TextStyle(fontSize: 16),
            ),
            if (isRetrying) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D3250)),
                strokeWidth: 3,
              ),
            ],
          ],
        ),
        actions: [
          if (!isRetrying)
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D3250),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
