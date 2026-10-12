# Online Music Player

Flutter music player with a Spotify-inspired library and a soft butter/green theme.

## Features

- Sign in with a local username.
- Search songs and switch between the full library and the user's liked songs.
- Stream MP3 audio from a URL with play/pause, next/previous, seeking, and track progress.
- Add, edit, and delete songs. Song metadata and liked-user lists are stored locally with Hive.
- Includes three SoundHelix sample streams on a fresh install. An internet connection is required to stream audio and load cover art.

## Run

```sh
flutter pub get
flutter run
```

To add a song, enter its title, artist, cover image URL, and a direct HTTP(S) audio URL from the **+** button on the library screen.

Sign-in is a local username flow for this demo; it does not use a password or a remote authentication backend.
