use api_macros::dto;
use serde::{Deserialize, Serialize};
use subsonic_client::dt::{AlbumSong, Artist, ArtistAlbums, SearchInfo};

#[derive(Deserialize)]
pub struct IdQuery {
    pub id: String,
}

#[derive(Deserialize)]
pub struct SearchQuery {
    pub q: String,
}

#[derive(Serialize)]
pub struct ExSearchContent {
    pub id: String,
    pub title: String,
    pub uploader: String,
    pub thumbnail: String,
    pub url: String,
}

#[allow(dead_code)]
#[dto]
pub struct PingDTO {
    pub status: String,
    pub version: String,
}

impl PingDTO {
    pub fn ok() -> Self {
        Self { status: "ok".to_string(), version: "1.16.1".to_string() }
    }
}

#[allow(dead_code)]
#[dto]
pub struct ArtistDTO {
    pub id: String,
    pub name: String,
    pub album_count: u32,
    pub cover_art: Option<String>,
}

#[allow(dead_code)]
#[dto]
pub struct AlbumDTO {
    pub id: String,
    pub name: String,
    pub song_count: u32,
    pub duration: u32,
    pub cover_art: Option<String>,
}

#[allow(dead_code)]
#[dto]
pub struct SongDTO {
    pub id: String,
    pub title: String,
    pub artist: String,
    pub duration: u32,
    pub cover_art: Option<String>,
}

#[allow(dead_code)]
#[dto]
pub struct SearchDTO {
    pub artists: Option<Vec<ArtistDTO>>,
    pub albums: Option<Vec<AlbumDTO>>,
    pub songs: Option<Vec<SongDTO>>,
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

impl From<AlbumSong> for SongDTO {
    fn from(a: AlbumSong) -> Self {
        SongDTO {
            id: a.id, artist: a.artist, title: a.title,
            duration: a.duration, cover_art: a.cover_art,
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
