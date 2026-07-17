import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'dart:io';

/// ---------------------------------------------------------------------
/// Design tokens — kept consistent with the rest of the admin panel
/// ---------------------------------------------------------------------
class _Palette {
  static const primary = Color(0xFFE94464);
  static const primaryDark = Color(0xFFD32F52);
  static const primarySoft = Color(0xFFFFE7EC);

  static const bg = Color(0xFFFBF9FA);
  static const surface = Colors.white;
  static const border = Color(0xFFF1E4E7);

  static const textDark = Color(0xFF2B2730);
  static const textMuted = Color(0xFF8F8A93);
  static const textFaint = Color(0xFFB9B3BB);

  static const success = Color(0xFF3FAE5C);
  static const danger = Color(0xFFE2504A);
}

class GalleryAdminPage extends StatefulWidget {
  final AuthService authService;
  const GalleryAdminPage({Key? key, required this.authService}) : super(key: key);

  @override
  State<GalleryAdminPage> createState() => _GalleryAdminPageState();
}

class _GalleryAdminPageState extends State<GalleryAdminPage> {
  List<Map<String, dynamic>> _images = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGallery();
  }

  Future<void> _loadGallery() async {
    setState(() => _loading = true);
    final images = await widget.authService.getGalleryImages();
    if (!mounted) return;
    setState(() {
      _images = images;
      _loading = false;
    });
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final List<XFile> files = await picker.pickMultiImage();
    if (files.isEmpty) return;
    final fileList = files.map((x) => File(x.path)).toList();

    setState(() => _loading = true);
    try {
      await widget.authService.uploadGalleryImages(fileList);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        _snack('Images uploaded successfully!', success: true),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        _snack('Failed to upload images: $e', success: false),
      );
    } finally {
      if (mounted) {
        await _loadGallery();
      }
    }
  }

  Future<void> _deleteImage(Map<String, dynamic> img) async {
    final id = img['id'] as int;
    final url = img['image_url'] as String;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _Palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _Palette.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: _Palette.danger, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Delete Image',
                style: TextStyle(color: _Palette.textDark, fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this image from gallery?',
          style: TextStyle(color: _Palette.textMuted, fontSize: 13.5, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: _Palette.textMuted),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _Palette.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _loading = true);
      try {
        await widget.authService.deleteGalleryImage(id, url);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          _snack('Image deleted successfully', success: true),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          _snack('Failed to delete image: $e', success: false),
        );
      } finally {
        if (mounted) {
          await _loadGallery();
        }
      }
    }
  }

  SnackBar _snack(String message, {required bool success}) {
    return SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: success ? _Palette.success : _Palette.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.bg,
      appBar: AppBar(
        title: const Text('Gallery Management',
            style: TextStyle(color: _Palette.textDark, fontWeight: FontWeight.w800, fontSize: 19)),
        backgroundColor: _Palette.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _Palette.textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: BorderSide(color: _Palette.border, width: 1)),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: _Palette.primarySoft, shape: BoxShape.circle),
              child: const Icon(Icons.add_a_photo_rounded, color: _Palette.primary, size: 18),
            ),
            onPressed: _loading ? null : _pickAndUpload,
            tooltip: 'Upload Images',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _pickAndUpload,
        backgroundColor: _Palette.primary,
        elevation: 2,
        icon: const Icon(Icons.upload_rounded, color: Colors.white),
        label: const Text('Upload',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _Palette.primary))
          : _images.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: _Palette.textFaint.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.photo_library_rounded, size: 46, color: _Palette.textFaint),
                      ),
                      const SizedBox(height: 18),
                      const Text('No Images Uploaded',
                          style: TextStyle(
                              fontSize: 16.5, color: _Palette.textDark, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      const Text('Tap upload to add gallery photos',
                          style: TextStyle(fontSize: 13, color: _Palette.textMuted, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _pickAndUpload,
                        icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                        label: const Text('Upload Images', style: TextStyle(fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _Palette.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadGallery,
                  color: _Palette.primary,
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      final img = _images[index];
                      final url = img['image_url'] as String;
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _Palette.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              url,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: _Palette.bg,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: _Palette.primary,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: _Palette.bg,
                                child: const Center(
                                  child: Icon(Icons.broken_image_rounded, color: _Palette.textFaint),
                                ),
                              ),
                            ),
                            // Subtle gradient so the delete button stays legible
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: 56,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.black.withOpacity(0.35), Colors.transparent],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Material(
                                color: Colors.white.withOpacity(0.92),
                                shape: const CircleBorder(),
                                elevation: 1,
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () => _deleteImage(img),
                                  child: const Padding(
                                    padding: EdgeInsets.all(7),
                                    child: Icon(Icons.delete_outline_rounded,
                                        color: _Palette.danger, size: 18),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}