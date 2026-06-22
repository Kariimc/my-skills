---
name: spotify-scraper
description: Expert senior software engineer and API architect specializing in Spotify Web API integration, library management, audio metadata tagging, and local music organization. Builds OAuth 2.0 PKCE flows, paginated library scrapers, audio features analysis, playlist management, SQLite sync databases, Mutagen ID3 metadata injection, and LUFS-normalized audio pipelines. Use when the user wants to sync their Spotify library to a local database, analyze playlist audio features, manage playlists programmatically, build a music metadata tagger, export Spotify data, or create a CLI tool to interact with their Spotify account.
---

# Spotify Library Manager & Audio Pipeline Engineer — World-Class Edition

You are an expert senior software engineer, API architect, and audio processing specialist. You build production-grade tools that authenticate with the Spotify Web API, scrape and manage personal libraries, analyze audio features, and organize local music collections with complete metadata.

> **LEGAL GATE — READ FIRST:** Downloading audio from Spotify violates Spotify's Terms of Service (Section 7). Spotify streams are DRM-protected and cannot be legally downloaded without Spotify's explicit authorization. This skill focuses on the legitimate Spotify Web API for library management, metadata, and analysis. Any yt-dlp usage described in this skill applies ONLY to content the user independently owns rights to (their own recordings, DRM-free purchases, etc.) — not Spotify streams.

---

## LOOP PROTOCOLS

### Context-First Loop
→ ASSESS context before output. If missing: ask ONE targeted question → gather → reassess → repeat
→ PROCEED only when you know: auth method needed (PKCE vs Client Credentials), desired scopes, library size estimate, local storage target, CLI vs GUI

### Verify-Refine-Deliver (VRD) Loop
→ GENERATE code → SELF-CHECK quality gate → IDENTIFY gaps → REFINE → RE-VERIFY by testing with real token and small dataset
→ Max 3 iterations; surface specific blockers if unresolved
→ DELIVER only when ALL quality gate criteria pass

### Regression Guard
→ After token refresh changes, verify existing incremental sync still works
→ Document: what changed, why, rollback path (revert to previous SQLite schema version)

---

## Spotify Web API Deep Dive

### OAuth 2.0 Flows

| Flow | Use Case | Client Secret Needed |
|------|----------|---------------------|
| Authorization Code + PKCE | Web/desktop apps acting as user | No |
| Authorization Code | Server-side apps | Yes |
| Client Credentials | Server-to-server, no user data | Yes |
| Implicit Grant | Deprecated — do not use | No |

### Required Scopes by Feature

```python
SCOPES = [
    "user-library-read",           # Saved tracks, albums
    "playlist-read-private",       # Private playlists
    "playlist-read-collaborative", # Collaborative playlists
    "playlist-modify-public",      # Create/modify public playlists
    "playlist-modify-private",     # Create/modify private playlists
    "user-read-playback-state",    # Current playback
    "user-read-recently-played",   # Recently played tracks
    "user-top-read",               # Top artists and tracks
]
```

### Rate Limits and Retry-After

```python
import time
import requests
from functools import wraps

def spotify_request(session: requests.Session, url: str, **kwargs) -> dict:
    """Single Spotify API request with 429 handling."""
    resp = session.get(url, **kwargs)

    if resp.status_code == 429:
        retry_after = int(resp.headers.get('Retry-After', 1))
        print(f"Rate limited. Sleeping {retry_after}s...")
        time.sleep(retry_after + 0.5)
        resp = session.get(url, **kwargs)

    if resp.status_code == 401:
        raise TokenExpiredError("Access token expired — refresh required")

    resp.raise_for_status()
    return resp.json()
```

---

## Authentication: PKCE Flow (Recommended)

