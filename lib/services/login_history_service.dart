import 'package:chingu/models/models.dart';

class LoginHistoryService {
  // 模擬數據服務 - 實際專案中應連接後端 API 或 Firestore
  // Mock data service - should connect to backend API or Firestore in real project
  Future<List<LoginHistoryModel>> getLoginHistory(String userId) async {
    // 模擬網路延遲
    await Future.delayed(const Duration(milliseconds: 800));

    final now = DateTime.now();

    // 根據 userId 回傳一些模擬數據
    return [
      LoginHistoryModel(
        id: '1',
        userId: userId,
        timestamp: now.subtract(const Duration(minutes: 5)),
        location: 'Taipei, Taiwan',
        device: 'iPhone 13 Pro',
        ipAddress: '192.168.1.1',
        status: 'success',
      ),
      LoginHistoryModel(
        id: '2',
        userId: userId,
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        location: 'Taipei, Taiwan',
        device: 'iPhone 13 Pro',
        ipAddress: '192.168.1.1',
        status: 'success',
      ),
      LoginHistoryModel(
        id: '3',
        userId: userId,
        timestamp: now.subtract(const Duration(days: 3, hours: 5)),
        location: 'Taichung, Taiwan',
        device: 'MacBook Pro',
        ipAddress: '203.145.2.10',
        status: 'success',
      ),
      LoginHistoryModel(
        id: '4',
        userId: userId,
        timestamp: now.subtract(const Duration(days: 7)),
        location: 'Kaohsiung, Taiwan',
        device: 'iPhone 13 Pro',
        ipAddress: '114.32.5.88',
        status: 'success',
      ),
      LoginHistoryModel(
        id: '5',
        userId: userId,
        timestamp: now.subtract(const Duration(days: 14)),
        location: 'Taipei, Taiwan',
        device: 'Chrome on Windows',
        ipAddress: '61.230.12.5',
        status: 'success',
      ),
    ];
  }
}
