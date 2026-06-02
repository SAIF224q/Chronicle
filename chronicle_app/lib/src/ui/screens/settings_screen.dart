import 'package:flutter/material.dart';

import '../../application/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.settingsService});

  final SettingsService settingsService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _hasPassword = false;
  String _currentTheme = 'sunset_coral';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final hasPassword = await widget.settingsService.hasHiddenMessagePassword();
    final currentTheme = await widget.settingsService.getSelectedTheme();
    if (!mounted) {
      return;
    }

    setState(() {
      _hasPassword = hasPassword;
      _currentTheme = currentTheme;
      _isLoading = false;
    });
  }

  Future<void> _saveTheme(String themeName) async {
    try {
      await widget.settingsService.setSelectedTheme(themeName);
      if (!mounted) {
        return;
      }
      setState(() {
        _currentTheme = themeName;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Theme updated.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update theme.')),
      );
    }
  }

  Future<void> _savePassword() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.settingsService.setHiddenMessagePassword(
        _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _hasPassword = true;
        _passwordController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hidden message password saved.')),
      );
    } on ArgumentError {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a password before saving.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save settings right now.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'App Theme',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        RadioListTile<String>(
                          title: const Text('Sunset Coral (Option A)'),
                          value: 'sunset_coral',
                          groupValue: _currentTheme,
                          activeColor: colorScheme.primary,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) {
                            if (value != null) {
                              _saveTheme(value);
                            }
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Burnt Ember (Option C)'),
                          value: 'burnt_ember',
                          groupValue: _currentTheme,
                          activeColor: colorScheme.primary,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) {
                            if (value != null) {
                              _saveTheme(value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Hidden messages',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _hasPassword
                              ? 'A reveal password is set.'
                              : 'Set a reveal password before hiding messages.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: _hasPassword
                                ? 'New reveal password'
                                : 'Reveal password',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: _isSaving ? null : _savePassword,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.lock_outline),
                            label: Text(
                              _hasPassword ? 'Update Password' : 'Set Password',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
