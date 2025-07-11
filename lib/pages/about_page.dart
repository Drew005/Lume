import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:lume/services/theme_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final version = '1.0.0';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Sobre o Aplicativo'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Logo e Nome do App
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      //color: ThemeManager.accentColor.withOpacity(0.1),
                      //shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage('assets/icon/icon_app.png'),
                        fit: BoxFit.contain,
                        colorFilter: ColorFilter.mode(
                          ThemeManager.accentColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(
                          'Versão ${snapshot.data!.version}${snapshot.data!.buildNumber.isNotEmpty ? '+${snapshot.data!.buildNumber}' : ''}',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey[600],
                          ),
                        );
                      }
                      return Text(
                        'Versão ...',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Seção de Informações
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Desenvolvedor
                  ListTile(
                    leading: Icon(
                      Icons.code,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    title: Text(
                      'Desenvolvedor',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    subtitle: Text(
                      'Drewen',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Colors.grey),

                  // Termos de Uso
                  ListTile(
                    leading: Icon(
                      Icons.description,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    title: Text(
                      'Termos de Uso',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    trailing: Icon(
                      CupertinoIcons.chevron_right,
                      color: Colors.grey[600],
                      size: 16,
                    ),
                    onTap: () => _showMarkdownDialog(
                      context,
                      'assets/TERMS.md',
                      'Termos de Uso',
                    ),
                    //_launchUrl('https://seusite.com/termos'),
                  ),
                  const Divider(height: 1, color: Colors.grey),

                  // Política de Privacidade
                  ListTile(
                    leading: Icon(
                      Icons.privacy_tip,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    title: Text(
                      'Política de Privacidade',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    trailing: Icon(
                      CupertinoIcons.chevron_right,
                      color: Colors.grey[600],
                      size: 16,
                    ),
                    onTap: () => _showMarkdownDialog(
                      context,
                      'assets/PRIVACY.md',
                      'Política de Privacidade',
                    ),
                    //_launchUrl('https://seusite.com/privacidade'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Redes Sociais
            Text(
              'Nos siga nas redes sociais',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.mail),
                  color: Theme.of(context).iconTheme.color,
                  onPressed: () =>
                      _launchUrl(context, 'mailto:suporte.lume@protonmail.com'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Direitos autorais
            Text(
              '© ${DateTime.now().year} Lume. Todos os direitos reservados.',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    bool launched = false;

    if (url.startsWith('mailto:')) {
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(uri);
      }

      if (!launched) {
        await _handleMailtoFallback(context, url);
      }
    } else {
      // Para URLs normais
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _handleMailtoFallback(BuildContext context, String url) async {
    final email = url.replaceFirst('mailto:', '').split('?').first;
    try {
      final gmailUri = Uri.parse('googlegmail:///co?to=$email');
      if (await canLaunchUrl(gmailUri)) {
        await launchUrl(gmailUri);
        return;
      }
    } catch (_) {}
    await Clipboard.setData(ClipboardData(text: email));
  }

  void _showMarkdownDialog(
    BuildContext context,
    String filePath,
    String title,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: FutureBuilder<String>(
                    future: rootBundle.loadString(filePath),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Markdown(
                            data: snapshot.data!,
                            styleSheet:
                                MarkdownStyleSheet.fromTheme(
                                  Theme.of(context),
                                ).copyWith(
                                  p: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                                    height: 1.5,
                                  ),
                                  h1: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.titleLarge?.color,
                                  ),
                                  h2: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.titleLarge?.color,
                                  ),
                                  a: TextStyle(color: ThemeManager.accentColor),
                                ),
                            shrinkWrap: false,
                            onTapLink: (text, href, title) {
                              if (href != null) {
                                _launchUrl(context, href);
                              }
                            },
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Erro ao carregar o conteúdo: ${snapshot.error}',
                          ),
                        );
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
                const Divider(height: 1),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fechar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
