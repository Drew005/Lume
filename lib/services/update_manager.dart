// update_manager.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateInfo {
  final String version;
  final String releaseName;
  final String releaseNotes;
  final String downloadUrl;
  final bool isPrerelease;
  final bool isDraft;
  final DateTime publishedAt;
  final bool isForced;

  UpdateInfo({
    required this.version,
    required this.releaseName,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.isPrerelease,
    required this.isDraft,
    required this.publishedAt,
    this.isForced = false,
  });

  factory UpdateInfo.fromGitHubRelease(Map<String, dynamic> release) {
    // Extrai a versão do nome da release ou da tag
    final version =
        release['tag_name']?.toString().replaceFirst('v', '') ?? '0.0.0';

    // Encontra o asset APK (para Android)
    String? downloadUrl;
    final assets = release['assets'] as List<dynamic>?;
    if (assets != null && assets.isNotEmpty) {
      for (final asset in assets) {
        if (asset['name'].toString().endsWith('.apk')) {
          downloadUrl = asset['browser_download_url'].toString();
          break;
        }
      }
    }

    return UpdateInfo(
      version: version,
      releaseName: release['name'] ?? 'Nova Atualização',
      releaseNotes: release['body'] ?? 'Melhorias e correções de bugs',
      downloadUrl: downloadUrl ?? '',
      isPrerelease: release['prerelease'] ?? false,
      isDraft: release['draft'] ?? false,
      publishedAt: DateTime.parse(
        release['published_at'] ?? DateTime.now().toIso8601String(),
      ),
      isForced:
          release['isForced'] ??
          false, // Você pode adicionar isso nas notas da release
    );
  }

  bool isNewerThan(String currentVersion) {
    final currentParts = currentVersion.split('.').map(int.parse).toList();
    final newParts = version.split('.').map(int.parse).toList();

    for (int i = 0; i < currentParts.length && i < newParts.length; i++) {
      if (newParts[i] > currentParts[i]) return true;
      if (newParts[i] < currentParts[i]) return false;
    }

    return newParts.length > currentParts.length;
  }
}

class GitHubUpdateChecker {
  static const String _repoOwner = 'Drew005';
  static const String _repoName = 'Lume';
  static const String _releasesUrl =
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases';

  final PackageInfo packageInfo;

  GitHubUpdateChecker(this.packageInfo);

  Future<UpdateInfo?> fetchLatestRelease() async {
    try {
      final response = await http.get(
        Uri.parse(_releasesUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final releases = jsonDecode(response.body) as List<dynamic>;

        // Filtra releases que não são draft ou prerelease
        final stableReleases =
            releases
                .where((r) => r['draft'] == false && r['prerelease'] == false)
                .toList();

        if (stableReleases.isNotEmpty) {
          final latestRelease = stableReleases.first;
          final updateInfo = UpdateInfo.fromGitHubRelease(latestRelease);

          // Verifica se é uma versão mais nova
          if (updateInfo.isNewerThan(packageInfo.version)) {
            return updateInfo;
          }
        }
      } else {
        debugPrint(
          'GitHub API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Failed to fetch GitHub releases: $e');
    }
    return null;
  }
}

class UpdateManager {
  static final ValueNotifier<UpdateInfo?> updateNotifier = ValueNotifier(null);
  static final ValueNotifier<bool> isChecking = ValueNotifier(false);

  static Future<UpdateInfo?> checkForUpdates({bool force = false}) async {
    if (isChecking.value) return null;

    isChecking.value = true;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final checker = GitHubUpdateChecker(packageInfo);
      final updateInfo = await checker.fetchLatestRelease();

      if (updateInfo != null) {
        updateNotifier.value = updateInfo;
        return updateInfo;
      }
      return null;
    } catch (e) {
      debugPrint('Update check failed: $e');
      return null;
    } finally {
      isChecking.value = false;
    }
  }

  static Future<void> downloadUpdate(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Failed to launch download URL: $e');
      rethrow;
    }
  }
}
