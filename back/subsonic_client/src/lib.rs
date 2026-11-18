pub mod dt;

use dt::{
    ApiResponse, Empty, AlbumContent, ArtistContent,
    ArtistsContent, SearchContent, SimilarContent, PlaylistsContent, PlaylistContent
};
use reqwest::{
    header::{HeaderMap, HeaderValue, RANGE},
    Client, Response,
};
use serde::de::DeserializeOwned;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum SubsonicError {
    #[error("HTTP network error: {0}")]
    Network(#[from] reqwest::Error),
    #[error("Subsonic API error (code {code}): {message}")]
    Api { code: u32, message: String },
    #[error("Unexpected or empty response from server")]
    EmptyResponse,
}

#[derive(Clone)]
pub struct SubsonicClient {
    base_url: String,
    user: String,
    password: String,
    client_name: String,
    http: Client,
}

impl SubsonicClient {
    pub fn new(base_url: impl Into<String>, user: impl Into<String>, password: impl Into<String>, client_name: impl Into<String>) -> Self {
        Self {
            base_url: base_url.into().trim_end_matches('/').to_string(),
            user: user.into(),
            password: password.into(),
            client_name: client_name.into(),
            http: Client::new(),
        }
    }

    fn auth_params(&self) -> Vec<(String, String)> {
        let salt = "123456".to_string();
        let digest = md5::compute(format!("{}{}", self.password, salt).as_bytes());
        let token = hex::encode(digest.0);

        vec![
            ("u".to_string(), self.user.clone()), ("t".to_string(), token),
            ("s".to_string(), salt), ("v".to_string(), "1.16.1".to_string()),
            ("c".to_string(), self.client_name.clone()), ("f".to_string(), "json".to_string()),
        ]
    }

    async fn get(&self, endpoint: &str, extra_params: &[(&str, &str)], extra_headers: Option<HeaderMap>) -> Result<Response, SubsonicError> {
        let url = format!("{}/rest/{}", self.base_url, endpoint);
        let mut query = self.auth_params();

        for (k, v) in extra_params { query.push((k.to_string(), v.to_string())); }
        let mut req = self.http.get(&url).query(&query);

        if let Some(headers) = extra_headers { req = req.headers(headers); }
        Ok(req.send().await?)
    }

    async fn get_json<T: DeserializeOwned>(&self, endpoint: &str, extra_params: &[(&str, &str)]) -> Result<T, SubsonicError> {
        let res: ApiResponse<T> = self.get(endpoint, extra_params, None).await?.json().await?;

        if res.subsonic_response.status != "ok" {
            if let Some(err) = res.subsonic_response.error {
                return Err(SubsonicError::Api { code: err.code, message: err.message });
            }
        }

        res.subsonic_response.data.ok_or(SubsonicError::EmptyResponse)
    }

    pub async fn stream(&self, song_id: &str, max_bit_rate: Option<u32>, range: Option<&HeaderValue>) -> Result<Response, SubsonicError> {
        let mut params = vec![("id", song_id)];
        let br_str;
        if let Some(br) = max_bit_rate {
            br_str = br.to_string();
            params.push(("maxBitRate", &br_str));
        }

        let mut headers = HeaderMap::new();
        if let Some(r) = range { headers.insert(RANGE, r.clone()); }

        self.get("stream", &params, Some(headers)).await
    }

    pub async fn ping(&self) -> Result<(), SubsonicError> {
        let _: Empty = self.get_json("ping", &[]).await?;
        Ok(())
    }

    pub async fn search(&self, query: &str) -> Result<SearchContent, SubsonicError> {
        self.get_json("search3", &[("query", query)]).await
    }

    pub async fn get_artists(&self) -> Result<ArtistsContent, SubsonicError> {
        self.get_json("getArtists", &[]).await
    }

    pub async fn get_artist(&self, id: &str) -> Result<ArtistContent, SubsonicError> {
        self.get_json("getArtist", &[("id", id)]).await
    }

    pub async fn get_album(&self, id: &str) -> Result<AlbumContent, SubsonicError> {
        self.get_json("getAlbum", &[("id", id)]).await
    }

    pub async fn get_similar_songs(&self, id: &str) -> Result<SimilarContent, SubsonicError> {
        self.get_json("getSimilarSongs", &[("id", id)]).await
    }

    pub async fn get_playlists(&self) -> Result<PlaylistsContent, SubsonicError> {
        self.get_json("getPlaylists", &[]).await
    }

    pub async fn get_playlist(&self, id: &str) -> Result<PlaylistContent,SubsonicError> {
        self.get_json("getPlaylist", &[("id", id)]).await
    }

    pub  async fn create_playlist(&self, name: &str, ids: Option<&[String]>) -> Result<PlaylistContent, SubsonicError> {
        let mut params = vec![("name", name)];

        if let Some(song_ids) = ids {
            for id in song_ids {
                params.push(("songId", id.as_str()));
            }
        }

        self.get_json("createPlaylist", &params).await
    }

    pub async fn start_scan(&self) -> Result<(), SubsonicError> {
        let _: Empty = self.get_json("startScan", &[]).await?;
        Ok(())
    }
}
