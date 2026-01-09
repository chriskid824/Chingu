import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/services/silent_hours_service.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('SilentHoursService', () {
    late SilentHoursService service;

    setUp(() {
      // We don't need FirestoreService for these logic tests
      service = SilentHoursService(firestoreService: null);
    });

    test('isSilentTime returns true when time is within range (same day)', () {
      final start = const TimeOfDay(hour: 9, minute: 0);
      final end = const TimeOfDay(hour: 17, minute: 0);

      // 10:00 is within 09:00 - 17:00
      final time = DateTime(2023, 1, 1, 10, 0);

      expect(service.isSilentTime(start, end, time), isTrue);
    });

    test('isSilentTime returns false when time is outside range (same day)', () {
      final start = const TimeOfDay(hour: 9, minute: 0);
      final end = const TimeOfDay(hour: 17, minute: 0);

      // 08:00 is before 09:00
      final timeBefore = DateTime(2023, 1, 1, 8, 0);
      expect(service.isSilentTime(start, end, timeBefore), isFalse);

      // 18:00 is after 17:00
      final timeAfter = DateTime(2023, 1, 1, 18, 0);
      expect(service.isSilentTime(start, end, timeAfter), isFalse);
    });

    test('isSilentTime returns true when time is within range (overnight)', () {
      final start = const TimeOfDay(hour: 22, minute: 0);
      final end = const TimeOfDay(hour: 7, minute: 0);

      // 23:00 is after start
      final timeLate = DateTime(2023, 1, 1, 23, 0);
      expect(service.isSilentTime(start, end, timeLate), isTrue);

      // 06:00 is before end
      final timeEarly = DateTime(2023, 1, 2, 6, 0);
      expect(service.isSilentTime(start, end, timeEarly), isTrue);
    });

    test('isSilentTime returns false when time is outside range (overnight)', () {
      final start = const TimeOfDay(hour: 22, minute: 0);
      final end = const TimeOfDay(hour: 7, minute: 0);

      // 21:00 is before start
      final timeBefore = DateTime(2023, 1, 1, 21, 0);
      expect(service.isSilentTime(start, end, timeBefore), isFalse);

      // 08:00 is after end
      final timeAfter = DateTime(2023, 1, 2, 8, 0);
      expect(service.isSilentTime(start, end, timeAfter), isFalse);
    });

    test('shouldNotify returns true when silent hours disabled', () {
      final user = UserModel(
        uid: '123',
        name: 'Test',
        email: 'test@example.com',
        age: 25,
        gender: 'male',
        job: 'dev',
        interests: [],
        country: 'TW',
        city: 'Taipei',
        district: 'Xinyi',
        preferredMatchType: 'any',
        minAge: 18,
        maxAge: 30,
        budgetRange: 1,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        isSilentHoursEnabled: false,
      );

      // Time doesn't matter
      expect(service.shouldNotify(user, currentTime: DateTime.now()), isTrue);
    });

    test('shouldNotify returns false when within silent hours', () {
      final user = UserModel(
        uid: '123',
        name: 'Test',
        email: 'test@example.com',
        age: 25,
        gender: 'male',
        job: 'dev',
        interests: [],
        country: 'TW',
        city: 'Taipei',
        district: 'Xinyi',
        preferredMatchType: 'any',
        minAge: 18,
        maxAge: 30,
        budgetRange: 1,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        isSilentHoursEnabled: true,
        silentHoursStart: '22:00',
        silentHoursEnd: '07:00',
      );

      final silentTime = DateTime(2023, 1, 1, 23, 0);
      expect(service.shouldNotify(user, currentTime: silentTime), isFalse);
    });

    test('shouldNotify returns true when outside silent hours', () {
       final user = UserModel(
        uid: '123',
        name: 'Test',
        email: 'test@example.com',
        age: 25,
        gender: 'male',
        job: 'dev',
        interests: [],
        country: 'TW',
        city: 'Taipei',
        district: 'Xinyi',
        preferredMatchType: 'any',
        minAge: 18,
        maxAge: 30,
        budgetRange: 1,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        isSilentHoursEnabled: true,
        silentHoursStart: '22:00',
        silentHoursEnd: '07:00',
      );

      final activeTime = DateTime(2023, 1, 1, 20, 0); // 8 PM
      expect(service.shouldNotify(user, currentTime: activeTime), isTrue);
    });
  });
}
