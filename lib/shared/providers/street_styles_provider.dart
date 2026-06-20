import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/cloudflare/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StyleComment {
  final String id;
  final String styleId;
  final String userId;
  final String username;
  final String comment;
  final DateTime createdAt;

  const StyleComment({
    required this.id,
    required this.styleId,
    required this.userId,
    required this.username,
    required this.comment,
    required this.createdAt,
  });

  factory StyleComment.fromJson(Map<String, dynamic> json) {
    return StyleComment(
      id: json['id'] as String? ?? '',
      styleId: json['style_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      comment: json['comment'] as String? ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'style_id': styleId,
      'user_id': userId,
      'username': username,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class StreetStyle {
  final String id;
  final List<String> images;
  final String username;
  final String location;
  final String description;
  final DateTime createdAt;
  final int likesCount;
  final bool isLiked;
  final List<StyleComment> comments;

  const StreetStyle({
    required this.id,
    required this.images,
    required this.username,
    required this.location,
    required this.description,
    required this.createdAt,
    this.likesCount = 0,
    this.isLiked = false,
    this.comments = const [],
  });

  factory StreetStyle.fromJson(Map<String, dynamic> json) {
    final rawComments = json['comments'] as List? ?? [];
    return StreetStyle(
      id: json['id'] as String,
      images: List<String>.from(json['images'] as List? ?? []),
      username: json['username'] as String? ?? '',
      location: json['location'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      likesCount: json['likes_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      comments: rawComments.map((c) => StyleComment.fromJson(Map<String, dynamic>.from(c as Map))).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'images': images,
      'username': username,
      'location': location,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'likes_count': likesCount,
      'is_liked': isLiked,
      'comments': comments.map((c) => c.toJson()).toList(),
    };
  }

  StreetStyle copyWith({
    String? id,
    List<String>? images,
    String? username,
    String? location,
    String? description,
    DateTime? createdAt,
    int? likesCount,
    bool? isLiked,
    List<StyleComment>? comments,
  }) {
    return StreetStyle(
      id: id ?? this.id,
      images: images ?? this.images,
      username: username ?? this.username,
      location: location ?? this.location,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      comments: comments ?? this.comments,
    );
  }
}

class StreetStylesNotifier extends Notifier<List<StreetStyle>> {
  static const _storageKey = 'cached_street_styles';

  @override
  List<StreetStyle> build() {
    _init();
    return [];
  }

  Future<void> _init() async {
    await _loadStyles();
    await fetchStyles();
  }

  Future<void> _loadStyles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        final List decoded = jsonDecode(jsonStr);
        state = decoded.map((item) => StreetStyle.fromJson(Map<String, dynamic>.from(item))).toList();
      }
    } catch (_) {}
  }

  Future<void> _saveStyles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = state.map((item) => item.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(encoded));
    } catch (_) {}
  }

  Future<void> fetchStyles() async {
    try {
      final response = await ApiClient.instance.get('/api/styles');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data.containsKey('styles')) {
          final List list = data['styles'];
          final styles = list.map((item) => StreetStyle.fromJson(Map<String, dynamic>.from(item))).toList();
          state = styles;
          await _saveStyles();
        }
      }
    } catch (e) {
      // Maintain cached state on failure
    }
  }

  Future<void> likeStyle(String styleId) async {
    // Optimistic local update
    state = state.map((item) {
      if (item.id == styleId) {
        final newIsLiked = !item.isLiked;
        final newLikesCount = newIsLiked ? item.likesCount + 1 : item.likesCount - 1;
        return item.copyWith(isLiked: newIsLiked, likesCount: newLikesCount);
      }
      return item;
    }).toList();
    await _saveStyles();

    try {
      final response = await ApiClient.instance.post('/api/styles/$styleId/like');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map) {
          final isLiked = data['liked'] as bool? ?? false;
          state = state.map((item) {
            if (item.id == styleId) {
              final diff = isLiked ? (item.isLiked ? 0 : 1) : (item.isLiked ? -1 : 0);
              return item.copyWith(isLiked: isLiked, likesCount: item.likesCount + diff);
            }
            return item;
          }).toList();
          await _saveStyles();
        }
      }
    } catch (_) {}
  }

  Future<void> addComment(String styleId, String commentText) async {
    if (commentText.trim().isEmpty) return;

    try {
      final response = await ApiClient.instance.post(
        '/api/styles/$styleId/comment',
        data: {'comment': commentText},
      );
      if (response.statusCode == 201) {
        final data = response.data;
        if (data is Map && data.containsKey('comment')) {
          final newComment = StyleComment.fromJson(
            Map<String, dynamic>.from(data['comment'] as Map),
          );
          
          state = state.map((item) {
            if (item.id == styleId) {
              return item.copyWith(comments: [...item.comments, newComment]);
            }
            return item;
          }).toList();
          await _saveStyles();
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addStyle(StreetStyle style) async {
    try {
      final data = {
        'username': style.username,
        'location': style.location,
        'description': style.description,
        'images': style.images,
      };
      final response = await ApiClient.instance.post('/api/styles', data: data);
      if (response.statusCode == 201) {
        final responseData = response.data;
        if (responseData is Map && responseData.containsKey('id')) {
          final newStyle = StreetStyle(
            id: responseData['id'].toString(),
            images: style.images,
            username: style.username,
            location: style.location,
            description: style.description,
            createdAt: style.createdAt,
            likesCount: 0,
            isLiked: false,
            comments: [],
          );
          state = [newStyle, ...state];
          await _saveStyles();
        }
      } else {
        throw Exception('Failed to add style: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteStyle(String id) async {
    try {
      final response = await ApiClient.instance.delete('/api/styles/$id');
      if (response.statusCode == 200) {
        state = state.where((item) => item.id != id).toList();
        await _saveStyles();
      } else {
        throw Exception('Failed to delete style: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}

final streetStylesProvider = NotifierProvider<StreetStylesNotifier, List<StreetStyle>>(StreetStylesNotifier.new);
