import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'dart:io';

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
        const SnackBar(
          content: Text('Images uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload images: $e'),
          backgroundColor: Colors.redAccent,
        ),
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
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text('Delete Image', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this image from gallery?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
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
          const SnackBar(
            content: Text('Image deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      } finally {
        if (mounted) {
          await _loadGallery();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text('Gallery Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E2C),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.add_a_photo), onPressed: _pickAndUpload),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF4E7E)))
          : _images.isEmpty
              ? const Center(child: Text('No images uploaded', style: TextStyle(color: Colors.white70)))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
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
                    return Card(
                      color: const Color(0xFF1E1E2C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(url, fit: BoxFit.cover),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black.withValues(alpha: 0.6),
                              radius: 18,
                              child: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                onPressed: () => _deleteImage(img),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
