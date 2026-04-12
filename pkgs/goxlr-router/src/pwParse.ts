import type {
  GraphModel,
  PwLinkModel,
  PwNodeModel,
  PwObject,
  PwPortModel,
} from "./pwTypes";

function str(v: string | number | undefined): string {
  if (v === undefined || v === null) return "";
  return String(v);
}

function linkEndpoint(info: Record<string, unknown>, keys: string[]): number | undefined {
  for (const k of keys) {
    const v = info[k];
    if (typeof v === "number" && !Number.isNaN(v)) return v;
    if (typeof v === "string" && v !== "") {
      const n = Number(v);
      if (!Number.isNaN(n)) return n;
    }
  }
  return undefined;
}

/** pw-dump uses pw_direction_as_string: "in" / "out", not "input" / "output". */
function portDirectionFromPwDump(
  dir: string | undefined,
): "input" | "output" {
  if (dir === "in" || dir === "input") return "input";
  return "output";
}

function flattenPwDumpObjects(raw: string): PwObject[] {
  const t = raw.trim();
  if (!t) return [];
  try {
    const v = JSON.parse(t) as unknown;
    if (Array.isArray(v)) return v as PwObject[];
  } catch {
    /* try fallbacks */
  }
  // Newline-delimited JSON arrays (e.g. monitor mode or multiple dumps)
  const merged: PwObject[] = [];
  for (const line of t.split(/\n/)) {
    const s = line.trim();
    if (!s.startsWith("[")) continue;
    try {
      const v = JSON.parse(s) as unknown;
      if (Array.isArray(v)) merged.push(...(v as PwObject[]));
    } catch {
      /* skip */
    }
  }
  if (merged.length > 0) return merged;
  // Adjacent arrays: ][ -> ,  (compact output only)
  try {
    const v = JSON.parse(t.replace(/\]\s*\[/g, ",")) as unknown;
    if (Array.isArray(v)) return v as PwObject[];
  } catch {
    /* */
  }
  return [];
}

/**
 * Build a graph model from pw-dump JSON for Vue Flow.
 */
export function parsePwDump(jsonText: string): GraphModel {
  const arr = flattenPwDumpObjects(jsonText);
  if (arr.length === 0) return { nodes: [], ports: [], links: [] };

  const nodeById = new Map<number, PwNodeModel>();
  const portById = new Map<number, PwPortModel>();
  const links: PwLinkModel[] = [];

  for (const o of arr) {
    if (o.type === "PipeWire:Interface:Node" && o.info?.props) {
      const p = o.info.props;
      const name = str(p["node.name"] || p["object.path"]);
      const desc = str(p["node.description"] || p["node.nick"] || name);
      const mediaClass = str(p["media.class"]);
      const lower = `${name} ${desc}`.toLowerCase();
      const isGoxlr =
        lower.includes("goxlr") ||
        lower.includes("tc-helicon") ||
        lower.includes("hifi__headphones__sink");
      nodeById.set(o.id, {
        id: o.id,
        name: name || `node-${o.id}`,
        description: desc,
        mediaClass,
        isGoxlr,
      });
    }
  }

  for (const o of arr) {
    if (o.type !== "PipeWire:Interface:Port" || !o.info) continue;
    const props = o.info.props;
    if (!props) continue;
    const nodeIdRaw = props["node.id"];
    const nodeId =
      typeof nodeIdRaw === "number"
        ? nodeIdRaw
        : typeof nodeIdRaw === "string"
          ? Number(nodeIdRaw)
          : NaN;
    if (Number.isNaN(nodeId)) continue;

    const node = nodeById.get(nodeId);
    const nodeName = node?.name || `node-${nodeId}`;
    const portName = str(props["port.name"] || props["port.alias"] || `port-${o.id}`);
    const direction = portDirectionFromPwDump(o.info.direction);
    const formatHint = str(props["format.dsp"] || props["audio.format"] || "");

    portById.set(o.id, {
      id: o.id,
      nodeId,
      nodeName,
      portName,
      direction,
      linkSpec: `${nodeName}:${portName}`,
      formatHint,
    });
  }

  for (const o of arr) {
    if (o.type !== "PipeWire:Interface:Link" || !o.info) continue;
    const info = o.info as unknown as Record<string, unknown>;
    const props =
      info.props && typeof info.props === "object" && info.props !== null
        ? (info.props as Record<string, unknown>)
        : {};
    const merged: Record<string, unknown> = { ...info, ...props };
    const outPid = linkEndpoint(merged, [
      "output-port-id",
      "outputPortId",
      "link.output.port",
    ]);
    const inPid = linkEndpoint(merged, [
      "input-port-id",
      "inputPortId",
      "link.input.port",
    ]);
    if (outPid === undefined || inPid === undefined) continue;
    links.push({
      id: o.id,
      outputPortId: outPid,
      inputPortId: inPid,
    });
  }

  return {
    nodes: [...nodeById.values()].sort((a, b) => a.name.localeCompare(b.name)),
    ports: [...portById.values()],
    links,
  };
}

/** BFS over port-level adjacency (undirected) to highlight a signal path. */
export function reachablePortIds(
  graph: GraphModel,
  startPortId: number,
): Set<number> {
  const adj = new Map<number, number[]>();
  const add = (a: number, b: number) => {
    if (!adj.has(a)) adj.set(a, []);
    adj.get(a)!.push(b);
  };
  for (const l of graph.links) {
    add(l.outputPortId, l.inputPortId);
    add(l.inputPortId, l.outputPortId);
  }
  const seen = new Set<number>();
  const q: number[] = [startPortId];
  seen.add(startPortId);
  while (q.length) {
    const cur = q.shift()!;
    for (const nxt of adj.get(cur) ?? []) {
      if (!seen.has(nxt)) {
        seen.add(nxt);
        q.push(nxt);
      }
    }
  }
  return seen;
}
