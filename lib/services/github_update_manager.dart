import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class GitHubUpdateInfo {
  final String version;
  final String releaseName;
  final String releaseNotes;
  final String downloadUrl;
  final bool isPrerelease;
  final bool isDraft;
  final DateTime publishedAt;
  final bool isForced;

  GitHubUpdateInfo({
    required this.version,
    required this.releaseName,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.isPrerelease,
    required this.isDraft,
    required this.publishedAt,
    this.isForced = false,
  });

  factory GitHubUpdateInfo.fromJson(Map<String, dynamic> release) {
    // Extrai versão da tag (remove o 'v' prefixado se existir)
    final version =
        release['tag_name']?.toString().replaceFirst('v', '') ?? '0.0.0';

    // Encontra o asset APK para download
    String? downloadUrl;
    final assets = release['assets'] as List<dynamic>?;
    if (assets != null) {
      for (final asset in assets) {
        if (asset['name'].toString().endsWith('.apk')) {
          downloadUrl = asset['browser_download_url'].toString();
          break;
        }
      }
    }

    // Verifica se é uma atualização forçada (procura por [FORCE] no título)
    final isForced =
        (release['name']?.toString().contains('[FORCE]') ?? false) ||
        (release['body']?.toString().contains('[FORCE]') ?? false);

    return GitHubUpdateInfo(
      version: version,
      releaseName: release['name'] ?? 'Nova Atualização Disponível',
      releaseNotes: release['body'] ?? 'Melhorias e correções de bugs',
      downloadUrl: downloadUrl ?? '',
      isPrerelease: release['prerelease'] ?? false,
      isDraft: release['draft'] ?? false,
      publishedAt: DateTime.parse(
        release['published_at'] ?? DateTime.now().toIso8601String(),
      ),
      isForced: isForced,
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

class GitHubUpdateManager {
  static const String _repoOwner = 'Drew005';
  static const String _repoName = 'Lume';
  static const String _releasesUrl =
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases';

  static final ValueNotifier<GitHubUpdateInfo?> updateNotifier = ValueNotifier(
    null,
  );
  static final ValueNotifier<bool> isChecking = ValueNotifier(false);

  static Future<GitHubUpdateInfo?> checkForUpdates() async {
    if (isChecking.value) return null;

    isChecking.value = true;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final response = await http.get(
        Uri.parse(_releasesUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final releases = jsonDecode(response.body) as List<dynamic>;

        // Filtra releases estáveis (não draft e não prerelease)
        final stableReleases =
            releases
                .where((r) => r['draft'] == false && r['prerelease'] == false)
                .toList();

        if (stableReleases.isNotEmpty) {
          final latestRelease = stableReleases.first;
          final updateInfo = GitHubUpdateInfo.fromJson(latestRelease);

          if (updateInfo.isNewerThan(packageInfo.version)) {
            updateNotifier.value = updateInfo;
            return updateInfo;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao verificar atualizações: $e');
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
      debugPrint('Erro ao baixar atualização: $e');
      rethrow;
    }
  }
}
