import '../models/sticker_pack_model.dart';

class StickerService {
  // Singleton pattern
  static final StickerService _instance = StickerService._internal();
  factory StickerService() => _instance;
  StickerService._internal();

  // Mock data
  final List<StickerPackModel> _allPacks = [
    StickerPackModel(
      id: 'pack_1',
      name: 'Chingu Friends',
      author: 'Chingu Team',
      description: 'The official sticker pack for Chingu.',
      thumbnailUrl: 'https://picsum.photos/id/237/200/200',
      stickerUrls: [
        'https://picsum.photos/id/237/200/200',
        'https://picsum.photos/id/238/200/200',
        'https://picsum.photos/id/239/200/200',
        'https://picsum.photos/id/240/200/200',
        'https://picsum.photos/id/241/200/200',
      ],
      price: 0.0,
    ),
    StickerPackModel(
      id: 'pack_2',
      name: 'Cute Animals',
      author: 'Artist X',
      description: 'Adorable animals for every occasion.',
      thumbnailUrl: 'https://picsum.photos/id/1025/200/200',
      stickerUrls: [
        'https://picsum.photos/id/1025/200/200',
        'https://picsum.photos/id/1074/200/200',
        'https://picsum.photos/id/169/200/200',
        'https://picsum.photos/id/219/200/200',
      ],
      price: 0.99,
    ),
     StickerPackModel(
      id: 'pack_3',
      name: 'Reaction Faces',
      author: 'Meme Lord',
      description: 'Perfect for when words are not enough.',
      thumbnailUrl: 'https://picsum.photos/id/64/200/200',
      stickerUrls: [
        'https://picsum.photos/id/64/200/200',
        'https://picsum.photos/id/65/200/200',
        'https://picsum.photos/id/91/200/200',
        'https://picsum.photos/id/103/200/200',
      ],
      price: 0.0,
    ),
  ];

  // In-memory downloaded packs (mock storage)
  final Set<String> _downloadedPackIds = {};

  Future<List<StickerPackModel>> getAvailablePacks() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Merge with downloaded status
    return _allPacks.map((pack) {
      return pack.copyWith(isDownloaded: _downloadedPackIds.contains(pack.id));
    }).toList();
  }

  Future<void> downloadPack(String packId) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate download
    _downloadedPackIds.add(packId);
  }

  Future<void> deletePack(String packId) async {
     await Future.delayed(const Duration(milliseconds: 300));
    _downloadedPackIds.remove(packId);
  }

  bool isPackDownloaded(String packId) {
    return _downloadedPackIds.contains(packId);
  }
}