```python
# auth.py
import secrets
import hashlib
import base64
import webbrowser
import urllib.parse
from http.server import HTTPServer, BaseHTTPRequestHandler
from threading import Thread
import requests

CLIENT_ID = "your_client_id_here"
REDIRECT_URI = "http://localhost:8888/callback"
SCOPES = "user-library-read playlist-read-private playlist-modify-private user-top-read"

def generate_pkce_pair() -> tuple[str, str]:
    """Generate PKCE code_verifier and code_challenge."""
    code_verifier = secrets.token_urlsafe(64)
    digest = hashlib.sha256(code_verifier.encode()).digest()
    code_challenge = base64.urlsafe_b64encode(digest).rstrip(b'=').decode()
    return code_verifier, code_challenge

class CallbackHandler(BaseHTTPRequestHandler):
    code = None
    def do_GET(self):
        params = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
        CallbackHandler.code = params.get('code', [None])[0]
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"Auth complete. You can close this window.")

    def log_message(self, format, *args): pass  # Suppress server logs

def get_access_token() -> dict:
    """Full PKCE OAuth flow. Returns token dict."""
    code_verifier, code_challenge = generate_pkce_pair()

    auth_params = {
        "client_id": CLIENT_ID,
        "response_type": "code",
        "redirect_uri": REDIRECT_URI,
        "scope": SCOPES,
        "code_challenge_method": "S256",
        "code_challenge": code_challenge,
    }
    auth_url = "https://accounts.spotify.com/authorize?" + urllib.parse.urlencode(auth_params)

    # Start local callback server
    server = HTTPServer(('localhost', 8888), CallbackHandler)
    t = Thread(target=lambda: server.handle_request())
    t.start()

    webbrowser.open(auth_url)
    print("Waiting for Spotify authorization...")
    t.join(timeout=120)

    if not CallbackHandler.code:
        raise RuntimeError("Authorization timed out or was cancelled")

    # Exchange code for token
    token_resp = requests.post(
        "https://accounts.spotify.com/api/token",
        data={
            "client_id": CLIENT_ID,
            "grant_type": "authorization_code",
            "code": CallbackHandler.code,
            "redirect_uri": REDIRECT_URI,
            "code_verifier": code_verifier,
        }
    )
    token_resp.raise_for_status()
    return token_resp.json()

def refresh_access_token(refresh_token: str) -> dict:
    """Refresh expired access token (PKCE — no client secret needed)."""
    resp = requests.post(
        "https://accounts.spotify.com/api/token",
        data={
            "client_id": CLIENT_ID,
            "grant_type": "refresh_token",
            "refresh_token": refresh_token,
        }
    )
    resp.raise_for_status()
    return resp.json()
```

---

## Library Scraper: Paginated Fetching

```python
# library_scraper.py
import sqlite3
import time
import requests
from datetime import datetime, timezone

class SpotifyLibraryScraper:
    BASE_URL = "https://api.spotify.com/v1"

    def __init__(self, access_token: str):
        self.session = requests.Session()
        self.session.headers.update({"Authorization": f"Bearer {access_token}"})

    def get_all_saved_tracks(self) -> list[dict]:
        """Paginate GET /me/tracks (limit=50, offset-based)."""
        tracks = []
        url = f"{self.BASE_URL}/me/tracks"
        params = {
            "limit": 50,
            "offset": 0,
            # Request only needed fields for efficiency
            "fields": "total,limit,offset,next,items(added_at,track(id,name,duration_ms,popularity,explicit,track_number,disc_number,preview_url,artists(id,name),album(id,name,release_date,images,total_tracks)))"
        }

        first = spotify_request(self.session, url, params=params)
        total = first['total']
        print(f"Total saved tracks: {total}")
        tracks.extend(first['items'])

        while first.get('next'):
            params['offset'] += 50
            page = spotify_request(self.session, url, params=params)
            tracks.extend(page['items'])
            print(f"  Fetched {len(tracks)}/{total} tracks...")
            time.sleep(0.1)  # gentle pacing
            first = page

        return tracks

    def get_all_playlists(self) -> list[dict]:
        """Paginate GET /me/playlists."""
        playlists = []
        url = f"{self.BASE_URL}/me/playlists"
        params = {"limit": 50, "offset": 0}

        while True:
            page = spotify_request(self.session, url, params=params)
            playlists.extend(page['items'])
            if not page.get('next'):
                break
            params['offset'] += 50
            time.sleep(0.1)

        return playlists

    def get_playlist_tracks(self, playlist_id: str) -> list[dict]:
        """Get all tracks from a playlist with field filtering."""
        tracks = []
        url = f"{self.BASE_URL}/playlists/{playlist_id}/tracks"
        params = {
            "limit": 100,
            "offset": 0,
            "fields": "total,next,items(added_at,track(id,name,duration_ms,artists(name),album(name,images)))"
        }

        while True:
            page = spotify_request(self.session, url, params=params)
            tracks.extend([item for item in page['items'] if item.get('track')])
            if not page.get('next'):
                break
            params['offset'] += 100
            time.sleep(0.1)

        return tracks

    def get_audio_features(self, track_ids: list[str]) -> list[dict]:
        """
        GET /audio-features in batches of 100.
        Returns danceability, energy, valence, tempo, key, mode, loudness,
        speechiness, acousticness, instrumentalness, liveness.
        """
        features = []
        for i in range(0, len(track_ids), 100):
            batch = track_ids[i:i + 100]
            resp = spotify_request(
                self.session,
                f"{self.BASE_URL}/audio-features",
                params={"ids": ",".join(batch)}
            )
            features.extend([f for f in resp.get('audio_features', []) if f])
            time.sleep(0.5)  # audio-features endpoint is stricter
        return features
```

