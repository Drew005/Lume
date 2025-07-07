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
  final bool isBeta;

  GitHubUpdateInfo({
    required this.version,
    required this.releaseName,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.isPrerelease,
    required this.isDraft,
    required this.publishedAt,
    this.isForced = false,
    required this.isBeta,
  });

  factory GitHubUpdateInfo.fromJson(Map<String, dynamic> release) {
    // Extrai versão da tag (remove o 'v' prefixado se existir)
    final version =
        release['tag_name']?.toString().replaceFirst('v', '') ?? '0.0.0';
    final isBeta =
        version.contains('beta') ||
        version.contains('alpha') ||
        release['prerelease'] == true;

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
      isBeta: isBeta,
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
    return _compareVersions(version, currentVersion) > 0;
  }

  /// Compara duas versões e retorna:
  /// - 1 se newVersion > currentVersion
  /// - 0 se newVersion == currentVersion
  /// - -1 se newVersion < currentVersion
  static int _compareVersions(String newVersion, String currentVersion) {
    try {
      final newVersionParts = _parseVersion(newVersion);
      final currentVersionParts = _parseVersion(currentVersion);

      // Compara major.minor.patch
      for (int i = 0; i < 3; i++) {
        if (newVersionParts[i] > currentVersionParts[i]) return 1;
        if (newVersionParts[i] < currentVersionParts[i]) return -1;
      }

      // Se as versões principais são iguais, compara os suffixes
      return _comparePrereleaseSuffixes(
        newVersionParts[3],
        currentVersionParts[3],
      );
    } catch (e) {
      debugPrint('Error comparing versions: $e');
      return 0;
    }
  }

  /// Parse uma versão no formato "major.minor.patch-suffix" ou "major.minor.patch"
  /// Retorna [major, minor, patch, suffixPriority]
  static List<int> _parseVersion(String version) {
    // Remove espaços e converte para minúsculas
    final cleanVersion = version.trim().toLowerCase();

    // Separa a versão principal do sufixo (se existir)
    final parts = cleanVersion.split('-');
    final versionPart = parts[0];
    final suffix = parts.length > 1 ? parts[1] : '';

    // Parse da versão principal (major.minor.patch)
    final versionNumbers = versionPart.split('.');
    final major =
        int.tryParse(versionNumbers.isNotEmpty ? versionNumbers[0] : '0') ?? 0;
    final minor =
        int.tryParse(versionNumbers.length > 1 ? versionNumbers[1] : '0') ?? 0;
    final patch =
        int.tryParse(versionNumbers.length > 2 ? versionNumbers[2] : '0') ?? 0;

    // Prioridade do sufixo (menor valor = menor prioridade)
    // alpha < beta < rc < stable
    int suffixPriority = _getSuffixPriority(suffix);

    return [major, minor, patch, suffixPriority];
  }

  /// Retorna a prioridade do sufixo para comparação
  /// Valores menores têm menor prioridade
  static int _getSuffixPriority(String suffix) {
    if (suffix.isEmpty) return 1000; // Versão estável tem prioridade máxima

    if (suffix.startsWith('alpha')) return 100;
    if (suffix.startsWith('beta')) return 200;
    if (suffix.startsWith('rc')) return 300;

    return 150; // Outros sufixos ficam entre alpha e beta
  }

  /// Compara sufixos de pré-lançamento
  static int _comparePrereleaseSuffixes(int newSuffix, int currentSuffix) {
    if (newSuffix > currentSuffix) return 1;
    if (newSuffix < currentSuffix) return -1;
    return 0;
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

  static Future<GitHubUpdateInfo?> checkForUpdates({
    bool includePrerelease = false,
    bool includeDraft = false,
  }) async {
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

        // Filtra releases de acordo com os parâmetros
        final filteredReleases = releases.where((r) {
          if (!includeDraft && r['draft'] == true) return false;
          if (!includePrerelease && r['prerelease'] == true) return false;
          return true;
        }).toList();

        if (filteredReleases.isNotEmpty) {
          final latestRelease = filteredReleases.first;
          final updateInfo = GitHubUpdateInfo.fromJson(latestRelease);

          debugPrint('Current version: ${packageInfo.version}');
          debugPrint('Latest version: ${updateInfo.version}');
          debugPrint(
            'Is newer: ${updateInfo.isNewerThan(packageInfo.version)}',
          );

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
