import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DeviceUtils {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<String> getDeviceInfo() async {
    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        return '${webInfo.browserName.name} (${webInfo.platform})';
      } else {
        if (defaultTargetPlatform == TargetPlatform.android) {
          final androidInfo = await _deviceInfo.androidInfo;
          return '${androidInfo.manufacturer} ${androidInfo.model}';
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final iosInfo = await _deviceInfo.iosInfo;
          return '${iosInfo.name} ${iosInfo.systemName} ${iosInfo.systemVersion}';
        } else {
          return 'Unknown Device';
        }
      }
    } catch (e) {
      return 'Unknown Device';
    }
  }

  static Future<Map<String, String>> getIpLocation() async {
    try {
      // Using ipapi.co (Free tier: 1000 requests/day)
      // Alternative: https://ipwhois.app/json/ (10k/month)
      // Alternative: http://ip-api.com/json (HTTP only, usually blocked by default on mobile)
      final response = await http.get(Uri.parse('https://ipapi.co/json/'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ip = data['ip'] ?? 'Unknown IP';
        final city = data['city'] ?? '';
        final country = data['country_name'] ?? '';
        String location = '';

        if (city.isNotEmpty && country.isNotEmpty) {
          location = '$city, $country';
        } else if (city.isNotEmpty) {
          location = city;
        } else if (country.isNotEmpty) {
          location = country;
        }

        return {
          'ip': ip,
          'location': location.isEmpty ? 'Unknown Location' : location,
        };
      }
    } catch (e) {
      debugPrint('Error fetching IP location: $e');
    }
    return {
      'ip': 'Unknown IP',
      'location': 'Unknown Location',
    };
  }
}
