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
  final DateTime? expiresAt;
  final bool isLive;
  final int maxAttempts;
  final String? pin;
  final int currentQuestionIndex;

  TestModel({
    String? id,
    required this.title,
    required this.classId,
    required this.className,
    required this.durationMinutes,
    required this.questions,
    this.scheduledAt,
    this.expiresAt,
    this.isLive = false,
    this.maxAttempts = 1,
    String? pin,
    this.currentQuestionIndex = 0,
  })  : id = id ?? _uuid.v4(),
        pin = pin ?? _pinFromId(id ?? _uuid.v4());

  static String _pinFromId(String id) =>
      id.replaceAll('-', '').substring(0, 6).toUpperCase();

  int get questionCount => questions.length;

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'classId': classId,
      'className': className,
      'durationMinutes': durationMinutes,
      'questions': questions.map((q) => q.toMap()).toList(),
      'scheduledAt': scheduledAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'isLive': isLive,
      'maxAttempts': maxAttempts,
      'pin': pin,
      'currentQuestionIndex': currentQuestionIndex,
    };
  }

  factory TestModel.fromMap(Map<String, dynamic> map) {
    final id = map['id'] as String;
    return TestModel(
      id: id,
      title: map['title'],
      classId: map['classId'],
      className: map['className'],
      durationMinutes: map['durationMinutes'],
      questions: (map['questions'] as List).map((q) => QuizQuestion.fromMap(q)).toList(),
      scheduledAt: map['scheduledAt'] != null ? DateTime.parse(map['scheduledAt']) : null,
      expiresAt: map['expiresAt'] != null ? DateTime.parse(map['expiresAt']) : null,
      isLive: map['isLive'] ?? false,
      maxAttempts: map['maxAttempts'] ?? 1,
      pin: map['pin'] as String?,
      currentQuestionIndex: map['currentQuestionIndex'] as int? ?? 0,
    );
  }
}

// ── Live Session ──────────────────────────────────────────────────────────────

enum LiveSessionStatus { waiting, active, showingResult, ended }

class LiveSession {
  final String id;
  final String testId;
  final String testTitle;
  final String hostId;
  final String hostName;
  final String pin;
  final int currentQuestion;
  final LiveSessionStatus status;
  final DateTime createdAt;
  final int participantCount;
  final bool isLocked; // host can lock room to prevent new joins

  const LiveSession({
    required this.id,
    required this.testId,
    required this.testTitle,
    required this.hostId,
    required this.hostName,
    required this.pin,
    this.currentQuestion = 0,
    this.status = LiveSessionStatus.waiting,
    required this.createdAt,
    this.participantCount = 0,
    this.isLocked = false,
  });

  bool get isWaiting       => status == LiveSessionStatus.waiting;
  bool get isActive        => status == LiveSessionStatus.active;
  bool get isShowingResult => status == LiveSessionStatus.showingResult;
  bool get isEnded         => status == LiveSessionStatus.ended;

  Map<String, dynamic> toMap() => {
    'id': id,
    'testId': testId,
    'testTitle': testTitle,
    'hostId': hostId,
    'hostName': hostName,
    'pin': pin,
    'currentQuestion': currentQuestion,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'participantCount': participantCount,
    'isLocked': isLocked,
  };

  factory LiveSession.fromMap(Map<String, dynamic> map) => LiveSession(
    id: map['id'],
    testId: map['testId'],
    testTitle: map['testTitle'],
    hostId: map['hostId'],
    hostName: map['hostName'] ?? '',
    pin: map['pin'],
    currentQuestion: map['currentQuestion'] ?? 0,
    status: LiveSessionStatus.values.byName(map['status'] ?? 'waiting'),
    createdAt: DateTime.parse(map['createdAt']),
    participantCount: map['participantCount'] ?? 0,
    isLocked: map['isLocked'] ?? false,
  );

  LiveSession copyWith({
    int? currentQuestion,
    LiveSessionStatus? status,
    int? participantCount,
    bool? isLocked,
  }) => LiveSession(
    id: id,
    testId: testId,
    testTitle: testTitle,
    hostId: hostId,
    hostName: hostName,
    pin: pin,
    currentQuestion: currentQuestion ?? this.currentQuestion,
    status: status ?? this.status,
    createdAt: createdAt,
    participantCount: participantCount ?? this.participantCount,
    isLocked: isLocked ?? this.isLocked,
  );
}

// ── Live Participant ──────────────────────────────────────────────────────────

class LiveParticipant {
  final String id;         // userId
  final String sessionId;
  final String name;
  final String avatarInitials;
  final int score;
  final int rank;
  final int answeredCount;
  final int correctCount;
  final DateTime joinedAt;

  const LiveParticipant({
    required this.id,
    required this.sessionId,
    required this.name,
    required this.avatarInitials,
    this.score = 0,
    this.rank = 0,
    this.answeredCount = 0,
    this.correctCount = 0,
    required this.joinedAt,
  });

  double get accuracy =>
      answeredCount == 0 ? 0 : correctCount / answeredCount;

  Map<String, dynamic> toMap() => {
    'id': id,
    'sessionId': sessionId,
    'name': name,
    'avatarInitials': avatarInitials,
    'score': score,
    'rank': rank,
    'answeredCount': answeredCount,
    'correctCount': correctCount,
    'joinedAt': joinedAt.toIso8601String(),
  };

