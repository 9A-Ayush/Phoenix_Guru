import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum UserRole { student, teacher }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String avatarInitials;
  final DateTime createdAt;

  UserModel({
    String? id,
    required this.name,
    required this.email,
    required this.role,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        avatarInitials = name.split(' ').take(2).map((w) => w[0].toUpperCase()).join();

  UserModel copyWith({String? name, String? email, UserRole? role}) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      role: UserRole.values.byName(map['role']),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}

class ClassModel {
  final String id;
  final String name;
  final String subject;
  final String description;
  final String teacherId;
  final String teacherName;
  final String classCode;
  final List<String> studentIds;
  final DateTime createdAt;

  ClassModel({
    String? id,
    required this.name,
    required this.subject,
    required this.description,
    required this.teacherId,
    required this.teacherName,
    String? classCode,
    List<String>? studentIds,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        classCode = classCode ?? _generateCode(),
        studentIds = studentIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  static String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = DateTime.now().microsecondsSinceEpoch;
    return List.generate(6, (i) => chars[(rand >> (i * 5)) % chars.length]).join();
  }

  int get studentCount => studentIds.length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'subject': subject,
      'description': description,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'classCode': classCode,
      'studentIds': studentIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ClassModel.fromMap(Map<String, dynamic> map) {
    return ClassModel(
      id: map['id'],
      name: map['name'],
      subject: map['subject'],
      description: map['description'],
      teacherId: map['teacherId'],
      teacherName: map['teacherName'],
      classCode: map['classCode'],
      studentIds: List<String>.from(map['studentIds'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;

  QuizQuestion({
    String? id,
    required this.question,
    required this.options,
    required this.correctIndex,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
    };
  }

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'],
      question: map['question'],
      options: List<String>.from(map['options']),
      correctIndex: map['correctIndex'],
    );
  }
}

class TestModel {
  final String id;
  final String title;
  final String classId;
  final String className;
  final int durationMinutes;
  final List<QuizQuestion> questions;
  final DateTime? scheduledAt;
  final bool isLive;

  TestModel({
    String? id,
    required this.title,
    required this.classId,
    required this.className,
    required this.durationMinutes,
    required this.questions,
    this.scheduledAt,
    this.isLive = false,
  }) : id = id ?? _uuid.v4();

  int get questionCount => questions.length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'classId': classId,
      'className': className,
      'durationMinutes': durationMinutes,
      'questions': questions.map((q) => q.toMap()).toList(),
      'scheduledAt': scheduledAt?.toIso8601String(),
      'isLive': isLive,
    };
  }

  factory TestModel.fromMap(Map<String, dynamic> map) {
    return TestModel(
      id: map['id'],
      title: map['title'],
      classId: map['classId'],
      className: map['className'],
      durationMinutes: map['durationMinutes'],
      questions: (map['questions'] as List).map((q) => QuizQuestion.fromMap(q)).toList(),
      scheduledAt: map['scheduledAt'] != null ? DateTime.parse(map['scheduledAt']) : null,
      isLive: map['isLive'] ?? false,
    );
  }
}

class QuizAttempt {
  final String id;
  final String testId;
  final String testTitle;
  final String userId;
  final String userName;
  final Map<String, int> answers; // questionId → selectedIndex
  final DateTime completedAt;

  QuizAttempt({
    String? id,
    required this.testId,
    required this.testTitle,
    required this.userId,
    required this.userName,
    required this.answers,
    DateTime? completedAt,
  })  : id = id ?? _uuid.v4(),
        completedAt = completedAt ?? DateTime.now();

  double score(List<QuizQuestion> questions) {
    if (questions.isEmpty) return 0;
    int correct = 0;
    for (final q in questions) {
      if (answers[q.id] == q.correctIndex) correct++;
    }
    return correct / questions.length;
  }

  int rank = 0;
  int totalParticipants = 0;

  String get grade {
    const s = 0.0; // computed externally
    if (s >= 0.9) return 'A+';
    if (s >= 0.8) return 'A';
    if (s >= 0.7) return 'B';
    if (s >= 0.6) return 'C';
    return 'D';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'testId': testId,
      'testTitle': testTitle,
      'userId': userId,
      'userName': userName,
      'answers': answers,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory QuizAttempt.fromMap(Map<String, dynamic> map) {
    return QuizAttempt(
      id: map['id'],
      testId: map['testId'],
      testTitle: map['testTitle'],
      userId: map['userId'],
      userName: map['userName'] ?? 'Unknown',
      answers: Map<String, int>.from(map['answers']),
      completedAt: DateTime.parse(map['completedAt']),
    );
  }
}
