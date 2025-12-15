import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
  bool _isSeeking = false;
  double _dragValue = 0.0;
  
  // Timer to hide controls
  VoidCallback? _hideControlsDelayed;

  @override
  void initState() {
    super.initState();
    player.open(Media(widget.url), play: true);
    _startHideControlsTimer();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
  
  void _startHideControlsTimer() {
    _hideControlsDelayed?.call(); // Cancel previous if any (dummy logic)
    _hideControlsDelayed = () {
      if (mounted && !_isSeeking) {
        setState(() => _isControlsVisible = false);
      }
    };
    Future.delayed(const Duration(seconds: 4), _hideControlsDelayed!);
  }

  void _toggleControls() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
      if (_isControlsVisible) {
        _startHideControlsTimer();
      }
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Video Display
          GestureDetector(
            onTap: _toggleControls,
            child: SizedBox.expand(
              child: Video(
                controller: controller,
                controls: NoVideoControls,
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
                    colors: [Colors.black87, Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
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
          ),
        ],
      ),
    );
  }

  Widget _buildTopControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.arrowRight, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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

  Widget _buildBottomControls() {
    return Column(
      children: [
        // Custom Progress Bar using Slider
        StreamBuilder<Duration>(
          stream: player.stream.position,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;
            final duration = player.state.duration;
            final max = duration.inMilliseconds.toDouble();
            final value = _isSeeking ? _dragValue : position.inMilliseconds.toDouble().clamp(0.0, max);

            return Row(
              children: [
                const SizedBox(width: 16),
                Text(_formatDuration(Duration(milliseconds: value.toInt())), style: const TextStyle(color: Colors.white, fontSize: 12)),
                Expanded(
                  child: Slider(
                    min: 0.0,
                    max: max > 0 ? max : 1.0,
                    value: value,
                    activeColor: const Color(0xFF7158e2),
                    inactiveColor: Colors.white24,
                    onChangeStart: (_) {
                      setState(() => _isSeeking = true);
                    },
                    onChanged: (v) {
                      setState(() => _dragValue = v);
                    },
                    onChangeEnd: (v) {
                      player.seek(Duration(milliseconds: v.toInt()));
                      setState(() => _isSeeking = false);
                      _startHideControlsTimer();
                    },
                  ),
                ),
                Text(_formatDuration(duration), style: const TextStyle(color: Colors.white, fontSize: 12)),
                const SizedBox(width: 16),
              ],
            );
          },
        ),
        
        // Buttons
        Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSeekButton(false),
              const SizedBox(width: 24),
              _buildPlayPauseButton(),
              const SizedBox(width: 24),
              _buildSeekButton(true),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPlayPauseButton() {
    return StreamBuilder<bool>(
      stream: player.stream.playing,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        return FloatingActionButton(
          backgroundColor: const Color(0xFF7158e2),
          onPressed: player.playOrPause,
          child: FaIcon(
            isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play,
            color: Colors.white,
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
        size: 28,
      ),
      onPressed: () {
        final position = player.state.position.inMilliseconds;
        final target = forward ? position + 10000 : position - 10000;
        player.seek(Duration(milliseconds: target));
        _startHideControlsTimer();
      },
    );
  }
  
  Widget _buildSettingsButton(Track? currentTrack) {
    return PopupMenuButton<String>(
      icon: const FaIcon(FontAwesomeIcons.cog, color: Colors.white),
      color: const Color(0xFF1a0b2e),
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
        // Subtitles
        if (currentTrack?.subtitle.isNotEmpty ?? false) {
          items.add(const PopupMenuItem(enabled: false, child: Text('الترجمة', style: TextStyle(color: Colors.grey))));
          for (var i = 0; i < currentTrack!.subtitle.length; i++) {
            items.add(PopupMenuItem(
              value: 'subtitle_$i',
              child: Text(currentTrack.subtitle[i].title ?? 'Track ${i+1}', style: const TextStyle(color: Colors.white)),
            ));
          }
        }
        // Audio
        if (currentTrack?.audio.isNotEmpty ?? false) {
          items.add(const PopupMenuItem(enabled: false, child: Text('الصوت', style: TextStyle(color: Colors.grey))));
          for (var i = 0; i < currentTrack!.audio.length; i++) {
            items.add(PopupMenuItem(
              value: 'audio_$i',
              child: Text(currentTrack.audio[i].title ?? 'Audio ${i+1}', style: const TextStyle(color: Colors.white)),
            ));
          }
        }
        if (items.isEmpty) {
          items.add(const PopupMenuItem(enabled: false, child: Text('لا توجد إعدادات', style: TextStyle(color: Colors.white))));
        }
        return items;
      },
    );
  }
}