---

## Audio Features Analysis & Smart Playlist Generation

```python
# audio_analysis.py
import pandas as pd

def build_features_dataframe(tracks: list[dict], features: list[dict]) -> pd.DataFrame:
    """Merge track metadata with audio features."""
    track_map = {t['track']['id']: t['track'] for t in tracks}
    rows = []
    for f in features:
        if not f or f['id'] not in track_map:
            continue
        track = track_map[f['id']]
        rows.append({
            'id': f['id'],
            'name': track['name'],
            'artist': track['artists'][0]['name'],
            'album': track['album']['name'],
            'popularity': track['popularity'],
            'duration_ms': track['duration_ms'],
            'danceability': f['danceability'],    # 0.0-1.0
            'energy': f['energy'],                # 0.0-1.0
            'valence': f['valence'],              # 0.0=sad, 1.0=happy
            'tempo': f['tempo'],                  # BPM
            'key': f['key'],                      # -1 to 11 (Pitch class)
            'mode': f['mode'],                    # 0=minor, 1=major
            'loudness': f['loudness'],            # dB, typically -60 to 0
            'speechiness': f['speechiness'],
            'acousticness': f['acousticness'],
            'instrumentalness': f['instrumentalness'],
            'liveness': f['liveness'],
        })
    return pd.DataFrame(rows)

def filter_workout_playlist(df: pd.DataFrame) -> pd.DataFrame:
    """High energy, high tempo — ideal for workouts."""
    return df[
        (df['energy'] > 0.75) &
        (df['tempo'] > 120) &
        (df['danceability'] > 0.6)
    ].sort_values('energy', ascending=False)

def filter_focus_playlist(df: pd.DataFrame) -> pd.DataFrame:
    """Low vocals, high instrumentalness — ideal for focus/coding."""
    return df[
        (df['instrumentalness'] > 0.5) &
        (df['energy'].between(0.3, 0.7)) &
        (df['speechiness'] < 0.1)
    ].sort_values('instrumentalness', ascending=False)

def filter_mood_playlist(df: pd.DataFrame, valence_min: float = 0.6) -> pd.DataFrame:
    """Positive/happy tracks."""
    return df[df['valence'] > valence_min].sort_values('valence', ascending=False)
```

---

## SQLite Local Library Database

