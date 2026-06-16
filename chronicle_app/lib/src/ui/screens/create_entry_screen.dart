import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/services/entry_service.dart';
import '../../application/services/location_service.dart';
import '../widgets/audio_recorder_widget.dart';

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
    final appBarActionColor =
        Theme.of(context).appBarTheme.foregroundColor ?? colorScheme.onPrimary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Entry'),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(foregroundColor: appBarActionColor),
            onPressed: _isSaving ? null : _saveEntry,
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
                  hintText: 'Write a thought, memory, or note...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_locationName != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: InputChip(
                avatar: const Icon(Icons.location_on, size: 16),
                label: Text(_locationName!),
                onDeleted: () {
                  setState(() {
                    _locationName = null;
                    _latitude = null;
                    _longitude = null;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_selectedImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.file(_selectedImage!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _isSaving || _recordedVoiceFile != null ? null : _attachImage,
              icon: const Icon(Icons.image_outlined),
              label: Text(
                _selectedImage == null ? 'Attach Image' : 'Change Image',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _isSaving ? null : _selectLocation,
              icon: const Icon(Icons.location_on_outlined),
              label: Text(
                _locationName == null ? 'Add Location' : 'Change Location',
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedImage == null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: AudioRecorderWidget(
                key: const Key('audio_recorder'),
                onAudioRecorded: (file) {
                  setState(() {
                    _recordedVoiceFile = file;
                  });
                },
              ),
            ),
          ],
        ],
      ),
    );
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
      title: const Text('Add Location'),
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
                    icon: const Icon(Icons.my_location),
                    label: const Text('Use Current Location'),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('OR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _customLocationController,
                    decoration: const InputDecoration(
                      labelText: 'Enter custom location name',
                      border: OutlineInputBorder(),
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
