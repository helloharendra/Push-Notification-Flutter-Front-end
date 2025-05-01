import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class MessageScreen extends StatefulWidget {
  final RemoteMessage? message;

  const MessageScreen({super.key, this.message});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  RemoteMessage? _message;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get message from arguments if not provided directly
    if (widget.message == null) {
      final message =
          ModalRoute.of(context)?.settings.arguments as RemoteMessage?;
      if (message != null) {
        _message = message;
      }
    } else {
      _message = widget.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Message'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_message?.notification != null) ...[
              Text(
                _message!.notification!.title ?? 'No Title',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                _message!.notification!.body ?? 'No Body',
                style: const TextStyle(fontSize: 18),
              ),
            ] else if (_message?.data.isNotEmpty ?? false) ...[
              const Text(
                'Data Message:',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                _message!.data.toString(),
                style: const TextStyle(fontSize: 18),
              ),
            ] else ...[
              const Text(
                'No message content',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ],
        ),
      ),
    );
  }
}