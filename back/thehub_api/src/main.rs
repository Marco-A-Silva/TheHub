use anyhow::Result;
use axum::{
    Json, Router,
    body::Body,
    extract::{Query, State, Path},
    http::{
        HeaderMap, StatusCode,
        header::{ACCEPT_RANGES, CONTENT_LENGTH, CONTENT_RANGE, CONTENT_TYPE, RANGE},
    },
    response::Response,
    routing::{get},
};
use dotenvy::dotenv;
use std::{env, process::Command};
use subsonic_client::SubsonicClient;

mod dto;
use dto::{
    AlbumDTO, ArtistDTO, PingDTO, SearchDTO, SongDTO, PlaylistDTO,
    ExSearchContent, SearchQuery, 
};

#[derive(Clone)]
struct AppState {
    subsonic: SubsonicClient,
}

async fn ping(State(s): State<AppState>) -> Result<Json<PingDTO>, StatusCode> {
    match s.subsonic.ping().await {
        Ok(_) => Ok(Json(PingDTO::ok())),
        Err(_) => Err(StatusCode::BAD_GATEWAY),
    }
}

async fn get_all_playlists(State(s): State<AppState>) -> Result<Json<Vec<PlaylistDTO>>, StatusCode> {
    let body = s.subsonic.get_playlists().await.map_err(|_| StatusCode::BAD_GATEWAY)?;
    let playlists: Vec<PlaylistDTO> = body.playlists.playlist.into_iter().map(PlaylistDTO::from).collect();

    Ok(Json(playlists))
}


async fn similar_songs(State(s): State<AppState>, Path(id): Path<String>) -> Result<Json<Vec<SongDTO>>, StatusCode> {
    let body = s.subsonic.get_similar_songs(&id).await.map_err(|_| StatusCode::BAD_GATEWAY)?;
    let songs: Vec<SongDTO> = body.similar_songs.song.into_iter().map(SongDTO::from).collect();

    Ok(Json(songs))
}

async fn get_all_artists(State(s): State<AppState>) -> Result<Json<Vec<ArtistDTO>>, StatusCode> {
    let body = s.subsonic.get_artists().await.map_err(|_| StatusCode::BAD_GATEWAY)?;
    let artists: Vec<ArtistDTO> = body.artists.index.into_iter().flat_map(|grupo| grupo.artist).map(ArtistDTO::from).collect();

    Ok(Json(artists))
}

async fn get_artist(State(s): State<AppState>, Path(id): Path<String>) -> Result<Json<Vec<AlbumDTO>>, StatusCode> {
    let body = s.subsonic.get_artist(&id).await.map_err(|_| StatusCode::BAD_GATEWAY)?;
    let albums: Vec<AlbumDTO> = body.artist.album.into_iter().map(AlbumDTO::from).collect();

    Ok(Json(albums))
}

async fn get_playlist(State(s): State<AppState>, Path(id): Path<String>) -> Result<Json<Vec<SongDTO>>, StatusCode> {
    let body = s.subsonic.get_playlist(&id).await.map_err(|_| StatusCode::BAD_GATEWAY)?;
    let songs: Vec<SongDTO> = body.playlist.entry.into_iter().flat_map(|playlist| playlist).map(SongDTO::from).collect();

    Ok(Json(songs))
}

async fn get_album(State(s): State<AppState>, Path(id): Path<String>) -> Result<Json<Vec<SongDTO>>, StatusCode> {
    let body = s.subsonic.get_album(&id).await.map_err(|_| StatusCode::BAD_GATEWAY)?;
    let songs: Vec<SongDTO> = body.album.song.into_iter().map(SongDTO::from).collect();

    Ok(Json(songs))
}

async fn search(State(s): State<AppState>, Query(q): Query<SearchQuery>) -> Result<Json<SearchDTO>, StatusCode> {
    let body = s.subsonic.search(&q.q).await.map_err(|_| StatusCode::BAD_GATEWAY)?;
    let search_res = SearchDTO::from(body.search_result3);

    Ok(Json(search_res))
}

