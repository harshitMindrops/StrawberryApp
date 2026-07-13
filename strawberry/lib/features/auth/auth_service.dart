import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  // Sends OTP to the provided phone number using Firebase
  Future<void> sendOTP({
    required String phone,
    required void Function(String verificationId) onCodeSent,
    required void Function(String errorMessage) onError,
  }) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await _firebaseAuth.signInWithCredential(credential);
        } catch (e) {
          onError(e.toString());
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? 'Verification failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  // Verifies the OTP and logs the user into Firebase
  Future<UserCredential> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    final PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _firebaseAuth.signInWithCredential(credential);
  }

  // Checks if a user is currently logged in via Firebase
  bool isLoggedIn() {
    return _firebaseAuth.currentUser != null;
  }

  // Get current user ID (Firebase UID string)
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  // Get current user Phone
  String? get currentUserPhone => _firebaseAuth.currentUser?.phoneNumber;

  // Log out of Firebase session
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  // Fetches the user profile from Supabase database matching Firebase UID
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      final data = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return data;
    } catch (e) {
      return null;
    }
  }

  // Check if a phone number is pre-authorized as admin in Supabase
  Future<bool> isPhoneAuthorizedAdmin(String phone) async {
    try {
      final response = await _supabaseClient
          .from('allowed_admins')
          .select('phone')
          .eq('phone', phone)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Create a profile for the current Firebase user in Supabase
  Future<Map<String, dynamic>> createProfile(String name) async {
    final userId = currentUserId;
    final phone = currentUserPhone;
    if (userId == null || phone == null) {
      throw Exception('User is not logged in');
    }

    final isAdmin = await isPhoneAuthorizedAdmin(phone);
    final profileData = {
      'id': userId, // Firebase UID
      'phone': phone,
      'name': name,
      'role': isAdmin ? 'admin' : 'student',
      'status': isAdmin ? 'approved' : 'pending',
      'student_type': isAdmin ? 'Admin' : null,
      'fees': 0,
    };

    await _supabaseClient.from('profiles').insert(profileData).select();
    return profileData;
  }

  // Get list of pending student approval requests (Admins only)
  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final response = await _supabaseClient
        .from('profiles')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  // Approve a pending request and assign type and fees (Admins only)
  Future<void> approveStudent(String uid, String type, double fees) async {
    await _supabaseClient
        .from('profiles')
        .update({'status': 'approved', 'student_type': type, 'fees': fees})
        .eq('id', uid);
  }

  // Add a phone number to allowed_admins (Admins only)
  Future<void> addAdmin(String phone) async {
    // 1. Add to allowed_admins
    await _supabaseClient.from('allowed_admins').insert({'phone': phone});

    // 2. If the user already has a profile, upgrade their role to admin and approve them
    try {
      await _supabaseClient
          .from('profiles')
          .update({'role': 'admin', 'status': 'approved'})
          .eq('phone', phone);
    } catch (e) {
      // Profile might not exist yet, which is fine
    }
  }

  // Get all pre-authorized admins
  Future<List<String>> getAllowedAdmins() async {
    final response = await _supabaseClient
        .from('allowed_admins')
        .select('phone');
    return List<String>.from(
      (response as List).map((e) => e['phone'] as String),
    );
  }
  // ----- New Methods -----

  // Fetch attendance records for a student between dates
  Future<List<Map<String, dynamic>>> getStudentAttendance(
    String uid, {
    DateTime? start,
    DateTime? end,
  }) async {
    var query = _supabaseClient
        .from('attendance')
        .select('*')
        .eq('student_id', uid);
    if (start != null) {
      query = query.gte('date', start.toIso8601String().split('T').first);
    }
    if (end != null) {
      query = query.lte('date', end.toIso8601String().split('T').first);
    }
    final response = await query.order('date', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // Mark attendance for a date; entries: list of maps {student_id, status}
  Future<void> markAttendance(
    String date,
    List<Map<String, dynamic>> entries,
  ) async {
    // Delete any existing records for this date to avoid duplicates
    await _supabaseClient.from('attendance').delete().eq('date', date);
    // Insert new entries with date field
    final toInsert = entries
        .map(
          (e) => {
            'student_id': e['student_id'],
            'date': date,
            'status': e['status'],
          },
        )
        .toList();
    await _supabaseClient.from('attendance').insert(toInsert);
  }

  // Retrieve all approved students (for admin dropdown)
  Future<List<Map<String, dynamic>>> getAllStudents() async {
    final response = await _supabaseClient
        .from('profiles')
        .select('id, name, student_type')
        .eq('role', 'student')
        .eq('status', 'approved');
    return List<Map<String, dynamic>>.from(response as List);
  }

  // Fetch notices for a particular audience (All or specific type)
  Future<List<Map<String, dynamic>>> getNotices({
    required String audience,
  }) async {
    final response = await _supabaseClient
        .from('notices')
        .select('*')
        .eq('target_audience', audience)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // Fetch notices targeted specifically at a student by UID
  Future<List<Map<String, dynamic>>> getStudentSpecificNotices(
    String uid,
  ) async {
    if (uid.isEmpty) return [];
    final response = await _supabaseClient
        .from('notices')
        .select('*')
        .eq('target_audience', 'Specific')
        .eq('specific_student_id', uid)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // Create a new notice
  Future<void> createNotice({
    required String title,
    required String body,
    required String audience,
    String? specificStudentId,
    String category = 'General',
  }) async {
    final data = {
      'title': title,
      'body': body,
      'target_audience': audience,
      'category': category,
      'created_at': DateTime.now().toIso8601String(),
    };
    if (audience == 'Specific' && specificStudentId != null) {
      data['specific_student_id'] = specificStudentId;
    }
    await _supabaseClient.from('notices').insert(data);
  }

  // Fetch all notices for admin review
  Future<List<Map<String, dynamic>>> getSentNotices() async {
    final response = await _supabaseClient
        .from('notices')
        .select('*')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // Delete a notice
  Future<void> deleteNotice(int id) async {
    await _supabaseClient.from('notices').delete().eq('id', id);
  }

  // Upload gallery images (compress to <=450KB) and store URLs
  Future<List<String>> uploadGalleryImages(List<File> files) async {
    final List<String> urls = [];
    for (var file in files) {
      try {
        // Compress image
        print("Starting compression for file: ${file.path}");
        final compressed = await compressImage(file);
        print(
          "Compression done. Compressed file size: ${await compressed.length()} bytes",
        );

        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
        print("Uploading to Supabase storage with name: $fileName");

        await Supabase.instance.client.storage
            .from('gallery')
            .uploadBinary(fileName, await compressed.readAsBytes());

        final publicUrl = Supabase.instance.client.storage
            .from('gallery')
            .getPublicUrl(fileName);
        print("Upload successful. Public URL: $publicUrl");

        // Insert record into gallery table
        await _supabaseClient.from('gallery').insert({
          'image_url': publicUrl,
          'uploaded_by': currentUserId,
          'created_at': DateTime.now().toIso8601String(),
        });
        urls.add(publicUrl);
      } catch (e, stackTrace) {
        print("ERROR DURING UPLOAD/COMPRESSION: $e");
        print(stackTrace);
        rethrow;
      }
    }
    return urls;
  }

  // Helper to compress image using flutter_image_compress to <=450KB
  Future<File> compressImage(File file) async {
    const maxSize = 450 * 1024; // 450KB
    var quality = 95;
    File? compressedFile = file;
    while (true) {
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        '${file.path}_compressed.jpg',
        quality: quality,
      );
      if (result == null) break;
      final asFile = File(result.path); // XFile → File (v2.x returns XFile)
      final bytes = await asFile.length();
      if (bytes <= maxSize || quality <= 30) {
        compressedFile = asFile;
        break;
      }
      quality -= 10;
    }
    return compressedFile!;
  }

  // Fetch gallery images
  Future<List<Map<String, dynamic>>> getGalleryImages() async {
    final response = await _supabaseClient
        .from('gallery')
        .select('*')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // Delete a gallery image from database and storage
  Future<void> deleteGalleryImage(int id, String imageUrl) async {
    await _supabaseClient.from('gallery').delete().eq('id', id);
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final fileName = pathSegments.last;
        await _supabaseClient.storage.from('gallery').remove([fileName]);
      }
    } catch (e) {
      print("Error deleting storage file: $e");
    }
  }

  // Send a chat message
  Future<void> sendMessage(
    String senderId,
    String receiverId,
    String text,
  ) async {
    await _supabaseClient.from('messages').insert({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': text,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Stream messages for a chat between student and admin
  // Uses Realtime channel subscription + initial fetch for reliability
  Stream<List<Map<String, dynamic>>> getChatStream(String studentId) {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
    List<Map<String, dynamic>> _messages = [];

    bool _isMessageForThisChat(Map<String, dynamic> m) {
      final sender = (m['sender_id'] ?? '') as String;
      final receiver = (m['receiver_id'] ?? '') as String;
      return (sender == studentId && receiver == 'admin') ||
          (sender == 'admin' && receiver == studentId);
    }

    // Step 1: Fetch existing messages immediately
    Future<void> fetchInitial() async {
      try {
        final data = await _supabaseClient
            .from('messages')
            .select()
            .or('and(sender_id.eq.$studentId,receiver_id.eq.admin),and(sender_id.eq.admin,receiver_id.eq.$studentId)')
            .order('created_at', ascending: true);
        _messages = List<Map<String, dynamic>>.from(data);
        if (!controller.isClosed) controller.add(List.from(_messages));
      } catch (e) {
        print('ChatStream fetchInitial error: $e');
      }
    }

    fetchInitial();

    // Step 2: Subscribe to Realtime INSERT events on messages table
    final channelName = 'chat_${studentId}_admin';
    final channel = _supabaseClient.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final newRow = payload.newRecord;
            if (_isMessageForThisChat(newRow)) {
              _messages.add(Map<String, dynamic>.from(newRow));
              // Sort by created_at to ensure correct order
              _messages.sort((a, b) {
                final ta = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(0);
                final tb = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(0);
                return ta.compareTo(tb);
              });
              if (!controller.isClosed) controller.add(List.from(_messages));
            }
          },
        )
        .subscribe();

    // Clean up channel when stream is cancelled
    controller.onCancel = () {
      _supabaseClient.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }

  // Fetch list of students who have chatted (admin inbox list)
  Future<List<Map<String, dynamic>>> getChatList() async {
    // Get unique student ids from messages
    final response = await _supabaseClient
        .from('messages')
        .select('sender_id, receiver_id')
        .order('created_at', ascending: false);

    final studentIds = <String>{};
    for (var m in response) {
      final s = m['sender_id'] as String;
      final r = m['receiver_id'] as String;
      if (s != 'admin') studentIds.add(s);
      if (r != 'admin') studentIds.add(r);
    }

    if (studentIds.isEmpty) return [];

    // Get profiles details for these student IDs
    final profilesResponse = await _supabaseClient
        .from('profiles')
        .select('id, name, phone, student_type')
        .inFilter('id', studentIds.toList());

    return List<Map<String, dynamic>>.from(profilesResponse as List);
  }
}
