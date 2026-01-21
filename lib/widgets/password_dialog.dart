import 'package:flutter/material.dart';
import 'package:password_strength_checker/password_strength_checker.dart';

/// Dialog for entering encryption password
class PasswordDialog extends StatefulWidget {
  final String title;
  final String? message;
  final bool showRememberOption;
  final bool initialRememberValue;

  const PasswordDialog({
    super.key,
    required this.title,
    this.message,
    this.showRememberOption = false,
    this.initialRememberValue = false,
  });

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _rememberPassword = false;
  final _passwordStrengthNotifier = ValueNotifier<PasswordStrength?>(null);

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _rememberPassword = widget.initialRememberValue;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordStrengthNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.message != null) ...[
              Text(
                widget.message!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _passwordController,
              autofocus: true,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Encryption Password',
                hintText: 'Enter password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              onChanged: (value) {
                _passwordStrengthNotifier.value = 
                    PasswordStrength.calculate(text: value);
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.pop(context, PasswordDialogResult(
                    password: value,
                    rememberPassword: _rememberPassword,
                  ));
                }
              },
            ),
            const SizedBox(height: 8),
            PasswordStrengthChecker(strength: _passwordStrengthNotifier),
            if (widget.showRememberOption) ...[
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _rememberPassword,
                onChanged: (value) {
                  setState(() {
                    _rememberPassword = value ?? false;
                  });
                },
                title: const Text('Remember password'),
                subtitle: const Text('Less secure, but more convenient'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final password = _passwordController.text.trim();
            if (password.isNotEmpty) {
              Navigator.pop(context, PasswordDialogResult(
                password: password,
                rememberPassword: _rememberPassword,
              ));
            }
          },
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

/// Result from password dialog
class PasswordDialogResult {
  final String password;
  final bool rememberPassword;

  PasswordDialogResult({
    required this.password,
    required this.rememberPassword,
  });
}

/// Show password dialog and return result
Future<PasswordDialogResult?> showPasswordDialog(
  BuildContext context, {
  required String title,
  String? message,
  bool showRememberOption = false,
  bool initialRememberValue = false,
}) {
  return showDialog<PasswordDialogResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PasswordDialog(
      title: title,
      message: message,
      showRememberOption: showRememberOption,
      initialRememberValue: initialRememberValue,
    ),
  );
}
