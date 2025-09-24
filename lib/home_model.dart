import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

/// HomeModel
/// - 方式A：論理カーソル（_cursor）に統一
/// - 文字列はトークン配列（_tokens）で管理
/// - 追加/改行/削除は全て _cursor 位置で実行
class HomeModel extends ChangeNotifier {
  // 本文を構成するトークン（1アイテム＝1文字や1記号）
  final List<String> _tokens = [];

  // プレビュー専用スクロール
  final ScrollController previewController = ScrollController();

  // 論理カーソル（0.._tokens.length）
  int _cursor = 0;
  int get cursor => _cursor;
  void setCursor(int i) {
    _cursor = i.clamp(0, _tokens.length);
    notifyListeners();
  }

  // タップ用 Recognizer（リーク防止のため都度破棄）
  final List<TapGestureRecognizer> _recognizers = [];

  // タイトル（ファイル名用）
  String _title = '';
  String get title => _title;
  void setTitle(String val) {
    _title = val;
    notifyListeners();
  }

  // プレビュー文字サイズ（任意）
  double _previewFontSize = 20;
  void setPreviewFontSize(double v) {
    if (v == _previewFontSize) return;
    _previewFontSize = v;
    // ここでは通知しない（build中の通知を避ける）
  }

  // --- 挿入系：カーソル位置に挿入 ---
  void appendText(String text) => insertAtCursor(text);

  void insertAtCursor(String text) {
    _tokens.insert(_cursor, text);
    _cursor++;
    notifyListeners();
    _autoScrollToEnd();
  }

  void insertNewline() {
    insertAtCursor('\n');
  }

  // --- 削除：カーソル直前を削除 ---
  void backspaceAtCursor() {
    if (_cursor == 0) return;
    _tokens.removeAt(_cursor - 1);
    _cursor--;
    notifyListeners();
    _autoScrollToEnd();
  }

  // 末尾1件を取り消し（簡易Undo）
  void undoLast() {
    if (_tokens.isEmpty) return;
    // カーソルが末尾にいない場合でも、末尾削除の振る舞いは維持
    if (_cursor > _tokens.length - 1) {
      _cursor = _tokens.length - 1;
    }
    _tokens.removeLast();
    _cursor = _cursor.clamp(0, _tokens.length);
    notifyListeners();
  }

  bool get isEmpty => _tokens.isEmpty;

  void resetAll() {
    _tokens.clear();
    _cursor = 0;
    notifyListeners();
  }

  String getText() => _tokens.join();

  /// ¶ を見せつつ、各トークン・改行にタップでカーソルを置けるようにする
  List<InlineSpan> buildPreviewSpans() {
    // 既存 recognizer をクリーンアップ
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final baseStyle = TextStyle(fontSize: _previewFontSize, color: Colors.indigo);
    const pilcrowStyle = TextStyle(color: Colors.grey);

    final spans = <InlineSpan>[];

    // 先頭（位置0）にも置けるように不可視タップ領域
    final headTap = TapGestureRecognizer()..onTap = () => setCursor(0);
    _recognizers.add(headTap);
    spans.add(TextSpan(text: '\u200B', recognizer: headTap, style: baseStyle)); // ZERO WIDTH

    for (var i = 0; i < _tokens.length; i++) {
      // カーソル可視化（位置 i の前）
      if (_cursor == i) {
        spans.add(const WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: SizedBox(
            width: 1.5,
            height: 20,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.indigo),
            ),
          ),
        ));
      }

      final tok = _tokens[i];
      final tap = TapGestureRecognizer()..onTap = () => setCursor(i + 1);
      _recognizers.add(tap);

      if (tok == '\n') {
        // ¶ を表示しつつ実改行も入れる
        spans.add(TextSpan(text: ' \u00B6\n', style: pilcrowStyle, recognizer: tap));
      } else {
        spans.add(TextSpan(text: tok, style: baseStyle, recognizer: tap));
      }
    }

    // 末尾カーソル（_tokens.length の位置）
    if (_cursor == _tokens.length) {
      spans.add(const WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: SizedBox(
          width: 1.5,
          height: 20,
          child: DecoratedBox(
            decoration: BoxDecoration(color: Colors.indigo),
          ),
        ),
      ));
    }

    if (_tokens.isEmpty) {
      spans.add(const TextSpan(
        text: '（La partition s\'affiche ici.）',
        style: TextStyle(color: Colors.black45, fontSize: 16),
      ));
    }

    return spans;
  }

  void _autoScrollToEnd() {
    if (!previewController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!previewController.hasClients) return;
      final max = previewController.position.maxScrollExtent;
      previewController.animateTo(
        max,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    previewController.dispose();
    super.dispose();
  }

  // --- Part selection ---
  final List<String> parts = ['〆', '大', '中A', '中B', '中C'];
  int _partIndex = 2; // default: 中A
  int get partIndex => _partIndex;
  String get part => parts[_partIndex];
  void setPartIndex(int i) {
    if (i < 0 || i >= parts.length) return;
    _partIndex = i;
    notifyListeners();
  }

  // --- CSV export helpers ---
  String _sanitizeForFile(String s) {
    // ファイル名に使えない文字を置換し、空白はアンダースコアに
    final replaced = s
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    // 長すぎる場合は切り詰め
    if (replaced.isEmpty) return 'untitled';
    return replaced.length > 60 ? replaced.substring(0, 60) : replaced;
  }

  String exportFileName() {
    final t = _sanitizeForFile(_title);
    final p = _sanitizeForFile(part);
    return '${t}_${p}.csv';
  }

  /// Build CSV where each token is one cell; newline starts new row.
  String buildCsv() {
    final List<List<String>> rows = [];
    List<String> current = [];
    for (final tok in _tokens) {
      if (tok == '\n') {
        rows.add(current);
        current = [];
      } else {
        current.add(tok.trimRight());
      }
    }
    // 最後の行（改行で終わらない場合）を追加
    if (current.isNotEmpty) rows.add(current);

    final buffer = StringBuffer();
    for (var i = 0; i < rows.length; i++) {
      buffer.writeln(rows[i].join(','));
    }
    return buffer.toString();
  }
}