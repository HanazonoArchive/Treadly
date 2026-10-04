import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/tire.dart';

/// DatabaseService manages Treadly's local SQLite database.
/// Streamlined & Universal:
/// - Universal Tire sizing (Width / Aspect Ratio / Rim Size).
/// - Complete schema for live prices, stock, ratings, reviews, and specifications.
/// - Fast local cache for tires, cart, wallet, and purchases.
class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  static const String _dbName = 'treadly.db';
  static const int _dbVersion = 2;

  Database? _db;

  Future<Database?> get database async {
    if (kIsWeb) {
      // sqflite native runs on Android and iOS devices.
      // Gracefully prevent MissingPluginException when previewing in browser.
      debugPrint('[DatabaseService] Web environment detected. SQLite native runs on mobile.');
      return null;
    }
    if (_db != null) return _db;
    _db = await _initDatabase();
    return _db;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final fullPath = p.join(dbPath, _dbName);

    return await openDatabase(
      fullPath,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Upgrade tires table to include full real database attributes
      await db.execute('DROP TABLE IF EXISTS tires;');
      await _createTiresTable(db);
    }
  }

  Future<void> _createTiresTable(Database db) async {
    await db.execute('''
      CREATE TABLE tires (
        id TEXT PRIMARY KEY,
        brand TEXT NOT NULL,
        model TEXT NOT NULL,
        category TEXT NOT NULL,
        season TEXT NOT NULL DEFAULT 'All-Season',
        size TEXT NOT NULL,
        width INTEGER NOT NULL,
        aspect_ratio INTEGER NOT NULL,
        rim_size INTEGER NOT NULL,
        load_index INTEGER,
        speed_rating TEXT,
        dot_year INTEGER,
        price REAL NOT NULL,
        original_price REAL,
        rating REAL NOT NULL DEFAULT 5.0,
        reviews_count INTEGER NOT NULL DEFAULT 0,
        stock INTEGER NOT NULL DEFAULT 0,
        wet_grip TEXT,
        fuel_efficiency TEXT,
        noise_db INTEGER,
        warranty_miles INTEGER,
        description TEXT,
        compatible_cars TEXT,
        image_asset TEXT,
        is_whitelisted INTEGER DEFAULT 1
      );
    ''');
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. TIRES (Lean Universal Catalog & Local Cache)
    await _createTiresTable(db);

    // 2. USERS (Local Auth & Identity cache)
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        avatar_asset TEXT,
        auth_token TEXT,
        created_at INTEGER NOT NULL
      );
    ''');

    // 3. USER WALLETS (Matches Profile "My Wallet" section)
    await db.execute('''
      CREATE TABLE user_wallets (
        user_id TEXT PRIMARY KEY,
        balance REAL NOT NULL DEFAULT 0.0,
        vouchers_count INTEGER NOT NULL DEFAULT 0,
        points_count INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      );
    ''');

    // 4. CART ITEMS (User's active cart)
    await db.execute('''
      CREATE TABLE cart_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        tire_id TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (tire_id) REFERENCES tires (id) ON DELETE CASCADE
      );
    ''');

    // 5. ORDERS (Matches Profile "My Purchase": to_ship, received, returns, cancelled)
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        status TEXT NOT NULL,
        total_amount REAL NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      );
    ''');

    // 6. ORDER ITEMS (Purchased line items)
    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id TEXT NOT NULL,
        tire_id TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        price_at_purchase REAL NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
        FOREIGN KEY (tire_id) REFERENCES tires (id) ON DELETE RESTRICT
      );
    ''');

    // 7. VOUCHERS (Catalog of available discount vouchers)
    await db.execute('''
      CREATE TABLE vouchers (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        discount_amount REAL NOT NULL DEFAULT 0.0,
        min_spend REAL NOT NULL DEFAULT 0.0,
        is_active INTEGER NOT NULL DEFAULT 1
      );
    ''');

    // 8. USER VOUCHERS (Tracks availability: is_available changes from 1 to 0 when redeemed)
    await db.execute('''
      CREATE TABLE user_vouchers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        voucher_id TEXT NOT NULL,
        is_available INTEGER NOT NULL DEFAULT 1,
        used_at INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (voucher_id) REFERENCES vouchers (id) ON DELETE CASCADE,
        UNIQUE (user_id, voucher_id)
      );
    ''');

    // 9. USER ADDRESSES (Delivery address storage for checkout & profile)
    await db.execute('''
      CREATE TABLE user_addresses (
        user_id TEXT PRIMARY KEY,
        recipient_name TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        street_address TEXT NOT NULL,
        city TEXT NOT NULL,
        postal_code TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      );
    ''');
  }

  /// Cache live tires into local SQLite database
  Future<void> cacheTires(List<Tire> tires) async {
    final db = await database;
    if (db == null) return;
    try {
      final batch = db.batch();
      batch.delete('tires'); // Clear any legacy duplicate entries
      for (final tire in tires) {
        batch.insert(
          'tires',
          tire.toSqliteMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      debugPrint('[DatabaseService] Cached ${tires.length} tires in SQLite');
    } catch (e) {
      debugPrint('[DatabaseService] Error caching tires in SQLite: $e');
    }
  }

  /// Retrieve cached tires from local SQLite database
  Future<List<Tire>> getCachedTires() async {
    final db = await database;
    if (db == null) return [];
    try {
      final List<Map<String, dynamic>> maps = await db.query('tires');
      return maps.map((m) => Tire.fromSqliteMap(m)).toList();
    } catch (e) {
      debugPrint('[DatabaseService] Error querying tires from SQLite: $e');
      return [];
    }
  }

  /// Close the database connection
  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
