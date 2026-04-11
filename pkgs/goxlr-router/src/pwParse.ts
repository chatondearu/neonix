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

/**
 * Build a graph model from pw-dump JSON for Vue Flow.
 */
export function parsePwDump(jsonText: string): GraphModel {
  let arr: PwObject[];
  try {
    arr = JSON.parse(jsonText) as PwObject[];
  } catch {
    return { nodes: [], ports: [], links: [] };
  }
  if (!Array.isArray(arr)) return { nodes: [], ports: [], links: [] };

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
    const direction = o.info.direction === "input" ? "input" : "output";
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
    const outPid = linkEndpoint(info, ["output-port-id", "outputPortId"]);
    const inPid = linkEndpoint(info, ["input-port-id", "inputPortId"]);
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
