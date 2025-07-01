import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:lume/services/theme_manager.dart';
import 'package:flutter/services.dart' show rootBundle;

class OnboardingPage extends StatefulWidget {
  final Function() onAccept;

  const OnboardingPage({super.key, required this.onAccept});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late Future<String> _termsFuture;
  late Future<String> _privacyFuture;
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _termsFuture = rootBundle.loadString('assets/TERMS.md');
    _privacyFuture = rootBundle.loadString('assets/PRIVACY.md');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading:
            _currentPage > 0
                ? IconButton(
                  icon: const Icon(CupertinoIcons.chevron_back),
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                )
                : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  // Página 1: Boas-vindas
                  _buildWelcomePage(theme),
                  // Página 2: Termos de Uso
                  _buildTermsPage(theme, isDark),
                  // Página 3: Política de Privacidade
                  _buildPrivacyPage(theme, isDark),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              _currentPage == index
                                  ? ThemeManager.accentColor
                                  : theme.dividerColor,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _currentPage < 2
                              ? () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                              : (_termsAccepted && _privacyAccepted)
                              ? () {
                                widget.onAccept();
                              }
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _currentPage < 2
                                ? ThemeManager.accentColor
                                : (_termsAccepted && _privacyAccepted)
                                ? ThemeManager.accentColor
                                : Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        _currentPage < 2 ? 'Continuar' : 'Começar a usar',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: ThemeManager.accentColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ThemeManager.accentColor.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Bem-vindo ao Lume',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'O aplicativo perfeito para organizar suas notas e tarefas do dia a dia',
            style: TextStyle(
              fontSize: 16,
              color: theme.textTheme.bodyMedium?.color,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.note_alt_outlined, color: theme.primaryColor),
              const SizedBox(width: 16),
              Icon(Icons.check_circle_outline, color: theme.primaryColor),
              const SizedBox(width: 16),
              Icon(Icons.category_outlined, color: theme.primaryColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTermsPage(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Termos de Uso',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<String>(
              future: _termsFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Markdown(
                    data: snapshot.data!,
                    styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                      p: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color,
                        height: 1.5,
                      ),
                      h1: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                      h2: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                      a: TextStyle(color: ThemeManager.accentColor),
                    ),
                    shrinkWrap: true,
                  );
                } else if (snapshot.hasError) {
                  return Text('Erro ao carregar os termos: ${snapshot.error}');
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _termsAccepted,
                onChanged: (value) {
                  setState(() => _termsAccepted = value ?? false);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                  if (states.contains(MaterialState.selected)) {
                    return ThemeManager.accentColor;
                  }
                  return Colors.transparent;
                }),
              ),
              const SizedBox(width: 8),
              Text(
                'Eu li e aceito os Termos de Uso',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPage(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Política de Privacidade',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<String>(
              future: _privacyFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Markdown(
                    data: snapshot.data!,
                    styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                      p: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color,
                        height: 1.5,
                      ),
                      h1: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                      h2: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                      a: TextStyle(color: ThemeManager.accentColor),
                    ),
                    shrinkWrap: true,
                  );
                } else if (snapshot.hasError) {
                  return Text('Erro ao carregar a política: ${snapshot.error}');
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _privacyAccepted,
                onChanged: (value) {
                  setState(() => _privacyAccepted = value ?? false);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                  if (states.contains(MaterialState.selected)) {
                    return ThemeManager.accentColor;
                  }
                  return Colors.transparent;
                }),
              ),
              const SizedBox(width: 8),
              Text(
                'Eu li e aceito a Política de Privacidade',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
