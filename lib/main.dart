import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/crop_state.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => CropState(),
      child: const InstaCropperApp(),
    ),
  );
}

class InstaCropperApp extends StatelessWidget {
  const InstaCropperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CropState>(
      builder: (context, state, _) {
        return MaterialApp(
          title: 'Insta Cropper',
          theme: state.darkMode ? ThemeData.dark() : ThemeData.light(),
          home: const HomeScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
