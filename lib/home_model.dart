import 'package:flutter/cupertino.dart';

class HomeModel extends ChangeNotifier {
  final List<String> _tokens = [];
  String _title = '';

  // --- Score content operations ---
  void appendText(String val) {
    _tokens.add(val);
    notifyListeners();
  }

  void undoLast() {
    if (_tokens.isNotEmpty) {
      _tokens.removeLast();
      notifyListeners();
    }
  }

  void insertNewline() {
    _tokens.add('\n');
    notifyListeners();
  }

  void resetAll() {
    _tokens.clear();
    notifyListeners();
  }

  String getText() {
    return _tokens.join();
  }

  // --- CSV export helpers ---
  String _sanitizeForFile(String s) {
    // Replace forbidden/sensitive filename chars and collapse whitespace
    final replaced = s.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').replaceAll(RegExp(r'\s+'), '_');
    // Trim to a reasonable length
    return replaced.isEmpty ? 'untitled' : (replaced.length > 60 ? replaced.substring(0, 60) : replaced);
  }

  String exportFileName() {
    final t = _sanitizeForFile(_title);
    final p = _sanitizeForFile(part);
    return '${t}_${p}.csv';
  }

  /// Build CSV where each item token is a comma-separated cell.
  /// Newline tokens ("\n") start a new CSV line.
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
    if (current.isNotEmpty) rows.add(current);
    // Join rows
    final buffer = StringBuffer();
    for (var i = 0; i < rows.length; i++) {
      buffer.writeln(rows[i].join(','));
    }
    return buffer.toString();
  }

  // --- Part selection ---
  final List<String> parts = ['締太鼓', '大太鼓', '中太鼓A', '中太鼓B'];
  int _partIndex = 0; // default: 締太鼓
  int get partIndex => _partIndex;
  String get part => parts[_partIndex];
  void setPartIndex(int i) {
    if (i < 0 || i >= parts.length) return;
    _partIndex = i;
    notifyListeners();
  }

  // --- Title operations ---
  String get title => _title;

  void setTitle(String val) {
    _title = val;
    notifyListeners();
  }
}