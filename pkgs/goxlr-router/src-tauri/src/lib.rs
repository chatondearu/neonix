use serde::Serialize;
use serde_json::{Map, Value};
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

/// Strip CSI color sequences so JSON.parse in Rust survives older pw-dump without -N.
fn strip_ansi(s: &str) -> String {
  let mut out = String::with_capacity(s.len());
  let mut it = s.chars().peekable();
  while let Some(c) = it.next() {
    if c == '\x1b' {
      if it.peek() == Some(&'[') {
        it.next();
        while let Some(&x) = it.peek() {
          it.next();
          if x == 'm' {
            break;
          }
        }
        continue;
      }
    }
    out.push(c);
  }
  out
}

fn pw_dump_json() -> Result<String, String> {
  let attempts: &[&[&str]] = &[&["-N"], &[], &["--color", "never"]];
  let mut last_empty = String::new();
  for args in attempts {
    match run_cmd("pw-dump", *args) {
      Ok(s) => {
        let t = s.trim();
        if t.len() > 2 {
          return Ok(strip_ansi(&s));
        }
        last_empty = format!("pw-dump {:?} returned empty stdout", args);
      }
      Err(e) => last_empty = e,
    }
  }
  Err(format!(
    "{last_empty}. Is PipeWire running and XDG_RUNTIME_DIR set?"
  ))
}

fn val_to_u32(v: &Value) -> Option<u32> {
  match v {
    Value::Number(n) => n.as_u64().map(|x| x as u32),
    Value::String(s) => s.parse().ok(),
    _ => None,
  }
}

