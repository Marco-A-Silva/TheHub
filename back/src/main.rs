use anyhow::Result;
use md5::{Digest, Md5};
use reqwest::{ Client, header::{CONTENT_TYPE, CONTENT_LENGTH, CONTENT_RANGE, ACCEPT_RANGES, RANGE} };
use std::{env, process::Command};
use dotenvy::dotenv;
use axum::{
    Json, Router, extract::{Query, State}, http::{StatusCode, HeaderMap}, routing::get,
    body::Body, response::Response
};

mod dt;
mod dto;
use dt::{
    ApiResponse, 
    IdQuery, SearchQuery,
    Empty, ArtistsContent, ArtistContent, AlbumContent, SearchContent, SimilarContent, ExSearchContent
};
use dto::{ 
    PingDTO, ArtistDTO, AlbumDTO, SongDTO, SearchDTO
};


const CLI_NAME: &str = "NavPI"; 
const API_VERSION: &str = "1.13";

#[derive(Clone)]
struct AppState {
    client: Client,
    url: String,
    user: String,
    passwd: String,
    salt: String,
}

impl AppState {
    fn api_url(&self, endpoint: &str) -> String {
        let mut hasher = Md5::new();
        hasher.update(format!("{}{}",self.passwd,self.salt).as_bytes());
        let token = hex::encode(hasher.finalize());    
         
        format!(
            "{}/rest/{}?u={}&t={}&s={}&v={}&c={}&f=json",
            self.url, endpoint, self.user, token, self.salt, API_VERSION, CLI_NAME
        ) 

    }
}

async fn ping(State(s): State<AppState>) -> Result<Json<PingDTO>, StatusCode> {
    let res = s.client.get(s.api_url("ping")).send().await.map_err(|_| StatusCode::BAD_GATEWAY)?;

    let body: ApiResponse<Empty> = res.json().await.map_err(|_| StatusCode::BAD_GATEWAY)?;
    Ok(Json(PingDTO::from(body.subsonic_response)))
}

async fn similar_songs(State(s): State<AppState>, Query(q): Query<IdQuery>) -> Result<Json<Vec<SongDTO>>, StatusCode> {
    let id = q.id;
    let res = s.client.get(s.api_url("getSimilarSongs")).query(&[("id", id)]).send().await.map_err(|_| StatusCode::BAD_GATEWAY)?;

    let body: ApiResponse<SimilarContent> = res.json().await.map_err(|_| StatusCode::BAD_GATEWAY)?;
    let songs: Vec<SongDTO> = body.subsonic_response.content.similar_songs.song
        .into_iter().map(SongDTO::from).collect();

    Ok(Json(songs))
}

async fn get_artists(State(s): State<AppState>) -> Result<Json<Vec<ArtistDTO>>, StatusCode> {
    let res = s.client.get(s.api_url("getArtists")).send().await.map_err(|_| StatusCode::BAD_GATEWAY)?;

    let body: ApiResponse<ArtistsContent> = res.json().await.map_err(|_| StatusCode::BAD_GATEWAY)?;
    let artists: Vec<ArtistDTO> = body
        .subsonic_response.content.artists.index
        .into_iter().flat_map(|grupo| grupo.artist).map(ArtistDTO::from).collect();
    Ok(Json(artists))
}

async fn get_arist(State(s): State<AppState>, Query(q): Query<IdQuery>) -> Result<Json<Vec<AlbumDTO>>, StatusCode> {
    let id = q.id;
    let res = s.client.get(s.api_url("getArtist")).query(&[("id", id)]).send().await.map_err(|_| StatusCode::BAD_GATEWAY)?;
    
    let body: ApiResponse<ArtistContent> = res.json().await.map_err(|_| StatusCode::BAD_GATEWAY)?;
    let albums: Vec<AlbumDTO> = body
        .subsonic_response.content.artist.album
        .into_iter().map(AlbumDTO::from).collect();

    Ok(Json(albums))
}

async fn get_album(State(s): State<AppState>, Query(q): Query<IdQuery>) -> Result<Json<Vec<SongDTO>>, StatusCode> {
    let id = q.id;
    let res = s.client.get(s.api_url("getAlbum")).query(&[("id", id)])
        .send().await.map_err(|_| StatusCode::BAD_GATEWAY)?;

    let body: ApiResponse<AlbumContent> = res.json().await.map_err(|_| StatusCode::BAD_GATEWAY)?;
    let songs: Vec<SongDTO> = body.subsonic_response.content.album.song
        .into_iter().map(SongDTO::from).collect();

    Ok(Json(songs))
}