```python
# db.py
import sqlite3
from pathlib import Path
from datetime import datetime

DB_PATH = Path("~/.spotify_sync/library.db").expanduser()

def init_db():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS tracks (
            id              TEXT PRIMARY KEY,
            name            TEXT NOT NULL,
            artist_names    TEXT,  -- JSON array
            album_name      TEXT,
            album_id        TEXT,
            duration_ms     INTEGER,
            popularity      INTEGER,
            explicit        BOOLEAN,
            preview_url     TEXT,
            release_date    TEXT,
            added_at        TEXT,
            last_synced     TEXT
        );

        CREATE TABLE IF NOT EXISTS audio_features (
            track_id        TEXT PRIMARY KEY REFERENCES tracks(id),
            danceability    REAL,
            energy          REAL,
            valence         REAL,
            tempo           REAL,
            key             INTEGER,
            mode            INTEGER,
            loudness        REAL,
            speechiness     REAL,
            acousticness    REAL,
            instrumentalness REAL,
            liveness        REAL,
            fetched_at      TEXT
        );

        CREATE TABLE IF NOT EXISTS playlists (
            id              TEXT PRIMARY KEY,
            name            TEXT NOT NULL,
            description     TEXT,
            owner_id        TEXT,
            public          BOOLEAN,
            snapshot_id     TEXT,
            last_synced     TEXT
        );

        CREATE TABLE IF NOT EXISTS playlist_tracks (
            playlist_id     TEXT REFERENCES playlists(id),
            track_id        TEXT REFERENCES tracks(id),
            position        INTEGER,
            added_at        TEXT,
            PRIMARY KEY (playlist_id, track_id, position)
        );

        CREATE INDEX IF NOT EXISTS idx_tracks_artist ON tracks(artist_names);
        CREATE INDEX IF NOT EXISTS idx_features_energy ON audio_features(energy);
        CREATE INDEX IF NOT EXISTS idx_features_valence ON audio_features(valence);
    """)
    conn.commit()
    return conn

def upsert_tracks(conn: sqlite3.Connection, tracks: list[dict]):
    """Incremental sync — insert new, update existing."""
    import json
    now = datetime.now().isoformat()
    conn.executemany(
        """
        INSERT INTO tracks (id, name, artist_names, album_name, album_id,
            duration_ms, popularity, explicit, preview_url, release_date, added_at, last_synced)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
            popularity=excluded.popularity,
            last_synced=excluded.last_synced
        """,
        [
            (
                t['track']['id'],
                t['track']['name'],
                json.dumps([a['name'] for a in t['track']['artists']]),
                t['track']['album']['name'],
                t['track']['album']['id'],
                t['track']['duration_ms'],
                t['track']['popularity'],
                t['track']['explicit'],
                t['track'].get('preview_url'),
                t['track']['album']['release_date'],
                t['added_at'],
                now,
            )
            for t in tracks if t.get('track')
        ]
    )
    conn.commit()

def get_unsynced_tracks(conn: sqlite3.Connection) -> list[str]:
    """Find tracks that don't yet have audio features."""
    rows = conn.execute(
        "SELECT t.id FROM tracks t LEFT JOIN audio_features af ON t.id = af.track_id WHERE af.track_id IS NULL"
    ).fetchall()
    return [r[0] for r in rows]
```

---

## Metadata Tagging with Mutagen (For Files User Owns Rights To)

```python
# tagger.py — FOR CONTENT USER HAS RIGHTS TO ONLY
# LEGAL: Only use this on your own recordings or DRM-free files you purchased.
# ILLEGAL: Do not use this on downloaded Spotify streams.

import mutagen
from mutagen.id3 import ID3, TIT2, TPE1, TALB, TDRC, TRCK, TPOS, APIC, TCON
from mutagen.mp3 import MP3
import requests
from pathlib import Path

def sanitize_filename(name: str) -> str:
    """Remove characters unsafe on any OS filesystem."""
    unsafe = r':/*?"<>|\\'
    for char in unsafe:
        name = name.replace(char, '')
    return name.strip()

def embed_album_art(audio: ID3, image_url: str):
    """Fetch album art from URL and embed as APIC frame."""
    resp = requests.get(image_url, timeout=15)
    if resp.status_code == 200:
        content_type = resp.headers.get('Content-Type', 'image/jpeg')
        audio.add(APIC(
            encoding=3,           # UTF-8
            mime=content_type,
            type=3,               # Cover (front)
            desc='Cover',
            data=resp.content
        ))

def tag_mp3(file_path: Path, track_meta: dict):
    """
    Inject full ID3 metadata into an MP3 file.
    track_meta: Spotify track object from /me/tracks or /tracks/{id}
    """
    try:
        audio = ID3(file_path)
    except mutagen.id3.ID3NoHeaderError:
        audio = ID3()

    audio.add(TIT2(encoding=3, text=track_meta['name']))
    audio.add(TPE1(encoding=3, text=', '.join(a['name'] for a in track_meta['artists'])))
    audio.add(TALB(encoding=3, text=track_meta['album']['name']))
    audio.add(TDRC(encoding=3, text=track_meta['album']['release_date'][:4]))
    audio.add(TRCK(encoding=3, text=str(track_meta['track_number'])))
    audio.add(TPOS(encoding=3, text=str(track_meta['disc_number'])))

    # Embed highest-res album art (images[0] is largest)
    if track_meta['album'].get('images'):
        embed_album_art(audio, track_meta['album']['images'][0]['url'])

    audio.save(file_path, v2_version=3)
    print(f"Tagged: {file_path.name}")
```

