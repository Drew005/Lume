import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart';
import 'package:intl/intl.dart';
import 'package:lume/pages/settings_page.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:lume/services/theme_manager.dart';
import 'package:lume/services/notes_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:translator/translator.dart';
import '../models/note.dart';
import 'package:flutter/rendering.dart';

// ==========================================
// MAIN WIDGET CLASS
// ==========================================
class NotePage extends StatefulWidget {
  final Note? existingNote;
  final int? existingNoteIndex;

  const NotePage({super.key, this.existingNote, this.existingNoteIndex});

  @override
  State<NotePage> createState() => _NotePageState();
}

// ==========================================
// STATE CLASS
// ==========================================
class _NotePageState extends State<NotePage> implements WidgetsBindingObserver {
  // ==========================================
  // CONTROLLERS & FOCUS MANAGEMENT
  // ==========================================
  final TextEditingController _titleController = TextEditingController();
  late quill.QuillController _contentController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _editorKey = GlobalKey();

  // ==========================================
  // STATE VARIABLES
  // ==========================================
  late String selectedCategory;
  late DateTime _updatedAt;
  bool _isSaving = false;
  bool _hasChanges = false;
  bool _isTyping = false;
  bool _isKeyboardVisible = false;
  bool _isDisposed = false;
  Note? _currentNote;
  bool _isCheckboxInteraction = false;
  bool _isCheckboxCooldown = false;
  Timer? _saveDebounceTimer;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _hasInternetConnection = true;

  // ==========================================
  // LIFECYCLE METHODS
  // ==========================================
  @override
  void initState() {
    super.initState();
    _initializeNote();
    WidgetsBinding.instance.addObserver(this);
    _initConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    _contentController.removeListener(_onContentChanged);
    _titleController.removeListener(_onTextChanged);
    ThemeManager.themeNotifier.removeListener(_onThemeChanged);
    _focusNode.removeListener(_onFocusChanged);

    _contentController.dispose();
    _titleController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();

    WidgetsBinding.instance.removeObserver(this);

    _connectivitySubscription.cancel();
    super.dispose();
  }

  // ==========================================
  // INITIALIZATION METHODS
  // ==========================================
  void _initializeNote() {
    _currentNote = widget.existingNote;
    _titleController.text = _currentNote?.title ?? '';
    selectedCategory = _currentNote?.category ?? 'Sem Categoria';
    _updatedAt = _currentNote?.updatedAt ?? DateTime.now();

    _initializeContentController(_currentNote?.content ?? '');

    ThemeManager.themeNotifier.addListener(_onThemeChanged);
    _focusNode.addListener(_onFocusChanged);
    _contentController.addListener(_onContentChanged);
    _titleController.addListener(_onTextChanged);
  }

