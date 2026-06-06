import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

import 'package:url_strategy/url_strategy.dart';
import 'screens/agent/agent_screen.dart';        
import 'screens/supervisor/supervisor_screen.dart';

/*void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}*/


void main() {
  setPathUrlStrategy();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
 /* Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ghabetna Admin',
      initialRoute: '/login', // start at login
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(
            user: {}), 
      },
    );
  }*/
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ghabetna',
      initialRoute: '/login',
      /*routes: {
        '/login':      (_) => const LoginScreen(),
        '/admin':  (_) => const DashboardScreen(user: {}),
        '/agent':      (_) => const AgentScreen(user: {}),
        '/supervisor': (_) => const SupervisorScreen(user: {}),
      },*/
      routes: {
        '/login': (_) => const LoginScreen(),
        '/admin': (ctx) {
          final user = (ModalRoute.of(ctx)!.settings.arguments as Map?)?.cast<String, dynamic>() ?? {};
          return DashboardScreen(user: user);
        },
        '/agent': (ctx) {
          final user = (ModalRoute.of(ctx)!.settings.arguments as Map?)?.cast<String, dynamic>() ?? {};
          return AgentScreen(user: user);
        },
        '/supervisor': (ctx) {
          final user = (ModalRoute.of(ctx)!.settings.arguments as Map?)?.cast<String, dynamic>() ?? {};
          return SupervisorScreen(user: user);
        },
      },
    );
  }
}