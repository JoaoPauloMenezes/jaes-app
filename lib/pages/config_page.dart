import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../services/data_sync_service.dart';
import '../services/user_service.dart';
import 'firebase_login_page.dart';

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
    {'key': 'muito_lento', 'label': 'Muito Lento', 'pitch': 0.65, 'rate': 0.4},
    {'key': 'lento', 'label': 'Lento', 'pitch': 0.75, 'rate': 0.6},
    {'key': 'normal', 'label': 'Normal', 'pitch': 0.9, 'rate': 0.8},
    {'key': 'rapido', 'label': 'Rápido', 'pitch': 0.95, 'rate': 1.0},
    {'key': 'muito_rapido', 'label': 'Muito Rápido', 'pitch': 1.05, 'rate': 1.2},
  ];

  bool _ttsEnabled = true;
  double _ttsPitch = 1.0;
  double _ttsRate = 1.0;
  String _ttsSpeedPreset = 'normal';
  String _ttsVoice = '';
  List<dynamic> _availableVoices = [];
  AppUser? _currentUser;
  bool _isDeletingAccount = false;

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

  String _ttsSpeedTestPhrase() {
    final locale = _ttsVoice.split('|').length > 1
        ? _ttsVoice.split('|')[1].toLowerCase()
        : '';
    if (locale.startsWith('pt')) {
      return 'Essa é a velocidade atual de leitura selecionada.';
    }
    if (locale.startsWith('es')) {
      return 'Esta es la velocidad de lectura seleccionada actualmente.';
    }
    if (locale.startsWith('fr')) {
      return 'Ceci est la vitesse de lecture actuellement sélectionnée.';
    }
    if (locale.startsWith('de')) {
      return 'Dies ist die aktuell ausgewählte Lesegeschwindigkeit.';
    }
    return 'This is the currently selected reading speed.';
  }

  Future<void> _speakSpeedTest() async {
    await _flutterTts.stop();
    await _flutterTts.speak(_ttsSpeedTestPhrase());
  }

  Future<void> _logoutLocally() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair deste dispositivo?'),
        content: const Text(
          'Os dados salvos neste dispositivo serão apagados. Os dados sincronizados no nosso servidor podem ser baixados novamente depois',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair e apagar'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    final cleared = await DataSyncService.clearAllLocalData();
    await UserService.clearUser();
    await GoogleSignIn().signOut();
    await _firebaseAuth.signOut();

    if (!mounted) return;
    if (!cleared) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel apagar todos os dados locais.')),
      );
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const FirebaseLoginPage()),
      (_) => false,
    );
  }

  Future<void> _deleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar conta permanentemente?'),
        content: const Text(
          'Essa ação vai apagar sua conta e todos os seus dados deste dispositivo e do nosso servidor. '
          'Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar conta'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    setState(() => _isDeletingAccount = true);

    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw StateError('Nenhum usuário autenticado.');
      }

      final reauthenticated = await _reauthenticateUser(user);
      if (!reauthenticated) {
        if (mounted) setState(() => _isDeletingAccount = false);
        return;
      }

      final serverDataDeleted = await DataSyncService.deleteAllServerData();
      if (!serverDataDeleted) {
        throw StateError(
          'Não foi possível remover os dados do servidor. A conta foi mantida.',
        );
      }

      await _deleteFirebaseUser(user);
      final localDataDeleted = await DataSyncService.clearAllLocalData();
      await UserService.clearUser();
      await GoogleSignIn().signOut();

      if (!mounted) return;
      if (!localDataDeleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Conta apagada, mas alguns dados locais não puderam ser removidos.',
            ),
          ),
        );
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const FirebaseLoginPage()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isDeletingAccount = false);
      final message = e.code == 'requires-recent-login'
          ? 'Por segurança, saia e entre novamente na sua conta antes de apagá-la.'
          : 'Erro ao apagar conta: ${e.message}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeletingAccount = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao apagar conta: $e')),
      );
    }
  }

  Future<bool> _reauthenticateUser(User user) async {
    final credential = await _getReauthenticationCredential(user);
    if (credential == null) return false;
    await user.reauthenticateWithCredential(credential);
    return true;
  }

  Future<void> _deleteFirebaseUser(User user) async {
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') rethrow;

      final credential = await _getReauthenticationCredential(user);
      if (credential == null) {
        throw StateError('A reautenticação foi cancelada.');
      }
      await user.reauthenticateWithCredential(credential);
      await user.delete();
    }
  }

  Future<AuthCredential?> _getReauthenticationCredential(User user) async {
    final providers = user.providerData.map((info) => info.providerId).toSet();

    if (providers.contains('google.com')) {
      final googleUser = await GoogleSignIn(scopes: ['email', 'profile']).signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      return GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
    }

    if (providers.contains('apple.com') &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS) {
      final rawNonce = _generateNonce();
      try {
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
        );
        return OAuthProvider('apple.com').credential(
          idToken: appleCredential.identityToken,
          rawNonce: rawNonce,
        );
      } on SignInWithAppleAuthorizationException catch (e) {
        if (e.code == AuthorizationErrorCode.canceled) return null;
        rethrow;
      }
    }

    if (providers.contains('password') && user.email != null) {
      final password = await _requestPassword();
      if (password == null) return null;
      return EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
    }

    throw StateError(
      'Não foi possível identificar um método de login para confirmar sua identidade.',
    );
  }

  Future<String?> _requestPassword() async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirme sua senha'),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Senha'),
            onSubmitted: (password) => Navigator.pop(dialogContext, password),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
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
    _speakSpeedTest();
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
          const SizedBox(height: 24),
          _buildLocalLogoutSection(),
          const SizedBox(height: 12),
          _buildDeleteAccountSection(),
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

  Widget _buildLocalLogoutSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text('Sair deste dispositivo'),
        subtitle: const Text('Sai da conta atual e apaga os dados locais.'),
        onTap: _logoutLocally,
      ),
    );
  }

  Widget _buildDeleteAccountSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: _isDeletingAccount
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.delete_forever, color: Colors.red),
        title: const Text('Apagar conta'),
        subtitle: const Text('Remove permanentemente sua conta e seus dados do dispositivo e do servidor.'),
        onTap: _isDeletingAccount ? null : _deleteAccount,
      ),
    );
  }
}