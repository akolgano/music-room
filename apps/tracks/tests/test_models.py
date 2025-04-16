from django.test import TestCase
from apps.tracks.models import Track


class TrackModelTest(TestCase):

    def setUp(self):
        """
        Set up test data for Track model.
        """
        self.track = Track.objects.create(
            name="Track 1",
            artist="Artist 1",
            album="Album 1",
        )

    def test_create_track(self):
        """
        Test that a Track object is created and saved correctly.
        """
        track = Track.objects.get(name="Track 1")
        self.assertEqual(track.name, "Track 1")
        self.assertEqual(track.artist, "Artist 1")
        self.assertEqual(track.album, "Album 1")

    def test_str_method(self):
        """
        Test the string representation of the Track model.
        """
        track = self.track
        self.assertEqual(str(track), "Track 1 by Artist 1")

    def test_track_without_album(self):
        """
        Test that a track can be created without an album name.
        """
        track = Track.objects.create(
            name="Track 2",
            artist="Artist 2",
        )
        self.assertEqual(track.album, None)
