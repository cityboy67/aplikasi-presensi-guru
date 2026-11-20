import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  // Parameter lama dipertahankan agar pemanggilan dari ProfileScreen
  // yang sudah ada tidak langsung menyebabkan error.
  final String initialName;
  final String initialEmail;
  final String initialAddress;
  final String initialPhone;
  final String? initialPhotoUrl;

  const EditProfileScreen({
    super.key,
    this.initialName = '',
    this.initialEmail = '',
    this.initialAddress = '',
    this.initialPhone = '',
    this.initialPhotoUrl,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  static const Color _green = Color(0xFF00C853);
  static const Color _darkGreen = Color(0xFF41735E);

  bool _isLoading = true;
  bool _isSaving = false;
  String? _guruId;
  String? _niy;
  String? _oldPhotoPath;
  String? _photoUrl;
  File? _newPhoto;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _photoUrl = widget.initialPhotoUrl;
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Sesi login tidak ditemukan. Silakan login kembali.');
      }

      final data = await _supabase
          .from('guru')
          .select('guru_id, nama, niy, no_telepon, foto_url')
          .eq('user_id', user.id)
          .maybeSingle();

      if (data == null) {
        throw Exception('Data guru tidak ditemukan.');
      }

      final storedPhoto = data['foto_url']?.toString();
      final photoPath = _extractStoragePath(storedPhoto);

      String? signedUrl;
      if (photoPath != null && photoPath.isNotEmpty) {
        signedUrl = await _supabase.storage
            .from('foto-guru')
            .createSignedUrl(photoPath, 3600);
      }

      if (!mounted) return;
      setState(() {
        _guruId = data['guru_id']?.toString();
        _niy = data['niy']?.toString();
        _nameController.text = data['nama']?.toString() ?? '';
        _phoneController.text = data['no_telepon']?.toString() ?? '';
        _oldPhotoPath = photoPath;
        _photoUrl = signedUrl;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat profil: $e')),
      );
    }
  }

  String? _extractStoragePath(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final input = value.trim();

    // Kolom foto_url idealnya menyimpan path relatif, misalnya:
    // guru/2405422/1795123456789.jpg
    if (!input.startsWith('http://') && !input.startsWith('https://')) {
      return input;
    }

    // Mendukung URL signed/public Supabase jika sebelumnya URL penuh tersimpan.
    final uri = Uri.tryParse(input);
    if (uri == null) return null;
    final segments = uri.pathSegments;
    final bucketIndex = segments.indexOf('foto-guru');
    if (bucketIndex < 0 || bucketIndex + 1 >= segments.length) return null;
    return segments.skip(bucketIndex + 1).map(Uri.decodeComponent).join('/');
  }
  
  Future<void> _showEditFieldDialog({
    required String label,
    required TextEditingController targetController,
    required int maxLength,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return _EditFieldDialog(
          label: label,
          initialValue: targetController.text,
          maxLength: maxLength,
          keyboardType: keyboardType,
          buttonColor: _darkGreen,
        );
      },
    );

    if (!mounted || result == null) return;

    setState(() {
      targetController.text = result;
    });
}

  Future<void> _showPhotoSourceBottomSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFDCDCDC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Foto Profil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil foto dengan kamera'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari galeri'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked == null || !mounted) return;
      setState(() => _newPhoto = File(picked.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih foto: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (_guruId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data guru belum berhasil dimuat.')),
      );
      return;
    }
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama lengkap wajib diisi.')),
      );
      return;
    }
    if (phone.isNotEmpty && !RegExp(r'^[0-9+]{8,15}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor WhatsApp harus 8–15 digit (boleh diawali +).'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    String? newPhotoPath;

    try {
      if (_newPhoto != null) {
        final bytes = await _newPhoto!.readAsBytes();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final folder = (_niy == null || _niy!.isEmpty) ? _guruId! : _niy!;
        newPhotoPath = 'guru/$folder/$fileName';

        await _supabase.storage.from('foto-guru').uploadBinary(
          newPhotoPath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );
      }

      final updateData = <String, dynamic>{
        'nama': name,
        'no_telepon': phone,
      };
      if (newPhotoPath != null) {
        updateData['foto_url'] = newPhotoPath;
      }

      // Update baris guru terlebih dahulu agar foto lama tidak hilang
      // jika penyimpanan data profil gagal.
      await _supabase
          .from('guru')
          .update(updateData)
          .eq('guru_id', _guruId!);

      var oldPhotoDeleted = true;
      if (newPhotoPath != null &&
          _oldPhotoPath != null &&
          _oldPhotoPath!.isNotEmpty &&
          _oldPhotoPath != newPhotoPath) {
        try {
          await _supabase.storage.from('foto-guru').remove([_oldPhotoPath!]);
        } catch (e) {
          oldPhotoDeleted = false;
          debugPrint('Foto profil lama gagal dihapus: $e');
        }
      }

      String? newSignedUrl = _photoUrl;
      if (newPhotoPath != null) {
        newSignedUrl = await _supabase.storage
            .from('foto-guru')
            .createSignedUrl(newPhotoPath, 3600);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newPhotoPath == null
                ? 'Profil berhasil diperbarui.'
                : oldPhotoDeleted
                    ? 'Profil dan foto berhasil diperbarui.'
                    : 'Profil tersimpan, tetapi foto lama belum terhapus. Periksa izin DELETE Storage.',
          ),
          backgroundColor: _darkGreen,
        ),
      );

      Navigator.pop(context, {
        'name': name,
        'phone': phone,
        'photo_url': newPhotoPath ?? _oldPhotoPath,
        'photo_signed_url': newSignedUrl,
        // Email tetap dikembalikan untuk kompatibilitas dengan halaman pemanggil.
        'email': widget.initialEmail,
        'address': '', // Kompatibilitas sementara dengan halaman pemanggil lama.
      });
    } catch (e) {
      // Jika file baru terunggah tetapi update tabel gagal, hapus file baru.
      if (newPhotoPath != null) {
        try {
          await _supabase.storage.from('foto-guru').remove([newPhotoPath]);
        } catch (cleanupError) {
          debugPrint('Gagal membersihkan foto baru: $cleanupError');
        }
      }

      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan profil: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPhoto() {
    Widget image;
    if (_newPhoto != null) {
      image = Image.file(_newPhoto!, fit: BoxFit.cover);
    } else if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      image = Image.network(
        _photoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _photoPlaceholder(),
      );
    } else {
      image = _photoPlaceholder();
    }

    return Stack(
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 4),
          ),
          child: ClipOval(child: image),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: InkWell(
            onTap: _showPhotoSourceBottomSheet,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFDCDCDC),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.edit_rounded,
                size: 18,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _photoPlaceholder() => Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.person, size: 70, color: Colors.grey),
      );

  Widget _buildEditFieldCard({
    required String label,
    required String value,
    required VoidCallback onEditTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade400, width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '-' : value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onEditTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.edit_rounded,
                color: Colors.grey.shade700,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarLogo(
    String assetPath,
    IconData fallbackIcon,
    Color fallbackColor,
  ) {
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                Icon(fallbackIcon, color: fallbackColor, size: 18),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
          onPressed: () {},
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                _buildAppBarLogo(
                  'assets/images/logo_upi.png',
                  Icons.school,
                  Colors.red.shade700,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    'x',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                _buildAppBarLogo(
                  'assets/images/logo_mitra.png',
                  Icons.public,
                  Colors.teal.shade700,
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(child: _buildPhoto()),
                      const SizedBox(height: 36),
                      _buildEditFieldCard(
                        label: 'Nama Lengkap',
                        value: _nameController.text,
                        onEditTap: () => _showEditFieldDialog(
                          label: 'Nama Lengkap',
                          targetController: _nameController,
                          maxLength: 60,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildEditFieldCard(
                        label: 'Nomor WhatsApp',
                        value: _phoneController.text,
                        onEditTap: () => _showEditFieldDialog(
                          label: 'Nomor WhatsApp',
                          targetController: _phoneController,
                          maxLength: 15,
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: Container(
        color: _green,
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.black, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Discard',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving || _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _darkGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditFieldDialog extends StatefulWidget {
  final String label;
  final String initialValue;
  final int maxLength;
  final TextInputType keyboardType;
  final Color buttonColor;

  const _EditFieldDialog({
    required this.label,
    required this.initialValue,
    required this.maxLength,
    required this.keyboardType,
    required this.buttonColor,
  });

  @override
  State<_EditFieldDialog> createState() =>
      _EditFieldDialogState();
}

class _EditFieldDialogState extends State<_EditFieldDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Ubah ${widget.label}'),
      content: TextField(
        controller: _controller,
        maxLength: widget.maxLength,
        keyboardType: widget.keyboardType,
        autofocus: true,
        decoration: InputDecoration(
          labelText: widget.label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(
              _controller.text.trim(),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.buttonColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

