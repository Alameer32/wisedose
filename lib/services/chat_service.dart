import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a composite index for the chat collection
  Future<bool> createChatIndex() async {
    try {
      // This is a dummy operation to check if the index exists
      // In a real app, you would create the index in the Firebase console
      await _firestore
          .collection('chats')
          .where('senderId', isEqualTo: 'test')
          .where('receiverId', isEqualTo: 'test')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      return true;
    } catch (e) {
      print('Index error: $e');
      // If the error contains a URL to create the index, you can extract and display it
      if (e.toString().contains('https://console.firebase.google.com')) {
        print('Please create the index using the Firebase console');
      }
      return false;
    }
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    final chatMessage = ChatMessage(
      id: '',
      senderId: senderId,
      receiverId: receiverId,
      message: message,
      timestamp: DateTime.now(),
    );

    await _firestore.collection('chats').add(chatMessage.toMap());
  }

  Stream<List<ChatMessage>> getMessages(String userId1, String userId2) {
    try {
      // Create a composite query that works with Firestore
      return _firestore
          .collection('chats')
          .where(Filter.or(
            Filter.and(
              Filter('senderId', isEqualTo: userId1),
              Filter('receiverId', isEqualTo: userId2),
            ),
            Filter.and(
              Filter('senderId', isEqualTo: userId2),
              Filter('receiverId', isEqualTo: userId1),
            ),
          ))
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      print('Error getting messages: $e');
      // Return an empty stream in case of error
      return Stream.value([]);
    }
  }
}
