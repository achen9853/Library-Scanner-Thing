import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:web_socket_channel/io.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keyboard Input Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: InputScreen(),
    );
  }
}

class InputScreen extends StatefulWidget {
  @override
  _InputScreenState createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  String _inputText = "";
  FocusNode _focusNode = FocusNode();
  WebSocketService _webSocketService = WebSocketService();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _webSocketService.connect(); // Connect to WebSocket
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      setState(() {
        if (event.logicalKey == LogicalKeyboardKey.enter) {
          _showConfirmationDialog();
        } else {
          _inputText += event.logicalKey.keyLabel;
        }
      });
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Input'),
          content: Text('You entered: $_inputText'),
          actions: <Widget>[
            TextButton(
              child: Text('Confirm'),
              onPressed: () {
                _webSocketService.sendMessage(_inputText); // Send message to WebSocket
                Navigator.of(context).pop(); // Close the dialog
                _clearInput(); // Clear input after confirming
              },
            ),
            TextButton(
              child: Text('Deny'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _clearInput(); // Clear the input to allow rescanning
              },
            ),
          ],
        );
      },
    );
  }

  void _addInput(String input) {
    setState(() {
      _inputText += input;
    });
  }

  void _clearInput() {
    setState(() {
      _inputText = "";
    });
  }

  @override
  void dispose() {
    _webSocketService.disconnect(); // Disconnect on dispose
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Library Sign-In'),
      ),
      body: Column(
        children: [
          Expanded(
            child: RawKeyboardListener(
              focusNode: _focusNode,
              onKey: _handleKeyPress,
              autofocus: true,
              child: Center(
                child: Text(
                  _inputText.isEmpty ? 'Awaiting input...' : 'You typed: $_inputText',
                  style: TextStyle(fontSize: 30),
                ),
              ),
            ),
          ),
          NumericKeypad(
            onInput: _addInput,
            onClear: _clearInput,
            onEnter: _showConfirmationDialog, // Show dialog on Enter
          ),
        ],
      ),
    );
  }
}

class NumericKeypad extends StatelessWidget {
  final Function(String) onInput;
  final VoidCallback onClear;
  final VoidCallback onEnter;

  NumericKeypad({required this.onInput, required this.onClear, required this.onEnter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['1', '2', '3'].map((digit) {
              return _buildKey(digit);
            }).toList(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['4', '5', '6'].map((digit) {
              return _buildKey(digit);
            }).toList(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['7', '8', '9'].map((digit) {
              return _buildKey(digit);
            }).toList(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('0'),
              ElevatedButton(
                onPressed: onClear,
                child: Text('Clear'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: Size(100, 50),
                ),
              ),
              ElevatedButton(
                onPressed: onEnter,
                child: Text('Enter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: Size(100, 50),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String label) {
    return ElevatedButton(
      onPressed: () => onInput(label),
      child: Text(label),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(70, 70),
      ),
    );
  }
}

// WebSocket Service
class WebSocketService {
  late IOWebSocketChannel channel;

  void connect() {
    // Connect to the WebSocket server
    channel = IOWebSocketChannel.connect(Uri.parse('ws://127.0.0.1:5000/socket.io/websocket'));

    channel.stream.listen((message) {
      // Handle incoming messages from the server
      print('Received: $message');
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket closed');
    });
  }

  void sendMessage(String message) {
    if (channel != null && channel.sink != null) {
      channel.sink.add(message);
    }
  }

  void disconnect() {
    channel.sink.close();
  }
}
