import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'views/home_view.dart';
import 'controllers/theme_controller.dart';

void main() {
  runApp(ForumHubApp());
}

class ForumHubApp extends StatelessWidget {
  final ThemeController themeController = ThemeController();

  ForumHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'ForumHub',
          debugShowCheckedModeBanner: false,
          themeMode: themeController.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            textTheme: GoogleFonts.oswaldTextTheme(), // 👈 Police Oswald
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            textTheme: GoogleFonts.oswaldTextTheme(ThemeData.dark().textTheme),
          ),
          home: HomeView(themeController: themeController),
        );
      },
    );
  }
}
