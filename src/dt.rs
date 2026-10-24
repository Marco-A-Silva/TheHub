use api_macros::data;

#[allow(dead_code)]
#[data]
struct ApiResponse {
    #[serde(rename = "subsonic-response")]
    subsonic_response: SubsonicData
}

#[allow(dead_code)]
#[data]
struct SubsonicData {
     status: String, 
     version: String,
     genres: Option<Genres>
}

#[allow(dead_code)]    
#[data]
struct Genres {
    genre: Vec<Genre>
}

#[allow(dead_code)]
#[data]
struct Genre {
    album_count: u32,
    song_count: u32,
    value: String
}
