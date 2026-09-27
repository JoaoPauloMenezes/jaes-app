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
  
  // Fixed pitch/rate combos exposed to the user as simple speed presets.
  static const List<Map<String, Object>> _speedPresets = [
    {'key': 'muito_lento', 'label': 'Muito Lento', 'pitch': 0.85, 'rate': 0.6},
    {'key': 'lento', 'label': 'Lento', 'pitch': 0.95, 'rate': 0.8},
    {'key': 'normal', 'label': 'Normal', 'pitch': 1.0, 'rate': 1.0},
    {'key': 'rapido', 'label': 'Rápido', 'pitch': 1.05, 'rate': 1.3},
    {'key': 'muito_rapido', 'label': 'Muito Rápido', 'pitch': 1.15, 'rate': 1.6},
  ];

  bool _ttsEnabled = true;
  double _ttsPitch = 1.0;
  double _ttsRate = 1.0;
  String _ttsSpeedPreset = 'normal';
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
            _ttsVoice = _voiceKey(_availableVoices.first);
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
      final savedPreset = _prefs.getString('tts_speed_preset');
      if (savedPreset != null &&
          _speedPresets.any((p) => p['key'] == savedPreset)) {
        _ttsSpeedPreset = savedPreset;
      }
      final preset = _speedPresets.firstWhere(
        (p) => p['key'] == _ttsSpeedPreset,
        orElse: () => _speedPresets[2],
      );
      _ttsPitch = preset['pitch'] as double;
      _ttsRate = preset['rate'] as double;
      final savedName = _prefs.getString('tts_voice_name') ?? '';
      final savedLocale = _prefs.getString('tts_voice_locale') ?? '';
      _ttsVoice = savedName.isNotEmpty ? '$savedName|$savedLocale' : '';
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

  void _updateSpeedPreset(String? presetKey) {
    if (presetKey == null) return;
    final preset = _speedPresets.firstWhere(
      (p) => p['key'] == presetKey,
      orElse: () => _speedPresets[2],
    );
    final pitch = preset['pitch'] as double;
    final rate = preset['rate'] as double;
    setState(() {
      _ttsSpeedPreset = presetKey;
      _ttsPitch = pitch;
      _ttsRate = rate;
    });
    _saveTtsSetting('tts_speed_preset', presetKey);
    _saveTtsSetting('tts_pitch', pitch);
    _saveTtsSetting('tts_rate', rate);
    _flutterTts.setPitch(pitch);
    _flutterTts.setSpeechRate(rate);
  }

  void _updateTtsVoice(String? value) {
    if (value == null) return;
    final parts = value.split('|');
    final name = parts.isNotEmpty ? parts[0] : '';
    final locale = parts.length > 1 ? parts[1] : '';
    setState(() {
      _ttsVoice = value;
    });
    _saveTtsSetting('tts_voice_name', name);
    _saveTtsSetting('tts_voice_locale', locale);
    _flutterTts.setVoice({'name': name, 'locale': locale});
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

  // Builds a stable "name|locale" key so the dropdown value matches an item
  // even though voice maps are new instances on every getVoices() call.
  String _voiceKey(dynamic voice) {
    try {
      final voiceMap = voice is Map ? voice : {};
      final name = voiceMap['name'] ?? 'Default';
      final locale = voiceMap['locale'] ?? 'Unknown';
      return '$name|$locale';
    } catch (e) {
      return voice.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    // iPhone 7 and other narrow devices (< 380 logical px) get tighter
    // spacing so cards don't feel cramped or unbalanced.
    final isNarrowScreen = MediaQuery.of(context).size.width < 380;
    final outerPadding = isNarrowScreen ? 12.0 : 16.0;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.all(outerPadding),
        children: [
          // User Profile Section
          _buildUserProfileSection(_currentUser),
          SizedBox(height: isNarrowScreen ? 24 : 32),

          // TTS Configuration Section
          _buildTtsConfigSection(isNarrowScreen),
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

  Widget _buildTtsConfigSection(bool isNarrowScreen) {
    final cardPadding = isNarrowScreen ? 12.0 : 16.0;
    final titleFontSize = isNarrowScreen ? 16.0 : 18.0;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Row(
              children: [
                Icon(Icons.volume_up, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Text-to-Speech Configuration',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            SizedBox(height: isNarrowScreen ? 16 : 20),

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
            SizedBox(height: isNarrowScreen ? 16 : 20),

            // Speed Preset Selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Velocidade da Voz',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _ttsSpeedPreset,
                    items: _speedPresets.map((preset) {
                      return DropdownMenuItem<String>(
                        value: preset['key'] as String,
                        child: Text(preset['label'] as String),
                      );
                    }).toList(),
                    onChanged: _updateSpeedPreset,
                    underline: const SizedBox(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
            SizedBox(height: isNarrowScreen ? 18 : 24),

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
                    : Builder(
                        builder: (context) {
                          final voiceKeys = _availableVoices
                              .map((voice) => _voiceKey(voice))
                              .toList();
                          // Guard against a stale/unknown saved value, which
                          // would otherwise crash the DropdownButton.
                          final currentValue =
                              voiceKeys.contains(_ttsVoice) ? _ttsVoice : null;
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: currentValue,
                              hint: Text(
                                'Select a voice',
                                style: TextStyle(color: Colors.grey.shade600),
                                overflow: TextOverflow.ellipsis,
                              ),
                              selectedItemBuilder: (context) {
                                return _availableVoices.map((voice) {
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _formatVoiceDisplay(voice),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  );
                                }).toList();
                              },
                              items: _availableVoices.map((voice) {
                                final voiceStr = _voiceKey(voice);
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
                          );
                        },
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}