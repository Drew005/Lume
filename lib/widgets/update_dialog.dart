import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:lume/services/update_manager.dart';
import 'package:lume/services/theme_manager.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;
  final VoidCallback? onUpdateStarted;
  final VoidCallback? onUpdateSkipped;
  final VoidCallback? onUpdateLater;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    this.onUpdateStarted,
    this.onUpdateSkipped,
    this.onUpdateLater,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuint),
        );

    _scaleController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    if (widget.updateInfo.isBeta) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text("Versão Beta"),
            content: const Text(
              "Esta é uma versão de testes. Pode conter bugs.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("ENTENDI"),
              ),
            ],
          ),
        );
      });
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: 500, // Adiciona largura máxima para melhor aparência
            ),
            child: Material(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header fixo
                  _buildHeader(isDark),

                  // Conteúdo scrollável
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildContent(isDark),
                    ),
                  ),

                  // Actions fixas
                  _buildActions(isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ThemeManager.accentColor.withOpacity(0.1),
            ThemeManager.accentColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ThemeManager.accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Symbols.system_update,
              color: ThemeManager.accentColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.updateInfo.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Versão ${widget.updateInfo.version}',
                  style: TextStyle(
                    fontSize: 14,
                    color: ThemeManager.accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final styleSheet = MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: TextStyle(
        fontSize: 16,
        height: 1.5,
        color: isDark ? Colors.white70 : Colors.grey[700],
      ),
      h1: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black,
      ),
      h2: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black,
      ),
      h3: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black,
      ),
      a: TextStyle(
        color: ThemeManager.accentColor,
        decoration: TextDecoration.underline,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),

        // Descrição principal
        MarkdownBody(
          data: widget.updateInfo.description,
          styleSheet: styleSheet,
          shrinkWrap: true,
        ),

        const SizedBox(height: 24),

        // Novos recursos
        if (widget.updateInfo.features.isNotEmpty) ...[
          _buildSection(
            title: '✨ Novos Recursos',
            items: widget.updateInfo.features,
            isDark: isDark,
            style: styleSheet,
          ),
          const SizedBox(height: 20),
        ],

        // Melhorias
        if (widget.updateInfo.improvements.isNotEmpty) ...[
          _buildSection(
            title: '🚀 Melhorias',
            items: widget.updateInfo.improvements,
            isDark: isDark,
            style: styleSheet,
          ),
          const SizedBox(height: 20),
        ],

        // Correções de bugs
        if (widget.updateInfo.bugFixes.isNotEmpty) ...[
          _buildSection(
            title: '🐛 Correções',
            items: widget.updateInfo.bugFixes,
            isDark: isDark,
            style: styleSheet,
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<String> items,
    required bool isDark,
    required MarkdownStyleSheet style,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.grey[700],
                            height: 1.6,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.grey[700],
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          if (widget.updateInfo.isForced)
            _buildForcedUpdateActions(isDark)
          else
            _buildOptionalUpdateActions(isDark),

          const SizedBox(height: 12),

          Text(
            'Lançado em ${_formatDate(widget.updateInfo.releaseDate)}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForcedUpdateActions(bool isDark) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              widget.onUpdateStarted?.call();
              try {
                UpdateManager.downloadUpdate(widget.updateInfo.downloadUrl);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao iniciar atualização: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeManager.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Symbols.download, size: 20),
                SizedBox(width: 8),
                Text(
                  'Atualizar Agora',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Esta é uma atualização obrigatória para continuar usando o aplicativo.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOptionalUpdateActions(bool isDark) {
    final hasUpdate = widget.updateInfo.downloadUrl.isNotEmpty;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: hasUpdate
                ? () {
                    widget.onUpdateStarted?.call();
                    UpdateManager.downloadUpdate(widget.updateInfo.downloadUrl);
                    Navigator.of(context).pop();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: hasUpdate
                  ? ThemeManager.accentColor
                  : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Symbols.download, size: 20),
                const SizedBox(width: 8),
                Text(
                  hasUpdate ? 'Atualizar Agora' : 'Você está atualizado',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (hasUpdate) ...[
          TextButton(
            onPressed: () {
              widget.onUpdateLater?.call();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Mais Tarde',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey[600],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }
}

/// Método utilitário para mostrar o dialog de atualização
class UpdateDialogHelper {
  static void showUpdateDialog(
    BuildContext context,
    UpdateInfo updateInfo, {
    VoidCallback? onUpdate,
    VoidCallback? onSkip,
    VoidCallback? onLater,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !updateInfo.isForced,
      builder: (context) => UpdateDialog(
        updateInfo: updateInfo,
        onUpdateStarted: onUpdate,
        onUpdateSkipped: onSkip,
        onUpdateLater: onLater,
      ),
    );
  }
}

class UpdateInfo {
  final String title;
  final String version;
  final String description;
  final List<String> features;
  final List<String> improvements;
  final List<String> bugFixes;
  final bool isForced;
  final String downloadUrl;
  final DateTime releaseDate;
  final bool isBeta;

  const UpdateInfo({
    required this.title,
    required this.version,
    required this.description,
    required this.features,
    required this.improvements,
    required this.bugFixes,
    required this.isForced,
    required this.downloadUrl,
    required this.releaseDate,
    this.isBeta = false,
  });
}
