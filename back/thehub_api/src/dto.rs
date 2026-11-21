use api_macros::dto;
use serde::{Deserialize};
use subsonic_client::dt::{Song, Artist, ArtistAlbums, SearchInfo, PlaylistInfo};

#[derive(Deserialize)]
#[dto]
struct IdQuery {
    id: String,
}

#[derive(Deserialize)]
#[dto]
struct SearchQuery {
    q: String,
}

#[derive(Deserialize)]
#[dto]
struct PlaylistPayload {
    name: String,
    song_ids: Option<Vec<String>>,
}

#[dto]
struct ExSearchContent {
    id: String,
    title: String,
    uploader: String,
    thumbnail: String,
    url: String,
}

#[allow(dead_code)]
#[dto]
struct PingDTO {
    status: String,
    version: String,
}

impl PingDTO {
    pub fn ok() -> Self {
        Self { status: "ok".to_string(), version: "1.16.1".to_string() }
    }
}

#[allow(dead_code)]
#[dto]
struct ArtistDTO {
    id: String,
    name: String,
    album_count: u32,
    cover_art: Option<String>,
}

#[allow(dead_code)]
#[dto]
struct AlbumDTO {
    id: String,
    name: String,
    song_count: u32,
    duration: u32,
    cover_art: Option<String>,
}

#[allow(dead_code)]
#[dto]
struct SongDTO {
    id: String,
    title: String,
    artist: String,
    duration: u32,
    cover_art: Option<String>,
}

#[allow(dead_code)]
#[dto]
struct SearchDTO {
    artists: Option<Vec<ArtistDTO>>,
    albums: Option<Vec<AlbumDTO>>,
    songs: Option<Vec<SongDTO>>,
}

#[allow(dead_code)]
#[dto]
struct PlaylistDTO {
    id: String,
    name: String,
    song_count: u32,
    duration: u32,
    comment: Option<String>,
    cover_art : Option<String>
}

impl From<Artist> for ArtistDTO {
    fn from(a: Artist) -> Self {
        ArtistDTO { id: a.id, name: a.name, album_count: a.album_count, cover_art: a.cover_art }
    }
}

impl From<ArtistAlbums> for AlbumDTO {
    fn from(a: ArtistAlbums) -> Self {
        AlbumDTO {
            id: a.id, name: a.name,
            song_count: a.song_count, duration: a.duration,
            cover_art: a.cover_art,
        }
    }
}

impl From<Song> for SongDTO {
    fn from(a: Song) -> Self {
        SongDTO {
            id: a.id, artist: a.artist, title: a.title,
            duration: a.duration, cover_art: a.cover_art,
        }
    }
}

impl From<PlaylistInfo> for PlaylistDTO {
    fn from(p: PlaylistInfo) -> Self {
        PlaylistDTO {
            id: p.id, name: p.name, comment: p.comment, 
            song_count: p.song_count, duration: p.duration, cover_art: p.cover_art
        }
    }
}

impl From<SearchInfo> for SearchDTO {
    fn from(info: SearchInfo) -> Self {
        SearchDTO {
            artists: info.artist.map(|list| list.into_iter().map(ArtistDTO::from).collect()),
            albums: info.album.map(|list| list.into_iter().map(AlbumDTO::from).collect()),
            songs: info.song.map(|list| list.into_iter().map(SongDTO::from).collect()),
        }
    }
}
