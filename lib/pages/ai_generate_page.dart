import 'package:flutter/material.dart';
import '../utils/logger.dart';
import 'user_management_page.dart';

class AIGeneratePage extends StatelessWidget {
  const AIGeneratePage({super.key});

  void _navigateToProfile(BuildContext context) {
    AppLogger.log('Navigating to user profile page');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const UserManagementPage()));
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.log('Building AI Generate page');

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'AI Generator',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _navigateToProfile(context),
            icon: const Icon(
              Icons.account_circle,
              color: Color(0xFFFFD700),
              size: 28,
            ),
            tooltip: 'My Profile',
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Welcome Icon
              Icon(Icons.auto_awesome, size: 120, color: Color(0xFFFFD700)),
              SizedBox(height: 32),

              // Welcome Text
              Text(
                'Hello, welcome!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                ),
              ),
              SizedBox(height: 16),

              // Subtitle
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Start creating amazing AI-generated assets for your projects',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ),
              SizedBox(height: 48),

              // Coming Soon Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFFFD700),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                child: Text(
                  'AI Generation Coming Soon',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
