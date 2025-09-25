import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
//import 'package:file_selector/file_selector.dart';
import 'home_model.dart';
import 'utils/notes.dart';

class HomePage extends StatelessWidget {
  final items = notes;

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final title = 'faire une dictée';

    final mq = MediaQuery.of(context);
    final size = mq.size;
    final isPortrait = mq.orientation == Orientation.portrait;
    final isSmallWidth = size.width < 380;
    // Adaptive sizes
    final double previewFontSize = isSmallWidth ? 18 : 20;
    //final double buttonFontSize = isSmallWidth ? 14 : 16;
/*     final double gridHeight = isPortrait
        ? (size.height * 0.27).clamp(160.0, 260.0)
        : 180.0; */

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ChangeNotifierProvider<HomeModel>(
        create: (_) => HomeModel(),
        child: Consumer<HomeModel>(
          builder: (_, model, __) {
            model.setPreviewFontSize(previewFontSize);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      // Title (flex: 2)
                      Expanded(
                        flex: 2,
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'title',
                            hintText: 'title du morceau',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          onChanged: model.setTitle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Part dropdown (flex: 1)
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<int>(
                          value: model.partIndex,
                          items: List.generate(model.parts.length, (i) {
                            final disp = switch (i) {
                              0 => '〆',
                              1 => '大',
                              2 => '中Ａ',
                              3 => '中Ｂ',
                              _ => '中Ｃ',
                            };
                            return DropdownMenuItem<int>(
                              value: i,
                              child: Text(disp),
                            );
                          }),
                          onChanged: (i) {
                            if (i != null) model.setPartIndex(i);
                          },
                          decoration: const InputDecoration(
                            labelText: 'part',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2) Scrollable multi-line preview (middle, expands)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Scrollbar(
                        controller: model.previewController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: model.previewController,
                          // ★追加：Scrollbar と共有
                          primary: false,
                          padding: const EdgeInsets.all(12.0),
                          child: SelectableText.rich(
                            TextSpan(children: model.buildPreviewSpans()),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 3) Controls row (above keyboard)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: Row(
                    children: [
                      // カーソル直前削除（統一）
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: model.backspaceAtCursor,
                          icon: const Icon(Icons.backspace),
                          label: const Text('back'),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // エクスポート
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showExportSheet(context, model),
                          icon: const Icon(Icons.save),
                          label: const Text('save'),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 改行（カーソル位置に挿入）
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: model.insertNewline,
                          icon: const Icon(Icons.keyboard_return),
                          label: const Text('newline'),
                        ),
                      ),
                    ],
                  ),
                ),

                // 4) Items Grid as a fixed-height bottom keyboard
                SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 240, // keyboard-like fixed height
                    child: GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      crossAxisCount: 5,
                      childAspectRatio: 2.6,
                      // compact rows
                      padding: const EdgeInsets.all(8),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: List.generate(items.length, (index) {
                        final label = items[index];
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                              vertical: 4.0,
                            ),
                          ),
                          onPressed: label.isEmpty
                              ? null
                              : () => model.appendText(label),
                          child: Text(
                            label.isEmpty ? ' ' : label,
                            style: const TextStyle(fontSize: 16.0),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  Future<String> _writeCsvToAppDocs(String filename, String content) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content, encoding: utf8);
    return file.path;
  }

  void _showExportSheet(BuildContext context, HomeModel model) async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: ListTile(
            leading: const Icon(Icons.save_alt),
            title: const Text(
              'Enregistrer dans l\'application',
            ),
            onTap: () async {
              final csv = model.buildCsv();
              final name = model.exportFileName();
              final path = await _writeCsvToAppDocs(name, csv);
              if (context.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Enregistrement Réussi',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 20),
                        ),
                    backgroundColor: Colors.white),
                );
              }
            },
          ),
        );
      },
    );
  }
}
