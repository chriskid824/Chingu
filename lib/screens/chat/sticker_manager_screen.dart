import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/sticker_pack_model.dart';
import '../../services/sticker_service.dart';
import '../../widgets/app_icon_button.dart';

class StickerManagerScreen extends StatefulWidget {
  const StickerManagerScreen({Key? key}) : super(key: key);

  @override
  State<StickerManagerScreen> createState() => _StickerManagerScreenState();
}

class _StickerManagerScreenState extends State<StickerManagerScreen> {
  final StickerService _stickerService = StickerService();
  List<StickerPackModel> _stickerPacks = [];
  bool _isLoading = true;
  final Set<String> _processingPacks = {}; // Track packs currently being downloaded/deleted

  @override
  void initState() {
    super.initState();
    _loadPacks();
  }

  Future<void> _loadPacks() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final packs = await _stickerService.getAvailablePacks();
      if (mounted) {
        setState(() {
          _stickerPacks = packs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load sticker packs: $e')),
        );
      }
    }
  }

  Future<void> _downloadPack(StickerPackModel pack) async {
    setState(() {
      _processingPacks.add(pack.id);
    });

    try {
      await _stickerService.downloadPack(pack.id);
      await _loadPacks(); // Reload to update status
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${pack.name} downloaded!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download ${pack.name}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingPacks.remove(pack.id);
        });
      }
    }
  }

  Future<void> _deletePack(StickerPackModel pack) async {
     setState(() {
      _processingPacks.add(pack.id);
    });

    try {
      await _stickerService.deletePack(pack.id);
      await _loadPacks(); // Reload to update status
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${pack.name} removed.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove ${pack.name}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingPacks.remove(pack.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ignore: unused_local_variable
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sticker Manager'),
        leading: const BackButton(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stickerPacks.isEmpty
              ? Center(
                  child: Text(
                    'No sticker packs available.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _stickerPacks.length,
                  itemBuilder: (context, index) {
                    final pack = _stickerPacks[index];
                    final isProcessing = _processingPacks.contains(pack.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                pack.thumbnailUrl,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 64,
                                    height: 64,
                                    color: theme.colorScheme.surfaceVariant,
                                    child: Icon(Icons.broken_image,
                                        color: theme.colorScheme.onSurfaceVariant),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pack.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    pack.author,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                  if (pack.description.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        pack.description,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Action Button
                            if (isProcessing)
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            else if (pack.isDownloaded)
                              AppIconButton(
                                icon: Icon(Icons.delete_outline,
                                    color: theme.colorScheme.error),
                                onPressed: () => _deletePack(pack),
                                tooltip: 'Remove Pack',
                              )
                            else
                              AppIconButton(
                                icon: Icon(Icons.download,
                                    color: theme.colorScheme.primary),
                                onPressed: () => _downloadPack(pack),
                                tooltip: 'Download Pack',
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
