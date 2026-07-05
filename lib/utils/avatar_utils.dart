import 'dart:convert';
import 'package:flutter/material.dart';

/// Chuyển field `avatarUrl` (lưu ở Firestore) thành [ImageProvider] để vẽ
/// lên [CircleAvatar]/`Image`. Dùng chung cho mọi màn hình có hiển thị
/// avatar (Profile, Thông tin cá nhân...) để tránh mỗi nơi tự viết 1 kiểu.
///
/// [avatarUrl] có thể là:
///   • URL ảnh thật (bắt đầu bằng "http") -> [NetworkImage]
///   • Ảnh chọn từ thiết bị, lưu dạng base64 ("data:image/...;base64,...")
///     -> [MemoryImage]
///   • null / rỗng / không hợp lệ -> trả về null (nơi gọi tự vẽ fallback,
///     VD chữ cái đầu tên).
ImageProvider? resolveAvatarImage(String? avatarUrl) {
  final url = avatarUrl?.trim();
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('data:image')) {
    try {
      final base64Str = url.substring(url.indexOf(',') + 1);
      return MemoryImage(base64Decode(base64Str));
    } catch (_) {
      return null;
    }
  }
  if (url.startsWith('http')) return NetworkImage(url);
  return null;
}
