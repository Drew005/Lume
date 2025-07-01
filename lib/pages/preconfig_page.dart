import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lume/services/theme_manager.dart';

class PreConfigPage extends StatefulWidget {
  final Function() onComplete;

  const PreConfigPage({super.key, required this.onComplete});

  @override
  State<PreConfigPage> createState() => _PreConfigPageState();
}

class _PreConfigPageState extends State<PreConfigPage> {
  int _currentStep = 0;
  ThemeMode _selectedTheme = ThemeMode.system;
  Color _selectedColor = ThemeManager.accentColor;

  final List<Color> _colorOptions = [
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.red,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_back),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Pré-configuração',
          style: TextStyle(color: theme.textTheme.titleLarge?.color),
        ),
      ),
      body: Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: ThemeManager.accentColor,
          ),
        ),
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue:
              _currentStep < 2
                  ? () => setState(() => _currentStep += 1)
                  : () {
                    ThemeManager.setThemeMode(_selectedTheme);
                    ThemeManager.setAccentColor(_selectedColor);
                    widget.onComplete();
                  },
          onStepCancel:
              _currentStep > 0 ? () => setState(() => _currentStep -= 1) : null,
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Voltar'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: details.onStepContinue,
                      child: Text(_currentStep == 2 ? 'Começar' : 'Continuar'),
                    ),
                  ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: Text(
                'Selecione seu tema',
                style: TextStyle(color: theme.textTheme.titleLarge?.color),
              ),
              content: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: const Text('Sistema'),
                    value: ThemeMode.system,
                    groupValue: _selectedTheme,
                    onChanged: (value) {
                      setState(() => _selectedTheme = value!);
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Claro'),
                    value: ThemeMode.light,
                    groupValue: _selectedTheme,
                    onChanged: (value) {
                      setState(() => _selectedTheme = value!);
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Escuro'),
                    value: ThemeMode.dark,
                    groupValue: _selectedTheme,
                    onChanged: (value) {
                      setState(() => _selectedTheme = value!);
                    },
                  ),
                ],
              ),
            ),
            Step(
              title: Text(
                'Escolha uma cor',
                style: TextStyle(color: theme.textTheme.titleLarge?.color),
              ),
              content: SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _colorOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final color = _colorOptions[index];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                _selectedColor == color
                                    ? isDark
                                        ? Colors.white
                                        : Colors.black
                                    : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child:
                            _selectedColor == color
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                      ),
                    );
                  },
                ),
              ),
            ),
            Step(
              title: Text(
                'Tudo pronto!',
                style: TextStyle(color: theme.textTheme.titleLarge?.color),
              ),
              content: Column(
                children: [
                  const SizedBox(height: 16),
                  Icon(
                    Icons.check_circle,
                    size: 80,
                    color: ThemeManager.accentColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Sua configuração inicial está completa',
                    style: TextStyle(
                      fontSize: 18,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Você pode alterar essas configurações a qualquer momento nas Configurações do app',
                    style: TextStyle(color: theme.textTheme.bodySmall?.color),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
