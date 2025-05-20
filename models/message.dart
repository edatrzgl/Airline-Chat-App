import 'package:cloud_firestore/cloud_firestore.dart';
class Message {
  final String id;
  final String flightNumber;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final String? intent;
  final Map<String, dynamic>? parameters;
  final Map<String, dynamic>? apiResponse;
  final bool? processed;

  Message({
    required this.id,
    required this.flightNumber,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.intent,
    this.parameters,
    this.apiResponse,
    this.processed,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'flightNumber': flightNumber,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': timestamp,
      'intent': intent,
      'parameters': parameters,
      'apiResponse': apiResponse,
      'processed': processed,
    };
  }

  static Message fromFirestore(Map<String, dynamic> data, String id) {
    return Message(
      id: id,
      flightNumber: data['flightNumber'],
      senderId: data['senderId'],
      senderName: data['senderName'],
      content: data['content'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      intent: data['intent'],
      parameters: data['parameters'],
      apiResponse: data['apiResponse'],
      processed: data['processed'],
    );
  }
}