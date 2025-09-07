import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
//import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_provider.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Usuario actual
  User? get currentUser => _auth.currentUser;

  // Stream de cambios de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // === AUTENTICACIÓN CON EMAIL ===

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Actualizar último login
      if (credential.user != null) {
        await _updateLastLogin(credential.user!.uid);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    }
  }

  Future<UserCredential?> createUserWithEmail(String email, String password, String displayName) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Actualizar perfil del usuario
        await credential.user!.updateDisplayName(displayName);

        // Enviar email de verificación
        await credential.user!.sendEmailVerification();

        // Crear documento del usuario en Firestore
        await _createUserDocument(credential.user!, 'email');
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    }
  }

  // === AUTENTICACIÓN CON GOOGLE ===

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Inicio de sesión con Google cancelado');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credentials
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Verificar si es la primera vez que se logea
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          // Es nuevo usuario, crear documento
          await _createUserDocument(userCredential.user!, 'google');
        } else {
          // Usuario existente, actualizar último login
          await _updateLastLogin(userCredential.user!.uid);
        }
      }

      return userCredential;
    } catch (e) {
      throw Exception('Error en inicio de sesión con Google: $e');
    }
  }

  // === AUTENTICACIÓN CON APPLE ===

  /*Future<UserCredential?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      if (userCredential.user != null) {
        // Verificar si es la primera vez que se logea
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          // Es nuevo usuario, crear documento
          await _createUserDocument(userCredential.user!, 'apple');
        } else {
          // Usuario existente, actualizar último login
          await _updateLastLogin(userCredential.user!.uid);
        }
      }

      return userCredential;
    } catch (e) {
      throw Exception('Error en inicio de sesión con Apple: $e');
    }
  }*/

  // === GESTIÓN DE USUARIOS EN FIRESTORE ===

  Future<void> _createUserDocument(User user, String loginProvider) async {
    final userModel = UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoURL: user.photoURL,
      isEmailVerified: user.emailVerified,
      hasAcceptedTerms: false, // Por defecto false, se debe aceptar después
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      loginProvider: loginProvider,
    );

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(userModel.toMap());
  }

  Future<void> _updateLastLogin(String uid) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .update({
      'lastLoginAt': DateTime.now().toIso8601String(),
    });
  }

  // === GESTIÓN DE TÉRMINOS Y CONDICIONES ===

  Future<void> acceptTermsAndConditions(String uid) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .update({
      'hasAcceptedTerms': true,
    });
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error obteniendo datos del usuario: $e');
      return null;
    }
  }

  // === OTRAS FUNCIONES ===

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // === MANEJO DE ERRORES ===

  String _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo electrónico';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo electrónico';
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'invalid-email':
        return 'Correo electrónico inválido';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Intenta más tarde';
      case 'operation-not-allowed':
        return 'Operación no permitida';
      case 'requires-recent-login':
        return 'Debes iniciar sesión nuevamente para realizar esta acción';
      default:
        return e.message ?? 'Error de autenticación desconocido';
    }
  }
}