  void _initializeContentController(String initialContent) {
    final doc =
        initialContent.isNotEmpty
            ? _parseDocument(initialContent)
            : quill.Document();

    _contentController = quill.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateHighlightColors(),
    );
  }

  quill.Document _parseDocument(String content) {
    try {
      final decoded = jsonDecode(content);
      return decoded is List<dynamic>
          ? quill.Document.fromJson(decoded)
          : quill.Document();
    } catch (_) {
      return quill.Document();
    }
  }

  Future<void> _initConnectivity() async {
    final List<ConnectivityResult> connectivityResult =
        await Connectivity().checkConnectivity();
    _updateConnectionStatus(connectivityResult);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    setState(() {
      _hasInternetConnection =
          results.isNotEmpty &&
          results.any((result) => result != ConnectivityResult.none);
    });
  }

  // ==========================================
  // EVENT HANDLERS
  // ==========================================
  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      setState(() {
        _isTyping = true;
        // Rolar para a posição de edição
        _scrollToCursor();
      });
    }
  }

  void _scrollToCursor() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderObject = _editorKey.currentContext?.findRenderObject();
      if (renderObject is RenderBox) {
        final offset = renderObject.localToGlobal(Offset.zero);
        final viewportHeight = MediaQuery.of(context).size.height;
        final cursorPosition = offset.dy + renderObject.size.height;

        if (cursorPosition > viewportHeight * 0.7) {
          _scrollController.animateTo(
            _scrollController.offset + cursorPosition - viewportHeight * 0.7,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  void _onThemeChanged() {
    if (mounted && !_isDisposed) _updateHighlightColors();
  }

  void _onContentChanged() {
    if (_isDisposed || !mounted) return;

    // Cancelar timer existente
    _saveDebounceTimer?.cancel();

    // Iniciar novo timer
    _saveDebounceTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && !_isDisposed && _hasChanges) {
        _saveNote();
      }
    });

    setState(() {
      _isTyping = true;
      _hasChanges = true;
    });
  }

  void _onTextChanged() {
    if (_isDisposed || !mounted) return;
    if (_titleController.text.trim().isNotEmpty) {
      setState(() {
        _isTyping = true;
        _hasChanges = true;
      });
    }
  }

  void _handleCheckboxStateChange() {
    if (_isDisposed || !mounted) return;

    _isCheckboxInteraction = true;
    setState(() => _hasChanges = true);

    Future.delayed(const Duration(milliseconds: 100), () {
      _isCheckboxInteraction = false;
    });
  }

  // ==========================================
  // APP LIFECYCLE HANDLING
  // ==========================================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.detached) &&
        _hasChanges &&
        !_isSaving) {
      _saveNote();
    }
  }

  @override
  void didChangeMetrics() {
    if (!mounted || _isDisposed) return;

    final newValue = WidgetsBinding.instance.window.viewInsets.bottom > 100;
    if (newValue != _isKeyboardVisible && mounted && !_isDisposed) {
      setState(() {
        _isKeyboardVisible = newValue;
        if (!_isKeyboardVisible) {
          _isTyping = false;
          _focusNode.unfocus();
        }
      });
    }
  }

  // ==========================================
  // NOTE OPERATIONS
  // ==========================================
  Future<bool> _onWillPop() async {
    if (_hasChanges && !_isSaving) await _saveNote();
    return true;
  }

  Future<void> _saveNote() async {
    if (_isSaving || !_hasChanges || _isDisposed) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final newNote = Note(
        title: _titleController.text.trim(),
        content: jsonEncode(_contentController.document.toDelta().toJson()),
        category: selectedCategory,
        createdAt: _currentNote?.createdAt ?? now,
        updatedAt: now,
      );

      if (_currentNote != null) {
        final index = NotesManager.allNotes.indexWhere(
          (n) => n.createdAt == _currentNote!.createdAt,
        );
        if (index >= 0) await NotesManager.updateNote(newNote, index);
      } else {
        await NotesManager.addNote(newNote);
        _currentNote = newNote;
      }

      if (mounted && !_isDisposed) {
        setState(() {
          _updatedAt = now;
          _hasChanges = false;
          _currentNote = newNote;
        });
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        IconSnackBar.show(
          context,
          snackBarType: SnackBarType.fail,
          label: 'Erro ao salvar: ${e.toString()}',
          duration: const Duration(seconds: 2),
        );
      }
    } finally {
      if (mounted && !_isDisposed) setState(() => _isSaving = false);
    }
  }

  // ==========================================
  // EDITOR OPERATIONS
  // ==========================================
  void _undo() {
    _contentController.undo();
    setState(() => _hasChanges = true);
  }

  void _redo() {
    _contentController.redo();
    setState(() => _hasChanges = true);
  }

  Future<void> _shareNote() async {
    try {
      final title = _titleController.text.trim();
      final content = _contentController.document.toPlainText().trim();

      if (title.isEmpty && content.isEmpty) {
        IconSnackBar.show(
          context,
          snackBarType: SnackBarType.fail,
          label: 'Nada para compartilhar',
          duration: const Duration(seconds: 2),
        );
        return;
      }

      String shareText = '';
      if (title.isNotEmpty) {
        shareText += '📝 *${title.toUpperCase()}*\n\n';
      }

      // Formatando o conteúdo com melhor espaçamento
      final formattedContent =
          content
              .replaceAll(
                RegExp(r'\n{3,}'),
                '\n\n',
              ) // Reduz múltiplas quebras de linha
              .replaceAll(
                RegExp(r'(\n\s*)+\n'),
                '\n\n',
              ) // Remove linhas vazias extras
              .trim();

      shareText += formattedContent;

      // Adiciona rodapé com informações do app
      shareText += '\n\n---\n';
      shareText += 'Enviado via Lume App';

      await Share.share(
        shareText,
        subject: title.isNotEmpty ? title : 'Nota compartilhada',
      );
    } catch (e) {
      IconSnackBar.show(
        context,
        snackBarType: SnackBarType.fail,
        label: 'Erro ao compartilhar: ${e.toString()}',
        duration: const Duration(seconds: 2),
      );
    }
  }

  bool _isChecklistActive() {
    final selection = _contentController.selection;
    if (!selection.isValid) return false;

    if (selection.isCollapsed) {
      try {
        final line = _contentController.document.queryChild(selection.start);
        return line.node?.style.attributes[quill.Attribute.list.key] != null;
      } catch (e) {
        return false;
      }
    }

    return _contentController.document.toDelta().operations.any(
      (op) => op.attributes?.containsKey(quill.Attribute.list.key) ?? false,
    );
  }

  String _getCurrentHighlightColor() {
    final accentColor = ThemeManager.accentColor;
    return '#80${accentColor.value.toRadixString(16).substring(2)}';
  }

  void _updateHighlightColors() {
    if (_isDisposed || !mounted) return;

    try {
      final newColor = _getCurrentHighlightColor();
      final delta = _contentController.document.toDelta();
      final newOps = <Operation>[];
      bool hasChanges = false;

      for (final op in delta.operations) {
        if (op.attributes?.containsKey('background') ?? false) {
          newOps.add(
            Operation.insert(op.data, {
              ...op.attributes!,
              'background': newColor,
            }),
          );
          hasChanges = true;
        } else {
          newOps.add(op);
        }
      }

      if (hasChanges) {
        final currentSelection = _contentController.selection;
        final newDocument = quill.Document.fromDelta(
          Delta()..operations.addAll(newOps),
        );

        _contentController.document = newDocument;
        _contentController.updateSelection(
          currentSelection,
          quill.ChangeSource.local,
        );
        setState(() => _hasChanges = true);
      }
    } catch (e) {
      debugPrint('Erro ao atualizar cores de destaque: $e');
    }
  }

  // ==========================================
  // BUILD METHODS
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, themeMode, child) {
        return WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            appBar: _buildAppBar(context),
            body: _buildEditorContent(
              context,
              Theme.of(context).brightness == Brightness.dark,
              _contentController.document
                  .toPlainText()
                  .replaceAll(RegExp(r'\s+'), '')
                  .length,
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      toolbarHeight: 40,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(CupertinoIcons.chevron_back),
        onPressed: () async {
          if (_hasChanges && !_isSaving) await _saveNote();
          if (mounted) Navigator.pop(context);
        },
      ),
      actions: _isTyping ? _buildAppBarActions() : _buildAppBarOtherActions(),
    );
  }

  List<Widget> _buildAppBarOtherActions() {
    return [
      IconButton(
        icon: const Icon(CupertinoIcons.share),
        onPressed: _shareNote,
        tooltip: 'Compartilhar',
      ),
    ];
  }

  List<Widget> _buildAppBarActions() {
    return [
      IconButton(
        icon: const Icon(CupertinoIcons.arrow_turn_up_left),
        onPressed: _contentController.hasUndo ? _undo : null,
        tooltip: 'Desfazer',
      ),
      IconButton(
        icon: const Icon(CupertinoIcons.arrow_turn_up_right),
        onPressed: _contentController.hasRedo ? _redo : null,
        tooltip: 'Refazer',
      ),
      IconButton(
        icon: Icon(
          CupertinoIcons.doc_checkmark_fill,
          fill: 1,
          color: _hasChanges ? ThemeManager.accentColor : Colors.grey[600],
        ),
        onPressed: _hasChanges && !_isSaving ? _saveNote : null,
        tooltip: 'Salvar',
      ),
    ];
  }

  Widget _buildEditorContent(
    BuildContext context,
    bool isDark,
    int characterCount,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() => _isTyping = true);
        if (!_contentController.selection.isValid ||
            _contentController.selection.isCollapsed) {
          final length = _contentController.document.length;
          _contentController.updateSelection(
            TextSelection.collapsed(offset: length),
            quill.ChangeSource.local,
          );
        }
        _focusNode.requestFocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTitleField(),
                  _buildMetadataRow(characterCount),
                  _buildQuillEditor(isDark),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                ],
              ),
            ),
          ),
          if (_isKeyboardVisible) _buildToolbar(),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: TextField(
        maxLines: null,
        maxLength: 300,
        buildCounter:
            (
              context, {
              required currentLength,
              required isFocused,
              maxLength,
            }) => null,
        controller: _titleController,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
        decoration: const InputDecoration(
          hintText: 'Título',
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildMetadataRow(int characterCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        children: [
          ValueListenableBuilder(
            valueListenable: DateFormatManager.dateFormatNotifier,
            builder: (context, dateFormat, _) {
              return ValueListenableBuilder(
                valueListenable: DateFormatManager.timeFormatNotifier,
                builder: (context, timeFormat, _) {
                  return Text(
                    '${DateFormat(dateFormat, 'pt_BR').format(_updatedAt)}   ${DateFormat(timeFormat, 'pt_BR').format(_updatedAt)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  );
                },
              );
            },
          ),
          const Spacer(),
          Text(
            '$characterCount caracteres',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildQuillEditor(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        child: quill.QuillEditor(
          key: _editorKey,
          controller: _contentController,
          focusNode: _focusNode,
          scrollController: _scrollController,
          config: _getEditorConfig(isDark),
        ),
      ),
    );
  }

  quill.QuillEditorConfig _getEditorConfig(bool isDark) {
    return quill.QuillEditorConfig(
      placeholder: 'Digite seu texto aqui...',
      scrollable: false,
      padding: EdgeInsets.zero,
      expands: false,
      customStyles: _getEditorStyles(isDark),
      enableInteractiveSelection: true,
      showCursor: true,
      requestKeyboardFocusOnCheckListChanged: false,
      embedBuilders: [],
    );
  }

  quill.DefaultStyles _getEditorStyles(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    final checkedTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    return quill.DefaultStyles(
      placeHolder: _createTextBlockStyle(
        TextStyle(fontSize: 17, color: Colors.grey),
      ),
      paragraph: _createTextBlockStyle(
        TextStyle(color: textColor, fontSize: 17),
        verticalSpacing: const quill.VerticalSpacing(6, 6),
      ),
      lists: quill.DefaultListBlockStyle(
        TextStyle(color: textColor, fontSize: 17, height: 1.4),
        const quill.HorizontalSpacing(6, 0),
        const quill.VerticalSpacing(2, 2),
        const quill.VerticalSpacing(0, 0),
        null,
        MyCustomCheckboxBuilder(
          _contentController,
          onChanged: _handleCheckboxStateChange,
          checkedTextColor: checkedTextColor,
          isCheckboxCooldown: ValueNotifier(_isCheckboxCooldown),
        ),
      ),
      h1: _createTextBlockStyle(
        TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.3,
        ),
      ),
      h2: _createTextBlockStyle(
        TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.3,
        ),
      ),
      h3: _createTextBlockStyle(
        TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.3,
        ),
      ),
    );
  }

  quill.DefaultTextBlockStyle _createTextBlockStyle(
    TextStyle style, {
    quill.VerticalSpacing? verticalSpacing,
  }) {
    return quill.DefaultTextBlockStyle(
      style,
      const quill.HorizontalSpacing(0, 0),
      verticalSpacing ?? const quill.VerticalSpacing(0, 0),
      const quill.VerticalSpacing(0, 0),
      null,
    );
  }

  // Atualize o _buildToolbar para usar o botão único:
  Widget _buildToolbar() {
    return SizedBox(
      height: 56,
      child: Material(
        color: Colors.grey.withAlpha(30),
        child: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 8),
                _buildCycleHeaderButton(),
                const SizedBox(width: 2),
                _buildToggleButton(
                  attribute: quill.Attribute.bold,
                  icon: const Icon(CupertinoIcons.bold, size: 30),
                  tooltip: 'Negrito',
                ),
                const SizedBox(width: 2),
                _buildToggleButton(
                  attribute: quill.Attribute.italic,
                  icon: const Icon(CupertinoIcons.italic, size: 30),
                  tooltip: 'Itálico',
                ),
                const SizedBox(width: 2),
                _buildToggleButton(
                  attribute: quill.Attribute.strikeThrough,
                  icon: const Icon(CupertinoIcons.strikethrough, size: 30),
                  tooltip: 'Tachado',
                ),
                _buildToggleButton(
                  attribute: quill.Attribute.underline,
                  icon: const Icon(CupertinoIcons.underline, size: 30),
                  tooltip: 'Sublinhado',
                ),
                const SizedBox(width: 2),
                _buildHighlightButton(),
                const SizedBox(width: 2),
                _buildChecklistButton(),
                const SizedBox(width: 2),
                _buildTextAlignmentButton(),
                const SizedBox(width: 2),
                IconButton(
                  icon: const Icon(Icons.translate, size: 24),
                  onPressed: _hasInternetConnection ? _translateWithML : null,
                  tooltip:
                      _hasInternetConnection
                          ? 'Traduzir texto selecionado'
                          : 'Sem conexão com a internet',
                  color:
                      _hasInternetConnection
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.grey,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getSelectedText() {
    if (!_contentController.selection.isValid) return '';

    final fullText = _contentController.document.toPlainText();
    final selection = _contentController.selection;

    // Se já está selecionada uma palavra completa, retornar como está
    if (selection.start != selection.end) {
      return fullText.substring(selection.start, selection.end);
    }

    // Encontrar os limites da palavra atual
    int wordStart = selection.start;
    int wordEnd = selection.end;

    // Expandir para trás até encontrar um caractere não-alfabético
    while (wordStart > 0 &&
        fullText[wordStart - 1].toLowerCase().contains(
          RegExp(r'[a-záéíóúãõâêôç]'),
        )) {
      wordStart--;
    }

    // Expandir para frente até encontrar um caractere não-alfabético
    while (wordEnd < fullText.length &&
        fullText[wordEnd].toLowerCase().contains(RegExp(r'[a-záéíóúãõâêôç]'))) {
      wordEnd++;
    }

    return fullText.substring(wordStart, wordEnd);
  }

  void _replaceSelectedText(String newText) {
    if (!_contentController.selection.isValid) return;

    // Obter o texto completo do documento
    final fullText = _contentController.document.toPlainText();
    final selection = _contentController.selection;

    // Encontrar os limites da palavra atual
    int wordStart = selection.start;
    int wordEnd = selection.end;

    // Expandir para trás até encontrar um caractere não-alfabético
    while (wordStart > 0 &&
        fullText[wordStart - 1].toLowerCase().contains(
          RegExp(r'[a-záéíóúãõâêôç]'),
        )) {
      wordStart--;
    }

    // Expandir para frente até encontrar um caractere não-alfabético
    while (wordEnd < fullText.length &&
        fullText[wordEnd].toLowerCase().contains(RegExp(r'[a-záéíóúãõâêôç]'))) {
      wordEnd++;
    }

    // Substituir a palavra inteira
    _contentController.replaceText(
      wordStart,
      wordEnd - wordStart,
      newText,
      TextSelection.collapsed(offset: wordStart + newText.length),
    );
  }

  Future<void> _translateWithML() async {
    if (!_hasInternetConnection) {
      if (mounted) {
        IconSnackBar.show(
          context,
          snackBarType: SnackBarType.fail,
          label: 'Sem conexão com a internet',
          duration: const Duration(seconds: 2),
        );
      }
      return;
    }

    final selectedText = _getSelectedText();
    if (selectedText.isEmpty) {
      if (mounted) {
        IconSnackBar.show(
          context,
          snackBarType: SnackBarType.fail,
          label: 'Selecione um texto para traduzir',
          duration: const Duration(seconds: 2),
        );
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text("Traduzindo..."),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text("Por favor, aguarde"),
              ],
            ),
          ),
    );

    try {
      final translator = GoogleTranslator();
      final translation = await translator.translate(
        selectedText,
        from: 'auto',
        to: 'pt',
      );

      if (mounted) {
        Navigator.pop(context);
        _replaceSelectedText(translation.text);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na tradução: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Tentar novamente',
              onPressed: _translateWithML,
            ),
          ),
        );
      }
    }
  }

  Widget _buildTextAlignmentButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Builder(
      builder: (context) {
        // Obter o alinhamento atual
        final currentAlignment =
            _contentController.getSelectionStyle().attributes['align']?.value ??
            'left';

        // Ícone baseado no alinhamento atual
        IconData icon;
        String tooltip;

        switch (currentAlignment) {
          case 'left':
            icon = CupertinoIcons.text_alignleft;
            tooltip = 'Alinhado à esquerda';
            break;
          case 'center':
            icon = CupertinoIcons.text_aligncenter;
            tooltip = 'Alinhado ao centro';
            break;
          case 'right':
            icon = CupertinoIcons.text_alignright;
            tooltip = 'Alinhado à direita';
            break;
          case 'justify':
            icon = CupertinoIcons.text_justify;
            tooltip = 'Justificado';
            break;
          default:
            icon = CupertinoIcons.text_alignleft;
            tooltip = 'Alinhado à esquerda';
        }

        return IconButton(
          icon: Icon(
            icon,
            size: 30,
            color:
                currentAlignment != 'left'
                    ? ThemeManager.accentColor
                    : isDark
                    ? Colors.white
                    : Colors.black,
          ),
          tooltip: tooltip,
          onPressed: () {
            // Ciclo de alinhamentos
            String nextAlignment;
            switch (currentAlignment) {
              case 'left':
                nextAlignment = 'center';
                break;
              case 'center':
                nextAlignment = 'right';
                break;
              case 'right':
                nextAlignment = 'justify';
                break;
              case 'justify':
                nextAlignment = 'left';
                break;
              default:
                nextAlignment = 'center';
            }

            _contentController.formatSelection(
              quill.Attribute.fromKeyValue('align', nextAlignment),
            );
            setState(() => _hasChanges = true);
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        );
      },
    );
  }

  Widget _buildCycleHeaderButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Builder(
      builder: (context) {
        final currentLevel =
            _contentController
                .getSelectionStyle()
                .attributes[quill.Attribute.header.key]
                ?.value ??
            0;

        return IconButton(
          icon:
              currentLevel == 0
                  ? Icon(
                    CupertinoIcons.textformat,
                    size: 32,
                    color: isDark ? Colors.white : Colors.black,
                    weight: 900,
                    fill: 1,
                  )
                  : Text(
                    'H$currentLevel',
                    style: const TextStyle(fontSize: 28),
                  ),
          tooltip: currentLevel == 0 ? 'Normal' : 'Título $currentLevel',
          onPressed: () {
            _contentController.formatSelection(
              quill.Attribute.clone(quill.Attribute.list, null),
            );

            final nextLevel = (currentLevel - 1) % 4;
            _contentController.formatSelection(
              nextLevel == 0
                  ? quill.Attribute.header
                  : quill.Attribute.clone(quill.Attribute.header, nextLevel),
            );
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        );
      },
    );
  }

  Widget _buildHighlightButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlightColor = ThemeManager.accentColor.withOpacity(0.5);

    return Builder(
      builder: (context) {
        final isActive =
            _contentController.getSelectionStyle().attributes[quill
                .Attribute
                .background
                .key] !=
            null;

        return IconButton(
          icon: Icon(
            Symbols.format_ink_highlighter,
            size: 30,
            color:
                isActive
                    ? ThemeManager.accentColor
                    : isDark
                    ? Colors.white
                    : Colors.black,
          ),
          tooltip: 'Marcador de texto',
          onPressed: () {
            _contentController.formatSelection(
              quill.Attribute.clone(
                quill.Attribute.background,
                isActive ? null : _getCurrentHighlightColor(),
              ),
            );
            setState(() => _hasChanges = true);
          },
        );
      },
    );
  }

  Widget _buildChecklistButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Builder(
      builder: (context) {
        final isActive = _isChecklistActive();

        return IconButton(
          icon: Icon(
            CupertinoIcons.checkmark_square_fill,
            size: 30,
            fill: 1,
            color:
                isActive
                    ? ThemeManager.accentColor
                    : isDark
                    ? Colors.white
                    : Colors.black,
          ),
          tooltip: 'Lista de verificação',
          onPressed: () {
            if (_isCheckboxCooldown) return;
            _isCheckboxCooldown = true;

            final selection = _contentController.selection;
            final text = _contentController.document.getPlainText(
              selection.start,
              selection.end,
            );

            // Sempre aplica o checkbox na linha atual
            _contentController.formatSelection(
              isActive
                  ? quill.Attribute.clone(quill.Attribute.list, null)
                  : quill.Attribute.clone(quill.Attribute.list, 'unchecked'),
            );

            // Se estiver em uma linha vazia, adiciona um espaço para manter o checkbox visível
            if (selection.isCollapsed && text.trim().isEmpty) {
              _contentController.replaceText(
                selection.start,
                0,
                ' ',
                TextSelection.collapsed(offset: selection.start + 1),
              );
            }

            setState(() => _hasChanges = true);
            Future.delayed(const Duration(milliseconds: 300), () {
              setState(() => _isCheckboxCooldown = false);
            });
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        );
      },
    );
  }

  bool _isAttributeActive(quill.Attribute attribute, dynamic value) {
    final attrs = _contentController.getSelectionStyle().attributes;
    return value != null
        ? attrs[attribute.key]?.value == value
        : attrs.containsKey(attribute.key);
  }

  Widget _buildToggleButton({
    required quill.Attribute attribute,
    dynamic value,
    required Widget icon,
    required String tooltip,
  }) {
    final isActive = _isAttributeActive(attribute, value);

    return Container(
      child: IconButton(
        icon: IconTheme(
          data: IconThemeData(
            color:
                isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
            size: 22,
          ),
          child: icon,
        ),
        tooltip: tooltip,
        onPressed: () => _toggleAttribute(attribute, value),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }

  void _toggleAttribute(quill.Attribute attribute, dynamic value) {
    _contentController.formatSelection(
      _isAttributeActive(attribute, value)
          ? quill.Attribute.clone(attribute, null)
          : value != null
          ? quill.Attribute.clone(attribute, value)
          : attribute,
    );
    setState(() {});
  }

  // ==========================================
  // UNUSED WIDGET BINDING OBSERVER METHODS
  // ==========================================
  @override
  void didChangeAccessibilityFeatures() {}
  @override
  void didChangeLocales(List<Locale>? locales) {}
  @override
  void didChangePlatformBrightness() {}
  @override
  void didChangeTextScaleFactor() {}
  @override
  Future<bool> didPopRoute() async => false;
  @override
  Future<bool> didPushRoute(String route) async => false;
  @override
  Future<bool> didPushRouteInformation(
    RouteInformation routeInformation,
  ) async => false;
  @override
  void didChangeViewFocus(ViewFocusEvent event) {}
  @override
  void didHaveMemoryPressure() {}
  @override
  Future<AppExitResponse> didRequestAppExit() => throw UnimplementedError();
  @override
  void handleCancelBackGesture() {}
  @override
  void handleCommitBackGesture() {}
  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) =>
      throw UnimplementedError();
  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {}
}

