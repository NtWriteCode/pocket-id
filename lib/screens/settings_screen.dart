import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:password_strength_checker/password_strength_checker.dart';
import '../providers/data_provider.dart';
import '../providers/settings_provider.dart';
import '../services/webdav_service.dart';
import '../services/encryption_service.dart';
import '../widgets/password_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _urlController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _encryptionPasswordController;
  bool _isLoading = false;
  bool _encryptionEnabled = false;
  bool _rememberEncryptionPassword = false;
  final _encryptionService = EncryptionService();
  final _passwordStrengthNotifier = ValueNotifier<PasswordStrength?>(null);
  
  // Edit mode states
  bool _isEditingWebDAV = false;
  bool _isEditingEncryption = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _urlController = TextEditingController(text: settings.webdavUrl ?? '');
    _usernameController = TextEditingController(text: settings.webdavUsername ?? '');
    _passwordController = TextEditingController(text: settings.webdavPassword ?? '');
    _encryptionPasswordController = TextEditingController(text: settings.encryptionPassword ?? '');
    _encryptionEnabled = settings.encryptionEnabled;
    _rememberEncryptionPassword = settings.rememberEncryptionPassword;
    
    // Start in edit mode if nothing is configured
    _isEditingWebDAV = !settings.isConfigured;
    _isEditingEncryption = !settings.encryptionEnabled;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _encryptionPasswordController.dispose();
    _passwordStrengthNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // WebDAV Configuration Section
            _buildWebDAVSection(),
            const SizedBox(height: 16),

            // Encryption Section
            _buildEncryptionSection(),
            const SizedBox(height: 16),

            // Backup Actions Section
            Consumer<SettingsProvider>(
              builder: (context, settings, child) {
                if (!settings.isConfigured) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Configure WebDAV credentials above to enable backup',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Backup Actions',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _isLoading ? null : _backupNow,
                          icon: const Icon(Icons.backup),
                          label: const Text('Backup Now'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _restoreNow,
                          icon: const Icon(Icons.restore),
                          label: const Text('Restore from Backup'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // App Info Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pocket ID v1.0.0',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Simple personal ID storage app',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebDAVSection() {
    final settings = context.watch<SettingsProvider>();
    
    if (!_isEditingWebDAV && settings.isConfigured) {
      // Summary card view
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.cloud_upload, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'WebDAV Backup',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      setState(() {
                        _isEditingWebDAV = true;
                      });
                    },
                    tooltip: 'Edit configuration',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.link, 'Server', settings.webdavUrl ?? ''),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.person, 'Username', settings.webdavUsername ?? ''),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.lock_outline, 'Password', '••••••••'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Configuration saved',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    
    // Edit form view
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_upload),
                const SizedBox(width: 8),
                Text(
                  'WebDAV Backup',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Configure WebDAV server for manual backup and restore',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'WebDAV URL',
                hintText: 'https://example.com/webdav',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _testConnection,
                    child: const Text('Test Connection'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _isLoading ? null : _saveConfig,
                    child: const Text('Save Config'),
                  ),
                ),
              ],
            ),
            if (settings.isConfigured) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isEditingWebDAV = false;
                    // Reload original values
                    _urlController.text = settings.webdavUrl ?? '';
                    _usernameController.text = settings.webdavUsername ?? '';
                    _passwordController.text = settings.webdavPassword ?? '';
                  });
                },
                child: const Text('Cancel'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEncryptionSection() {
    final settings = context.watch<SettingsProvider>();
    
    if (!_isEditingEncryption && settings.encryptionEnabled) {
      // Summary card view - Encryption ENABLED
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.lock, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'End-to-End Encryption',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      setState(() {
                        _isEditingEncryption = true;
                      });
                    },
                    tooltip: 'Edit configuration',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.shield, 'Status', 'Enabled'),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.key,
                'Password',
                settings.rememberEncryptionPassword ? 'Saved (remembered)' : 'Session only',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.security, 'Algorithm', 'AES-256-GCM'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Backups will be encrypted',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    
    if (!_isEditingEncryption && !settings.encryptionEnabled) {
      // Summary card view - Encryption DISABLED
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.lock_open, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'End-to-End Encryption',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      setState(() {
                        _isEditingEncryption = true;
                      });
                    },
                    tooltip: 'Enable encryption',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.shield_outlined, 'Status', 'Disabled'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Backups will NOT be encrypted',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    
    // Edit form view
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.lock),
                const SizedBox(width: 8),
                Text(
                  'End-to-End Encryption',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Encrypt backups before uploading to WebDAV server',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _encryptionEnabled,
              onChanged: (value) {
                setState(() {
                  _encryptionEnabled = value;
                });
              },
              title: const Text('Enable E2E Encryption'),
              subtitle: const Text('Protects your data on the server'),
              contentPadding: EdgeInsets.zero,
            ),
            if (_encryptionEnabled) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _encryptionPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Encryption Password',
                  hintText: 'Enter a strong password',
                  border: OutlineInputBorder(),
                  helperText: 'This is NOT your WebDAV password',
                ),
                obscureText: true,
                onChanged: (value) {
                  _passwordStrengthNotifier.value = 
                      PasswordStrength.calculate(text: value);
                },
              ),
              const SizedBox(height: 8),
              PasswordStrengthChecker(strength: _passwordStrengthNotifier),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _rememberEncryptionPassword,
                onChanged: (value) {
                  setState(() {
                    _rememberEncryptionPassword = value ?? false;
                  });
                },
                title: const Text('Remember password'),
                subtitle: const Text('Less secure, but more convenient'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const Divider(),
              Row(
                children: [
                  const Icon(Icons.warning_amber, size: 20, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'If you forget this password, your backup cannot be recovered!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            // Save button - always show
            FilledButton(
              onPressed: _isLoading ? null : _saveEncryptionConfig,
              child: const Text('Save Encryption Settings'),
            ),
            // Cancel button - only show if encryption was previously configured
            if (settings.encryptionEnabled || (!settings.encryptionEnabled && _encryptionEnabled != settings.encryptionEnabled)) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isEditingEncryption = false;
                    // Reload original values
                    _encryptionEnabled = settings.encryptionEnabled;
                    _encryptionPasswordController.text = settings.encryptionPassword ?? '';
                    _rememberEncryptionPassword = settings.rememberEncryptionPassword;
                  });
                },
                child: const Text('Cancel'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveConfig() async {
    final url = _urlController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (url.isEmpty || username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await context.read<SettingsProvider>().saveWebDAVConfig(
            url: url,
            username: username,
            password: password,
          );

      if (mounted) {
        setState(() {
          _isEditingWebDAV = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveEncryptionConfig() async {
    if (_encryptionEnabled && _encryptionPasswordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an encryption password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await context.read<SettingsProvider>().saveEncryptionConfig(
            enabled: _encryptionEnabled,
            password: _encryptionEnabled ? _encryptionPasswordController.text.trim() : null,
            rememberPassword: _rememberEncryptionPassword,
          );

      // Clear password controller when encryption is disabled
      if (!_encryptionEnabled) {
        _encryptionPasswordController.clear();
      }

      if (mounted) {
        setState(() {
          _isEditingEncryption = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Encryption settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (url.isEmpty || username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final service = WebDAVService(
        url: url,
        username: username,
        password: password,
      );

      final success = await service.testConnection();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Connection successful!'
                : 'Connection failed. Check your credentials.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _backupNow() async {
    final settings = context.read<SettingsProvider>();
    String? encryptionPassword = settings.encryptionPassword;

    // If encryption enabled but no password, ask for it
    if (settings.encryptionEnabled && encryptionPassword == null) {
      final result = await showPasswordDialog(
        context,
        title: 'Enter Encryption Password',
        message: 'Your backup will be encrypted with this password',
        showRememberOption: true,
        initialRememberValue: settings.rememberEncryptionPassword,
      );

      if (result == null) return; // User cancelled
      
      encryptionPassword = result.password;
      
      // Save password if user wants to remember it
      if (result.rememberPassword) {
        await settings.saveEncryptionConfig(
          enabled: true,
          password: encryptionPassword,
          rememberPassword: true,
        );
      } else {
        settings.setSessionEncryptionPassword(encryptionPassword);
      }
    }

    // Check server backup status and warn about mismatches
    try {
      final service = WebDAVService(
        url: settings.webdavUrl,
        username: settings.webdavUsername,
        password: settings.webdavPassword,
      );
      
      final serverData = await service.downloadBackup();
      final serverIsEncrypted = _encryptionService.isEncrypted(serverData);
      
      // Case 1: Encryption disabled, but server has encrypted data
      if (!settings.encryptionEnabled && serverIsEncrypted) {
        final overwrite = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Overwrite Encrypted Backup?'),
            content: const Text(
              'The server has an encrypted backup, but you have encryption disabled. '
              'If you continue, the encrypted backup will be replaced with an unencrypted one.\n\n'
              'Do you want to overwrite the encrypted backup with unencrypted data?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Overwrite'),
              ),
            ],
          ),
        );
        
        if (overwrite != true) return;
      }
      
      // Case 2: Encryption enabled with password, check if server encrypted with different password
      if (settings.encryptionEnabled && encryptionPassword != null && serverIsEncrypted) {
        // Try to decrypt with current password
        try {
          await _encryptionService.decrypt(serverData, encryptionPassword);
        } catch (e) {
          // Wrong password - warn user
          final overwrite = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Password Mismatch'),
              content: const Text(
                'The server has an encrypted backup, but your current password cannot decrypt it. '
                'If you continue, the server backup will be overwritten and the old data will be lost forever.\n\n'
                'Do you want to overwrite the server backup?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Overwrite'),
                ),
              ],
            ),
          );
          
          if (overwrite != true) return;
        }
      }
    } catch (e) {
      // Server backup doesn't exist yet, that's fine
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dataProvider = context.read<DataProvider>();
      final service = WebDAVService(
        url: settings.webdavUrl,
        username: settings.webdavUsername,
        password: settings.webdavPassword,
      );

      String jsonData = dataProvider.exportData();
      
      // Encrypt if enabled AND we have a password
      // Double-check: only encrypt if explicitly enabled
      if (settings.encryptionEnabled && encryptionPassword != null && encryptionPassword.isNotEmpty) {
        jsonData = await _encryptionService.encrypt(jsonData, encryptionPassword);
      }

      await service.uploadBackup(jsonData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(settings.encryptionEnabled 
                ? 'Backup encrypted and uploaded!' 
                : 'Backup successful!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _restoreNow() async {
    final settings = context.read<SettingsProvider>();
    
    setState(() {
      _isLoading = true;
    });

    try {
      final service = WebDAVService(
        url: settings.webdavUrl,
        username: settings.webdavUsername,
        password: settings.webdavPassword,
      );

      String jsonData = await service.downloadBackup();
      final isEncrypted = _encryptionService.isEncrypted(jsonData);

      // Handle encryption mismatches
      if (isEncrypted && !settings.encryptionEnabled) {
        // Server encrypted, user has no password
        if (mounted) {
          final pull = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Encrypted Backup Found'),
              content: const Text(
                'The server has an encrypted backup, but you haven\'t enabled encryption. '
                'Do you want to pull and decrypt it?\n\n'
                'You will need to enter the encryption password.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Pull & Decrypt'),
                ),
              ],
            ),
          );
          
          if (pull != true) {
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }
      } else if (!isEncrypted && settings.encryptionEnabled) {
        // Server unencrypted, user has encryption enabled
        if (mounted) {
          final pull = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Unencrypted Backup Found'),
              content: const Text(
                'The server has an unencrypted backup, but you have encryption enabled. '
                'Do you want to pull the unencrypted backup?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Pull Anyway'),
                ),
              ],
            ),
          );
          
          if (pull != true) {
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }
      }

      // Decrypt if needed
      if (isEncrypted) {
        String? encryptionPassword = settings.encryptionPassword;
        
        // Ask for password if not available
        if (encryptionPassword == null) {
          if (mounted) {
            final result = await showPasswordDialog(
              context,
              title: 'Enter Decryption Password',
              message: 'Enter the password used to encrypt this backup',
              showRememberOption: true,
              initialRememberValue: false,
            );

            if (result == null) {
              setState(() {
                _isLoading = false;
              });
              return;
            }
            
            encryptionPassword = result.password;
          }
        }

        if (encryptionPassword == null) {
          throw Exception('Encryption password required');
        }

        try {
          jsonData = await _encryptionService.decrypt(jsonData, encryptionPassword);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Wrong password or corrupted data'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Show confirmation dialog
      if (mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Restore from Backup'),
            content: const Text(
              'This will replace all current data with the backup. Are you sure?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text('Restore'),
              ),
            ],
          ),
        );

        if (confirmed != true) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Import the data
      final dataProvider = context.read<DataProvider>();
      await dataProvider.importData(jsonData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restore successful!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
