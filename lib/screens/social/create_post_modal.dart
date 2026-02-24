import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../services/social_service.dart';
import '../../utils/colors.dart';

/// Modal para criar novo post. Retorna o [Post] criado ou null se cancelado.
class CreatePostModal extends StatefulWidget {
  final User user;
  final String userBikeModel;

  const CreatePostModal({
    super.key,
    required this.user,
    required this.userBikeModel,
  });

  @override
  State<CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<CreatePostModal> {
  final _controller = TextEditingController();
  final List<String> _imagePaths = [];
  bool _loading = false;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x != null && mounted) setState(() => _imagePaths.add(x.path));
  }

  void _removeImage(int index) {
    setState(() => _imagePaths.removeAt(index));
  }

  Future<void> _publish() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final post = await SocialService.createPost(
        userId: widget.user.id,
        userName: widget.user.name,
        userBikeModel: widget.userBikeModel,
        userAvatarUrl: widget.user.photoUrl,
        content: text,
        imageUrls: _imagePaths.isEmpty ? null : _imagePaths,
      );
      if (mounted) Navigator.of(context).pop(post);
    } catch (e) {
      if (mounted) {
        final message = e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : 'Erro ao publicar. Tenta novamente.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nova publicação',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    TextButton(
                      onPressed: _loading ? null : _publish,
                      child: _loading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.racingOrange,
                              ),
                            )
                          : Text(
                              'Publicar',
                              style: TextStyle(
                                color: AppColors.racingOrange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _controller,
                        maxLines: 5,
                        minLines: 4,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: 'O que está acontecendo? Dica de manutenção, passeio...',
                          hintStyle: TextStyle(
                            color: theme.hintColor.withOpacity(0.8),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: theme.dividerColor.withOpacity(0.6),
                            ),
                          ),
                          filled: true,
                          fillColor: theme.cardColor,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      if (_imagePaths.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 88,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _imagePaths.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (context, i) {
                              return Stack(
                                children: [
                                  Container(
                                    width: 76,
                                    height: 76,
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: theme.dividerColor.withOpacity(0.5),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.photo_library,
                                      color: theme.iconTheme.color?.withOpacity(0.5),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(i),
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: theme.colorScheme.error,
                                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Material(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            child: IconButton(
                              onPressed: _pickImage,
                              icon: Icon(
                                Icons.photo_library_outlined,
                                color: theme.iconTheme.color,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Adicionar foto',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
