import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/services/entry_service.dart';
import '../../application/services/location_service.dart';
import '../../application/services/speech_to_text_service.dart';
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
  String? _voiceTranscript;
  bool _isTranscribing = false;
  Future<String?>? _transcriptionFuture;

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

  void _startTranscription(File file) {
    setState(() {
      _isTranscribing = true;
      _voiceTranscript = null;
    });

    final speechService = SpeechToTextService();
    _transcriptionFuture = speechService.transcribe(file).then((transcript) {
      if (mounted) {
        setState(() {
          _voiceTranscript = transcript;
          _isTranscribing = false;
        });
      }
      return transcript;
    }).catchError((_) {
      if (mounted) {
        setState(() {
          _isTranscribing = false;
        });
      }
      return null;
    });
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
      String? transcript = _voiceTranscript;
      if (_recordedVoiceFile != null && transcript == null && _transcriptionFuture != null) {
        transcript = await _transcriptionFuture;
      }

      await widget.entryService.createEntry(
        content: _contentController.text,
        image: _selectedImage,
        voiceNote: _recordedVoiceFile,
        locationName: _locationName,
        latitude: _latitude,
        longitude: _longitude,
        mood: _selectedMood,
        transcript: transcript,
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
                            if (file == null) {
                              _voiceTranscript = null;
                              _transcriptionFuture = null;
                            }
                          });
                          if (file != null) {
                            _startTranscription(file);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Voice Transcript Preview panel
                    if (_recordedVoiceFile != null) ...[
                      _buildTranscriptPreviewPanel(),
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
          _buildGlassmorphicOverlay(),
        ],
      ),
    );
  }

  Widget _buildTranscriptPreviewPanel() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E1A17) : colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isDark ? const Color(0xFF2C2825) : colorScheme.outlineVariant.withOpacity(0.8),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description_outlined, 
                  size: 18, 
                  color: isDark ? Colors.white70 : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Voice Transcript Preview',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : colorScheme.onSurface,
                      ),
                ),
                const Spacer(),
                if (_isTranscribing)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
              ],
            ),
            const SizedBox(height: 12),
            if (_isTranscribing)
              Text(
                'Transcribing voice note... 🎙️',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white54 : colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
              )
            else
              TextFormField(
                initialValue: _voiceTranscript,
                maxLines: 3,
                minLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Voice transcript will appear here...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white70 : colorScheme.onSurface,
                    ),
                onChanged: (text) {
                  _voiceTranscript = text;
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassmorphicOverlay() {
    if (!_isSaving || _recordedVoiceFile == null) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.35),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                )
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Transcribing your voice... 🎙️',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
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
