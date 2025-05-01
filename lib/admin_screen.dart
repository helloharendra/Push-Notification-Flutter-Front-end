import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  List<String> tokens = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    if (tokens.isEmpty) {
      setState(() {
        _errorMessage = "Please add at least one device token";
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await http
          .post(
            Uri.parse('http://0.0.0.0:3000/notifications/send'),
            headers: {
              'Content-Type': 'application/json',
              'accept': 'application/json',
            },
            body: jsonEncode({
              'token': tokens,
              'title': _titleController.text,
              'body': _bodyController.text,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData['success'] == true) {
          setState(() {
            _successMessage = 'Notification sent successfully!';
            _titleController.clear();
            _bodyController.clear();
            tokens = [];
          });
        } else {
          setState(() {
            _errorMessage =
                responseData['error'] ?? 'Failed to send notification';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
        });
      }
    } on SocketException catch (e) {
      setState(() {
        _errorMessage = 'Network error: Could not connect to server. '
            'Make sure the server is running and accessible.';
      });
    } on http.ClientException catch (e) {
      setState(() {
        _errorMessage = 'Connection error: ${e.message}';
      });
    } on TimeoutException catch (e) {
      setState(() {
        _errorMessage = 'Request timed out. Server is not responding.';
      });
    } on FormatException catch (e) {
      setState(() {
        _errorMessage = 'Data format error: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addToken() {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;

    // Basic validation for FCM token format
    if (!token.contains(':') || token.length < 50) {
      setState(() {
        _errorMessage = 'Token format appears invalid';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      tokens.add(token);
      _tokenController.clear();
      _errorMessage = null;
    });
  }

  void _removeToken(int index) {
    setState(() {
      tokens.removeAt(index);
    });
  }

  void _clearAll() {
    setState(() {
      _titleController.clear();
      _bodyController.clear();
      _tokenController.clear();
      tokens.clear();
      _errorMessage = null;
      _successMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Notification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearAll,
            tooltip: 'Clear all',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Success Message
                if (_successMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ),
                  ),

                // Error Message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
                  ),

                // Title Field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    hintText: 'Enter notification title',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Body Field
                TextFormField(
                  controller: _bodyController,
                  decoration: const InputDecoration(
                    labelText: 'Message Body',
                    border: OutlineInputBorder(),
                    hintText: 'Enter notification message',
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a message';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Token Input
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tokenController,
                        decoration: const InputDecoration(
                          labelText: 'Device Token',
                          border: OutlineInputBorder(),
                          hintText: 'Enter FCM device token',
                        ),
                        onFieldSubmitted: (_) => _addToken(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      onPressed: _addToken,
                      tooltip: 'Add token',
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Tokens List
                const Text(
                  'Target Devices:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),

                if (tokens.isEmpty)
                  const Text(
                    'No devices added yet',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        for (int i = 0; i < tokens.length; i++)
                          ListTile(
                            title: Text(
                              tokens[i],
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeToken(i),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            '${tokens.length} device(s) added',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Send Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: _isLoading ? null : _sendNotification,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'SEND NOTIFICATION',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
