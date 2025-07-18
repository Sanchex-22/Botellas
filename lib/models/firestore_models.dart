import 'package:cloud_firestore/cloud_firestore.dart';

// --- Modelo para la Colección 'botellas' ---
class Botella {
  final String id; // El ID del documento en Firestore
  final String message;
  final String emoji;
  final String ocean;
  final Timestamp? timestamp; // Hacemos que timestamp sea nullable
  final String userId;
  final int likes;
  final int views;
  final int repliesCount;
  final bool isPremium;
  final String? specialEffects; // Opcional

  Botella({
    required this.id,
    required this.message,
    required this.emoji,
    required this.ocean,
    this.timestamp, // No es requerido en el constructor si es nullable
    required this.userId,
    this.likes = 0,
    this.views = 0,
    this.repliesCount = 0,
    this.isPremium = false,
    this.specialEffects,
  });

  // Factory constructor para crear una instancia de Botella desde un DocumentSnapshot de Firestore
  factory Botella.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Botella(
      id: doc.id,
      message: data['message'] as String,
      emoji: data['emoji'] as String,
      ocean: data['ocean'] as String,
      timestamp: data['timestamp'] != null ? data['timestamp'] as Timestamp : null, // Leer como Timestamp?
      userId: data['userId'] as String,
      likes: (data['likes'] as num?)?.toInt() ?? 0,
      views: (data['views'] as num?)?.toInt() ?? 0,
      repliesCount: (data['repliesCount'] as num?)?.toInt() ?? 0,
      isPremium: data['isPremium'] as bool? ?? false,
      specialEffects: data['specialEffects'] as String?,
    );
  }

  // Método para convertir la instancia de Botella a un Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'message': message,
      'emoji': emoji,
      'ocean': ocean,
      'timestamp': timestamp,
      'userId': userId,
      'likes': likes,
      'views': views,
      'repliesCount': repliesCount,
      'isPremium': isPremium,
      if (specialEffects != null) 'specialEffects': specialEffects,
    };
  }

  Botella copyWith({
    String? id,
    String? userId,
    String? message,
    String? emoji, // Añadido el campo emoji para copyWith
    String? ocean,
    Timestamp? timestamp,
    int? likes,
    int? repliesCount,
    bool? isPremium,
    int? views,
  }) {
    return Botella(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      emoji: emoji ?? this.emoji, // Actualizado para incluir emoji
      ocean: ocean ?? this.ocean,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      repliesCount: repliesCount ?? this.repliesCount,
      isPremium: isPremium ?? this.isPremium,
      views: views ?? this.views,
    );
  }
}

// --- Modelo para la Colección 'usuarios' ---
class Usuario {
  final String id; // El ID del documento (que es el userId)
  final String name;
  final String avatarEmoji;
  final int bottlesSent;
  final int heartsReceived;
  final int followersCount;
  final int followingCount;
  final bool isVerified;
  final bool isPremiumSubscriber;
  final Timestamp? lastActivity; // Opcional
  final bool premiumCrown;

  Usuario({
    required this.id,
    required this.name,
    required this.avatarEmoji,
    this.bottlesSent = 0,
    this.heartsReceived = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isVerified = false,
    this.isPremiumSubscriber = false,
    this.lastActivity,
    this.premiumCrown = false,
  });

  // Factory constructor para crear una instancia de Usuario desde un DocumentSnapshot de Firestore
  factory Usuario.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Usuario(
      id: doc.id,
      name: data['name'] as String,
      avatarEmoji: data['avatarEmoji'] as String,
      bottlesSent: (data['bottlesSent'] as num?)?.toInt() ?? 0,
      heartsReceived: (data['heartsReceived'] as num?)?.toInt() ?? 0,
      followersCount: (data['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (data['followingCount'] as num?)?.toInt() ?? 0,
      isVerified: data['isVerified'] as bool? ?? false,
      isPremiumSubscriber: data['isPremiumSubscriber'] as bool? ?? false,
      lastActivity: data['lastActivity'] as Timestamp?,
      premiumCrown: data['premiumCrown'] as bool? ?? false,
    );
  }

  // Método para convertir la instancia de Usuario a un Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'avatarEmoji': avatarEmoji,
      'bottlesSent': bottlesSent,
      'heartsReceived': heartsReceived,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'isVerified': isVerified,
      'isPremiumSubscriber': isPremiumSubscriber,
      'lastActivity': lastActivity,
      'premiumCrown': premiumCrown,
    };
  }
}

// --- Modelo para la Subcolección 'respuestas' ---
class Respuesta {
  final String id; // El ID del documento de la respuesta
  final String content;
  final String userId;
  final Timestamp? timestamp;

  Respuesta({
    required this.id,
    required this.content,
    required this.userId,
    required this.timestamp,
  });

  // Factory constructor para crear una instancia de Respuesta desde un DocumentSnapshot de Firestore
  factory Respuesta.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Respuesta(
      id: doc.id,
      content: data['content'] as String,
      userId: data['userId'] as String,
      timestamp: data['timestamp'] is Timestamp ? data['timestamp'] as Timestamp : null,
    );
  }

  // Método para convertir la instancia de Respuesta a un Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'content': content,
      'userId': userId,
      'timestamp': timestamp,
    };
  }
}

// --- Modelo para la Subcolección 'likes' ---
class Like {
  final String id; // El ID del documento (que es el userId del que dio like)
  final Timestamp timestamp;

  Like({
    required this.id,
    required this.timestamp,
  });

  // Factory constructor para crear una instancia de Like desde un DocumentSnapshot de Firestore
  factory Like.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Like(
      id: doc.id,
      timestamp: data['timestamp'] as Timestamp,
    );
  }

  // Método para convertir la instancia de Like a un Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'timestamp': timestamp,
    };
  }
}

// --- Modelo para las Subcolecciones 'following' y 'followers' ---
class Follow {
  final String id; // El ID del documento (el userId del seguido/seguidor)
  final Timestamp timestamp;

  Follow({
    required this.id,
    required this.timestamp,
  });

  // Factory constructor para crear una instancia de Follow desde un DocumentSnapshot de Firestore
  factory Follow.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Follow(
      id: doc.id,
      timestamp: data['timestamp'] as Timestamp,
    );
  }

  // Método para convertir la instancia de Follow a un Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'timestamp': timestamp,
    };
  }
}

// --- Modelo para la Colección 'metadata_oceanos' ---
class OceanoMetadata {
  final String id; // El ID del documento (que es el nombre del océano)
  final String name;
  final String? description; // Opcional
  final bool isPremium;
  final String? emojiIcon; // Opcional

  OceanoMetadata({
    required this.id,
    required this.name,
    this.description,
    required this.isPremium,
    this.emojiIcon,
  });

  // Factory constructor para crear una instancia de OceanoMetadata desde un DocumentSnapshot de Firestore
  factory OceanoMetadata.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return OceanoMetadata(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String?,
      isPremium: data['isPremium'] as bool? ?? false,
      emojiIcon: data['emojiIcon'] as String?,
    );
  }

  // Método para convertir la instancia de OceanoMetadata a un Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (description != null) 'description': description,
      'isPremium': isPremium,
      if (emojiIcon != null) 'emojiIcon': emojiIcon,
    };
  }
}


