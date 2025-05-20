import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wisedose/services/chat_service.dart';
import 'package:wisedose/utils/app_theme.dart';

class PharmacistChatScreen extends StatefulWidget {
  final String pharmacistId;

  const PharmacistChatScreen({
    super.key,
    required this.pharmacistId,
  });

  @override
  State<PharmacistChatScreen> createState() => _PharmacistChatScreenState();
}

class _PharmacistChatScreenState extends State<PharmacistChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> patients = [];
  String? selectedPatientId;
  String? selectedPatientName;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'patient')
        .get();
    
    setState(() {
      patients = querySnapshot.docs.map((doc) => doc.id).toList();
      if (patients.isNotEmpty) {
        _selectPatient(patients.first);
      }
    });
  }

  Future<void> _selectPatient(String patientId) async {
    final doc = await _firestore.collection('users').doc(patientId).get();
    setState(() {
      selectedPatientId = patientId;
      selectedPatientName = doc.data()?['name'] ?? 'Patient';
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || selectedPatientId == null) {
      return;
    }

    _chatService.sendMessage(
      senderId: widget.pharmacistId,
      receiverId: selectedPatientId!,
      message: _messageController.text.trim(),
    );

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (patients.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        // Patient selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<String>(
            value: selectedPatientId,
            decoration: InputDecoration(
              labelText: 'Select Patient',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: patients.map((patientId) {
              return DropdownMenuItem<String>(
                value: patientId,
                child: FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection('users').doc(patientId).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('Loading...');
                    }
                    final name = snapshot.data?.get('name') ?? 'Patient';
                    return Text(name);
                  },
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                _selectPatient(value);
              }
            },
          ),
        ),

        // Chat messages
        Expanded(
          child: selectedPatientId == null
              ? const Center(
                  child: Text('Select a patient to start chatting'),
                )
              : StreamBuilder<List<ChatMessage>>(
                  stream: _chatService.getMessages(
                    widget.pharmacistId,
                    selectedPatientId!,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    final messages = snapshot.data ?? [];

                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start a conversation with your patient',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId == widget.pharmacistId;

                        return _buildMessageBubble(message, isMe);
                      },
                    );
                  },
                ),
        ),

        // Message input
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                onPressed: _sendMessage,
                mini: true,
                child: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              backgroundColor: AppTheme.secondaryColor,
              child: Text(
                selectedPatientName?.substring(0, 1).toUpperCase() ?? 'P',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isMe ? AppTheme.primaryColor : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.message,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
