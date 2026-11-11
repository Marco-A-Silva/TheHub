use api_macros::data;

#[allow(dead_code)]
#[data] 
struct ApiResponse<T> {
    #[serde(rename = "subsonic-response")]
    subsonic_response: Envelope<T>,
}

#[data]
struct Empty {}

#[allow(dead_code)]
#[data]
struct Envelope<T> {
    status: String, 
    version: String,
    #[serde(flatten)]
    content: T,
}

#[data]
struct IdQuery {
    id: String,
}

#[data]
struct SearchQuery {
    q: String,
}

/*--------------------------------------------------------------*/
//Artists

#[data] struct ArtistsContent {artists: Artists}

#[data] struct Artists {index: Vec<ArtistIndex>}

#[data] struct ArtistIndex {name: String, artist: Vec<Artist>}

#[data] struct Artist {
    id: String, name: String,
    album_count: u32,
    cover_art: Option<String>    
}

#[data] struct ArtistContent {artist: ArtistInfo}

#[data] struct ArtistInfo {
    id: String, name: String, cover_art: String,
    album_count: u32,
    album: Vec<ArtistAlbums>
}

#[data] struct ArtistAlbums {
    id: String, name: String, created: String, artist: String, artist_id: String,
    song_count: u32, duration: u32,
    cover_art: Option<String>,
}

/*--------------------------------------------------------------*/
//Albums

#[data] struct AlbumContent {album: AlbumInfo}

#[data] struct AlbumInfo {
    id: String, artist_id: String, artist:String, name: String, created: String, 
    duration: u32, song_count: u32,
    cover_art: Option<String>,
    song: Vec<AlbumSong>
}

#[data] struct AlbumSong {
    id: String, album_id: String, artist_id: String, title: String, album: String, artist: String, created: String,
    suffix: String, content_type: String, path: String,parent: String,
    #[serde(rename = "type")]
    taipe: String, 
    duration: u32, bit_rate: u16, size: u64,
    is_dir: Option<bool>, is_video: Option<bool>, cover_art: Option<String>, track: Option<u32>, genre: Option<String>, year: Option<u16>
}

/*--------------------------------------------------------------*/
//Search

#[data] struct SearchContent {search_result3: SearchInfo}

#[data] struct SearchInfo {
    artist: Option<Vec<Artist>>,
    album: Option<Vec<ArtistAlbums>>,
    song: Option<Vec<AlbumSong>>,
}

#[data] struct SimilarContent {similar_songs : SimilarInfo}

#[data] struct SimilarInfo { song: Vec<AlbumSong> }
