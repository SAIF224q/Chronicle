import 'package:flutter/material.dart';

import '../../application/services/entry_service.dart';

class EditEntryScreen extends StatefulWidget {
  const EditEntryScreen({
    super.key,
    required this.entryService,
    required this.entryId,
    required this.initialContent,
  });

  final EntryService entryService;
  final int entryId;
  final String initialContent;

  @override
  State<EditEntryScreen> createState() => _EditEntryScreenState();
}

class _EditEntryScreenState extends State<EditEntryScreen> {
  late final TextEditingController _contentController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.initialContent);
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
    final appBarActionColor =
        Theme.of(context).appBarTheme.foregroundColor ?? colorScheme.onPrimary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Entry'),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(foregroundColor: appBarActionColor),
            onPressed: _isSaving ? null : _saveEdit,
            child: _isSaving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        appBarActionColor,
                      ),
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _contentController,
                maxLines: 8,
                minLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Update your entry...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
