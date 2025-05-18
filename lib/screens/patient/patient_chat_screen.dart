import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wisedose/services/chat_service.dart';
import 'package:wisedose/utils/app_theme.dart';

class PatientChatScreen extends StatefulWidget {
  final String patientId;

  const PatientChatScreen({
    Key? key,
    required this.patientId,
  }) : super(key: key);

  @override
  State<PatientChatScreen> createState() => _PatientChatScreenState();
}

class _PatientChatScreenState extends State<PatientChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> pharmacists = [];
  String? selectedPharmacistId;
  String? selectedPharmacistName;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPharmacists();
  }

  Future<void> _loadPharmacists() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'pharmacist')
          .get();
      
      final pharmacistsList = querySnapshot.docs.map((doc) => doc.id).toList();
      
      setState(() {
        pharmacists = pharmacistsList;
        _isLoading = false;
        
        if (pharmacists.isNotEmpty) {
          _selectPharmacist(pharmacists.first);
        } else {
          _errorMessage = 'No pharmacists available';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load pharmacists: $e';
      });
    }
  }

  Future<void> _selectPharmacist(String pharmacistId) async {
    try {
      final doc = await _firestore.collection('users').doc(pharmacistId).get();
      setState(() {
        selectedPharmacistId = pharmacistId;
        selectedPharmacistName = doc.data()?['name'] ?? 'Pharmacist';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to select pharmacist: $e';
      });
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || selectedPharmacistId == null) {
      return;
    }

    _chatService.sendMessage(
      senderId: widget.patientId,
      receiverId: selectedPharmacistId!,
      message: _messageController.text.trim(),
    );

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPharmacists,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (pharmacists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No Pharmacists Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no pharmacists available to chat with at the moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Pharmacist selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<String>(
            value: selectedPharmacistId,
            decoration: InputDecoration(
              labelText: 'Select Pharmacist',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: pharmacists.map((pharmacistId) {
              return DropdownMenuItem<String>(
                value: pharmacistId,
                child: FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection('users').doc(pharmacistId).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('Loading...');
                    }
                    final name = snapshot.data?.get('name') ?? 'Pharmacist';
                    return Text(name);
                  },
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                _selectPharmacist(value);
              }
            },
          ),
        ),

        // Chat messages
        Expanded(
          child: selectedPharmacistId == null
              ? const Center(
                  child: Text('Select a pharmacist to start chatting'),
                )
              : FutureBuilder<bool>(
                  future: _chatService.createChatIndex(),
                  builder: (context, indexSnapshot) {
                    if (indexSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    
                    return StreamBuilder<List<ChatMessage>>(
                      stream: _chatService.getMessages(
                        widget.patientId,
                        selectedPharmacistId!,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error loading messages: ${snapshot.error}',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {});
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
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
                                  'Start a conversation with your pharmacist',
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
                            final isMe = message.senderId == widget.patientId;

                            return _buildMessageBubble(message, isMe);
                          },
                        );
                      },
                    );
                  }
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
                selectedPharmacistName?.substring(0, 1).toUpperCase() ?? 'P',
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
