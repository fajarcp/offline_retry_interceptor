import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class OfflineQueueDb {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await initDb();
    return _database!;
  }

  Future<Database> initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'offline_retry_queue.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE network_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            url TEXT,
            method TEXT,
            body TEXT,
            headers TEXT,
            timestamp INTEGER
          )
        ''');
      },
    );
  }

  Future<void> queueRequest(String url, String method, String? body, String? headers) async {
    final db = await database;
    await db.insert('network_queue', {
      'url': url,
      'method': method,
      'body': body,
      'headers': headers,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String,dynamic>>> getQueuedRequests() async{
    final db=await database;
    return await db.query('network_queue',orderBy: 'timestamp ASC');
  }

  Future<void> deleteRequest(int id) async {
    final db = await database;
    await db.delete('network_queue', where: 'id = ?', whereArgs: [id]);
  }
}
