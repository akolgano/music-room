import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_room/models/track.dart';
import 'package:music_room/providers/music_service_provider.dart';
import 'package:music_room/widgets/track_item.dart';

class MusicTrackVoteScreen extends StatefulWidget {
  const MusicTrackVoteScreen({Key? key}) : super(key: key);

  @override
  _MusicTrackVoteScreenState createState() => _MusicTrackVoteScreenState();
}

class _MusicTrackVoteScreenState extends State<MusicTrackVoteScreen> {
  String _eventId = '';
  final List<Track> _tracks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
  }

  Future<void> _voteForTrack(String trackId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<MusicServiceProvider>(context, listen: false);
      await provider.voteForTrack(_eventId, trackId);
      
      setState(() {
        final track = _tracks.firstWhere((t) => t.id == trackId);
        track.votes += 1;
        
        _tracks.sort((a, b) => b.votes.compareTo(a.votes));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to vote: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showCreateEventDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isPublic = true;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Vote Event'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Event Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Public Event'),
                subtitle: const Text('Anyone can join and vote'),
                value: isPublic,
                onChanged: (value) {
                  setState(() {
                    isPublic = value;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              
              setState(() {
                _isLoading = true;
              });
              
              try {
                final provider = Provider.of<MusicServiceProvider>(context, listen: false);
                await provider.createVoteEvent(
                  name: nameController.text,
                  description: descriptionController.text,
                  isPublic: isPublic,
                );
                
                await _loadEvents();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to create event: ${e.toString()}')),
                );
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Track Vote'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tracks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No tracks to vote on yet',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _showCreateEventDialog,
                        child: const Text('Create Vote Event'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _tracks.length,
                  itemBuilder: (ctx, index) {
                    final track = _tracks[index];
                    return TrackItem(
                      track: track,
                      onVote: () => _voteForTrack(track.id),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateEventDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
