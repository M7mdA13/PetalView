import 'dart:io'; // <-- NEW: Needed to handle image files
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // <-- NEW
import 'package:firebase_storage/firebase_storage.dart'; // <-- NEW

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  static const routeName = 'Account';

  // ثوابت ألوان
  static const mint = Color(0xFFE6F3EA);
  static const green = Color(0xFFDAEFDE);
  static const barGreen = Color(0xFF1E7E5A);
  static const pastelChip = Color(0xFFFFE0B2);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // State variables
  String? _firstName;
  String? _lastName;
  String? _email;
  String? _profilePicUrl; // <-- NEW: To store the image URL
  bool _isLoading = true;
  bool _isUploading = false; // <-- NEW: For image upload loading

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  // <-- NEW: To hold the image picked in the dialog
  File? _tempPickedImageFile;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  /// Fetches the current user's data from Firestore
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _firstName = data['firstName'];
          _lastName = data['lastName'];
          _email = data['email'];
          _profilePicUrl = data['profilePicUrl']; // <-- NEW: Load the URL
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error loading user data: $e");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading your profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// The function for the "Sign out" button
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // <-- NEW: Helper function to pick an image
  Future<void> _pickImage(StateSetter dialogSetState) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Update the state *inside the dialog*
      dialogSetState(() {
        _tempPickedImageFile = File(pickedFile.path);
      });
    }
  }

  /// The function for the "Edit" icon
  Future<void> _showEditProfileDialog() async {
    // Reset temp image file
    _tempPickedImageFile = null;

    _firstNameController.text = _firstName ?? '';
    _lastNameController.text = _lastName ?? '';

    await showDialog(
      context: context,
      builder: (context) {
        // Use a StatefulBuilder so the dialog can update its own state
        // when an image is picked, without closing.
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: const Text("Edit Profile"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // <-- NEW: Image Picker UI
                  GestureDetector(
                    onTap: () => _pickImage(dialogSetState),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          // Show the temporarily picked image
                          backgroundImage: _tempPickedImageFile != null
                              ? FileImage(_tempPickedImageFile!)
                              // Else, show the current profile pic
                              : _profilePicUrl != null
                              ? NetworkImage(_profilePicUrl!)
                              : null,
                          // If no image, show an icon
                          child:
                              _profilePicUrl == null &&
                                  _tempPickedImageFile == null
                              ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey[400],
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AccountScreen.barGreen,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                            padding: EdgeInsets.all(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: "First Name"),
                  ),
                  TextField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: "Last Name"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  // Show loading spinner on button
                  child: _isUploading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text("Save"),
                  onPressed: _isUploading
                      ? null
                      : () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;

                          setState(
                            () => _isUploading = true,
                          ); // Start upload loading

                          try {
                            String? newImageUrl;
                            // 1. If a new image was picked, upload it
                            if (_tempPickedImageFile != null) {
                              // Create a reference in Firebase Storage
                              final ref = FirebaseStorage.instance
                                  .ref()
                                  .child('profile_pictures')
                                  .child('${user.uid}.jpg');

                              // Upload the file
                              await ref.putFile(_tempPickedImageFile!);

                              // Get the download URL
                              newImageUrl = await ref.getDownloadURL();
                            }

                            // 2. Prepare data to update in Firestore
                            final newFirstName = _firstNameController.text
                                .trim();
                            final newLastName = _lastNameController.text.trim();

                            final Map<String, dynamic> dataToUpdate = {
                              'firstName': newFirstName,
                              'lastName': newLastName,
                            };

                            if (newImageUrl != null) {
                              dataToUpdate['profilePicUrl'] = newImageUrl;
                            }

                            // 3. Update Firestore
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .update(dataToUpdate);

                            // 4. Update the local state
                            setState(() {
                              _firstName = newFirstName;
                              _lastName = newLastName;
                              if (newImageUrl != null) {
                                _profilePicUrl = newImageUrl;
                              }
                            });

                            if (mounted) Navigator.pop(context); // Close dialog
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error saving profile: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            setState(
                              () => _isUploading = false,
                            ); // Stop loading
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/bg_welcome.png', fit: BoxFit.cover),
          Container(color: AccountScreen.mint.withOpacity(0.15)),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Image.asset('assets/onboarding/logo.png', height: 52),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      //
                      // vvv UPDATED CONTAINER TO SHOW IMAGE vvv
                      //
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          // Changed to BoxDecoration
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 6),
                            ),
                          ],
                          // <-- NEW: Show profile pic here
                          image: _profilePicUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(_profilePicUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        // <-- NEW: Show icon ONLY if there is no image
                        child: _profilePicUrl == null
                            ? const Icon(
                                Icons.perm_identity_sharp,
                                size: 90,
                                color: Colors.black,
                              )
                            : null,
                      ),
                      // ^^^ UPDATED CONTAINER ^^^
                      //
                      if (!_isLoading && _profilePicUrl == null)
                      const Positioned(
                        right: 30,
                        top: 50,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.favorite,
                            size: 30,
                            color: Color(0xffFCD9BB),
                            
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -12,
                        right: 56,
                        child: InkWell(
                          onTap: _showEditProfileDialog, // <-- WIRED UP
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(60),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 18,
                              color: AccountScreen.barGreen,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Hello, ",
                      style: GoogleFonts.merriweather(
                        fontSize: 22,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _isLoading ? "..." : "${_firstName ?? 'User'}!",
                      style: GoogleFonts.merriweather(
                        fontSize: 30,
                        color: AccountScreen.barGreen,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _AccountButton(text: "SOS", onPressed: () {}),
                      const SizedBox(height: 12),
                      _AccountButton(text: "Settings", onPressed: () {}),
                      const SizedBox(height: 12),
                      _AccountButton(text: "About us", onPressed: () {}),
                      const SizedBox(height: 12),
                      _AccountButton(
                        text: "Sign out",
                        filled: true,
                        onPressed: _signOut, // <-- WIRED UP
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// (No changes to _AccountButton)
class _AccountButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool filled;

  const _AccountButton({
    required this.text,
    required this.onPressed,
    this.filled = false,
  });

  static const green = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Text(
            text,
            style: GoogleFonts.merriweather(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: green, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.merriweather(
            color: green,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
