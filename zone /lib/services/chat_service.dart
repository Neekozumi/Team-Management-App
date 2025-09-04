import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<MessageModel>> getChannelMessages(String channelId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('*')
          .eq('channel_id', channelId)
          .order('created_at', ascending: true);

      return response.map((json) => MessageModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy tin nhắn: $e');
    }
  }

  Future<void> sendMessage(String channelId, String content) async {
    try {
      await _supabase.from('messages').insert({
        'channel_id': channelId,
        'user_id': _supabase.auth.currentUser!.id,
        'content': content,
      });
    } catch (e) {
      throw Exception('Lỗi khi gửi tin nhắn: $e');
    }
  }

  Stream<List<MessageModel>> subscribeToChannel(String channelId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('channel_id', channelId)
        .order('created_at')
        .map((data) => data.map((json) => MessageModel.fromJson(json)).toList());
  }
}