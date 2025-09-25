import 'package:flutter/material.dart';
import 'utils/discribe_card.dart';


class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Information'),
        ),
        body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Text("Handling of Personal Information",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Text("This app does not collect any personal information from you, nor does it track or use any information on your device.",
                      style: TextStyle(fontSize: 16)),
                  SizedBox(height: 12),
                  Text("Advertisements",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Text("This app does not display any advertisements. Therefore, there is no tracking from ads. ",
                      style: TextStyle(fontSize: 16)),
                  SizedBox(height: 12),
                  Text("Contact Us",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("If you have any questions or concerns about this privacy policy, please contact us at",
                      style: TextStyle(fontSize: 16)),
                  CustomTextContainer(
                      textContent: "ecole.la.porte@gmail.com"),
                  LaunchUrlContainer(
                    textContent: 'Ecole la Porte Privacy Policy',
                    url:
                    'https://laporte727.github.io/ecole.la.porte/dokodon.html',
                  ),
                ],
              ),
            ),
          ),
        );
  }
}