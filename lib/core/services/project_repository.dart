import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/project.dart';

/// Repository for managing project persistence using SQLite
class ProjectRepository {
  static const String _databaseName = 'sz_pic_projects.db';
  static const int _databaseVersion = 1;

  Database? _database;

  /// Initialize the database
  Future<void> initialize() async {
    if (_database != null) return;

    if (kIsWeb) {
      // Web: Use in-memory database or fallback
      _database = await openDatabase(
        ':memory:',
        version: _databaseVersion,
        onCreate: _onCreate,
      );
      debugPrint('ProjectRepository: Initialized in-memory database for web');
      return;
    }

    final Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, _databaseName);
    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
    debugPrint('ProjectRepository: Initialized database at $path');
  }

  /// Create database schema
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        thumbnail_path TEXT,
        is_draft INTEGER NOT NULL DEFAULT 1,
        auto_save_version INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_projects_type ON projects(type)
    ''');

    await db.execute('''
      CREATE INDEX idx_projects_updated ON projects(updated_at DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_projects_draft ON projects(is_draft, updated_at DESC)
    ''');

    debugPrint('ProjectRepository: Created database schema');
  }

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    await initialize();
    return _database!;
  }

  /// Save a project (insert or update)
  Future<String> saveProject(Project project) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    debugPrint('=== ProjectRepository: saveProject() ===');
    debugPrint('Project ID: ${project.id}');
    debugPrint('Project name: ${project.name}');
    debugPrint('Project type: ${project.type}');
    debugPrint('Is draft: ${project.isDraft}');
    debugPrint('Data keys: ${project.data.keys}');

    final Map<String, dynamic> projectMap = {
      'id': project.id,
      'name': project.name,
      'type': project.type.toValue(),
      'data': jsonEncode(project.data),
      'created_at': project.createdAt.millisecondsSinceEpoch,
      'updated_at': now,
      'thumbnail_path': project.thumbnailPath,
      'is_draft': project.isDraft ? 1 : 0,
      'auto_save_version': project.autoSaveVersion ?? 0,
    };

    debugPrint('Inserting into database...');
    await db.insert(
      'projects',
      projectMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    debugPrint('ProjectRepository: Successfully saved project ${project.id}');
    return project.id;
  }

  /// Get a project by ID
  Future<Project?> getProject(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    return _mapToProject(maps.first);
  }

  /// Get all projects
  Future<List<Project>> getAllProjects() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'projects',
      orderBy: 'updated_at DESC',
    );

    return maps.map((map) => _mapToProject(map)).toList();
  }

  /// Get projects by type
  Future<List<Project>> getProjectsByType(ProjectType type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'projects',
      where: 'type = ?',
      whereArgs: [type.toValue()],
      orderBy: 'updated_at DESC',
    );

    return maps.map((map) => _mapToProject(map)).toList();
  }

  /// Get draft projects only
  Future<List<Project>> getDrafts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'projects',
      where: 'is_draft = ?',
      whereArgs: [1],
      orderBy: 'updated_at DESC',
    );

    debugPrint('ProjectRepository: getDrafts() found ${maps.length} draft(s)');
    return maps.map((map) => _mapToProject(map)).toList();
  }

  /// Delete a project by ID
  Future<void> deleteProject(String id) async {
    final db = await database;
    final int count = await db.delete(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (count > 0) {
      debugPrint('ProjectRepository: Deleted project $id');
    }
  }

  /// Delete all draft projects
  Future<void> deleteAllDrafts() async {
    final db = await database;
    final int count = await db.delete(
      'projects',
      where: 'is_draft = ?',
      whereArgs: [1],
    );

    debugPrint('ProjectRepository: Deleted $count draft projects');
  }

  /// Delete old drafts (older than specified duration)
  Future<void> deleteOldDrafts({Duration olderThan = const Duration(days: 7)}) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(olderThan).millisecondsSinceEpoch;

    final int count = await db.delete(
      'projects',
      where: 'is_draft = ? AND updated_at < ?',
      whereArgs: [1, cutoff],
    );

    debugPrint('ProjectRepository: Deleted $count old draft projects');
  }

  /// Update project thumbnail path
  Future<void> updateThumbnailPath(String projectId, String thumbnailPath) async {
    final db = await database;
    await db.update(
      'projects',
      {'thumbnail_path': thumbnailPath},
      where: 'id = ?',
      whereArgs: [projectId],
    );
  }

  /// Save thumbnail bytes to file
  Future<String> saveThumbnail(String projectId, List<int> thumbnailBytes) async {
    if (kIsWeb) {
      // Web: Return base64 string (not ideal but works)
      throw UnsupportedError('Thumbnail saving not supported on web');
    }

    final Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final thumbnailsDir = Directory('${documentsDirectory.path}/thumbnails');
    if (!await thumbnailsDir.exists()) {
      await thumbnailsDir.create(recursive: true);
    }

    final thumbnailPath = '${thumbnailsDir.path}/$projectId.png';
    final thumbnailFile = File(thumbnailPath);
    await thumbnailFile.writeAsBytes(thumbnailBytes);

    debugPrint('ProjectRepository: Saved thumbnail at $thumbnailPath');
    return thumbnailPath;
  }

  /// Delete thumbnail file
  Future<void> deleteThumbnail(String? thumbnailPath) async {
    if (thumbnailPath == null || kIsWeb) return;

    try {
      final file = File(thumbnailPath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('ProjectRepository: Deleted thumbnail at $thumbnailPath');
      }
    } catch (e) {
      debugPrint('ProjectRepository: Error deleting thumbnail: $e');
    }
  }

  /// Get project count
  Future<int> getProjectCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM projects');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get draft count
  Future<int> getDraftCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM projects WHERE is_draft = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Map database row to Project object
  Project _mapToProject(Map<String, dynamic> map) {
    // Parse the JSON data string back to Map
    final dataString = map['data'] as String;
    Map<String, dynamic> dataMap = {};
    try {
      dataMap = jsonDecode(dataString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('ProjectRepository: Error parsing data JSON: $e');
    }

    return Project(
      id: map['id'] as String,
      name: map['name'] as String,
      type: ProjectTypeExtension.fromValue(map['type'] as String),
      data: dataMap,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      thumbnailPath: map['thumbnail_path'] as String?,
      isDraft: (map['is_draft'] as int) == 1,
      autoSaveVersion: map['auto_save_version'] as int?,
    );
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    debugPrint('ProjectRepository: Closed database');
  }
}
