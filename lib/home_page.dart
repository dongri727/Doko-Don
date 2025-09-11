import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'home_model.dart';
import 'notes.dart';

class HomePage extends StatelessWidget {
  final items = notes;

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final title = 'faire une dictée';
    //String inputText = '';

    return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: ChangeNotifierProvider<HomeModel>(
          create: (_) => HomeModel(),
          child: Consumer<HomeModel>(builder: (_, model, __) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1) Title input field (top, fixed)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'title',
                      hintText: 'title du morceau',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: model.setTitle,
                  ),
                ),

                // Part selector (four buttons in a row)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                  child: ToggleButtons(
                    isSelected: List.generate(5, (i) => i == model.partIndex),
                    onPressed: (i) => model.setPartIndex(i),
                    borderRadius: BorderRadius.circular(8),
                    constraints: const BoxConstraints(minHeight: 40, minWidth: 72),
                    children: const [
                      Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('〆')),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('大')),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('中Ａ')),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('中Ｂ')),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('中Ｃ')),
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
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(12.0),
                          child: SelectableText(
                            model.getText().isEmpty ? '（La partition s\'affiche ici.）' : model.getText(),
                            style: const TextStyle(fontSize: 20, color: Colors.indigo),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 3) Controls row (above keyboard)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: model.undoLast,
                        icon: const Icon(Icons.backspace),
                        label: const Text('défaire'),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () => _showExportSheet(context, model),
                        icon: const Icon(Icons.ios_share),
                        label: const Text('exporte'),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: model.insertNewline,
                        icon: const Icon(Icons.keyboard_return),
                        label: const Text('alinéa'),
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
                      childAspectRatio: 2.6, // compact rows
                      padding: const EdgeInsets.all(8),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: List.generate(items.length, (index) {
                        final label = items[index];
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                          ),
                          onPressed: label.isEmpty ? null : () => model.appendText(label),
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
          }),
        ),
    );
  }

  Future<String> _writeCsvToAppDocs(String filename, String content) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content, encoding: utf8);
    return file.path;
  }

  Future<String> _writeCsvToTemp(String filename, String content) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content, encoding: utf8);
    return file.path;
  }

  void _showExportSheet(BuildContext context, HomeModel model) async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.save_alt),
                title: const Text('Enregistrer sur l\'appareil (dossier Documents dans l\'application)'),
                onTap: () async {
                  final csv = model.buildCsv();
                  final name = model.exportFileName();
                  final path = await _writeCsvToAppDocs(name, csv);
                  if (context.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sauvegardé: $path')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.ios_share),
                title: const Text('共有（LINE・メール など）'),
                onTap: () async {
                  final csv = model.buildCsv();
                  final name = model.exportFileName();
                  final path = await _writeCsvToTemp(name, csv);
                  await Share.shareXFiles([
                    XFile(
                      path,
                      mimeType: 'text/csv',
                      name: name,
                    )
                  ],
                      text: '和太鼓譜面CSV');
                  if (context.mounted) Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}