/** Raw pw-dump object (subset). */
export interface PwObject {
  id: number;
  type: string;
  version?: number;
  permissions?: string[] | string;
  info?: PwInfo;
}

export interface PwInfo {
  direction?: "input" | "output";
  props?: Record<string, string | number | undefined>;
  state?: string;
  /** Link endpoints (kebab-case from pw-dump). */
  "output-node-id"?: number;
  "output-port-id"?: number;
  "input-node-id"?: number;
  "input-port-id"?: number;
}

export interface PwNodeModel {
  id: number;
  name: string;
  description: string;
  mediaClass: string;
  isGoxlr: boolean;
}

export interface PwPortModel {
  id: number;
  nodeId: number;
  nodeName: string;
  portName: string;
  direction: "input" | "output";
  /** Full spec for pw-link, e.g. alsa_output...:monitor_FL */
  linkSpec: string;
  formatHint: string;
}

export interface PwLinkModel {
  id: number;
  outputPortId: number;
  inputPortId: number;
}

export interface GraphModel {
  nodes: PwNodeModel[];
  ports: PwPortModel[];
  links: PwLinkModel[];
}
