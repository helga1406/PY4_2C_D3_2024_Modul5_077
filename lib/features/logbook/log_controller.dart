import 'package:flutter/material.dart';
import 'package:logbook_app_077/features/logbook/models/log_model.dart';
import 'package:logbook_app_077/services/mongo_service.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:logbook_app_077/services/access_control_service.dart';
import 'package:logbook_app_077/helpers/log_helper.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LogController {
  // --- STATE UI ---
  final ValueNotifier<String> searchQuery = ValueNotifier("");
  final ValueNotifier<String> selectedFilter = ValueNotifier("Semua");
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);

  final String username;
  final String userRole;

  late final Box<LogModel> _myBox;

  LogController({
    required this.username,
    this.userRole = 'Anggota',
  }) {
    _myBox = Hive.box<LogModel>('offline_logs');

    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (!results.contains(ConnectivityResult.none)) {
        _syncPendingData();
      }
    });
  }

  // --- LOGIKA TASK 5: FILTER PRIVASI ---
  List<LogModel> _applyPrivacyFilter(List<LogModel> allLogs) {
    return allLogs.where((log) {
      bool isMyOwnLog = log.authorId == username;
      bool isPublicLog = log.isPublic == true;
      return isMyOwnLog || isPublicLog;
    }).toList();
  }

  // --- SINKRONISASI DATA ---
  Future<void> _syncPendingData() async {
    await LogHelper.writeLog(
      "INTERNET AKTIF: Memulai sinkronisasi...",
      level: 2,
    );

    final localLogs = _myBox.values.toList();

    for (var log in localLogs) {
      try {
        await MongoService().insertLog(log, username);
      } catch (e) {
        await LogHelper.writeLog(
          "ERROR: Sinkronisasi gagal untuk log ${log.id}",
          level: 1,
        );
      }
    }
  }

  // --- LOGIKA PENCARIAN & FILTER ---
  void searchLog(String query) {
    searchQuery.value = query;
  }

  void setFilterCategory(String category) {
    selectedFilter.value = category;
  }

  // --- FUNGSI LOAD LOGS ---
  Future<void> loadLogs(String teamId) async {
    final localData = _applyPrivacyFilter(
      _myBox.values.toList(),
    );
    logsNotifier.value = localData;

    try {
      final cloudData = await MongoService().getLogs(teamId);

      Map<String, LogModel> dataMap = {
        for (var item in cloudData) item.id!: item,
      };

      await _myBox.putAll(dataMap);

      logsNotifier.value = _applyPrivacyFilter(
        _myBox.values.toList(),
      );

      await LogHelper.writeLog(
        "SYNC: Data sinkron dengan Cloud",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "OFFLINE: Menampilkan data cache",
        level: 2,
      );
    }
  }

  // --- FUNGSI ADD LOG ---
  Future<void> addLog(
    String title,
    String desc,
    String category, {
    required bool isPublic,
  }) async {
    if (!AccessControlService.canPerform(
      userRole,
      AccessControlService.actionCreate,
    )) {
      await LogHelper.writeLog(
        "SECURITY BREACH: Unauthorized create attempt",
        source: "LogController",
        level: 1,
      );
      return;
    }

    final String formattedTime = DateTime.now().toString().substring(0, 16);

    final newLog = LogModel(
      id: mongo.ObjectId().oid,
      title: title,
      description: desc,
      date: formattedTime,
      authorId: username,
      teamId: 'team_01',
      category: category,
      isPublic: isPublic,
    );

    await _myBox.put(newLog.id, newLog);
    
    logsNotifier.value = _applyPrivacyFilter(
      _myBox.values.toList(),
    );

    try {
      await MongoService().insertLog(newLog, username);
      await LogHelper.writeLog(
        "SUCCESS: Data Cloud Updated",
        source: "log_controller.dart",
      );
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Data tersimpan lokal",
        level: 1,
      );
    }
  }

  // --- FUNGSI UPDATE LOG ---
  Future<void> updateLog(LogModel updatedLog) async {
    bool isOwner = updatedLog.authorId == username;

    if (!AccessControlService.canPerform(
      userRole,
      AccessControlService.actionUpdate,
      isOwner: isOwner,
    )) {
      await LogHelper.writeLog(
        "SECURITY BREACH: Unauthorized update attempt",
        source: "LogController",
        level: 1,
      );
      return;
    }

    await _myBox.put(updatedLog.id, updatedLog);
    
    logsNotifier.value = _applyPrivacyFilter(
      _myBox.values.toList(),
    );

    try {
      await MongoService().updateLog(updatedLog, username);
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Update tersimpan lokal",
        level: 1,
      );
    }
  }

  // --- FUNGSI REMOVE LOG ---
  Future<void> removeLog(LogModel log) async {
    bool isOwner = log.authorId == username;

    if (!AccessControlService.canPerform(
      userRole,
      AccessControlService.actionDelete,
      isOwner: isOwner,
    )) {
      await LogHelper.writeLog(
        "SECURITY BREACH: Unauthorized delete attempt",
        source: "LogController",
        level: 1,
      );
      return;
    }

    if (log.id != null) {
      await _myBox.delete(log.id);
      
      logsNotifier.value = _applyPrivacyFilter(
        _myBox.values.toList(),
      );

      try {
        final objectId = mongo.ObjectId.fromHexString(log.id!);
        await MongoService().deleteLog(objectId, username);
      } catch (e) {
        await LogHelper.writeLog(
          "WARNING: Gagal hapus di Cloud",
          level: 1,
        );
      }
    }
  }
}