import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chingu/core/theme/app_theme.dart';

class GifPicker extends StatelessWidget {
  final Function(String) onGifSelected;

  const GifPicker({
    super.key,
    required this.onGifSelected,
  });

  // Mock data for GIFs - using public Giphy URLs
  static const List<String> _gifUrls = [
    'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExcGZ4bHdybXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/3o7TKSjRrfIPjeiVyM/giphy.gif', // Hello
    'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExbXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/l0HlHFRbmaZtBRhXG/giphy.gif', // Yes
    'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExbXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/3o7TKVIx4C2cT5HhTi/giphy.gif', // No
    'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExbXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/xT5LMHxhOfscxPfIfm/giphy.gif', // Laugh
    'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExbXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/3oKIPnAiaMCws8nOsE/giphy.gif', // Cat
    'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExbXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/l0HlO3BJ8LALPW4sE/giphy.gif', // Dog
    'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExbXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/d2Z8XQ6J9qg9S/giphy.gif', // Bye
    'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExbXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/3o7TKnYVvhjh6qk0VO/giphy.gif', // Sorry
    'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExbXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/l2JdZOv5p5y7y5X4Q/giphy.gif', // Thanks
    'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExbXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/3o7TKs384dZt1t4gFy/giphy.gif', // Party
    'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExbXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/l0HlCqVze6w7K/giphy.gif', // Love
    'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExbXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bXF4bSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/3o7TKMeCOV3oX/giphy.gif', // Cool
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.gif_box_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Select GIF',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: _gifUrls.length,
              itemBuilder: (context, index) {
                final url = _gifUrls[index];
                return GestureDetector(
                  onTap: () => onGifSelected(url),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: theme.colorScheme.surfaceVariant,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: theme.colorScheme.surfaceVariant,
                        child: Icon(Icons.error_outline, color: theme.colorScheme.error),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