// ==========================================
// CUSTOM WIDGET CLASSES
// ==========================================
class MyCustomCheckboxBuilder implements quill.QuillCheckboxBuilder {
  final quill.QuillController controller;
  final VoidCallback? onChanged;
  final Color? checkedTextColor;
  final ValueNotifier<bool> isCheckboxCooldown;

  const MyCustomCheckboxBuilder(
    this.controller, {
    this.onChanged,
    this.checkedTextColor,
    required this.isCheckboxCooldown,
  });

  @override
  Widget build({
    required BuildContext context,
    required bool isChecked,
    required ValueChanged<bool> onChanged,
  }) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        // Espaçamento para o checkbox
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(right: 10, top: 3, bottom: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? ThemeManager.accentColor
                        : ThemeManager.accentColor,
                width: 1.5,
              ),
              color: isChecked ? ThemeManager.accentColor : Colors.transparent,
            ),
            child:
                isChecked
                    ? Icon(
                      Icons.check,
                      size: 14,
                      color: Theme.of(context).colorScheme.onPrimary,
                    )
                    : null,
          ),
        ),
        // Área clicável (hitbox) exata
        Positioned(
          left: 6,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (isCheckboxCooldown.value) return;

              isCheckboxCooldown.value = true;
              onChanged(!isChecked);
              this.onChanged?.call();

              Future.delayed(const Duration(milliseconds: 300), () {
                isCheckboxCooldown.value = false;
              });
            },
            child: const SizedBox(width: 18, height: 18),
          ),
        ),
      ],
    );
  }
}
