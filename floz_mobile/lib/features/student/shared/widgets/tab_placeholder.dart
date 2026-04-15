import 'package:flutter/material.dart';

class TabPlaceholder extends StatelessWidget {
  final String title;
  final String message;
  const TabPlaceholder({
    super.key,
    required this.title,
    this.message = 'Fitur ini akan hadir di pembaruan selanjutnya.',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
