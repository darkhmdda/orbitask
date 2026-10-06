import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/orbitask_profile.dart';

class ProfileService {
  ProfileService(this._client);

  static const String avatarBucket = 'profile-avatars';

  final SupabaseClient? _client;

  bool get isConfigured => _client != null;

  Future<OrbitaskProfile?> loadCurrentProfile() async {
    final client = _requireClient();
    final user = client.auth.currentUser;
    if (user == null) return null;

    final rows = await client
        .from('profiles')
        .select('id, display_name, username, avatar_path')
        .eq('id', user.id)
        .limit(1);

    if (rows.isEmpty) {
      return OrbitaskProfile(id: user.id);
    }

    final row = rows.first;
    final avatarPath = row['avatar_path'] as String?;
    return OrbitaskProfile(
      id: row['id'] as String,
      displayName: row['display_name'] as String?,
      username: row['username'] as String?,
      avatarPath: avatarPath,
      avatarUrl: avatarPath == null || avatarPath.isEmpty
          ? null
          : client.storage.from(avatarBucket).getPublicUrl(avatarPath),
    );
  }

  Future<OrbitaskProfile> updateProfile({
    required String rawDisplayName,
    required String rawUsername,
  }) async {
    final client = _requireClient();
    final user = _requireUser(client);
    final displayName = rawDisplayName.trim();
    final username = rawUsername.trim().toLowerCase();

    if (displayName.length > 40) {
      throw const FormatException(
        'El nombre visible no puede superar los 40 caracteres.',
      );
    }

    if (!RegExp(r'^[a-z0-9_]{3,24}

  Future<OrbitaskProfile> uploadAvatar({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final client = _requireClient();
    final user = _requireUser(client);

    if (bytes.length > 3 * 1024 * 1024) {
      throw const FormatException(
        'La imagen supera el límite de 3 MB.',
      );
    }

    if (!{'image/jpeg', 'image/png', 'image/webp'}.contains(mimeType)) {
      throw const FormatException(
        'Usa una imagen JPG, PNG o WEBP.',
      );
    }

    final previousProfile = await loadCurrentProfile();
    final previousPath = previousProfile?.avatarPath;
    final path =
        '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}';

    await client.storage.from(avatarBucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        upsert: true,
        contentType: mimeType,
        cacheControl: '3600',
      ),
    );

    await client
        .from('profiles')
        .update({
          'avatar_path': path,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', user.id);

    if (previousPath != null &&
        previousPath.isNotEmpty &&
        previousPath != path) {
      await client.storage.from(avatarBucket).remove([previousPath]);
    }

    final profile = await loadCurrentProfile();
    return profile ?? OrbitaskProfile(
      id: user.id,
      avatarPath: path,
      avatarUrl: client.storage.from(avatarBucket).getPublicUrl(path),
    );
  }

  Future<OrbitaskProfile> removeAvatar() async {
    final client = _requireClient();
    final user = _requireUser(client);
    final profile = await loadCurrentProfile();
    final path = profile?.avatarPath;

    if (path != null && path.isNotEmpty) {
      await client.storage.from(avatarBucket).remove([path]);
    }

    await client
        .from('profiles')
        .update({
          'avatar_path': null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', user.id);

    return OrbitaskProfile(
      id: user.id,
      displayName: profile?.displayName,
      username: profile?.username,
    );
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase no está configurado.');
    }
    return client;
  }

  User _requireUser(SupabaseClient client) {
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('No hay una sesión iniciada.');
    }
    return user;
  }
}
).hasMatch(username)) {
      throw const FormatException(
        'El username debe tener entre 3 y 24 caracteres y usar solo letras minúsculas, números o guion bajo.',
      );
    }

    await client
        .from('profiles')
        .update({
          'display_name': displayName.isEmpty ? null : displayName,
          'username': username,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', user.id);

    final profile = await loadCurrentProfile();
    return profile ??
        OrbitaskProfile(
          id: user.id,
          displayName: displayName.isEmpty ? null : displayName,
          username: username,
        );
  }

  Future<OrbitaskProfile> updateUsername(String rawUsername) async {
    final current = await loadCurrentProfile();
    return updateProfile(
      rawDisplayName: current?.displayName ?? '',
      rawUsername: rawUsername,
    );
  }

  Future<OrbitaskProfile> uploadAvatar({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final client = _requireClient();
    final user = _requireUser(client);

    if (bytes.length > 3 * 1024 * 1024) {
      throw const FormatException(
        'La imagen supera el límite de 3 MB.',
      );
    }

    if (!{'image/jpeg', 'image/png', 'image/webp'}.contains(mimeType)) {
      throw const FormatException(
        'Usa una imagen JPG, PNG o WEBP.',
      );
    }

    final previousProfile = await loadCurrentProfile();
    final previousPath = previousProfile?.avatarPath;
    final path =
        '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}';

    await client.storage.from(avatarBucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        upsert: true,
        contentType: mimeType,
        cacheControl: '3600',
      ),
    );

    await client
        .from('profiles')
        .update({
          'avatar_path': path,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', user.id);

    if (previousPath != null &&
        previousPath.isNotEmpty &&
        previousPath != path) {
      await client.storage.from(avatarBucket).remove([previousPath]);
    }

    final profile = await loadCurrentProfile();
    return profile ?? OrbitaskProfile(
      id: user.id,
      avatarPath: path,
      avatarUrl: client.storage.from(avatarBucket).getPublicUrl(path),
    );
  }

  Future<OrbitaskProfile> removeAvatar() async {
    final client = _requireClient();
    final user = _requireUser(client);
    final profile = await loadCurrentProfile();
    final path = profile?.avatarPath;

    if (path != null && path.isNotEmpty) {
      await client.storage.from(avatarBucket).remove([path]);
    }

    await client
        .from('profiles')
        .update({
          'avatar_path': null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', user.id);

    return OrbitaskProfile(
      id: user.id,
      displayName: profile?.displayName,
      username: profile?.username,
    );
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase no está configurado.');
    }
    return client;
  }

  User _requireUser(SupabaseClient client) {
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('No hay una sesión iniciada.');
    }
    return user;
  }
}
