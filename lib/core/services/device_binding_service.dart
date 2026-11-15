
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class DeviceBindingService {
  final SupabaseClient supabase = Supabase.instance.client;

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static const String _deviceKey = 'prokon_device_identifier';

  Future<String> _getDeviceIdentifier() async {
    String? identifier = await _storage.read(key: _deviceKey);

    if (identifier == null) {
      identifier = const Uuid().v4();

      await _storage.write(
        key: _deviceKey,
        value: identifier,
      );
    }

    return identifier;
  }

  Future<Map<String, dynamic>> bindDevice() async {
    try {
      final identifier = await _getDeviceIdentifier();

      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      final deviceName =
          '${androidInfo.manufacturer} ${androidInfo.model}';

      final response = await supabase.rpc(
        'bind_my_device',
        params: {
          'p_device_identifier': identifier,
          'p_device_nama': deviceName,
        },
      );

      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }

      return {
        'success': false,
        'code': 'invalid_response',
        'message': 'Respons server tidak valid.',
      };
    } catch (e) {
      return {
        'success': false,
        'code': 'binding_error',
        'message': 'Gagal memeriksa perangkat: $e',
      };
    }
  }
}
