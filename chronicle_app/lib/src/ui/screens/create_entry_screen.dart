import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/services/entry_service.dart';
import '../../application/services/location_service.dart';
import '../widgets/audio_recorder_widget.dart';
import '../widgets/vibe_selector_strip.dart';

typedef ImageFilePicker = Future<File?> Function();

class CreateEntryScreen extends StatefulWidget {
  const CreateEntryScreen({
    super.key,
    required this.entryService,
    this.pickImage,
  });

  final EntryService entryService;
  final ImageFilePicker? pickImage;

  @override
  State<CreateEntryScreen> createState() => _CreateEntryScreenState();
}

class _CreateEntryScreenState extends State<CreateEntryScreen> {
  final TextEditingController _contentController = TextEditingController();
  File? _selectedImage;
  File? _recordedVoiceFile;
  bool _isSaving = false;
  String? _locationName;
  double? _latitude;
  double? _longitude;
  String _selectedMood = 'none';
  DateTime? _timeCapsuleUnlockDate;

  @override
  void dispose() {
    _contentController.dispose();
    _cleanupTempAudio();
    super.dispose();
  }

  Future<void> _cleanupTempAudio() async {
    final file = _recordedVoiceFile;
    if (file != null && await file.exists()) {
      try {
        await file.delete();
      } catch (_) {
        // Ignore any errors during cleanup
      }
    }
  }

  Future<void> _attachImage() async {
    final picker = widget.pickImage ?? _defaultPickImage;
    final image = await picker();
    if (!mounted || image == null) {
      return;
    }

    setState(() {
      _selectedImage = image;
    });
  }

  Future<void> _saveEntry() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.entryService.createEntry(
        content: _contentController.text,
        image: _selectedImage,
        voiceNote: _recordedVoiceFile,
        locationName: _locationName,
        latitude: _latitude,
        longitude: _longitude,
        mood: _selectedMood,
        unlockAt: _timeCapsuleUnlockDate?.millisecondsSinceEpoch,
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
        const SnackBar(content: Text('Unable to save the entry right now.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _selectLocation() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return const _LocationPickDialog(locationService: LocationService());
      },
    );

    if (result != null) {
      setState(() {
        _locationName = result['name'] as String?;
        _latitude = result['latitude'] as double?;
        _longitude = result['longitude'] as double?;
      });
    }
  }

