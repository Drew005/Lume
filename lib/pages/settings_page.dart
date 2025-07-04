import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:lume/pages/about_page.dart';
import 'package:lume/pages/blank_page.dart';
import 'package:lume/services/theme_manager.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _formatName(String format) {
    switch (format) {
      case 'd \'de\' MMM y':
        return 'Brasileiro';
      case 'MMMM d, y':
        return 'Internacional';
      case 'HH:mm':
        return '24h';
      case 'h:mm a':
        return 'AM/PM';
      default:
        return format;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aparência',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Opção de tema com três estados
                    ListTile(
                      leading: Icon(
                        _getThemeIcon(),
                        color: Theme.of(context).iconTheme.color,
                      ),
                      title: Text(
                        'Tema',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      subtitle: Text(
                        _getThemeText(),
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      trailing: Icon(
                        CupertinoIcons.chevron_right,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                      onTap: () => _showThemeSelector(context),
                    ),
                    const Divider(height: 1, color: Colors.grey),

                    ListTile(
                      leading: Icon(
                        CupertinoIcons.paintbrush,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      title: Text(
                        'Cor de Destaque',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      trailing: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: ThemeManager.accentColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onTap: () => _showColorPicker(context),
                    ),
                    const Divider(height: 1, color: Colors.grey),

                    ListTile(
                      leading: Icon(
                        CupertinoIcons.calendar,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      title: Text(
                        'Formato de data',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      subtitle: FutureBuilder<String>(
                        future: DateFormatManager.getDateFormat(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final dateFormat = snapshot.data!;
                            return Text(
                              _formatName(dateFormat),
                              style: TextStyle(
                                color:
                                    isDark ? Colors.white70 : Colors.grey[600],
                                fontSize: 12,
                              ),
                            );
                          }
                          return Text(
                            'Carregando...',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.grey[600],
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                      trailing: Icon(
                        CupertinoIcons.chevron_right,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                      onTap: () => _showDateFormatSelector(context),
                    ),
                    const Divider(height: 1, color: Colors.grey),
                    ListTile(
                      leading: Icon(
                        CupertinoIcons.clock,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      title: Text(
                        'Formato de hora',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      subtitle: FutureBuilder<String>(
                        future: DateFormatManager.getTimeFormat(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final timeFormat = snapshot.data!;
                            return Text(
                              _formatName(timeFormat),
                              style: TextStyle(
                                color:
                                    isDark ? Colors.white70 : Colors.grey[600],
                                fontSize: 12,
                              ),
                            );
                          }
                          return Text(
                            'Carregando...',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.grey[600],
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                      trailing: Icon(
                        CupertinoIcons.chevron_right,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                      onTap: () => _showTimeFormatSelector(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Sobre',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        CupertinoIcons.info_circle_fill,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      title: Text(
                        'Sobre o Aplicativo',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      trailing: Icon(
                        CupertinoIcons.chevron_right,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getThemeIcon() {
    switch (ThemeManager.themeMode) {
      case ThemeMode.light:
        return CupertinoIcons.sun_max_fill;
      case ThemeMode.dark:
        return CupertinoIcons.moon_circle_fill;
      case ThemeMode.system:
        return MdiIcons.brightnessAuto; // MdiIcons.themeLightDark
    }
  }

  String _getThemeText() {
    switch (ThemeManager.themeMode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Escuro';
      case ThemeMode.system:
        return 'Sistema';
    }
  }

  void _showThemeSelector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Selecionar Tema',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),

                // Opção Sistema
                ListTile(
                  leading: Icon(
                    MdiIcons.brightnessAuto,
                    color:
                        ThemeManager.themeMode == ThemeMode.system
                            ? ThemeManager.accentColor
                            : (isDark ? Colors.white70 : Colors.grey[700]),
                  ),
                  title: Text(
                    'Sistema',
                    style: TextStyle(
                      color:
                          ThemeManager.themeMode == ThemeMode.system
                              ? ThemeManager.accentColor
                              : (isDark ? Colors.white : Colors.black),
                      fontWeight:
                          ThemeManager.themeMode == ThemeMode.system
                              ? FontWeight.w600
                              : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    'Segue as configurações do dispositivo',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  trailing:
                      ThemeManager.themeMode == ThemeMode.system
                          ? Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            color: ThemeManager.accentColor,
                          )
                          : null,
                  onTap: () {
                    ThemeManager.setThemeMode(ThemeMode.system);
                    setState(() {});
                    Navigator.pop(context);
                  },
                ),

                // Opção Claro
                ListTile(
                  leading: Icon(
                    CupertinoIcons.sun_max_fill,
                    color:
                        ThemeManager.themeMode == ThemeMode.light
                            ? ThemeManager.accentColor
                            : (isDark ? Colors.white70 : Colors.grey[700]),
                  ),
                  title: Text(
                    'Claro',
                    style: TextStyle(
                      color:
                          ThemeManager.themeMode == ThemeMode.light
                              ? ThemeManager.accentColor
                              : (isDark ? Colors.white : Colors.black),
                      fontWeight:
                          ThemeManager.themeMode == ThemeMode.light
                              ? FontWeight.w600
                              : FontWeight.normal,
                    ),
                  ),
                  trailing:
                      ThemeManager.themeMode == ThemeMode.light
                          ? Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            color: ThemeManager.accentColor,
                          )
                          : null,
                  onTap: () {
                    ThemeManager.setThemeMode(ThemeMode.light);
                    setState(() {});
                    Navigator.pop(context);
                  },
                ),

                // Opção Escuro
                ListTile(
                  leading: Icon(
                    CupertinoIcons.moon_circle_fill,
                    color:
                        ThemeManager.themeMode == ThemeMode.dark
                            ? ThemeManager.accentColor
                            : (isDark ? Colors.white70 : Colors.grey[700]),
                  ),
                  title: Text(
                    'Escuro',
                    style: TextStyle(
                      color:
                          ThemeManager.themeMode == ThemeMode.dark
                              ? ThemeManager.accentColor
                              : (isDark ? Colors.white : Colors.black),
                      fontWeight:
                          ThemeManager.themeMode == ThemeMode.dark
                              ? FontWeight.w600
                              : FontWeight.normal,
                    ),
                  ),
                  trailing:
                      ThemeManager.themeMode == ThemeMode.dark
                          ? Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            color: ThemeManager.accentColor,
                          )
                          : null,
                  onTap: () {
                    ThemeManager.setThemeMode(ThemeMode.dark);
                    setState(() {});
                    Navigator.pop(context);
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  void _showColorPicker(BuildContext context) {
    // Paleta de cores expandida e organizada por categorias
    final Map<String, List<Color>> colorCategories = {
      'Azuis': [
        Colors.blue.shade50,
        Colors.blue.shade100,
        Colors.blue.shade200,
        Colors.blue.shade300,
        Colors.blue.shade400,
        Colors.blue,
        Colors.blue.shade600,
        Colors.blue.shade700,
        Colors.blue.shade800,
        Colors.blue.shade900,
        Colors.lightBlue.shade300,
        Colors.lightBlue,
        Colors.lightBlue.shade700,
        Colors.blueAccent,
        Colors.blueAccent.shade400,
        Colors.blueAccent.shade700,
        const Color(0xFF0066CC), // Azul corporativo
        const Color(0xFF0052A5), // Azul marinho
        const Color(0xFF003366), // Azul noturno
      ],
      'Verdes': [
        Colors.teal.shade50,
        Colors.teal.shade100,
        Colors.teal.shade200,
        Colors.teal.shade300,
        Colors.teal.shade400,
        Colors.teal,
        Colors.teal.shade600,
        Colors.teal.shade700,
        Colors.teal.shade800,
        Colors.teal.shade900,
        Colors.green.shade50,
        Colors.green.shade100,
        Colors.green.shade200,
        Colors.green.shade300,
        Colors.green.shade400,
        Colors.green,
        Colors.green.shade600,
        Colors.green.shade700,
        Colors.green.shade800,
        Colors.green.shade900,
        Colors.lightGreen.shade300,
        Colors.lightGreen,
        Colors.lightGreen.shade700,
        Colors.greenAccent,
        const Color(0xFF00CC66), // Verde vibrante
        const Color(0xFF00994D), // Verde floresta
        const Color(0xFF006633), // Verde escuro
      ],
      'Vermelhos': [
        Colors.red.shade50,
        Colors.red.shade100,
        Colors.red.shade200,
        Colors.red.shade300,
        Colors.red.shade400,
        Colors.red,
        Colors.red.shade600,
        Colors.red.shade700,
        Colors.red.shade800,
        Colors.red.shade900,
        Colors.redAccent,
        Colors.redAccent.shade200,
        Colors.redAccent.shade400,
        Colors.redAccent.shade700,
        const Color(0xFFCC0000), // Vermelho intenso
        const Color(0xFF990000), // Vermelho vinho
        const Color(0xFF660000), // Vermelho escuro
      ],
      'Laranjas/Amarelos': [
        Colors.orange.shade50,
        Colors.orange.shade100,
        Colors.orange.shade200,
        Colors.orange.shade300,
        Colors.orange.shade400,
        Colors.orange,
        Colors.orange.shade600,
        Colors.orange.shade700,
        Colors.orange.shade800,
        Colors.orange.shade900,
        Colors.orangeAccent,
        Colors.deepOrange.shade300,
        Colors.deepOrange,
        Colors.deepOrange.shade700,
        Colors.amber.shade300,
        Colors.amber,
        Colors.amber.shade700,
        Colors.yellow.shade300,
        Colors.yellow,
        Colors.yellow.shade700,
        const Color(0xFFFF9900), // Laranja neon
        const Color(0xFFFF6600), // Laranja queimado
        const Color(0xFFCC3300), // Laranja avermelhado
      ],
      'Roxos/Violetas': [
        Colors.purple.shade50,
        Colors.purple.shade100,
        Colors.purple.shade200,
        Colors.purple.shade300,
        Colors.purple.shade400,
        Colors.purple,
        Colors.purple.shade600,
        Colors.purple.shade700,
        Colors.purple.shade800,
        Colors.purple.shade900,
        Colors.deepPurple.shade300,
        Colors.deepPurple,
        Colors.deepPurple.shade700,
        Colors.pink.shade300,
        Colors.pink,
        Colors.pink.shade700,
        Colors.pinkAccent,
        const Color(0xFF9933CC), // Roxo vibrante
        const Color(0xFF660099), // Violeta
        const Color(0xFF330066), // Roxo escuro
      ],
      'Rosas/Peaches': [
        Colors.pink.shade50,
        Colors.pink.shade100,
        Colors.pink.shade200,
        Colors.pinkAccent.shade200,
        Colors.pinkAccent.shade400,
        const Color(0xFFFF99CC), // Rosa claro
        const Color(0xFFFF66B3), // Rosa médio
        const Color(0xFFFF3399), // Rosa forte
        const Color(0xFFCC0066), // Rosa escuro
        const Color(0xFFFFCCCC), // Rosa pálido
        const Color(0xFFFF9999), // Coral claro
        const Color(0xFFFF6666), // Coral
        const Color(0xFFCC9999), // Peach
        const Color(0xFFFF9966), // Peach escuro
        const Color(0xFFd993ac), // Rosa pó
        const Color(0xFFcc7a8d), // Rosa poeirento
      ],
      'Neutros/Especiais': [
        Colors.grey.shade50,
        Colors.grey.shade100,
        Colors.grey.shade200,
        Colors.grey.shade300,
        Colors.grey.shade400,
        Colors.grey,
        Colors.grey.shade600,
        Colors.grey.shade700,
        Colors.grey.shade800,
        Colors.grey.shade900,
        Colors.brown.shade300,
        Colors.brown,
        Colors.brown.shade700,
        Colors.blueGrey.shade300,
        Colors.blueGrey,
        Colors.blueGrey.shade700,
        const Color(0xFFd49c2c), // Dourado
        const Color(0xFFb8860b), // Ouro escuro
        const Color(0xFFdaa520), // Ouro claro
        const Color(0xFFc0c0c0), // Prata
        const Color(0xFFa9a9a9), // Cinza escuro
        const Color(0xFF808080), // Cinza médio
        const Color(0xFF36454F), // Carvão
        const Color(0xFF2C3539), // Azul aço escuro
      ],
    };

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
            insetPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Text(
                      'Selecione uma cor de destaque',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.grey[900],
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            colorCategories.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 8,
                                        bottom: 8,
                                      ),
                                      child: Text(
                                        entry.key,
                                        style: TextStyle(
                                          color:
                                              isDark
                                                  ? Colors.white70
                                                  : Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    GridView.count(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      crossAxisCount:
                                          screenWidth > 600
                                              ? 8
                                              : (screenWidth > 400 ? 6 : 4),
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      childAspectRatio: 1.0,
                                      children:
                                          entry.value.map((color) {
                                            return GestureDetector(
                                              onTap: () {
                                                ThemeManager.setAccentColor(
                                                  color,
                                                );
                                                setState(() {});
                                                Navigator.of(context).pop();
                                              },
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 200,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: color,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color:
                                                        ThemeManager.accentColor ==
                                                                color
                                                            ? (isDark
                                                                ? Colors.white
                                                                : Colors.black)
                                                            : Colors
                                                                .transparent,
                                                    width:
                                                        ThemeManager.accentColor ==
                                                                color
                                                            ? 2.5
                                                            : 1.5,
                                                  ),
                                                  boxShadow: [
                                                    if (ThemeManager
                                                            .accentColor ==
                                                        color)
                                                      BoxShadow(
                                                        color: color
                                                            .withOpacity(0.7),
                                                        blurRadius: 8,
                                                        spreadRadius: 2,
                                                      ),
                                                  ],
                                                ),
                                                child:
                                                    ThemeManager.accentColor ==
                                                            color
                                                        ? Center(
                                                          child: Icon(
                                                            Icons.check,
                                                            size: 18,
                                                            color:
                                                                color.computeLuminance() >
                                                                        0.5
                                                                    ? Colors
                                                                        .black
                                                                    : Colors.white,
                                                          ),
                                                        )
                                                        : null,
                                              ),
                                            );
                                          }).toList(),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor:
                            isDark ? Colors.grey[800] : Colors.grey[300],
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey[700],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showDateFormatSelector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Selecionar Formato de Data',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    leading: Icon(
                      CupertinoIcons.calendar,
                      color: ThemeManager.accentColor,
                    ),
                    title: Text(
                      'Brasileiro',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '${DateFormat('d \'de\' MMM y', 'pt_BR').format(DateTime.now())}',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    trailing: FutureBuilder<String>(
                      future: DateFormatManager.getDateFormat(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData &&
                            snapshot.data == 'd \'de\' MMM y') {
                          return Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            color: ThemeManager.accentColor,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    onTap: () async {
                      await DateFormatManager.setDateFormat('d \'de\' MMM y');
                      setModalState(() {});
                      setState(() {});
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      CupertinoIcons.globe,
                      color: ThemeManager.accentColor,
                    ),
                    title: Text(
                      'Internacional',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '${DateFormat('MMMM d, y', 'pt_BR').format(DateTime.now())}',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    trailing: FutureBuilder<String>(
                      future: DateFormatManager.getDateFormat(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data == 'MMMM d, y') {
                          return Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            color: ThemeManager.accentColor,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    onTap: () async {
                      await DateFormatManager.setDateFormat('MMMM d, y');
                      setModalState(() {});
                      setState(() {});
                      Navigator.pop(context);
                    },
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTimeFormatSelector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Selecionar Formato de Hora',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    leading: Icon(
                      CupertinoIcons.clock,
                      color: ThemeManager.accentColor,
                    ),
                    title: Text(
                      '24 Horas',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '${DateFormat('HH:mm', 'pt_BR').format(DateTime.now())}',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    trailing: FutureBuilder<String>(
                      future: DateFormatManager.getTimeFormat(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data == 'HH:mm') {
                          return Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            color: ThemeManager.accentColor,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    onTap: () async {
                      await DateFormatManager.setTimeFormat('HH:mm');
                      setModalState(() {});
                      setState(() {});
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      CupertinoIcons.time,
                      color: ThemeManager.accentColor,
                    ),
                    title: Text(
                      'AM/PM',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '${DateFormat('h:mm a', 'pt_BR').format(DateTime.now())}',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    trailing: FutureBuilder<String>(
                      future: DateFormatManager.getTimeFormat(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data == 'h:mm a') {
                          return Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            color: ThemeManager.accentColor,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    onTap: () async {
                      await DateFormatManager.setTimeFormat('h:mm a');
                      setModalState(() {});
                      setState(() {});
                      Navigator.pop(context);
                    },
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class DateFormatManager {
  static const String _dateFormatKey = 'dateFormat';
  static const String _timeFormatKey = 'timeFormat';

  static final ValueNotifier<String> dateFormatNotifier = ValueNotifier<String>(
    'd \'de\' MMM y',
  );
  static final ValueNotifier<String> timeFormatNotifier = ValueNotifier<String>(
    'HH:mm',
  );

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    dateFormatNotifier.value =
        prefs.getString(_dateFormatKey) ?? 'd \'de\' MMM y';
    timeFormatNotifier.value = prefs.getString(_timeFormatKey) ?? 'HH:mm';
  }

  static Future<void> setDateFormat(String format) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateFormatKey, format);
    dateFormatNotifier.value = format;
  }

  static Future<void> setTimeFormat(String format) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timeFormatKey, format);
    timeFormatNotifier.value = format;
  }

  static Future<String> getDateFormat() async {
    return dateFormatNotifier.value;
  }

  static Future<String> getTimeFormat() async {
    return timeFormatNotifier.value;
  }
}
