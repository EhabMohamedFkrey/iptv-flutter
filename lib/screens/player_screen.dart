import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Advanced Player Screen using media_kit for MKV, H265, Subtitles, and Audio Tracks support
class PlayerScreen extends StatefulWidget {
  final String url;
  final String title;

  const PlayerScreen({super.key, required this.url, required this.title});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player player = Player();
  late final VideoController controller = VideoController(player);

  bool _isControlsVisible = true;
  
  // Timer to hide controls
  VoidCallback? _hideControlsDelayed;

  @override
  void initState() {
    super.initState();
    // Open and start playback
    player.open(Media(widget.url), play: true);
    
    // Initial hide timeout
    _startHideControlsTimer();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
  
  void _startHideControlsTimer() {
    if (_hideControlsDelayed != null) {
      // Clear previous timeout if exists (not easily done in Flutter, but we override the callback)
    }
    _hideControlsDelayed = () {
      if (mounted) {
        setState(() => _isControlsVisible = false);
      }
    };
    Future.delayed(const Duration(seconds: 3), _hideControlsDelayed!);
  }

  void _toggleControls() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
      if (_isControlsVisible) {
        _startHideControlsTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Video Display Area
          GestureDetector(
            onTap: _toggleControls,
            child: SizedBox.expand(
              child: Video(
                controller: controller,
                controls: NoVideoControls, // Use custom controls
                fit: BoxFit.contain,
              ),
            ),
          ),
          
          // 2. Custom Controls Overlay
          AnimatedOpacity(
            opacity: _isControlsVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !_isControlsVisible,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black54, Colors.transparent, Colors.black54],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    _buildTopControls(),
                    const Spacer(),
                    _buildBottomControls(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Top bar with title and back button
  Widget _buildTopControls() {
    return Padding(
      padding: const EdgeInsets.only(top: 32.0, left: 16.0, right: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.arrowRight, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Settings button (Audio/Subtitle tracks)
          StreamBuilder<PlayerState>(
            stream: player.stream.state,
            builder: (context, snapshot) {
              return _buildSettingsButton(snapshot.data?.track);
            },
          ),
        ],
      ),
    );
  }

  // Bottom bar with progress and media controls
  Widget _buildBottomControls() {
    return Column(
      children: [
        // Progress bar (using media_kit built-in progress bar)
        VideoProgressBar(player: player),
        
        // Play/Pause and Seek buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSeekButton(false), // Backward 10s
              const SizedBox(width: 20),
              _buildPlayPauseButton(),
              const SizedBox(width: 20),
              _buildSeekButton(true), // Forward 10s
            ],
          ),
        ),
        const SizedBox(height: 32.0),
      ],
    );
  }
  
  Widget _buildPlayPauseButton() {
    return StreamBuilder<PlayerState>(
      stream: player.stream.state,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data?.playing ?? false;
        return FloatingActionButton(
          backgroundColor: const Color(0xFF7158e2),
          onPressed: player.playOrPause,
          child: FaIcon(
            isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play,
            color: Colors.white,
            size: 20,
          ),
        );
      },
    );
  }
  
  Widget _buildSeekButton(bool forward) {
    return IconButton(
      icon: FaIcon(
        forward ? FontAwesomeIcons.forwardStep : FontAwesomeIcons.backwardStep,
        color: Colors.white,
        size: 30,
      ),
      onPressed: () {
        final position = player.state.position.inMilliseconds;
        final target = forward ? position + 10000 : position - 10000;
        player.seek(Duration(milliseconds: target));
        _toggleControls();
      },
    );
  }
  
  Widget _buildSettingsButton(Track? currentTrack) {
    return PopupMenuButton<String>(
      icon: const FaIcon(FontAwesomeIcons.cog, color: Colors.white),
      onSelected: (value) {
        if (value.startsWith('audio_')) {
          final index = int.parse(value.substring(6));
          player.setAudioTrack(player.state.track.audio[index]);
        } else if (value.startsWith('subtitle_')) {
          final index = int.parse(value.substring(9));
          player.setSubtitleTrack(player.state.track.subtitle[index]);
        }
      },
      itemBuilder: (context) {
        List<PopupMenuEntry<String>> items = [];

        // 1. Subtitle Tracks
        if (currentTrack?.subtitle.isNotEmpty ?? false) {
          items.add(const PopupMenuItem<String>(
            enabled: false,
            child: Text('الترجمات (Subtitles)', style: TextStyle(fontWeight: FontWeight.bold)),
          ));
          for (var i = 0; i < currentTrack!.subtitle.length; i++) {
            final track = currentTrack.subtitle[i];
            items.add(PopupMenuItem<String>(
              value: 'subtitle_$i',
              child: Text(track.title ?? (i == 0 ? 'Disabled' : 'Subtitle Track ${i + 1}')),
            ));
          }
        }

        // 2. Audio Tracks
        if (currentTrack?.audio.isNotEmpty ?? false) {
          items.add(const PopupMenuItem<String>(
            enabled: false,
            child: Text('مسارات الصوت (Audio)', style: TextStyle(fontWeight: FontWeight.bold)),
          ));
          for (var i = 0; i < currentTrack!.audio.length; i++) {
            final track = currentTrack.audio[i];
            items.add(PopupMenuItem<String>(
              value: 'audio_$i',
              child: Text(track.title ?? 'Audio Track ${i + 1}'),
            ));
          }
        }

        if (items.isEmpty) {
          items.add(const PopupMenuItem<String>(
            enabled: false,
            child: Text('No Extra Settings'),
          ));
        }

        return items;
      },
    );
  }
}