  Future<File?> _defaultPickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) {
      return null;
    }

    return File(pickedFile.path);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Entry'),
        actions: <Widget>[
          TextButton(
            onPressed: _isSaving ? null : _saveEntry,
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
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: <Widget>[
                    if (_timeCapsuleUnlockDate != null) ...[
                      _buildTimeCapsuleActiveBadge(context),
                      const SizedBox(height: 12),
                    ],
                    // Content editor Card
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
                          hintText: 'Write a thought, memory, or note...',
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
                    const SizedBox(height: 16),

                    // Location attached preview
                    if (_locationName != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1A17) : colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2C2825) : colorScheme.outlineVariant,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_rounded, color: colorScheme.primary, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _locationName!,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _locationName = null;
                                  _latitude = null;
                                  _longitude = null;
                                });
                              },
                              child: Icon(
                                Icons.cancel_rounded,
                                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Image attached preview with clear/delete button
                    if (_selectedImage != null) ...[
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: AspectRatio(
                              aspectRatio: 16 / 10,
                              child: Image.file(_selectedImage!, fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImage = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Voice Note Recorder preview
                    if (_selectedImage == null) ...[
                      AudioRecorderWidget(
                        key: const Key('audio_recorder'),
                        onAudioRecorded: (file) {
                          setState(() {
                            _recordedVoiceFile = file;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Vibe Selector Strip
                    VibeSelectorStrip(
                      selectedMood: _selectedMood,
                      onMoodSelected: (mood) {
                        setState(() {
                          _selectedMood = mood;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              // Attachment toolbar at the bottom
              _buildAttachmentToolbar(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentToolbar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outlineColor = isDark ? const Color(0xFF2C2825) : colorScheme.outlineVariant.withOpacity(0.8);

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141211) : colorScheme.surface,
        border: Border(
          top: BorderSide(color: outlineColor, width: 1.2),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _isSaving || _recordedVoiceFile != null ? null : _attachImage,
            icon: Icon(
              _selectedImage == null ? Icons.image_outlined : Icons.image_rounded,
              color: _recordedVoiceFile != null 
                  ? colorScheme.onSurfaceVariant.withOpacity(0.3) 
                  : colorScheme.primary,
              size: 24,
            ),
            tooltip: 'Attach Image',
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isSaving ? null : _selectLocation,
            icon: Icon(
              _locationName == null ? Icons.location_on_outlined : Icons.location_on_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
            tooltip: 'Add Location',
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isSaving ? null : _showTimeCapsulePicker,
            icon: Icon(
              _timeCapsuleUnlockDate == null ? Icons.lock_outline : Icons.lock,
              color: _timeCapsuleUnlockDate == null ? colorScheme.primary : Colors.purpleAccent,
              size: 24,
            ),
            tooltip: 'Seal Time Capsule',
          ),
          const Spacer(),
          if (_selectedImage != null || _locationName != null || _recordedVoiceFile != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Attached',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeCapsuleActiveBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedDate = '${_timeCapsuleUnlockDate!.year}-${_timeCapsuleUnlockDate!.month.toString().padLeft(2, '0')}-${_timeCapsuleUnlockDate!.day.toString().padLeft(2, '0')}';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.purple.shade900.withOpacity(0.35) : Colors.purple.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purpleAccent.withOpacity(isDark ? 0.4 : 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(isDark ? 0.15 : 0.05),
            blurRadius: 8,
            spreadRadius: 0.5,
          )
        ],
      ),
      child: Row(
        children: [
          const Text('⏳ ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              'Sealed until $formattedDate',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.purple.shade100 : Colors.purple.shade700,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _timeCapsuleUnlockDate = null;
              });
            },
            child: Icon(
              Icons.cancel_rounded,
              color: isDark ? Colors.purple.shade200.withOpacity(0.8) : Colors.purple.shade400,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTimeCapsulePicker() async {
    final pickedDate = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _TimeCapsulePickerSheet(initialDate: _timeCapsuleUnlockDate);
      },
    );

    if (pickedDate != null) {
      setState(() {
        _timeCapsuleUnlockDate = pickedDate;
      });
    }
  }
}

class _LocationPickDialog extends StatefulWidget {
  const _LocationPickDialog({required this.locationService});

  final LocationService locationService;

  @override
  State<_LocationPickDialog> createState() => _LocationPickDialogState();
}

class _LocationPickDialogState extends State<_LocationPickDialog> {
  final TextEditingController _customLocationController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _customLocationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final position = await widget.locationService.getCurrentPosition();
      if (position == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not access device location. Please ensure location services and permissions are enabled.';
        });
        return;
      }

      final name = await widget.locationService.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      Navigator.of(context).pop(<String, dynamic>{
        'name': name ?? '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching location: $e';
      });
    }
  }

  void _submitCustomLocation() {
    final name = _customLocationController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(<String, dynamic>{
      'name': name,
      'latitude': null,
      'longitude': null,
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Add Location', style: TextStyle(fontWeight: FontWeight.bold)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: _isLoading
          ? const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Fetching location details...'),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: colorScheme.error, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.my_location_rounded),
                    label: const Text('Use Current Location'),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('OR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _customLocationController,
                    decoration: const InputDecoration(
                      labelText: 'Enter custom location name',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    onSubmitted: (_) => _submitCustomLocation(),
                  ),
                ],
              ),
            ),
      actions: _isLoading
          ? null
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: _submitCustomLocation,
                child: const Text('Add'),
              ),
            ],
    );
  }
}

class _TimeCapsulePickerSheet extends StatefulWidget {
  const _TimeCapsulePickerSheet({this.initialDate});

  final DateTime? initialDate;

  @override
  State<_TimeCapsulePickerSheet> createState() => _TimeCapsulePickerSheetState();
}

class _TimeCapsulePickerSheetState extends State<_TimeCapsulePickerSheet> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  void _selectPreset(Duration duration) {
    setState(() {
      _selectedDate = DateTime.now().add(duration);
    });
  }

  void _selectMonthsPreset(int months) {
    final now = DateTime.now();
    setState(() {
      _selectedDate = DateTime(now.year, now.month + months, now.day, now.hour, now.minute);
    });
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final firstDate = now.add(const Duration(days: 1));
    final lastDate = now.add(const Duration(days: 365 * 10));
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate != null && _selectedDate!.isAfter(firstDate) ? _selectedDate! : firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.purpleAccent,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day, now.hour, now.minute);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final hasSelection = _selectedDate != null;
    String selectionText = 'No date selected';
    if (hasSelection) {
      final daysDiff = _selectedDate!.difference(DateTime.now()).inDays;
      final format = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      selectionText = 'Sealed until $format (in $daysDiff days)';
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1A22).withOpacity(0.85) : Colors.white.withOpacity(0.9),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : colorScheme.primary.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Seal a Time Capsule ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  '⏳',
                  style: TextStyle(fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _PresetCapsule(
                    label: '1 Week ⏳',
                    onTap: () => _selectPreset(const Duration(days: 7)),
                  ),
                  const SizedBox(width: 8),
                  _PresetCapsule(
                    label: '1 Month 🗓️',
                    onTap: () => _selectMonthsPreset(1),
                  ),
                  const SizedBox(width: 8),
                  _PresetCapsule(
                    label: '6 Months 🚀',
                    onTap: () => _selectMonthsPreset(6),
                  ),
                  const SizedBox(width: 8),
                  _PresetCapsule(
                    label: '1 Year 🎂',
                    onTap: () => _selectMonthsPreset(12),
                  ),
                  const SizedBox(width: 8),
                  _PresetCapsule(
                    label: 'Custom Date ⚙️',
                    onTap: _pickCustomDate,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.hourglass_bottom,
                    color: hasSelection ? Colors.purpleAccent : colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selectionText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: hasSelection ? (isDark ? Colors.purple.shade100 : Colors.purple.shade700) : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Once sealed, you won't be able to read or edit this entry until the unlock date. Choose wisely!",
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.orange.shade200 : Colors.orange.shade800,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: hasSelection
                  ? () => Navigator.of(context).pop(_selectedDate)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.purpleAccent.withOpacity(0.2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: Colors.purpleAccent.withOpacity(0.5),
              ),
              child: const Text(
                'Seal Capsule & Close',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetCapsule extends StatelessWidget {
  const _PresetCapsule({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.purple.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.purple.withOpacity(0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.purpleAccent.withOpacity(0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
