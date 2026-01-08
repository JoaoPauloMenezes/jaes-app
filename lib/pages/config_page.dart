import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FlutterTts _flutterTts = FlutterTts();
  late SharedPreferences _prefs;
  
  bool _ttsEnabled = true;
  double _ttsPitch = 1.0;
  double _ttsRate = 1.0;
  String _ttsVoice = '';
  List<dynamic> _availableVoices = [];
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadTtsSettings();
    _loadAvailableVoices();
  }

  Future<void> _loadCurrentUser() async {
    final user = await UserService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  Future<void> _loadAvailableVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      if (mounted) {
        setState(() {
          _availableVoices = voices ?? [];
          if (_availableVoices.isNotEmpty && _ttsVoice.isEmpty) {
            _ttsVoice = _availableVoices.first.toString();
          }
        });
      }
    } catch (e) {
      print('Error loading voices: $e');
    }
  }

  Future<void> _loadTtsSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _ttsEnabled = _prefs.getBool('tts_enabled') ?? true;
      _ttsPitch = _prefs.getDouble('tts_pitch') ?? 1.0;
      _ttsRate = _prefs.getDouble('tts_rate') ?? 1.0;
      _ttsVoice = _prefs.getString('tts_voice') ?? '';
    });
  }

  Future<void> _saveTtsSetting(String key, dynamic value) async {
    if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    } else if (value is String) {
      await _prefs.setString(key, value);
    }
  }

  void _updateTtsEnabled(bool value) {
    setState(() {
      _ttsEnabled = value;
    });
    _saveTtsSetting('tts_enabled', value);
  }

  void _updateTtsPitch(double value) {
    setState(() {
      _ttsPitch = value;
    });
    _saveTtsSetting('tts_pitch', value);
  }

  void _updateTtsRate(double value) {
    setState(() {
      _ttsRate = value;
    });
    _saveTtsSetting('tts_rate', value);
  }

  void _updateTtsVoice(String? value) {
    if (value != null) {
      setState(() {
        _ttsVoice = value;
      });
      _saveTtsSetting('tts_voice', value);
    }
  }

  String _formatVoiceDisplay(dynamic voice) {
    try {
      final voiceMap = voice is Map ? voice : {};
      final locale = voiceMap['locale'] ?? 'Unknown';
      final name = voiceMap['name'] ?? 'Default';
      return '$locale - $name';
    } catch (e) {
      return voice.toString();
    }
  }

  String _voiceToString(dynamic voice) {
    try {
      if (voice is Map) {
        return voice.toString();
      }
      return voice.toString();
    } catch (e) {
      return voice.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // User Profile Section
          _buildUserProfileSection(_currentUser),
          const SizedBox(height: 32),

          // TTS Configuration Section
          _buildTtsConfigSection(),
        ],
      ),
    );
  }

  Widget _buildUserProfileSection(AppUser? user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // User Avatar/Picture
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.shade100,
                border: Border.all(
                  color: Colors.blue.shade300,
                  width: 2,
                ),
              ),
              child: user?.photoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        user!.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.blue.shade600,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.blue.shade600,
                    ),
            ),
            const SizedBox(height: 16),

            // User Name
            Text(
              user?.name ?? 'User',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // User Email
            Text(
              user?.email ?? 'No email',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // User ID
            Text(
              'ID: ${user?.id.substring(0, 8) ?? 'N/A'}...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTtsConfigSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Row(
              children: [
                Icon(Icons.volume_up, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Text-to-Speech Configuration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Enable/Disable TTS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enable Sound',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _ttsEnabled ? 'ON' : 'OFF',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _ttsEnabled,
                  onChanged: _updateTtsEnabled,
                  activeColor: Colors.blue.shade600,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Pitch Control
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pitch',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _ttsPitch.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _ttsPitch,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  label: _ttsPitch.toStringAsFixed(2),
                  onChanged: _updateTtsPitch,
                  activeColor: Colors.blue.shade600,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Low',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      Text(
                        'High',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Rate Control
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Speech Rate',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _ttsRate.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _ttsRate,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  label: _ttsRate.toStringAsFixed(2),
                  onChanged: _updateTtsRate,
                  activeColor: Colors.green.shade600,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Slow',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      Text(
                        'Fast',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Voice Selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Voice',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                _availableVoices.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Loading voices...',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _ttsVoice.isNotEmpty ? _ttsVoice : null,
                          hint: Text(
                            'Select a voice',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          items: _availableVoices.map((voice) {
                            final voiceStr = _voiceToString(voice);
                            final voiceDisplay = _formatVoiceDisplay(voice);
                            return DropdownMenuItem<String>(
                              value: voiceStr,
                              child: Text(
                                voiceDisplay,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: _updateTtsVoice,
                          underline: const SizedBox(),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}