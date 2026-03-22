import 'package:flutter/material.dart';
import 'package:paw_stay/utils/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:paw_stay/screens/owner/chat_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final user = Supabase.instance.client.auth.currentUser;
  List<dynamic> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  Future<void> _fetchChats() async {
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      // For a real production app, you'd use a more complex query to get unique conversations.
      // For now, we'll fetch recent messages and group them.
      // This is a simplified version.
      final response = await Supabase.instance.client
          .from('messages')
          .select()
          .or('sender_id.eq.${user!.id},receiver_id.eq.${user!.id}')
          .order('created_at', ascending: false);

      // Logic to group messages into conversations
      final Map<String, dynamic> groupedChats = {};
      for (var chat in (response as List<dynamic>)) {
        final isSender = chat['sender_id'] == user!.id;
        final otherId = isSender ? chat['receiver_id'] : chat['sender_id'];

        // Keep only the most recent message per conversation (already sorted descending)
        if (!groupedChats.containsKey(otherId.toString())) {
          groupedChats[otherId.toString()] = chat;
        }
      }

      setState(() {
        // Render conversations instead of every individual message
        _chats = groupedChats.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Messages',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 32),

              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      )
                    : _chats.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        itemCount: _chats.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, indent: 80),
                        itemBuilder: (context, index) {
                          final chat = _chats[index];
                          final isSender = chat['sender_id'] == user!.id;
                          final otherId = isSender
                              ? chat['receiver_id']
                              : chat['sender_id'];

                          // Read the correct name based on who sent the last message
                          final otherName = isSender
                              ? (chat['receiver_name'] ?? 'User')
                              : (chat['sender_name'] ?? 'User');

                          final otherAvatar =
                              'https://api.dicebear.com/7.x/avataaars/png?seed=$otherId';

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundImage: NetworkImage(otherAvatar),
                            ),
                            title: Text(
                              otherName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textMain,
                              ),
                            ),
                            subtitle: Text(
                              chat['content'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            trailing: Text(
                              DateFormat('HH:mm').format(
                                DateTime.parse(chat['created_at']).toLocal(),
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    otherUserId: otherId,
                                    otherUserName: otherName,
                                    otherUserAvatarUrl: otherAvatar,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.background,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.forum_rounded,
              size: 64,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMain,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Contact hosts to start a conversation',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
