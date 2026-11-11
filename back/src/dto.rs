use api_macros::dto;
use crate::dt::{
    Artist, ArtistAlbums, AlbumSong, SearchInfo,
    Envelope, Empty
};

#[allow(dead_code)]
#[dto]
struct PingDTO {
    status: String, version: String
}

#[allow(dead_code)]
#[dto]
struct ArtistDTO {
    id: String, name: String,
    album_count: u32,
    cover_art:Option<String>
}



#[allow(dead_code)]
#[dto]
struct AlbumDTO {
    id: String,  name: String,
    song_count: u32, duration: u32,
    cover_art: Option<String>,
}

#[allow(dead_code)]
#[dto] 
struct SongDTO {
    id: String, title: String, artist: String,
    duration: u32,
    cover_art: Option<String>,
}

#[allow(dead_code)]
#[dto]
struct SearchDTO {
    artists: Option<Vec<ArtistDTO>>,
    albums: Option<Vec<AlbumDTO>>,
    songs: Option<Vec<SongDTO>>
}


impl From<Envelope<Empty>> for PingDTO {
    fn from(e: Envelope<Empty>) -> Self {
        PingDTO {
            status: e.status,
            version: e.version,
        }
    }
}

impl From<Artist> for ArtistDTO {
    fn from(a: Artist) -> Self {
        ArtistDTO {
            id: a.id,
            name: a.name,
            album_count: a.album_count,
            cover_art: a.cover_art,
        }
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
            duration: a.duration, cover_art: a.cover_art
        }
    }
}

impl From<SearchInfo> for SearchDTO {
    fn from(info: SearchInfo) -> Self {
        SearchDTO {
            artists: info.artist.map(|lista| { lista.into_iter().map(ArtistDTO::from).collect() }),
            albums: info.album.map(|lista| { lista.into_iter().map(AlbumDTO::from).collect() }),
            songs: info.song.map(|lista| { lista.into_iter().map(SongDTO::from).collect() }),
        }
    }
}