  factory LiveParticipant.fromMap(Map<String, dynamic> map) => LiveParticipant(
    id: map['id'],
    sessionId: map['sessionId'],
    name: map['name'],
    avatarInitials: map['avatarInitials'] ?? '',
    score: map['score'] ?? 0,
    rank: map['rank'] ?? 0,
    answeredCount: map['answeredCount'] ?? 0,
    correctCount: map['correctCount'] ?? 0,
    joinedAt: DateTime.parse(map['joinedAt']),
  );
}

// ── Live Answer ───────────────────────────────────────────────────────────────

class LiveAnswer {
  final String id;
  final String sessionId;
  final String participantId;
  final String questionId;
  final int questionIndex;
  final int selectedIndex;
  final bool isCorrect;
  final int pointsEarned;
  final int responseMs; // milliseconds to answer
  final DateTime answeredAt;

  const LiveAnswer({
    required this.id,
    required this.sessionId,
    required this.participantId,
    required this.questionId,
    required this.questionIndex,
    required this.selectedIndex,
    required this.isCorrect,
    required this.pointsEarned,
    required this.responseMs,
    required this.answeredAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'sessionId': sessionId,
    'participantId': participantId,
    'questionId': questionId,
    'questionIndex': questionIndex,
    'selectedIndex': selectedIndex,
    'isCorrect': isCorrect,
    'pointsEarned': pointsEarned,
    'responseMs': responseMs,
    'answeredAt': answeredAt.toIso8601String(),
  };

  factory LiveAnswer.fromMap(Map<String, dynamic> map) => LiveAnswer(
    id: map['id'],
    sessionId: map['sessionId'],
    participantId: map['participantId'],
    questionId: map['questionId'],
    questionIndex: map['questionIndex'] ?? 0,
    selectedIndex: map['selectedIndex'],
    isCorrect: map['isCorrect'] ?? false,
    pointsEarned: map['pointsEarned'] ?? 0,
    responseMs: map['responseMs'] ?? 0,
    answeredAt: DateTime.parse(map['answeredAt']),
  );
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

// ── Feedback & Support ────────────────────────────────────────────────────────

enum FeedbackType { bug, feature, general }

enum FeedbackPriority { low, medium, high }

enum FeedbackStatus { pending, inReview, resolved }

class FeedbackModel {
  final String id;
  final String userId;
  final String userName;
  final UserRole userRole;
  final FeedbackType type;
  final String subject;
  final String description;
  final FeedbackPriority? priority;
  final String? category;
  final List<String> attachmentUrls;
  final FeedbackStatus status;
  final DateTime submittedAt;
  final String? adminResponse;
  final DateTime? respondedAt;

  FeedbackModel({
    String? id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.type,
    required this.subject,
    required this.description,
    this.priority,
    this.category,
    List<String>? attachmentUrls,
    this.status = FeedbackStatus.pending,
    DateTime? submittedAt,
    this.adminResponse,
    this.respondedAt,
  })  : id = id ?? _uuid.v4(),
        attachmentUrls = attachmentUrls ?? [],
        submittedAt = submittedAt ?? DateTime.now();

  String get typeLabel {
    switch (type) {
      case FeedbackType.bug:
        return 'Bug Report';
      case FeedbackType.feature:
        return 'Feature Request';
      case FeedbackType.general:
        return 'General Feedback';
    }
  }

  String get statusLabel {
    switch (status) {
      case FeedbackStatus.pending:
        return 'Pending';
      case FeedbackStatus.inReview:
        return 'In Review';
      case FeedbackStatus.resolved:
        return 'Resolved';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userRole': userRole.name,
      'type': type.name,
      'subject': subject,
      'description': description,
      'priority': priority?.name,
      'category': category,
      'attachmentUrls': attachmentUrls,
      'status': status.name,
      'submittedAt': submittedAt.toIso8601String(),
      'adminResponse': adminResponse,
      'respondedAt': respondedAt?.toIso8601String(),
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map) {
    return FeedbackModel(
      id: map['id'],
      userId: map['userId'],
      userName: map['userName'],
      userRole: UserRole.values.byName(map['userRole']),
      type: FeedbackType.values.byName(map['type']),
      subject: map['subject'],
      description: map['description'],
      priority: map['priority'] != null
          ? FeedbackPriority.values.byName(map['priority'])
          : null,
      category: map['category'],
      attachmentUrls: List<String>.from(map['attachmentUrls'] ?? []),
      status: FeedbackStatus.values.byName(map['status'] ?? 'pending'),
      submittedAt: DateTime.parse(map['submittedAt']),
      adminResponse: map['adminResponse'],
      respondedAt: map['respondedAt'] != null
          ? DateTime.parse(map['respondedAt'])
          : null,
    );
  }

  FeedbackModel copyWith({
    FeedbackStatus? status,
    String? adminResponse,
    DateTime? respondedAt,
  }) {
    return FeedbackModel(
      id: id,
      userId: userId,
      userName: userName,
      userRole: userRole,
      type: type,
      subject: subject,
      description: description,
      priority: priority,
      category: category,
      attachmentUrls: attachmentUrls,
      status: status ?? this.status,
      submittedAt: submittedAt,
      adminResponse: adminResponse ?? this.adminResponse,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}