async fn search(State(s): State<AppState>, Query(q): Query<SearchQuery>) -> Result<Json<SearchDTO>, StatusCode> {
    let res = s.client.get(s.api_url("search3")).query(&[("query", q.q.as_str())])
        .send().await.map_err(|_| StatusCode::BAD_GATEWAY)?;
        
    let body: ApiResponse<SearchContent> = res.json().await.map_err(|_| StatusCode::BAD_GATEWAY)?;
    let search_res = SearchDTO::from(body.subsonic_response.content.search_result3);

    Ok(Json(search_res))
}

async fn ex_search(Query(q): Query<SearchQuery>) -> Result<Json<Vec<ExSearchContent>>, StatusCode> {
    let output = Command::new("yt-dlp").arg(format!("ytsearch10:{} - Topic", q.q)).arg("--dump-json")
        .arg("--no-playlist").output().map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    let stdout = String::from_utf8_lossy(&output.stdout);
    let mut results = Vec::new();

    for line in stdout.lines() {
        if let Ok(json) = serde_json::from_str::<serde_json::Value>(line) {
            let song = ExSearchContent {
                id: json["id"].as_str().unwrap_or("").to_string(),
                title: json["title"].as_str().unwrap_or("Desconocido").to_string(),
                uploader: json["uploader"].as_str().unwrap_or("Artista desconocido").to_string(),
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

async fn ex_download(State(s): State<AppState> ,Json(payload): Json<SearchQuery>) -> Result<Json<serde_json::Value>, StatusCode> {
    let output = Command::new("yt-dlp").arg("-x").arg("--audio-format").arg("mp3").arg("--embed-metadata")
        .arg("-o").arg("/srv/data/music/%(title)s.%(ext)s").arg(&payload.q).output()
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR);

    if output.unwrap().status.success() {
        
        let _ = s.client.get(s.api_url("startScan")).send().await;

        Ok(Json(serde_json::json!({
            "status": "ok", 
            "msg": "Canción descargada e indexada"
        })))
    } else {
        Err(StatusCode::BAD_GATEWAY)
    }
}

async fn stream(State(s): State<AppState>, Query(q): Query<IdQuery>, headers: HeaderMap) -> Result<Response, StatusCode> {

    let mut req = s.client.get(s.api_url("stream")).query(&[("id", q.id.as_str()), ("maxBitRate", "320")]);

    if let Some(range) = headers.get(RANGE) {
        req = req.header(RANGE, range);
    }

    let res = req.send().await.map_err(|e| {
        eprintln!("stream: error al contactar Navidrome: {}", e.without_url());
        StatusCode::BAD_GATEWAY
    })?;


    let status = res.status();
    if !status.is_success() {
        eprintln!("stream: Navidrome respondió {}", status);
        return Err(StatusCode::BAD_GATEWAY);
    }

    let es_json = res.headers().get(CONTENT_TYPE)
        .and_then(|v| v.to_str().ok()).map(|ct| ct.contains("json")).unwrap_or(false);

    if es_json {
        eprintln!("stream: Navidrome devolvió JSON en vez de audio (id no válido?)");
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
        client: Client::new(),
        url: env::var("URL").expect("Falta URL en el .env"),
        user: env::var("NAVI_USER").expect("Falta USER en el .env"),
        passwd: env::var("NAVI_PASS").expect("Falta PASSWRD en el .env"),
        salt: env::var("SALT").expect("Falta SALT en el .env"),
    };

    let app = Router::new()
        .route("/api/ping", get(ping))
        .route("/api/getArtists", get(get_artists))
        .route("/api/getArtist", get(get_arist))
        .route("/api/getAlbum", get(get_album))
        .route("/api/similarSongs", get(similar_songs))
        .route("/api/search", get(search))
        .route("/api/exSearch", get(ex_search))
        .route("/api/exDownload", get(ex_download))
        .route("/api/stream", get(stream))
        .with_state(state);

    let listener = tokio::net::TcpListener::bind("100.121.136.54:3000").await?;
    axum::serve(listener, app).await?;
    Ok(())
}
