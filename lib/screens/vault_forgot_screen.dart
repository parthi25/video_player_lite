import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/vault_service.dart';

class VaultForgotScreen extends StatefulWidget {
  const VaultForgotScreen({super.key});

  @override
  State<VaultForgotScreen> createState() => _VaultForgotScreenState();
}

class _VaultForgotScreenState extends State<VaultForgotScreen> {
  List<TextEditingController> _answerControllers = [];
  List<FocusNode> _answerFocusNodes = [];
  List<String> _questions = [];
  List<bool> _answerVisibility = [];

  bool _isLoading = false;
  bool _showError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSecurityQuestions();
  }

  @override
  void dispose() {
    for (final controller in _answerControllers) {
      controller.dispose();
    }
    for (final focusNode in _answerFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSecurityQuestions() async {
    final questions = await VaultService.getSecurityQuestions();
    if (!mounted) return;
    if (questions != null && questions.isNotEmpty) {
      setState(() {
        _questions = questions;
        _answerControllers = List.generate(
          questions.length,
          (index) => TextEditingController(),
        );
        _answerFocusNodes = List.generate(
          questions.length,
          (index) => FocusNode(),
        );
        _answerVisibility = List.generate(questions.length, (index) => false);
      });
    } else {
      // No security questions set up
      Navigator.of(context).pushReplacementNamed('/vault-security-setup');
    }
  }

  Future<void> _resetPassword() async {
    if (_answerControllers.any((controller) => controller.text.isEmpty)) {
      _showErrorMessage('Please answer all security questions');
      return;
    }

    setState(() {
      _isLoading = true;
      _showError = false;
    });

    HapticFeedback.mediumImpact();

    final answers = _answerControllers
        .map((controller) => controller.text)
        .toList();
    final success = await VaultService.resetPasswordWithSecurity(
      'private123',
      answers,
    );

    if (success) {
      HapticFeedback.heavyImpact();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Password Reset'),
          content: const Text(
            'Your Main Password has been reset to: private123\n'
            'Your Decoy Password has been reset to: decoy123\n\n'
            'Please change these immediately after logging in.',
          ),
          backgroundColor: Colors.grey.shade900,
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
          contentTextStyle: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(
                  context,
                ).pushReplacementNamed('/vault-auth'); // Go to login
              },
              child: const Text('OK', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      HapticFeedback.lightImpact();

      setState(() {
        _isLoading = false;
        _showError = true;
        _errorMessage = 'Incorrect answers to security questions';
      });
    }
  }

  void _showErrorMessage(String message) {
    setState(() {
      _showError = true;
      _errorMessage = message;
    });

    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              const Text(
                'No Security Questions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Security questions are not set up yet',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushReplacementNamed('/vault-security-setup');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Set Up Security Questions'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Security Questions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.grey.shade900],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),

                Icon(Icons.lock_reset, size: 80, color: Colors.red.shade700),

                const SizedBox(height: 30),

                const Text(
                  'Answer Security Questions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Answer all questions correctly to reset your password',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Security Questions
                ...List.generate(_questions.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade700,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Question ${index + 1}: ${_questions[index]}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          TextField(
                            controller: _answerControllers[index],
                            focusNode: _answerFocusNodes[index],
                            obscureText: !_answerVisibility[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter your answer',
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              prefixIcon: const Icon(
                                Icons.question_answer,
                                color: Colors.grey,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _answerVisibility[index] =
                                        !_answerVisibility[index];
                                  });
                                  HapticFeedback.lightImpact();
                                },
                                icon: Icon(
                                  _answerVisibility[index]
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey,
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                // Error Message
                if (_showError)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.shade600.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade400,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(
                              color: Colors.red.shade400,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Reset Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Verifying...'),
                            ],
                          )
                        : const Text(
                            'Reset Password',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
