// comments_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:botellas/models/firestore_models.dart'; // Asegúrate de que esta ruta sea correcta

class CommentsScreen extends StatefulWidget {
  final String bottleId; // ID de la botella a la que pertenecen los comentarios
  final String bottleOwnerId; // ID del propietario de la botella para actualizar repliesCount

  const CommentsScreen({
    super.key,
    required this.bottleId,
    required this.bottleOwnerId,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isSendingComment = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// Función para añadir un nuevo comentario a la botella.
  Future<void> _addComment() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para comentar.')),
      );
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'El comentario no puede estar vacío.';
      });
      return;
    }

    setState(() {
      _isSendingComment = true;
      _errorMessage = null;
    });

    try {
      // 1. Añadir el comentario a la subcolección 'respuestas'
      await _firestore
          .collection('botellas')
          .doc(widget.bottleId)
          .collection('respuestas')
          .add({
        'content': _commentController.text.trim(),
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Incrementar el contador de respuestas en el documento de la botella
      await _firestore
          .collection('botellas')
          .doc(widget.bottleId)
          .update({'repliesCount': FieldValue.increment(1)});

      // Opcional: Si también quieres un contador de respuestas en el perfil del propietario de la botella
      // (similar a heartsReceived), podrías añadirlo aquí. Por ahora, solo actualizamos en la botella.

      _commentController.clear(); // Limpiar el campo de texto
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comentario enviado!')),
      );
    } on FirebaseException catch (e) {
      setState(() {
        _errorMessage = 'Error de Firebase al enviar comentario: ${e.message}';
      });
      print('Firebase error adding comment: $e');
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al enviar comentario: $e';
      });
      print('Error adding comment: $e');
    } finally {
      setState(() {
        _isSendingComment = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comentarios'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            // StreamBuilder para escuchar los comentarios en tiempo real
            child: StreamBuilder<QuerySnapshot<Respuesta>>(
              stream: _firestore
                  .collection('botellas')
                  .doc(widget.bottleId)
                  .collection('respuestas')
                  .orderBy('timestamp', descending: true) // Mostrar los más recientes primero
                  .withConverter<Respuesta>(
                    fromFirestore: (snap, _) => Respuesta.fromFirestore(snap),
                    toFirestore: (respuesta, _) => respuesta.toFirestore(),
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Sé el primero en comentar.'));
                }

                final comments = snapshot.data!.docs.map((doc) => doc.data()).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    // Para mostrar el nombre/avatar del usuario que comentó,
                    // necesitarás hacer una consulta adicional al documento del usuario.
                    // Esto se hace con un FutureBuilder anidado para cada comentario.
                    return FutureBuilder<DocumentSnapshot<Usuario>>(
                      future: _firestore
                          .collection('usuarios')
                          .doc(comment.userId)
                          .withConverter<Usuario>(
                            fromFirestore: (snap, _) => Usuario.fromFirestore(snap),
                            toFirestore: (usuario, _) => usuario.toFirestore(),
                          )
                          .get(),
                      builder: (context, userSnapshot) {
                        String userName = 'Usuario Desconocido';
                        String userAvatarEmoji = '👤';
                        if (userSnapshot.connectionState == ConnectionState.done && userSnapshot.hasData && userSnapshot.data!.exists) {
                          final userData = userSnapshot.data!.data();
                          userName = userData?.name ?? 'Usuario Desconocido';
                          userAvatarEmoji = userData?.avatarEmoji ?? '👤';
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.grey[200],
                                      child: Text(userAvatarEmoji, style: const TextStyle(fontSize: 14)),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      userName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatTimestamp(comment.timestamp),
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  comment.content,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          // Sección para escribir un nuevo comentario
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Escribe un comentario...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        maxLines: 3,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (value) => _addComment(), // Permite enviar con Enter
                      ),
                    ),
                    const SizedBox(width: 10),
                    _isSendingComment
                        ? const CircularProgressIndicator()
                        : FloatingActionButton(
                            onPressed: _addComment,
                            backgroundColor: Colors.blueAccent,
                            mini: true,
                            child: const Icon(Icons.send, color: Colors.white),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Función para formatear el timestamp a un formato legible
String _formatTimestamp(Timestamp? timestamp) {
  if (timestamp == null) return 'Sin fecha';

  final DateTime date = timestamp.toDate();
  final Duration diff = DateTime.now().difference(date);

  if (diff.inDays > 365) {
    return '${(diff.inDays / 365).floor()}a';
  } else if (diff.inDays > 30) {
    return '${(diff.inDays / 30).floor()}m';
  } else if (diff.inDays > 0) {
    return '${diff.inDays}d';
  } else if (diff.inHours > 0) {
    return '${diff.inHours}h';
  } else if (diff.inMinutes > 0) {
    return '${diff.inMinutes}min';
  } else {
    return 'Ahora';
  }
}

}
