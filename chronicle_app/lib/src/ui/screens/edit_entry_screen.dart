import 'package:flutter/material.dart';

import '../../application/services/entry_service.dart';
import '../widgets/vibe_selector_strip.dart';

class EditEntryScreen extends StatefulWidget {
  const EditEntryScreen({
    super.key,
    required this.entryService,
    required this.entryId,
    required this.initialContent,
    this.initialMood = 'none',
  });

  final EntryService entryService;
  final int entryId;
  final String initialContent;
  final String initialMood;

  @override
  State<EditEntryScreen> createState() => _EditEntryScreenState();
}

class _EditEntryScreenState extends State<EditEntryScreen> {
  late final TextEditingController _contentController;
  bool _isSaving = false;
  late String _selectedMood;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.initialContent);
    _selectedMood = widget.initialMood;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveEdit() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.entryService.editEntry(
        entryId: widget.entryId,
        content: _contentController.text,
        mood: _selectedMood,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save changes right now.')),
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
      appBar: AppBar(
        title: const Text('Edit Entry'),
        actions: <Widget>[
          TextButton(
            onPressed: _isSaving ? null : _saveEdit,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1715) : colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF2C2825) : colorScheme.outlineVariant.withOpacity(0.8),
                width: 1.2,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _contentController,
              maxLines: 8,
              minLines: 6,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface,
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: 'Update your entry...',
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 20),
          VibeSelectorStrip(
            selectedMood: _selectedMood,
            onMoodSelected: (mood) {
              setState(() {
                _selectedMood = mood;
              });
            },
          ),
        ],
      ),
    );
  }
}
