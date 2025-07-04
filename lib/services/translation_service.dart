import 'package:translator/translator.dart';
import 'package:fluent_validator/fluent_validator.dart';

class TranslationService {
  static final _translator = GoogleTranslator();
  static const _maxRetries = 2;
  static const _delayBetweenRetries = Duration(seconds: 1);

  /// Traduz texto do inglês para português com tratamento de erros
  static Future<Object> translateToPortuguese(String text) async {
    if (text.isEmpty) return text;

    try {
      // Validação básica do texto
      if (containsInvalidCharacters(text)) {
        throw Exception('Texto contém caracteres inválidos');
      }

      // Tentativa com retry automático
      return await _translateWithRetry(text);
    } catch (e) {
      print('Erro na tradução: $e');
      return text; // Retorna o texto original em caso de falha
    }
  }

  /// Lógica de tentativa com repetição
  static Future<Object> _translateWithRetry(
    String text, {
    int attempt = 0,
  }) async {
    try {
      return await _translator.translate(text, from: 'en', to: 'pt');
    } catch (e) {
      if (attempt >= _maxRetries) rethrow;
      await Future.delayed(_delayBetweenRetries);
      return _translateWithRetry(text, attempt: attempt + 1);
    }
  }

  /// Validação de caracteres (opcional)
  static bool containsInvalidCharacters(String text) {
    return text.contains(
      RegExp(r'[^\p{L}\p{M}\p{N}\p{P}\p{S}\p{Z}\p{Cf}]', unicode: true),
    );
  }

  /// Verifica disponibilidade do serviço
  static Future<bool> isAvailable() async {
    try {
      await _translator.translate('test', to: 'pt');
      return true;
    } catch (_) {
      return false;
    }
  }
}
