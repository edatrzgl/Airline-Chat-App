import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import '../services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;
  final String flightNumber = "TK101"; // Örnek uçuş numarası

  @override
  void initState() {
    super.initState();
    print("ChatScreen - User: ${user?.uid ?? 'null'}");
  }

  // OpenAI API anahtarı
  final String openAiApiKey =
      "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";

  // Midterm API için token alma
  Future<String> getToken() async {
    try {
      final response = await http.post(
        Uri.parse("http://localhost:5205/api/v1/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": "admin", "password": "admin123"}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["Token"];
      } else {
        throw Exception("Failed to get token: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error in getToken: $e");
      throw Exception("Failed to connect to Midterm API: $e");
    }
  }

  // OpenAI ile mesajı ayrıştırma
  Future<Map<String, dynamic>> parseMessageWithOpenAI(String messageContent, {int retryCount = 5}) async {
    for (int i = 0; i < retryCount; i++) {
      try {
        final response = await http.post(
          Uri.parse("https://api.openai.com/v1/chat/completions"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $openAiApiKey",
          },
          body: jsonEncode({
            "model": "gpt-3.5-turbo",
            "messages": [
              {
                "role": "system",
                "content":
                    "You are a chat parser. Extract intent and parameters from the message. Return JSON with 'intent' and 'parameters' fields. Example: { 'intent': 'flight_query', 'parameters': { 'flightNumber': 'TK101', 'airportFrom': 'IST', 'airportTo': 'JFK' } }"
              },
              {"role": "user", "content": messageContent},
            ],
          }),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return jsonDecode(data["choices"][0]["message"]["content"]);
        } else if (response.statusCode == 429) {
          print("OpenAI rate limit exceeded, retrying after delay... (Attempt ${i + 1}/$retryCount)");
          await Future.delayed(Duration(seconds: 5 * (i + 1)));
          continue;
        } else {
          throw Exception("Failed to parse message with OpenAI: ${response.statusCode}");
        }
      } catch (e) {
        if (i == retryCount - 1) {
          print("Failed to parse message with OpenAI after $retryCount attempts: $e");
          throw Exception("Failed to parse message with OpenAI after $retryCount attempts: $e");
        }
      }
    }
    throw Exception("Failed to parse message with OpenAI after $retryCount attempts");
  }

  // Midterm API’ye istek yapma
  Future<Map<String, dynamic>> callMidtermApi(String intent, Map<String, dynamic> parameters) async {
    final token = await getToken();
    String apiUrl = "";
    Map<String, dynamic> body = {};

    if (intent == "flight_query") {
      apiUrl = "http://localhost:5000/api/gateway/query-flight";
      body = {
        "flightNumber": parameters["flightNumber"] ?? "",
        "airportFrom": parameters["airportFrom"] ?? "",
        "airportTo": parameters["airportTo"] ?? "",
      };
    } else if (intent == "buy_ticket") {
      apiUrl = "http://localhost:5000/api/gateway/buy-ticket";
      body = {
        "flightNumber": parameters["flightNumber"] ?? "",
        "airportFrom": parameters["airportFrom"] ?? "",
        "airportTo": parameters["airportTo"] ?? "",
        "date": parameters["date"] ?? DateTime.now().toIso8601String(),
        "passengerNames": parameters["passengerNames"] ?? ["User"],
      };
    } else if (intent == "check_in") {
      apiUrl = "http://localhost:5000/api/gateway/check-in";
      body = {
        "flightNumber": parameters["flightNumber"] ?? "",
        "airportFrom": parameters["airportFrom"] ?? "",
        "airportTo": parameters["airportTo"] ?? "",
        "date": parameters["date"] ?? DateTime.now().toIso8601String(),
        "passengerName": parameters["passengerName"] ?? "User",
      };
    }

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to call Midterm API: ${response.statusCode}");
    }
  }

  // Mesaj gönder ve işle
  Future<void> sendAndProcessMessage() async {
    print("Controller text: ${_controller.text}");
    if (_controller.text.isEmpty || user == null) {
      print("Cannot send: Empty message or user is null");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to send a message')),
      );
      Navigator.pushReplacementNamed(context, '/');
      return;
    }

    final message = Message(
      id: '',
      flightNumber: flightNumber,
      senderId: user!.uid,
      senderName: user!.displayName ?? 'User',
      content: _controller.text,
      timestamp: DateTime.now(),
    );

    print("Sending message: ${message.content}");
    try {
      final docRef = await _firestore
          .collection('chats')
          .doc(flightNumber)
          .collection('messages')
          .add(message.toFirestore());
      print("Message added with ID: ${docRef.id}");

      try {
        final parsedResult = await parseMessageWithOpenAI(message.content, retryCount: 5);
        final intent = parsedResult["intent"];
        final parameters = parsedResult["parameters"] ?? {};

        final apiResponse = await callMidtermApi(intent, parameters);

        await docRef.update({
          "intent": intent,
          "parameters": parameters,
          "apiResponse": apiResponse,
          "processed": true,
        });
        print("Message processed and updated.");
      } catch (e) {
        if (e.toString().contains("429")) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'OpenAI request limit reached. Please wait a moment and try again.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              duration: Duration(seconds: 5),
            ),
          );
          return;
        } else if (e.toString().contains("Failed to connect to Midterm API")) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to connect to Midterm API. Please ensure the server is running.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              duration: Duration(seconds: 5),
            ),
          );
          return;
        }
        rethrow;
      }

      _controller.clear();
    } catch (e) {
      print("Error in sendAndProcessMessage: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat - Flight $flightNumber'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(flightNumber)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Error loading messages', style: TextStyle(color: Colors.red)),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs
                    .map((doc) => Message.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
                    .toList();
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = user != null && message.senderId == user!.uid;
                    final intent = message.intent ?? 'Unknown';
                    final parameters = message.parameters ?? {};
                    final apiResponse = message.apiResponse ?? {};
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: ListTile(
                        title: Text(isMe ? 'You' : message.senderName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(message.content),
                            if (message.processed == true) ...[
                              const SizedBox(height: 4),
                              Text('Intent: $intent', style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (parameters.isNotEmpty)
                                Text('Parameters: ${parameters.toString()}'),
                              if (apiResponse.isNotEmpty)
                                Text('API Response: ${apiResponse.toString()}'),
                            ],
                          ],
                        ),
                        trailing: Text(
                          '${message.timestamp.hour}:${message.timestamp.minute}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Enter your message...',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        sendAndProcessMessage();
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendAndProcessMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}