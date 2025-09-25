import 'package:flutter/material.dart';

class HintPage extends StatelessWidget {
  const HintPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Hints')),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 20),
                Text(
                  'This app is designed specifically to quickly digitize taiko rhythms learned through oral recitation. With a single key press, you can input two eighth notes (equivalent to one quarter note), making it the perfect speed for entering rhythms while chanting or singing along.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 12),
                Text(
                  'Data is saved and exported in a versatile CSV format, allowing not only in-app editing but also easy output to other apps and sharing on social media. You can combine short segments into a full piece or gather individual parts into a complete score.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 12),
                Text(
                  'Top Screen',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  'This is the main screen where you can see all your Taiko Score Cards. From the list, you can review, delete, or export entries. Tap the "+" button to add a new card.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 12),
                Text(
                  'Input Screen',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  'Here you can enter details for a new Taiko Score Card. Fill in the title and description, then tap "Save" to add it to your collection.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 12),
                Text(
                  'Edit Screen',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  'Use this screen to modify an existing card. Update the information as needed and tap "Save" to apply changes.',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),  
        ),
);
  }
}