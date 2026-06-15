import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class FeedVideoAd extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const FeedVideoAd({
    Key? key,
    required this.product,
    required this.onDismiss,
    required this.onTap,
  }) : super(key: key);

  // Global static notifier to ensure only one ad plays at a time.
  static final ValueNotifier<String?> activeAdIdNotifier = ValueNotifier<String?>(null);

  @override
  State<FeedVideoAd> createState() => _FeedVideoAdState();
}

class _FeedVideoAdState extends State<FeedVideoAd> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isMuted = true;
  bool _isVisible = false;
  bool _initStarted = false; // ensures the controller is initialized lazily, only once

  @override
  void initState() {
    super.initState();
    // Controller is initialized lazily on first visibility (see _handleVisibilityChanged)
    // to avoid spinning up network video buffers for off-screen ads.
    FeedVideoAd.activeAdIdNotifier.addListener(_onActiveAdChanged);
  }

  void _initController() {
    if (_initStarted) return;
    _initStarted = true;

    final String url = widget.product['videoUrl']?.toString() ?? '';
    final String type = widget.product['videoType']?.toString() ?? 'auto';

    // Bypass YouTube URLs completely.
    if (type == 'youtube' || url.contains('youtube') || url.contains('youtu.be') || url.isEmpty) {
      return;
    }

    try {
      final uri = Uri.parse(url);
      _controller = VideoPlayerController.networkUrl(uri)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
            });
            // Loop is true
            _controller?.setLooping(true);
            // Volume is 0 initially (muted)
            _controller?.setVolume(0.0);
            // If the ad was already visible and is the active ad, play it
            if (_isVisible && FeedVideoAd.activeAdIdNotifier.value == widget.product['id']) {
              _controller?.play();
            }
          }
        }).catchError((e) {
          debugPrint("Video Player Init Error: $e");
        });
    } catch (e) {
      debugPrint("Video Player Parsing Error: $e");
    }
  }

  void _onActiveAdChanged() {
    if (!mounted || _controller == null || !_isInitialized) return;

    if (FeedVideoAd.activeAdIdNotifier.value == widget.product['id']) {
      if (_isVisible) {
        _controller?.play();
      }
    } else {
      _controller?.pause();
    }
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    final isVisibleNow = info.visibleFraction >= 0.6;
    _isVisible = isVisibleNow;

    if (isVisibleNow) {
      // Lazily initialize the controller the first time this ad becomes visible.
      _initController();
      // Set this ad as active, which will trigger _onActiveAdChanged for all ads
      FeedVideoAd.activeAdIdNotifier.value = widget.product['id'];
      if (_isInitialized) {
        _controller?.play();
      }
    } else {
      // If we are scrolling out of view, and we were the active ad, set active to null
      if (FeedVideoAd.activeAdIdNotifier.value == widget.product['id']) {
        FeedVideoAd.activeAdIdNotifier.value = null;
      }
      if (_isInitialized) {
        _controller?.pause();
      }
    }
  }

  void _toggleMute() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller?.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  void dispose() {
    FeedVideoAd.activeAdIdNotifier.removeListener(_onActiveAdChanged);
    // If we were the active ad, clear it
    if (FeedVideoAd.activeAdIdNotifier.value == widget.product['id']) {
      FeedVideoAd.activeAdIdNotifier.value = null;
    }
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String url = widget.product['videoUrl']?.toString() ?? '';
    final String type = widget.product['videoType']?.toString() ?? 'auto';

    if (type == 'youtube' || url.contains('youtube') || url.contains('youtu.be') || url.isEmpty) {
      return const SizedBox.shrink();
    }

    // Poster Image fallback
    final imageUrls = widget.product['imageUrls'] as List<dynamic>? ?? [];
    final String posterUrl = (widget.product['videoThumbnail']?.toString() ?? '').isNotEmpty
        ? widget.product['videoThumbnail'].toString()
        : (imageUrls.isNotEmpty ? imageUrls.first.toString() : (widget.product['imageUrl']?.toString() ?? ''));

    final productPrice = widget.product['price']?.toString() ?? '';
    final productName = widget.product['name']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: VisibilityDetector(
          key: Key('feed-ad-${widget.product['id'] ?? widget.product['name']}'),
          onVisibilityChanged: _handleVisibilityChanged,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AspectRatio(
              aspectRatio: 16 / 9, // premium video aspect ratio
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Video Player or Poster
                  if (_isInitialized && _controller != null)
                    VideoPlayer(_controller!)
                  else
                    const SizedBox.shrink(),

                  // Poster Image display (on top of player if not initialized, or as fallback)
                  if (!_isInitialized && posterUrl.isNotEmpty)
                    Image.network(
                      posterUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF00897B).withOpacity(0.08),
                        child: Center(
                          child: Text(
                            widget.product['emoji'] ?? '🛍️',
                            style: const TextStyle(fontSize: 50),
                          ),
                        ),
                      ),
                    ),

                  // Bottom Gradient Overlay for readability of white text
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: const [0.0, 0.25, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Top Overlay Controls: Dismiss (Skip)
                  Positioned(
                    top: 10,
                    left: 10, // Top-Left close button
                    child: GestureDetector(
                      onTap: widget.onDismiss,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),

                  // Top Right overlay badge for "إعلان"
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E63), // Pink accent color
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'إعلان مميز',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Bottom Controls: Sound toggle & Product details
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Product details and CTA
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                productName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 1),
                                      blurRadius: 3,
                                      color: Colors.black45,
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    productPrice,
                                    style: const TextStyle(
                                      color: Color(0xFF00897B), // Teal accent
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: widget.onTap,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00897B),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'اطلبي الآن',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Mute/Unmute Button
                        GestureDetector(
                          onTap: _toggleMute,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isMuted ? Icons.volume_off : Icons.volume_up,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
