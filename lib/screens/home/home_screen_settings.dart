part of 'home_screen.dart';

extension _HomeScreenSettings on _HomeScreenState {
  Future<void> _showChangePasswordDialog() async {
    final formKey = GlobalKey<FormState>();
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    var hideCurrent = true;
    var hideNew = true;
    var loading = false;
    String? errorMessage;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: !loading,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final theme = Theme.of(dialogContext);

            return AlertDialog(
              title: const Text('Cambiar contraseña'),
              content: SizedBox(
                width: 460,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Por seguridad, confirma tu contraseña actual antes de establecer una nueva.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: currentController,
                          obscureText: hideCurrent,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Contraseña actual',
                            prefixIcon:
                                const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              tooltip: hideCurrent
                                  ? 'Mostrar contraseña'
                                  : 'Ocultar contraseña',
                              onPressed: loading
                                  ? null
                                  : () => setDialogState(
                                        () => hideCurrent = !hideCurrent,
                                      ),
                              icon: Icon(
                                hideCurrent
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if ((value ?? '').isEmpty) {
                              return 'Escribe tu contraseña actual.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: newController,
                          obscureText: hideNew,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: 'Nueva contraseña',
                            prefixIcon:
                                const Icon(Icons.password_rounded),
                            suffixIcon: IconButton(
                              tooltip: hideNew
                                  ? 'Mostrar contraseña'
                                  : 'Ocultar contraseña',
                              onPressed: loading
                                  ? null
                                  : () => setDialogState(
                                        () => hideNew = !hideNew,
                                      ),
                              icon: Icon(
                                hideNew
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            final password = value ?? '';
                            if (password.length < 6) {
                              return 'Usa al menos 6 caracteres.';
                            }
                            if (password == currentController.text) {
                              return 'La nueva contraseña debe ser diferente.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: confirmController,
                          obscureText: hideNew,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: loading
                              ? null
                              : (_) async {
                                  if (!(formKey.currentState?.validate() ??
                                      false)) {
                                    return;
                                  }

                                  setDialogState(() {
                                    loading = true;
                                    errorMessage = null;
                                  });

                                  try {
                                    await widget.authService.changePassword(
                                      currentPassword:
                                          currentController.text,
                                      newPassword: newController.text,
                                    );

                                    if (!dialogContext.mounted) return;
                                    Navigator.of(dialogContext).pop();

                                    if (mounted) {
                                      _showMessage(
                                        'Contraseña actualizada correctamente.',
                                      );
                                    }
                                  } on AuthException catch (error) {
                                    if (dialogContext.mounted) {
                                      setDialogState(() {
                                        errorMessage = error.message;
                                        loading = false;
                                      });
                                    }
                                  } catch (error) {
                                    if (dialogContext.mounted) {
                                      setDialogState(() {
                                        errorMessage =
                                            'No se pudo cambiar la contraseña: $error';
                                        loading = false;
                                      });
                                    }
                                  }
                                },
                          decoration: const InputDecoration(
                            labelText: 'Confirmar nueva contraseña',
                            prefixIcon: Icon(Icons.lock_reset_rounded),
                          ),
                          validator: (value) {
                            if (value != newController.text) {
                              return 'Las contraseñas no coinciden.';
                            }
                            return null;
                          },
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              errorMessage!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: loading
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: loading
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }

                          setDialogState(() {
                            loading = true;
                            errorMessage = null;
                          });

                          try {
                            await widget.authService.changePassword(
                              currentPassword: currentController.text,
                              newPassword: newController.text,
                            );

                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();

                            if (mounted) {
                              _showMessage(
                                'Contraseña actualizada correctamente.',
                              );
                            }
                          } on AuthException catch (error) {
                            if (dialogContext.mounted) {
                              setDialogState(() {
                                errorMessage = error.message;
                                loading = false;
                              });
                            }
                          } catch (error) {
                            if (dialogContext.mounted) {
                              setDialogState(() {
                                errorMessage =
                                    'No se pudo cambiar la contraseña: $error';
                                loading = false;
                              });
                            }
                          }
                        },
                  icon: loading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.password_rounded),
                  label: Text(
                    loading ? 'Actualizando…' : 'Guardar contraseña',
                  ),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      currentController.dispose();
      newController.dispose();
      confirmController.dispose();
    }
  }

  Future<void> _showSettingsInfo() async {
    var selectedThemeId = widget.themeId;
    var uploadingCloud = false;
    var profileBusy = false;
    String? profileError;
    OrbitaskProfile? profile;

    if (widget.authService.currentUser != null &&
        widget.profileService.isConfigured) {
      try {
        profile = await widget.profileService.loadCurrentProfile();
      } catch (error) {
        profileError = 'No se pudo cargar el perfil: $error';
      }
    }

    if (!mounted) return;

    final usernameController = TextEditingController(
      text: profile?.username ?? '',
    );

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => DefaultTabController(
          length: 3,
          child: StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              final theme = Theme.of(dialogContext);
              final email = widget.authService.currentUser?.email;
              final dialogSize = MediaQuery.sizeOf(dialogContext);
              final compactDialog = dialogSize.width < 600;

              return AlertDialog(
                insetPadding: EdgeInsets.symmetric(
                  horizontal: compactDialog ? 12 : 40,
                  vertical: compactDialog ? 12 : 24,
                ),
                titlePadding: EdgeInsets.fromLTRB(
                  compactDialog ? 16 : 24,
                  compactDialog ? 16 : 20,
                  compactDialog ? 16 : 24,
                  0,
                ),
                contentPadding: EdgeInsets.fromLTRB(
                  compactDialog ? 16 : 24,
                  12,
                  compactDialog ? 16 : 24,
                  8,
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ajustes'),
                    const SizedBox(height: 14),
                    TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelPadding: EdgeInsets.symmetric(
                        horizontal: compactDialog ? 12 : 16,
                      ),
                      tabs: [
                        const Tab(
                          icon: Icon(Icons.palette_outlined),
                          text: 'Apariencia',
                        ),
                        Tab(
                          icon: const Icon(Icons.person_outline_rounded),
                          text: compactDialog ? 'Cuenta' : 'Cuenta y nube',
                        ),
                        Tab(
                          icon: const Icon(Icons.notifications_outlined),
                          text: compactDialog ? 'Avisos' : 'Notificaciones',
                        ),
                      ],
                    ),
                  ],
                ),
                content: SizedBox(
                  width: compactDialog ? dialogSize.width : 720,
                  height: compactDialog ? dialogSize.height * 0.68 : 570,
                  child: TabBarView(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 8, bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Tema de Orbitask',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.authService.currentUser == null
                                  ? 'Elige la apariencia que prefieras. La selección se guarda localmente.'
                                  : 'Elige la apariencia que prefieras. La selección se sincroniza con tu cuenta.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ThemePicker(
                              currentThemeId: selectedThemeId,
                              onSelected: (themeId) {
                                setDialogState(
                                  () => selectedThemeId = themeId,
                                );
                                widget.onThemeChanged(themeId);
                                _scheduleCloudSync();
                              },
                            ),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 8, bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Perfil',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.all(compactDialog ? 12 : 16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: compactDialog ? 30 : 38,
                                    backgroundColor:
                                        theme.colorScheme.surfaceContainerHigh,
                                    backgroundImage:
                                        profile?.avatarUrl == null
                                            ? null
                                            : NetworkImage(
                                                profile!.avatarUrl!,
                                              ),
                                    child: profile?.avatarUrl == null
                                        ? Icon(
                                            Icons.person_rounded,
                                            size: compactDialog ? 30 : 38,
                                            color: theme.colorScheme
                                                .onSurfaceVariant,
                                          )
                                        : null,
                                  ),
                                  SizedBox(width: compactDialog ? 12 : 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          profile?.username == null
                                              ? 'Configura tu username'
                                              : '@${profile!.username}',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          email ?? 'Cuenta local',
                                          maxLines: compactDialog ? 2 : 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: theme.colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            OutlinedButton.icon(
                                              onPressed: profileBusy ||
                                                      email == null
                                                  ? null
                                                  : () async {
                                                      final picked =
                                                          await FilePicker
                                                              .platform
                                                              .pickFiles(
                                                        type: FileType.custom,
                                                        allowedExtensions: const [
                                                          'jpg',
                                                          'jpeg',
                                                          'png',
                                                          'webp',
                                                        ],
                                                        withData: true,
                                                        allowMultiple: false,
                                                      );

                                                      if (picked == null ||
                                                          picked.files
                                                              .isEmpty) {
                                                        return;
                                                      }

                                                      final file =
                                                          picked.files.single;
                                                      final bytes = file.bytes;
                                                      if (bytes == null) {
                                                        setDialogState(() {
                                                          profileError =
                                                              'No se pudo leer la imagen seleccionada.';
                                                        });
                                                        return;
                                                      }

                                                      final extension = file
                                                          .extension
                                                          ?.toLowerCase();
                                                      final mimeType =
                                                          extension == 'png'
                                                              ? 'image/png'
                                                              : extension ==
                                                                      'webp'
                                                                  ? 'image/webp'
                                                                  : 'image/jpeg';

                                                      setDialogState(() {
                                                        profileBusy = true;
                                                        profileError = null;
                                                      });

                                                      try {
                                                        final updated =
                                                            await widget
                                                                .profileService
                                                                .uploadAvatar(
                                                          bytes: bytes,
                                                          mimeType: mimeType,
                                                        );
                                                        if (!dialogContext
                                                            .mounted) {
                                                          return;
                                                        }
                                                        setDialogState(() {
                                                          profile = updated;
                                                          profileBusy = false;
                                                        });
                                                      } catch (error) {
                                                        if (dialogContext
                                                            .mounted) {
                                                          setDialogState(() {
                                                            profileBusy =
                                                                false;
                                                            profileError =
                                                                'No se pudo actualizar la foto: $error';
                                                          });
                                                        }
                                                      }
                                                    },
                                              icon: const Icon(
                                                Icons.photo_camera_outlined,
                                              ),
                                              label: Text(
                                                profileBusy
                                                    ? 'Subiendo…'
                                                    : (compactDialog
                                                        ? 'Foto'
                                                        : 'Cambiar foto'),
                                              ),
                                            ),
                                            if (profile?.avatarPath != null)
                                              TextButton.icon(
                                                onPressed: profileBusy
                                                    ? null
                                                    : () async {
                                                        setDialogState(() {
                                                          profileBusy = true;
                                                          profileError = null;
                                                        });
                                                        try {
                                                          final updated =
                                                              await widget
                                                                  .profileService
                                                                  .removeAvatar();
                                                          if (!dialogContext
                                                              .mounted) {
                                                            return;
                                                          }
                                                          setDialogState(() {
                                                            profile = updated;
                                                            profileBusy =
                                                                false;
                                                          });
                                                        } catch (error) {
                                                          if (dialogContext
                                                              .mounted) {
                                                            setDialogState(() {
                                                              profileBusy =
                                                                  false;
                                                              profileError =
                                                                  'No se pudo quitar la foto: $error';
                                                            });
                                                          }
                                                        }
                                                      },
                                                icon: const Icon(
                                                  Icons.delete_outline_rounded,
                                                ),
                                                label: Text(
                                                  compactDialog
                                                      ? 'Quitar'
                                                      : 'Quitar foto',
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: usernameController,
                              enabled: !profileBusy && email != null,
                              maxLength: 24,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                prefixText: '@',
                                helperText:
                                    '3–24 caracteres: letras, números y guion bajo.',
                                prefixIcon:
                                    Icon(Icons.alternate_email_rounded),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FilledButton.icon(
                                onPressed: profileBusy || email == null
                                    ? null
                                    : () async {
                                        setDialogState(() {
                                          profileBusy = true;
                                          profileError = null;
                                        });

                                        try {
                                          final updated = await widget
                                              .profileService
                                              .updateUsername(
                                                usernameController.text,
                                              );
                                          if (!dialogContext.mounted) return;
                                          usernameController.text =
                                              updated.username ?? '';
                                          setDialogState(() {
                                            profile = updated;
                                            profileBusy = false;
                                          });
                                          if (mounted) {
                                            _showMessage(
                                              'Perfil actualizado.',
                                            );
                                          }
                                        } on PostgrestException catch (error) {
                                          if (dialogContext.mounted) {
                                            setDialogState(() {
                                              profileBusy = false;
                                              profileError =
                                                  error.code == '23505'
                                                      ? 'Ese username ya está en uso.'
                                                      : error.message;
                                            });
                                          }
                                        } catch (error) {
                                          if (dialogContext.mounted) {
                                            setDialogState(() {
                                              profileBusy = false;
                                              profileError =
                                                  error is FormatException
                                                      ? error.message
                                                      : 'No se pudo guardar el username: $error';
                                            });
                                          }
                                        }
                                      },
                                icon: const Icon(Icons.save_outlined),
                                label: Text(
                                  profileBusy
                                      ? 'Guardando…'
                                      : 'Guardar username',
                                ),
                              ),
                            ),
                            if (profileError != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  profileError!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            Text(
                              'Sincronización',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _cloudSyncFailed
                                            ? Icons.cloud_off_outlined
                                            : (_cloudSyncing
                                                ? Icons.sync_rounded
                                                : Icons.cloud_done_outlined),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _cloudSyncing
                                              ? 'Sincronizando…'
                                              : (_cloudSyncFailed
                                                  ? 'Pendiente de sincronizar'
                                                  : 'Sincronización activa'),
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Última sincronización: '
                                    '${_formatSyncTime(widget.cloudSyncService.lastSuccessfulSyncAt)}',
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: theme
                                          .colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Última subida local: '
                                    '${_formatSyncTime(widget.cloudSyncService.lastSuccessfulUploadAt)}',
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: theme
                                          .colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop();
                                      _showSyncStatus();
                                    },
                                    icon: const Icon(
                                      Icons.info_outline_rounded,
                                    ),
                                    label: const Text('Ver detalles'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                FilledButton.icon(
                                  onPressed: uploadingCloud || _cloudSyncing
                                      ? null
                                      : () async {
                                          setDialogState(
                                            () => uploadingCloud = true,
                                          );
                                          setState(
                                            () => _cloudSyncing = true,
                                          );
                                          try {
                                            final result = await widget
                                                .cloudSyncService
                                                .syncNow();
                                            if (!mounted) return;

                                            widget.onCloudThemeChanged(
                                              result.themeId,
                                            );
                                            setDialogState(() {
                                              selectedThemeId =
                                                  result.themeId;
                                            });

                                            setState(() {
                                              _cloudSyncFailed = false;
                                              _cloudSyncError = null;
                                              _lastCloudSyncAt = widget
                                                  .cloudSyncService
                                                  .lastSuccessfulSyncAt;
                                            });

                                            _notificationsReconciled = false;
                                            await _loadData();

                                            if (mounted) {
                                              _showMessage(
                                                'Sincronización completada.',
                                              );
                                            }
                                          } catch (error) {
                                            if (mounted) {
                                              setState(() {
                                                _cloudSyncFailed = true;
                                                _cloudSyncError =
                                                    error.toString();
                                              });
                                              _showMessage(
                                                'No se pudo sincronizar con Supabase: $error',
                                              );
                                            }
                                          } finally {
                                            if (dialogContext.mounted) {
                                              setDialogState(
                                                () => uploadingCloud = false,
                                              );
                                            }
                                            if (mounted) {
                                              setState(
                                                () => _cloudSyncing = false,
                                              );
                                            }
                                          }
                                        },
                                  icon: uploadingCloud
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.sync_rounded),
                                  label: Text(
                                    uploadingCloud
                                        ? 'Sincronizando…'
                                        : 'Sincronizar ahora',
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: email == null
                                      ? null
                                      : () async {
                                          Navigator.of(dialogContext).pop();
                                          await _showChangePasswordDialog();
                                        },
                                  icon:
                                      const Icon(Icons.password_rounded),
                                  label:
                                      const Text('Cambiar contraseña'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: email == null
                                      ? null
                                      : () async {
                                          try {
                                            await widget.authService
                                                .signOut();
                                            if (dialogContext.mounted) {
                                              Navigator.of(dialogContext)
                                                  .pop();
                                            }
                                          } catch (error) {
                                            if (mounted) {
                                              _showMessage(
                                                'No se pudo cerrar la sesión: $error',
                                              );
                                            }
                                          }
                                        },
                                  icon: const Icon(Icons.logout_rounded),
                                  label: const Text('Cerrar sesión'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 8, bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Notificaciones',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Comprueba que Orbitask puede mostrar avisos en este dispositivo.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                              child: compactDialog
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Icon(
                                            Icons
                                                .notifications_active_outlined,
                                            size: 30,
                                            color:
                                                theme.colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Envía una notificación de prueba para verificar permisos y funcionamiento.',
                                        ),
                                        const SizedBox(height: 14),
                                        FilledButton.icon(
                                          onPressed: () async {
                                            await widget.notificationService
                                                .requestPermissions();
                                            final shown = await widget
                                                .notificationService
                                                .showNow(
                                              title: 'Orbitask',
                                              body:
                                                  'Las notificaciones están funcionando.',
                                            );
                                            if (mounted) {
                                              _showMessage(
                                                shown
                                                    ? 'Notificación de prueba enviada.'
                                                    : 'El sistema de notificaciones no está disponible en este dispositivo.',
                                              );
                                            }
                                          },
                                          icon: const Icon(
                                            Icons
                                                .notifications_active_rounded,
                                          ),
                                          label: const Text('Probar'),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Icon(
                                          Icons
                                              .notifications_active_outlined,
                                          size: 30,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 14),
                                        const Expanded(
                                          child: Text(
                                            'Envía una notificación de prueba para verificar permisos y funcionamiento.',
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        FilledButton.icon(
                                          onPressed: () async {
                                            await widget.notificationService
                                                .requestPermissions();
                                            final shown = await widget
                                                .notificationService
                                                .showNow(
                                              title: 'Orbitask',
                                              body:
                                                  'Las notificaciones están funcionando.',
                                            );
                                            if (mounted) {
                                              _showMessage(
                                                shown
                                                    ? 'Notificación de prueba enviada.'
                                                    : 'El sistema de notificaciones no está disponible en este dispositivo.',
                                              );
                                            }
                                          },
                                          icon: const Icon(
                                            Icons
                                                .notifications_active_rounded,
                                          ),
                                          label: const Text('Probar'),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.of(dialogContext).pop(),
                    child: const Text('Cerrar'),
                  ),
                ],
              );
            },
          ),
        ),
      );
    } finally {
      usernameController.dispose();
    }
  }}