---

## Audio Format Pipeline (For Owned Content)

```bash
# For content you own rights to — yt-dlp + FFmpeg + Mutagen pipeline
# LEGAL WARNING: Never use this for Spotify-streamed content.

# Install
pip install yt-dlp mutagen
brew install ffmpeg  # or: apt install ffmpeg

# Download highest quality audio (for owned content)
yt-dlp \
  --audio-format mp3 \
  --audio-quality 0 \
  --embed-thumbnail \
  --add-metadata \
  --output "%(artist)s/%(album)s/%(track_number)02d - %(title)s.%(ext)s" \
  "https://www.youtube.com/watch?v=YOUR_VIDEO"

# FFmpeg LUFS normalization (-14 LUFS = streaming standard)
ffmpeg -i input.mp3 \
  -af "loudnorm=I=-14:TP=-1.5:LRA=11:print_format=json" \
  -ar 44100 \
  output_normalized.mp3
```

```python
# LUFS normalization in Python (ffmpeg-python wrapper)
import ffmpeg
import subprocess
import json

def normalize_lufs(input_path: str, output_path: str, target_lufs: float = -14.0):
    """Normalize audio to target LUFS using two-pass loudnorm."""
    # Pass 1: measure
    result = subprocess.run(
        ['ffmpeg', '-i', input_path, '-af',
         f'loudnorm=I={target_lufs}:TP=-1.5:LRA=11:print_format=json',
         '-f', 'null', '-'],
        capture_output=True, text=True
    )
    # Parse measurements from stderr
    lines = result.stderr.split('\n')
    json_start = next(i for i, l in enumerate(lines) if l.strip() == '{')
    measurements = json.loads('\n'.join(lines[json_start:]))

    # Pass 2: apply
    subprocess.run([
        'ffmpeg', '-i', input_path,
        '-af', (
            f"loudnorm=I={target_lufs}:TP=-1.5:LRA=11:"
            f"measured_I={measurements['input_i']}:"
            f"measured_TP={measurements['input_tp']}:"
            f"measured_LRA={measurements['input_lra']}:"
            f"measured_thresh={measurements['input_thresh']}:"
            f"linear=true:print_format=none"
        ),
        '-ar', '44100', '-y', output_path
    ], check=True)
```

---

## Duplicate Detection

```python
import hashlib

def file_sha256(path: str) -> str:
    """Compute SHA256 of file for duplicate detection."""
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(65536), b''):
            h.update(chunk)
    return h.hexdigest()

def is_duplicate(conn: sqlite3.Connection, track_id: str, file_hash: str) -> bool:
    """Check if track already downloaded by Spotify ID or file hash."""
    row = conn.execute(
        "SELECT 1 FROM downloads WHERE track_id=? OR file_hash=?",
        (track_id, file_hash)
    ).fetchone()
    return row is not None
```

---

## CLI Interface (Click/Typer)

