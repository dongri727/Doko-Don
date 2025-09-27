import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class CsvEditPage extends StatefulWidget {
  final File file;
  final String initialText;

  CsvEditPage({required this.file, required this.initialText});

  @override
  State<CsvEditPage> createState() => CsvEditPageState();
}

class CsvEditPageState extends State<CsvEditPage> {
  List<File> _csvFiles = [];
  late final TextEditingController _controller;
  bool _saving = false;

  bool _showEol = true; // show visible EOL markers by default
  bool _updatingText = false; // guard to avoid recursive controller updates

  String _visualizeEol(String s) {
    // First normalize Windows CRLF to a token, then apply replacements
    s = s.replaceAll('\r\n', '⏎\r\n');
    // Lone \n
    s = s.replaceAllMapped(RegExp(r'(?<!⏎)\n'), (m) => '⏎\n');
    // Lone \r
    s = s.replaceAllMapped(RegExp(r'(?<!⏎)\r'), (m) => '⏎\r');
    return s;
  }

  String _stripEolMarks(String s) {
    return s.replaceAll('⏎', '');
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);

    if (_showEol) {
      final vis = _visualizeEol(_controller.text);
      _controller.value = TextEditingValue(
        text: vis,
        selection: TextSelection.collapsed(offset: vis.length),
      );
    }

    _controller.addListener(() {
      if (!_showEol) return;
      if (_updatingText) return;
      final oldText = _controller.text;
      final newText = _visualizeEol(oldText);
      if (newText != oldText) {
        _updatingText = true;
        final sel = _controller.selection;
        final delta = newText.length - oldText.length;
        final newBase = sel.baseOffset == -1 ? -1 : (sel.baseOffset + delta);
        final newExtent = sel.extentOffset == -1
            ? -1
            : (sel.extentOffset + delta);
        _controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection(
            baseOffset: newBase,
            extentOffset: newExtent,
          ),
        );
        _updatingText = false;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final raw = _showEol
          ? _stripEolMarks(_controller.text)
          : _controller.text;
      await widget.file.writeAsString(raw);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Saved (overwritten).',
            style: TextStyle(color: Colors.green, fontSize: 20),
          ),
          backgroundColor: Colors.white,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }

    void _toggleShowEol() {
      final current = _controller.text;
      String nextText;
      if (_showEol) {
        // turn OFF markers: strip ⏎
        nextText = _stripEolMarks(current);
      } else {
        // turn ON markers: add ⏎ before line endings
        nextText = _visualizeEol(current);
      }
      setState(() {
        _showEol = !_showEol;
        _updatingText = true;
        final sel = _controller.selection;
        final delta = nextText.length - current.length;
        final newBase = sel.baseOffset == -1 ? -1 : (sel.baseOffset + delta);
        final newExtent = sel.extentOffset == -1
            ? -1
            : (sel.extentOffset + delta);
        _controller.value = TextEditingValue(
          text: nextText,
          selection: TextSelection(
            baseOffset: newBase,
            extentOffset: newExtent,
          ),
        );
        _updatingText = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = p.basename(widget.file.path);
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'CSV content',
            alignLabelWithHint: true,
          ),
          keyboardType: TextInputType.multiline,
          maxLines: null,
          expands: true,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const CircularProgressIndicator()
            : const Icon(Icons.save),
      ),
    );
  }
}
