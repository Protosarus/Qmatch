class UserModel {
  final String uid;
  final String name;
  final String email;
  final bool testCompleted;
  final String? archetype;
  final int? level;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.testCompleted = false,
    this.archetype,
    this.level,
  });

  // Firestore'dan user oluştur
  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      testCompleted: data['test_completed'] ?? false,
      archetype: data['archetype'],
      level: data['level'],
    );
  }

  // Firestore'a kaydet — omit optional nulls (do not erase stored archetype).
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'test_completed': testCompleted,
      if (archetype != null) 'archetype': archetype,
      if (level != null) 'level': level,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}