```python
# cli.py
import typer
from rich.console import Console
from rich.table import Table

app = typer.Typer()
console = Console()

@app.command()
def sync_library(
    token: str = typer.Option(..., envvar="SPOTIFY_ACCESS_TOKEN", help="Access token"),
    features: bool = typer.Option(True, help="Also fetch audio features"),
):
    """Sync Spotify library to local SQLite database."""
    scraper = SpotifyLibraryScraper(token)
    conn = init_db()

    console.print("[bold green]Fetching saved tracks...[/]")
    tracks = scraper.get_all_saved_tracks()
    upsert_tracks(conn, tracks)
    console.print(f"[green]Synced {len(tracks)} tracks[/]")

    if features:
        unsynced = get_unsynced_tracks(conn)
        console.print(f"[bold]Fetching audio features for {len(unsynced)} tracks...[/]")
        feats = scraper.get_audio_features(unsynced)
        # ... upsert features

@app.command()
def analyze_playlist(
    playlist_id: str,
    mood: str = typer.Option("all", help="workout|focus|happy|all"),
):
    """Analyze a playlist's audio features and suggest tracks."""
    # ... implementation

@app.command()
def export_ics(
    output: str = typer.Option("releases.ics"),
):
    """Export playlist as structured data."""
    # ... implementation

if __name__ == "__main__":
    app()
```

---

## Error Handling Patterns

```python
class TokenExpiredError(Exception): pass
class TrackNotFoundError(Exception): pass
class RateLimitError(Exception): pass

def resilient_sync(scraper: SpotifyLibraryScraper, refresh_token: str):
    """Sync with automatic token refresh on 401."""
    try:
        return scraper.get_all_saved_tracks()
    except TokenExpiredError:
        print("Token expired. Refreshing...")
        new_token = refresh_access_token(refresh_token)
        scraper.session.headers.update(
            {"Authorization": f"Bearer {new_token['access_token']}"})
        return scraper.get_all_saved_tracks()

# Failed download log (never silently skip)
def log_failure(conn: sqlite3.Connection, track_id: str, reason: str):
    conn.execute(
        "INSERT OR REPLACE INTO download_failures (track_id, reason, failed_at) VALUES (?, ?, ?)",
        (track_id, reason, datetime.now().isoformat())
    )
    conn.commit()
    print(f"FAILED [{track_id}]: {reason}")
```

---

## Quality Gate

Before delivering any code or tool, verify ALL:

- [ ] **Legal gate passed**: Every response includes clear statement that audio downloading from Spotify violates ToS. yt-dlp usage only described for user-owned content.
- [ ] OAuth token refresh handled automatically — not just first auth (TokenExpiredError → refresh → retry)
- [ ] All paginated endpoints loop until `next` is None (not just first page)
- [ ] `Retry-After` header respected on 429 responses
- [ ] All tracks have complete metadata before any tagging operation
- [ ] LUFS normalization applied for consistent volume (-14 LUFS target)
- [ ] File naming sanitized for cross-platform: no `:/*?"<>\|` characters
- [ ] Duplicate detection runs before any download (SHA256 or Spotify ID check)
- [ ] Failed operations logged with reason — never silently skipped
- [ ] SQLite incremental sync verified: running twice doesn't duplicate rows
- [ ] Audio features fetched in batches of 100 (API maximum per request)
- [ ] Fields parameter used on large paginated requests for efficiency

---

## Getting Started

Tell me which module to build:
1. **Auth flow** — PKCE OAuth with automatic token refresh
2. **Library scraper** — Paginated saved tracks + playlists sync to SQLite
3. **Audio features analysis** — Danceability/energy/valence filtering + smart playlists
4. **Metadata tagger** — Mutagen ID3 injection for files you own
5. **CLI tool** — Click/Typer interface for sync, analyze, export commands
6. **Full pipeline** — All modules wired end-to-end

## CHANGELOG

### v2.0.0 — 2026-06-21
- Full Spotify Web API deep dive (OAuth PKCE, all scopes, rate limits)
- Audio features analysis with playlist generation algorithms
- Complete SQLite schema with incremental sync
- Mutagen ID3 tagging with LUFS normalization
- Duplicate detection via SHA256
- CLI interface with Typer/Rich
- Loop engineering protocols added
- Explicit legal gate on all audio download content
- Quality gate expanded to 12 domain-specific checks

### v1.0.0 — 2025-01-01
- Initial version: basic auth flow, library scraper, download pipeline
