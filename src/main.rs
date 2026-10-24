use anyhow::Result;
use md5::{Digest, Md5};
use reqwest::Client;
use std::env;
use dotenvy::dotenv;
use serde_json::Value;
use axum::{
    Json, Router, extract::{Path, Query, State}, http::StatusCode, routing::get, serve::Listener,
};

mod dt;
use dt::ApiResponse;

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

async fn ping(State(s): State<AppState>) -> Result<Json<ApiResponse>, StatusCode> {
    let res = s.client.get(s.api_url("ping")).send().await.map_err(|_| StatusCode::BAD_GATEWAY)?;

    let body: ApiResponse = res.json().await.map_err(|_| StatusCode::BAD_GATEWAY)?;
    
    Ok(Json(body))
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
        .with_state(state);

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await?;
    axum::serve(listener, app).await?;
    Ok(())

    /*let api_url = format!("{}/rest/ping?u={}&t={}&s={}&v={}&c={}&f=json", url, user, token, salt, API_VERSION, CLI_NAME);

    let cli = Client::new();
    let res = cli.get(&api_url).send().await?;

    if true == true {
        let body: Value = res.json().await?;
        println!("{:#?}", body);
    }else {
        let body: ApiResponse = res.json().await?;
        println!("version {}", body.subsonic_response.version);
        println!("status {}", body.subsonic_response.status);
        if let Some(genre_list) = body.subsonic_response.genres {
            for genre in genre_list.genre {
                println!("{:#?}", genre);
            }
    
        }
    }
    Ok(())*/
}
