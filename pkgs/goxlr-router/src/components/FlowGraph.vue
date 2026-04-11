<script setup lang="ts">
import { Background } from "@vue-flow/background";
import { Controls } from "@vue-flow/controls";
import { MiniMap } from "@vue-flow/minimap";
import {
  VueFlow,
  type Connection,
  type Edge,
  type EdgeTypesObject,
  type Node,
  type NodeTypesObject,
  type VueFlowStore,
} from "@vue-flow/core";
import { computed, markRaw, nextTick, shallowRef, watch } from "vue";
import type { GraphModel, PwPortModel } from "../pwTypes";
import SwitchboardNode from "./SwitchboardNode.vue";
import TelephoneEdge from "./TelephoneEdge.vue";

const props = defineProps<{
  graph: GraphModel;
  highlightPortIds: Set<number>;
  filter: string;
  goxlrOnly: boolean;
}>();

const emit = defineEmits<{
  connectPorts: [fromSpec: string, toSpec: string];
  disconnectLink: [fromSpec: string, toSpec: string];
  selectPort: [portId: number | null];
}>();

const nodeTypes = {
  switchboard: markRaw(SwitchboardNode),
} as unknown as NodeTypesObject;
const edgeTypes = {
  telephone: markRaw(TelephoneEdge),
} as unknown as EdgeTypesObject;

const vueFlowRef = shallowRef<VueFlowStore | null>(null);

const portById = computed(() => {
  const m = new Map<number, PwPortModel>();
  for (const p of props.graph.ports) m.set(p.id, p);
  return m;
});

const filteredNodes = computed(() => {
  const q = props.filter.trim().toLowerCase();
  return props.graph.nodes.filter((n) => {
    if (props.goxlrOnly && !n.isGoxlr) return false;
    if (!q) return true;
    const hay = `${n.name} ${n.description} ${n.mediaClass}`.toLowerCase();
    return hay.includes(q);
  });
});

const visibleNodeIds = computed(() => new Set(filteredNodes.value.map((n) => n.id)));

const flowNodes = computed((): Node[] => {
  const cols = 2;
  const xGap = 340;
  const yGap = 32;
  return filteredNodes.value.map((n, i) => {
    const ports = props.graph.ports.filter((p) => p.nodeId === n.id);
    const col = i % cols;
    const row = Math.floor(i / cols);
    return {
      id: `n-${n.id}`,
      type: "switchboard",
      position: { x: col * xGap, y: row * yGap },
      data: {
        model: n,
        ports,
        highlightPortIds: props.highlightPortIds,
        onPortSelect: (pid: number) => emit("selectPort", pid),
      },
    };
  });
});

const flowEdges = computed((): Edge[] => {
  const out: Edge[] = [];
  const pmap = portById.value;
  for (const l of props.graph.links) {
    const op = pmap.get(l.outputPortId);
    const ip = pmap.get(l.inputPortId);
    if (!op || !ip) continue;
    if (!visibleNodeIds.value.has(op.nodeId)) continue;
    if (!visibleNodeIds.value.has(ip.nodeId)) continue;
    const hi =
      props.highlightPortIds.has(l.outputPortId) ||
      props.highlightPortIds.has(l.inputPortId);
    out.push({
      id: `e-${l.id}`,
      type: "telephone",
      source: `n-${op.nodeId}`,
      target: `n-${ip.nodeId}`,
      sourceHandle: `h-${op.id}`,
      targetHandle: `h-${ip.id}`,
      data: {
        highlight: hi,
        linkSpec: `${op.portName} → ${ip.portName}`,
      },
    });
  }
  return out;
});

function onInit(api: VueFlowStore) {
  vueFlowRef.value = api;
  api.fitView({ padding: 0.15, duration: 200 });
}

watch(
  () => [flowNodes.value.length, props.filter, props.goxlrOnly],
  () => {
    nextTick(() => {
      vueFlowRef.value?.fitView({ padding: 0.15, duration: 200 });
    });
  },
);

function handleConnect(c: Connection) {
  if (!c.sourceHandle || !c.targetHandle) return;
  const outId = Number(String(c.sourceHandle).replace(/^h-/, ""));
  const inId = Number(String(c.targetHandle).replace(/^h-/, ""));
  const op = portById.value.get(outId);
  const ip = portById.value.get(inId);
  if (!op || !ip) return;
  if (op.direction !== "output" || ip.direction !== "input") return;
  if (
    !confirm(
      `Connect audio link?\n\n${op.linkSpec}\n  →\n${ip.linkSpec}`,
    )
  ) {
    return;
  }
  emit("connectPorts", op.linkSpec, ip.linkSpec);
}

function handleEdgeClick(ev: { edge: Edge }) {
  const edge = ev.edge;
  const lid = Number(String(edge.id).replace(/^e-/, ""));
  const link = props.graph.links.find((x) => x.id === lid);
  if (!link) return;
  const op = portById.value.get(link.outputPortId);
  const ip = portById.value.get(link.inputPortId);
  if (!op || !ip) return;
  if (
    !confirm(
      `Disconnect this link?\n\n${op.linkSpec}\n  →\n${ip.linkSpec}`,
    )
  ) {
    return;
  }
  emit("disconnectLink", op.linkSpec, ip.linkSpec);
}
</script>

<template>
  <div class="flow-wrap" @click.self="emit('selectPort', null)">
    <VueFlow
      :nodes="flowNodes"
      :edges="flowEdges"
      :node-types="nodeTypes"
      :edge-types="edgeTypes"
      :default-edge-options="{ type: 'telephone' }"
      fit-view-on-init
      class="switchboard-flow"
      @init="onInit"
      @connect="handleConnect"
      @edge-click="handleEdgeClick"
      @node-click="emit('selectPort', null)"
    >
      <Background pattern-color="#3d3428" :gap="20" />
      <Controls />
      <MiniMap
        class="minimap"
        :node-color="() => '#5c4d3a'"
        mask-color="rgba(20, 16, 12, 0.85)"
      />
    </VueFlow>
  </div>
</template>

<style>
@import "@vue-flow/core/dist/style.css";
@import "@vue-flow/core/dist/theme-default.css";
@import "@vue-flow/controls/dist/style.css";
@import "@vue-flow/minimap/dist/style.css";

.flow-wrap {
  width: 100%;
  height: 100%;
  min-height: 420px;
  background: radial-gradient(ellipse at center, #252018 0%, #120e0a 100%);
}
.switchboard-flow {
  width: 100%;
  height: 100%;
}
.minimap {
  background: #1a1510 !important;
}
</style>
