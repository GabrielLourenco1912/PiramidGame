import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../app/app_dependencies.dart';
import '../../core/result/result.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/profile_photo_source.dart';
import 'student_avatar.dart';

enum _PhotoAction { camera, gallery, remove }

class ProfilePhotoEditor extends SignalWidget {
  const ProfilePhotoEditor({required this.name, this.size = 64, super.key});
  final String name;
  final double size;

  Future<void> _choose(BuildContext context) async {
    final auth = AppDependencies.of(context).authViewModel;
    final action = await showModalBottomSheet<_PhotoAction>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alterar foto de perfil',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text('Sua foto aparecerá no seu perfil e nos rankings.'),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Tirar foto'),
                  subtitle: const Text('Autorize a câmera quando solicitado.'),
                  onTap: () => Navigator.pop(sheetContext, _PhotoAction.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Escolher da galeria'),
                  subtitle: const Text(
                    'Você escolhe qual foto o app pode acessar.',
                  ),
                  onTap: () =>
                      Navigator.pop(sheetContext, _PhotoAction.gallery),
                ),
                if (auth.user.value?.foto != null)
                  ListTile(
                    leading: const Icon(Icons.hide_image_outlined),
                    title: const Text('Remover foto'),
                    subtitle: const Text(
                      'Voltar a mostrar as iniciais do nome.',
                    ),
                    onTap: () =>
                        Navigator.pop(sheetContext, _PhotoAction.remove),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Cancelar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    final result = switch (action) {
      _PhotoAction.camera => await auth.changeProfilePhotoCommand.execute(
        ProfilePhotoSource.camera,
      ),
      _PhotoAction.gallery => await auth.changeProfilePhotoCommand.execute(
        ProfilePhotoSource.gallery,
      ),
      _PhotoAction.remove => await auth.removeProfilePhotoCommand.execute(),
    };
    if (!context.mounted) return;
    final message = switch (result) {
      Success<AppUser?>(data: null) => null,
      Success<AppUser?>() =>
        action == _PhotoAction.remove
            ? 'Foto removida.'
            : 'Foto de perfil atualizada.',
      Failure<AppUser?>(:final message) => message,
    };
    if (message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppDependencies.of(context).authViewModel;
    final colors = Theme.of(context).colorScheme;
    final busy = auth.photoBusy.value;
    return Semantics(
      button: true,
      label: busy ? 'Salvando foto de perfil' : 'Alterar foto de perfil',
      child: Tooltip(
        message: 'Alterar foto de perfil',
        child: InkResponse(
          onTap: auth.busy.value ? null : () => _choose(context),
          radius: size / 2 + 8,
          child: SizedBox(
            width: size + 8,
            height: size + 8,
            child: Stack(
              alignment: Alignment.center,
              children: [
                StudentAvatar(
                  name: name,
                  photoUrl: auth.user.value?.foto,
                  size: size,
                ),
                if (busy)
                  SizedBox(
                    width: size + 6,
                    height: size + 6,
                    child: const CircularProgressIndicator(strokeWidth: 3),
                  ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: colors.primary,
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: colors.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