async fn ex_search(Query(q): Query<SearchQuery>) -> Result<Json<Vec<ExSearchContent>>, StatusCode> {
    let output = Command::new("yt-dlp").arg(format!("ytsearch10:{} - Topic", q.q)).arg("--dump-json")
        .arg("--flat-playlist").arg("--no-playlist").output().map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    let stdout = String::from_utf8_lossy(&output.stdout);
    let mut results = Vec::new();

    for line in stdout.lines() {
        if let Ok(json) = serde_json::from_str::<serde_json::Value>(line) {
            let song = ExSearchContent {
                id: json["id"].as_str().unwrap_or("").to_string(),
                title: json["title"].as_str().unwrap_or("Unknown").to_string(),
                uploader: json["uploader"].as_str().unwrap_or("Unknown Artist").to_string(),
                thumbnail: json["thumbnail"].as_str().unwrap_or("").to_string(),
                url: json["webpage_url"].as_str().unwrap_or("").to_string(),
            };

            if !song.id.is_empty() {
                results.push(song);
            }
        }
    }
    Ok(Json(results))
}

async fn ex_download(State(s): State<AppState>, Json(payload): Json<SearchQuery>) -> Result<Json<serde_json::Value>, StatusCode> {
    let output = Command::new("yt-dlp").arg("-x").arg("--audio-format").arg("mp3").arg("--embed-metadata")
        .arg("-o").arg("/srv/data/music/%(uploader)s/%(title)s.%(ext)s").arg(&payload.q).output()
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    if output.status.success() {
        let _ = s.subsonic.start_scan().await;

        Ok(Json(serde_json::json!({
            "status": "ok",
            "msg": "Song downloaded and indexed"
        })))
    } else {
        Err(StatusCode::BAD_GATEWAY)
    }
}

async fn stream(State(s): State<AppState>, Path(id): Path<String>, headers: HeaderMap) -> Result<Response, StatusCode> {
    let res = s.subsonic.stream(&id, Some(320), headers.get(RANGE)).await.map_err(|e| {
        eprintln!("stream: error while connecting to Navidrome: {}", e);
        StatusCode::BAD_GATEWAY
    })?;

    let status = res.status();
    if !status.is_success() {
        eprintln!("stream: Navidrome answered  {}", status);
        return Err(StatusCode::BAD_GATEWAY);
    }

    let es_json = res.headers().get(CONTENT_TYPE)
        .and_then(|v| v.to_str().ok()).map(|ct| ct.contains("json")).unwrap_or(false);

    if es_json {
        eprintln!("stream: Navidrome gave JSON instead of audio (unvalid id?)");
        return Err(StatusCode::NOT_FOUND);
    }

    let mut out = Response::builder().status(status);
    for name in [CONTENT_TYPE, CONTENT_LENGTH, CONTENT_RANGE, ACCEPT_RANGES] {
        if let Some(v) = res.headers().get(&name) {
            out = out.header(name, v);
        }
    }

    out.body(Body::from_stream(res.bytes_stream())).map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)
}


#[tokio::main]
async fn main() -> Result<()> {
    dotenv().ok();

    let state = AppState {
        subsonic: SubsonicClient::new(
            env::var("URL").expect("URL missing in .env"),
            env::var("NAVI_USER").expect("NAVI_USER missing in .env"),
            env::var("NAVI_PASS").expect("NAVI_PASS missing in .env"),
            "NavPI",
        ),
    };

    let app = Router::new()
        .route("/api/ping", get(ping))

        .route("/api/artists", get(get_all_artists))
        .route("/api/artists/{id}", get(get_artist))
        .route("/api/albums/{id}", get(get_album))
        
        .route("/api/songs", get(search))
        .route("/api/songs/{id}/similar", get(similar_songs))
        .route("/api/songs/{id}/stream", get(stream))

        .route("/api/playlists", get(get_all_playlists)/*.post(create_playlist)*/)
        .route("/api/playlists/{id}", get(get_playlist))

        .route("/api/external", get(ex_search).post(ex_download))
        .with_state(state);

    let listener = tokio::net::TcpListener::bind("100.121.136.54:3000").await?;
    axum::serve(listener, app).await?;
    Ok(())
}
