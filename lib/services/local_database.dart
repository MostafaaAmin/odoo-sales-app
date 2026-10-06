import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  static final LocalDatabase instance =
      LocalDatabase._internal();

  LocalDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath =
        await getDatabasesPath();

    final path = join(
      databasePath,
      'odoo_sales.db',
    );

    return openDatabase(
      path,
      version: 1,
      onCreate: (
        Database db,
        int version,
      ) async {
        await db.execute(
          '''
          CREATE TABLE customers (
            id INTEGER PRIMARY KEY,
            data TEXT NOT NULL
          )
          ''',
        );

        await db.execute(
          '''
          CREATE TABLE pending_phone_updates (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customer_id INTEGER NOT NULL,
            phone TEXT NOT NULL
          )
          ''',
        );
      },
    );
  }

  Future<void> saveCustomers(
    List<dynamic> customers,
  ) async {
    final db = await database;

    final batch = db.batch();

    await db.delete(
      'customers',
    );

    for (final customer in customers) {
      final map =
          Map<String, dynamic>.from(
        customer,
      );

      batch.insert(
        'customers',
        {
          'id': map['id'],
          'data': jsonEncode(map),
        },
        conflictAlgorithm:
            ConflictAlgorithm.replace,
      );
    }

    await batch.commit(
      noResult: true,
    );
  }

  Future<List<dynamic>>
      getCustomers() async {
    final db = await database;

    final result =
        await db.query(
      'customers',
    );

    return result.map(
      (row) {
        final data =
            row['data'] as String;

        return Map<String, dynamic>.from(
          jsonDecode(data),
        );
      },
    ).toList();
  }

  Future<void>
      updateCustomerPhoneLocally(
    int customerId,
    String phone,
  ) async {
    final db = await database;

    final rows =
        await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [
        customerId,
      ],
      limit: 1,
    );

    if (rows.isEmpty) {
      return;
    }

    final data =
        Map<String, dynamic>.from(
      jsonDecode(
        rows.first['data'] as String,
      ),
    );

    data['phone'] = phone;

    await db.update(
      'customers',
      {
        'data': jsonEncode(data),
      },
      where: 'id = ?',
      whereArgs: [
        customerId,
      ],
    );
  }

  Future<void> queuePhoneUpdate(
    int customerId,
    String phone,
  ) async {
    final db = await database;

    await db.delete(
      'pending_phone_updates',
      where: 'customer_id = ?',
      whereArgs: [
        customerId,
      ],
    );

    await db.insert(
      'pending_phone_updates',
      {
        'customer_id': customerId,
        'phone': phone,
      },
    );
  }

  Future<List<Map<String, dynamic>>>
      getPendingPhoneUpdates() async {
    final db = await database;

    return db.query(
      'pending_phone_updates',
      orderBy: 'id ASC',
    );
  }

  Future<void> removePendingUpdate(
    int id,
  ) async {
    final db = await database;

    await db.delete(
      'pending_phone_updates',
      where: 'id = ?',
      whereArgs: [
        id,
      ],
    );
  }
}