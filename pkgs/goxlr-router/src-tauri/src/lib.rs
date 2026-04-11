use std::process::Command;

fn run_cmd(bin: &str, args: &[&str]) -> Result<String, String> {
  let out = Command::new(bin)
    .args(args)
    .output()
    .map_err(|e| format!("failed to run {bin}: {e}"))?;
  let stdout = String::from_utf8_lossy(&out.stdout).to_string();
  let stderr = String::from_utf8_lossy(&out.stderr).to_string();
  if !out.status.success() {
    return Err(if stderr.is_empty() {
      format!("{bin} exited {}", out.status)
    } else {
      stderr
    });
  }
  Ok(stdout)
}

#[tauri::command]
fn get_pw_dump() -> Result<String, String> {
  run_cmd("pw-dump", &["--color", "never"])
}

#[tauri::command]
fn pw_link_connect(from_spec: String, to_spec: String) -> Result<(), String> {
  run_cmd("pw-link", &[&from_spec, &to_spec]).map(|_| ())
}

#[tauri::command]
fn pw_link_disconnect(from_spec: String, to_spec: String) -> Result<(), String> {
  run_cmd("pw-link", &["-d", &from_spec, &to_spec]).map(|_| ())
}

#[tauri::command]
fn get_alsa_playback() -> Result<String, String> {
  run_cmd("aplay", &["-l"])
}

#[tauri::command]
fn get_alsa_capture() -> Result<String, String> {
  run_cmd("arecord", &["-l"])
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
  tauri::Builder::default()
    .invoke_handler(tauri::generate_handler![
      get_pw_dump,
      pw_link_connect,
      pw_link_disconnect,
      get_alsa_playback,
      get_alsa_capture,
    ])
    .run(tauri::generate_context!())
    .expect("error while running tauri application");
}
