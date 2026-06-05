import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../map/data/models/foto_model.dart';

class PhotoViewerScreen extends StatefulWidget {
  final List<FotoModel> fotos;
  final int initialIndex;
  final String entryTitle;

  const PhotoViewerScreen({
    super.key,
    required this.fotos,
    required this.initialIndex,
    required this.entryTitle,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _showUI = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleUI() => setState(() => _showUI = !_showUI);

  @override
  Widget build(BuildContext context) {
    final foto = widget.fotos[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _showUI
          ? AppBar(
              backgroundColor: Colors.black.withValues(alpha: 0.6),
              foregroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                '${_currentIndex + 1} de ${widget.fotos.length}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => Share.share(
                    '${widget.entryTitle}\n${foto.url}',
                    subject: widget.entryTitle,
                  ),
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: _toggleUI,
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.fotos.length,
          onPageChanged: (i) => setState(() => _currentIndex = i),
          itemBuilder: (_, i) {
            final f = widget.fotos[i];
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Hero(
                tag: 'photo_hero_${f.id}',
                child: Center(
                  child: Image.network(
                    f.url,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white54),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_outlined,
                            size: 64, color: Colors.white38),
                        SizedBox(height: 12),
                        Text('No se pudo cargar la foto',
                            style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      // Indicador de página en la parte inferior
      bottomNavigationBar: _showUI && widget.fotos.length > 1
          ? Container(
              color: Colors.black.withValues(alpha: 0.6),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.fotos.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _currentIndex ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _currentIndex
                          ? Colors.white
                          : Colors.white38,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