fn val_to_string(v: &Value) -> String {
  match v {
    Value::String(s) => s.clone(),
    Value::Number(n) => n.to_string(),
    _ => String::new(),
  }
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct NodeOut {
  id: u32,
  name: String,
  description: String,
  media_class: String,
  is_goxlr: bool,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct PortOut {
  id: u32,
  node_id: u32,
  node_name: String,
  port_name: String,
  direction: String,
  link_spec: String,
  format_hint: String,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct LinkOut {
  id: u32,
  output_port_id: u32,
  input_port_id: u32,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct GraphOut {
  nodes: Vec<NodeOut>,
  ports: Vec<PortOut>,
  links: Vec<LinkOut>,
}

fn props_map<'a>(info: &'a Value) -> Option<&'a Map<String, Value>> {
  info.get("props")?.as_object()
}

fn link_endpoint(info: &Value, props: Option<&Map<String, Value>>, keys: &[&str]) -> Option<u32> {
  for k in keys {
    if let Some(v) = info.get(*k) {
      if let Some(n) = val_to_u32(v) {
        return Some(n);
      }
    }
    if let Some(p) = props {
      if let Some(v) = p.get(*k) {
        if let Some(n) = val_to_u32(v) {
          return Some(n);
        }
      }
    }
  }
  None
}

fn port_direction(dir: Option<&str>) -> &'static str {
  match dir {
    Some("in") | Some("input") => "input",
    _ => "output",
  }
}

/// Build a small graph JSON (fits Tauri IPC); mirrors frontend pwParse.ts.
fn build_graph_from_pw_dump(raw: &str) -> Result<GraphOut, String> {
  let root: Value = serde_json::from_str(raw.trim()).map_err(|e| {
    format!(
      "invalid JSON from pw-dump (truncated IPC or bad output?): {e}"
    )
  })?;
  let arr = root
    .as_array()
    .ok_or_else(|| "pw-dump root is not a JSON array".to_string())?;

  let mut node_by_id: std::collections::HashMap<u32, NodeOut> =
    std::collections::HashMap::new();
  let mut ports: Vec<PortOut> = Vec::new();
  let mut links: Vec<LinkOut> = Vec::new();

  for item in arr {
    let id = item.get("id").and_then(val_to_u32).unwrap_or(0);
    let typ = item
      .get("type")
      .and_then(|t| t.as_str())
      .unwrap_or("")
      .to_string();

    if typ == "PipeWire:Interface:Node" {
      let Some(info) = item.get("info") else { continue };
      let Some(props) = props_map(info) else { continue };
      let name = val_to_string(props.get("node.name").unwrap_or(&Value::Null));
      let name = if name.is_empty() {
        val_to_string(props.get("object.path").unwrap_or(&Value::Null))
      } else {
        name
      };
      let name = if name.is_empty() {
        format!("node-{id}")
      } else {
        name
      };
      let desc = val_to_string(
        props
          .get("node.description")
          .or_else(|| props.get("node.nick"))
          .unwrap_or(&Value::String(name.clone())),
      );
      let media_class = val_to_string(props.get("media.class").unwrap_or(&Value::Null));
      let lower = format!("{name} {desc}").to_lowercase();
      let is_goxlr = lower.contains("goxlr")
        || lower.contains("tc-helicon")
        || lower.contains("hifi__headphones__sink");
      node_by_id.insert(
        id,
        NodeOut {
          id,
          name: name.clone(),
          description: desc,
          media_class,
          is_goxlr,
        },
      );
    }
  }

  for item in arr {
    let id = item.get("id").and_then(val_to_u32).unwrap_or(0);
    let typ = item.get("type").and_then(|t| t.as_str()).unwrap_or("");

    if typ == "PipeWire:Interface:Port" {
      let Some(info) = item.get("info") else { continue };
      let Some(props) = props_map(info) else { continue };
      let Some(node_id) = props.get("node.id").and_then(val_to_u32) else {
        continue;
      };
      let node_name = node_by_id
        .get(&node_id)
        .map(|n| n.name.clone())
        .unwrap_or_else(|| format!("node-{node_id}"));
      let port_name = props
        .get("port.name")
        .or_else(|| props.get("port.alias"))
        .map(val_to_string)
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| format!("port-{id}"));
      let dir_str = info.get("direction").and_then(|v| v.as_str());
      let direction = port_direction(dir_str).to_string();
      let format_hint = val_to_string(
        props
          .get("format.dsp")
          .or_else(|| props.get("audio.format"))
          .unwrap_or(&Value::Null),
      );
      let link_spec = format!("{node_name}:{port_name}");
      ports.push(PortOut {
        id,
        node_id,
        node_name,
        port_name,
        direction,
        link_spec,
        format_hint,
      });
    }
  }

  for item in arr {
    let id = item.get("id").and_then(val_to_u32).unwrap_or(0);
    let typ = item.get("type").and_then(|t| t.as_str()).unwrap_or("");

    if typ == "PipeWire:Interface:Link" {
      let Some(info) = item.get("info") else { continue };
      let props = info.get("props").and_then(|p| p.as_object());
      let out_pid = link_endpoint(
        info,
        props,
        &[
          "output-port-id",
          "outputPortId",
          "link.output.port",
        ],
      );
      let in_pid = link_endpoint(
        info,
        props,
        &[
          "input-port-id",
          "inputPortId",
          "link.input.port",
        ],
      );
      if let (Some(output_port_id), Some(input_port_id)) = (out_pid, in_pid) {
        links.push(LinkOut {
          id,
          output_port_id,
          input_port_id,
        });
      }
    }
  }

  let mut nodes: Vec<NodeOut> = node_by_id.into_values().collect();
  nodes.sort_by(|a, b| a.name.cmp(&b.name));

  Ok(GraphOut {
    nodes,
    ports,
    links,
  })
}

#[tauri::command]
fn get_pipewire_graph() -> Result<String, String> {
  let raw = pw_dump_json()?;
  let graph = build_graph_from_pw_dump(&raw)?;
  serde_json::to_string(&graph).map_err(|e| e.to_string())
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
      get_pipewire_graph,
      pw_link_connect,
      pw_link_disconnect,
      get_alsa_playback,
      get_alsa_capture,
    ])
    .run(tauri::generate_context!())
    .expect("error while running tauri application");
}
