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
  final TextEditingController _currentPasswordController = TextEditingController();
  bool _hasPassword = false;
  String _currentTheme = 'sunset_coral';
  bool _isLoading = true;
  bool _isSaving = false;
  int _startDayOfWeek = 1;
  bool _showStreaks = true;
  bool _botEnabled = true;
  String _botTime = '20:00';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _currentPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final hasPassword = await widget.settingsService.hasHiddenMessagePassword();
    final currentTheme = await widget.settingsService.getSelectedTheme();
    final startDayOfWeek = await widget.settingsService.getVibeCalendarStartDayOfWeek();
    final showStreaks = await widget.settingsService.getVibeCalendarShowStreaks();
    final botEnabled = await widget.settingsService.getVibeCheckBotEnabled();
    final botTime = await widget.settingsService.getVibeCheckBotTime();
    if (!mounted) {
      return;
    }

    setState(() {
      _hasPassword = hasPassword;
      _currentTheme = currentTheme;
      _startDayOfWeek = startDayOfWeek;
      _showStreaks = showStreaks;
      _botEnabled = botEnabled;
      _botTime = botTime;
      _isLoading = false;
    });
  }

  Future<void> _saveStartDayOfWeek(int day) async {
    try {
      await widget.settingsService.setVibeCalendarStartDayOfWeek(day);
      setState(() {
        _startDayOfWeek = day;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start day of week updated.')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update settings.')),
      );
    }
  }

  Future<void> _saveShowStreaks(bool show) async {
    try {
      await widget.settingsService.setVibeCalendarShowStreaks(show);
      setState(() {
        _showStreaks = show;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Show streaks preference updated.')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update settings.')),
      );
    }
  }

  Future<void> _saveBotEnabled(bool enabled) async {
    try {
      await widget.settingsService.setVibeCheckBotEnabled(enabled);
      setState(() {
        _botEnabled = enabled;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vibe check bot status updated.')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update settings.')),
      );
    }
  }

  Future<void> _selectBotTime() async {
    final parts = _botTime.split(':');
    final initialHour = int.tryParse(parts[0]) ?? 20;
    final initialMinute = int.tryParse(parts[1]) ?? 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    );

    if (picked != null) {
      final hourStr = picked.hour.toString().padLeft(2, '0');
      final minuteStr = picked.minute.toString().padLeft(2, '0');
      final timeStr = '$hourStr:$minuteStr';

      try {
        await widget.settingsService.setVibeCheckBotTime(timeStr);
        setState(() {
          _botTime = timeStr;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vibe check bot time set to ${_formatTimeOfDay(picked)}.')),
        );
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update settings.')),
        );
      }
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final minuteStr = time.minute.toString().padLeft(2, '0');
    return '$hour:$minuteStr $period';
  }

  String _formatTimeStr(String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.tryParse(parts[0]) ?? 20;
    final minute = int.tryParse(parts[1]) ?? 0;
    return _formatTimeOfDay(TimeOfDay(hour: hour, minute: minute));
  }

  Future<void> _clearBotHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Bot History'),
          content: const Text('Are you sure you want to delete all Vibe Check Bot messages from your timeline? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await widget.settingsService.clearBotMessages();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bot history cleared successfully.')),
        );
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to clear bot history.')),
        );
      }
    }
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

    final newPassword = _passwordController.text.trim();
    if (newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a password before saving.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_hasPassword) {
        final currentPassword = _currentPasswordController.text;
        final isValid = await widget.settingsService.verifyHiddenMessagePassword(currentPassword);
        if (!isValid) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect current password.')),
          );
          setState(() {
            _isSaving = false;
          });
          return;
        }
      }

      await widget.settingsService.setHiddenMessagePassword(newPassword);
      if (!mounted) {
        return;
      }
      setState(() {
        _hasPassword = true;
        _passwordController.clear();
        _currentPasswordController.clear();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: <Widget>[
                // Theme Selection Section
                Text(
                  'App Theme',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildThemeCard(
                        title: 'Sunset Coral',
                        subtitle: 'Warm & Creamy',
                        themeName: 'sunset_coral',
                        primaryColor: const Color(0xFFFF5D35),
                        bgColor: const Color(0xFFFCFAF7),
                        cardColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildThemeCard(
                        title: 'Burnt Ember',
                        subtitle: 'Deep & Obsidian',
                        themeName: 'burnt_ember',
                        primaryColor: const Color(0xFFF59E0B),
                        bgColor: const Color(0xFF0F0D0C),
                        cardColor: const Color(0xFF1A1715),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Hidden Messages Card
                Text(
                  'Security',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1715) : colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2C2825) : colorScheme.outlineVariant.withOpacity(0.8),
                      width: 1.2,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: [
                          Icon(
                            _hasPassword ? Icons.lock_rounded : Icons.lock_open_rounded,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Hidden Messages',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _hasPassword
                            ? 'A reveal password is set. Hidden entries are locked in the timeline.'
                            : 'Set a password before hiding entries in the timeline.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                              height: 1.3,
                            ),
                      ),
                      const SizedBox(height: 20),
                      if (_hasPassword) ...[
                        TextField(
                          key: const Key('current_password_field'),
                          controller: _currentPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Current reveal password',
                            prefixIcon: Icon(Icons.password_rounded),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextField(
                        key: const Key('new_password_field'),
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: _hasPassword ? 'New reveal password' : 'Reveal password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _savePassword,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.save_rounded, size: 18),
                          label: Text(
                            _hasPassword ? 'Update Password' : 'Set Password',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Vibe Calendar Settings
                Text(
                  'Vibe Calendar Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1715) : colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2C2825) : colorScheme.outlineVariant.withOpacity(0.8),
                      width: 1.2,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Column(
                    children: <Widget>[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.calendar_view_week_rounded, color: colorScheme.primary),
                        title: const Text('Start Day of Week', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(_startDayOfWeek == 1 ? 'Monday' : 'Sunday', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant.withOpacity(0.7))),
                        trailing: DropdownButton<int>(
                          value: _startDayOfWeek,
                          underline: const SizedBox(),
                          onChanged: (value) {
                            if (value != null) {
                              _saveStartDayOfWeek(value);
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Monday')),
                            DropdownMenuItem(value: 7, child: Text('Sunday')),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: Icon(Icons.local_fire_department_rounded, color: colorScheme.primary),
                        title: const Text('Show Vibe Streaks', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Show streak counts on calendar and timeline', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant.withOpacity(0.7))),
                        value: _showStreaks,
                        onChanged: _saveShowStreaks,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Vibe Check-In Bot Settings
                Text(
                  'Vibe Check-In Bot Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1715) : colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2C2825) : colorScheme.outlineVariant.withOpacity(0.8),
                      width: 1.2,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Column(
                    children: <Widget>[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: Icon(Icons.smart_toy_outlined, color: colorScheme.primary),
                        title: const Text('Enable Daily Vibe Check Bot', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Bot will check in automatically once a day', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant.withOpacity(0.7))),
                        value: _botEnabled,
                        onChanged: _saveBotEnabled,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.schedule_rounded, color: colorScheme.primary),
                        title: const Text('Scheduled Check-In Time', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(_formatTimeStr(_botTime), style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant.withOpacity(0.7))),
                        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colorScheme.onSurfaceVariant),
                        onTap: _botEnabled ? _selectBotTime : null,
                        enabled: _botEnabled,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                        title: const Text('Clear Vibe Check History', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                        subtitle: const Text('Delete all bot conversation messages', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.redAccent),
                        onTap: _clearBotHistory,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildThemeCard({
    required String title,
    required String subtitle,
    required String themeName,
    required Color primaryColor,
    required Color bgColor,
    required Color cardColor,
  }) {
    final isSelected = _currentTheme == themeName;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _saveTheme(themeName),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? primaryColor.withOpacity(0.08) 
              : (isDarkTheme ? const Color(0xFF1E1A17) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? primaryColor 
                : (isDarkTheme ? const Color(0xFF2C2825) : Theme.of(context).colorScheme.outlineVariant),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(isDarkTheme ? 0.25 : 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDarkTheme ? Colors.white : const Color(0xFF1E1613),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: primaryColor,
                    size: 18,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isDarkTheme ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 14),
            // Mini Palette Preview
            Container(
              height: 34,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDarkTheme ? const Color(0xFF2D2825) : Colors.black.withOpacity(0.05),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
