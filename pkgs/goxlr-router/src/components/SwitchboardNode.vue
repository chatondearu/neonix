<script setup lang="ts">
import { Handle, Position } from "@vue-flow/core";
import { computed } from "vue";
import type { PwNodeModel, PwPortModel } from "../pwTypes";

const props = defineProps<{
  data: {
    model: PwNodeModel;
    ports: PwPortModel[];
    highlightPortIds: Set<number>;
    onPortSelect?: (portId: number) => void;
  };
}>();

function onJackClick(portId: number) {
  props.data.onPortSelect?.(portId);
}

const inPorts = computed(() =>
  props.data.ports.filter((p) => p.direction === "input"),
);
const outPorts = computed(() =>
  props.data.ports.filter((p) => p.direction === "output"),
);

function handleId(portId: number): string {
  return `h-${portId}`;
}

function jackClass(portId: number): string {
  return props.data.highlightPortIds.has(portId) ? "jack hot" : "jack";
}
</script>

<template>
  <div class="sb-node" :class="{ goxlr: data.model.isGoxlr }">
    <div class="sb-title" :title="data.model.description">
      {{ data.model.name }}
    </div>
    <div v-if="data.model.mediaClass" class="sb-sub">
      {{ data.model.mediaClass }}
    </div>
    <div class="sb-body">
      <div class="sb-col in">
        <div
          v-for="p in inPorts"
          :key="p.id"
          class="jack-row"
          :title="`${p.linkSpec}${p.formatHint ? ' · ' + p.formatHint : ''}`"
          @click.stop="onJackClick(p.id)"
        >
          <Handle
            :id="handleId(p.id)"
            type="target"
            :position="Position.Left"
            :class="jackClass(p.id)"
          />
          <span class="lbl in">{{ p.portName }}</span>
        </div>
      </div>
      <div class="sb-col out">
        <div
          v-for="p in outPorts"
          :key="p.id"
          class="jack-row"
          :title="`${p.linkSpec}${p.formatHint ? ' · ' + p.formatHint : ''}`"
          @click.stop="onJackClick(p.id)"
        >
          <span class="lbl out">{{ p.portName }}</span>
          <Handle
            :id="handleId(p.id)"
            type="source"
            :position="Position.Right"
            :class="jackClass(p.id)"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.sb-node {
  min-width: 220px;
  background: linear-gradient(165deg, #2a2418 0%, #1a1510 100%);
  border: 3px solid #5c4d3a;
  border-radius: 6px;
  box-shadow:
    inset 0 1px 0 rgba(255, 220, 160, 0.12),
    0 4px 14px rgba(0, 0, 0, 0.45);
  font-family: "Segoe UI", system-ui, sans-serif;
  font-size: 11px;
  color: #e8dcc8;
}
.sb-node.goxlr {
  border-color: #8b6914;
  box-shadow:
    inset 0 1px 0 rgba(255, 200, 80, 0.15),
    0 0 0 1px rgba(255, 180, 60, 0.25),
    0 4px 16px rgba(40, 20, 0, 0.5);
}
.sb-title {
  padding: 6px 8px;
  font-weight: 600;
  letter-spacing: 0.02em;
  border-bottom: 1px solid rgba(90, 75, 55, 0.6);
  background: rgba(0, 0, 0, 0.25);
  max-width: 280px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.sb-sub {
  padding: 2px 8px 4px;
  font-size: 9px;
  opacity: 0.75;
  border-bottom: 1px solid rgba(90, 75, 55, 0.35);
}
.sb-body {
  display: flex;
  gap: 8px;
  padding: 6px 4px 8px;
}
.sb-col {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.jack-row {
  display: flex;
  align-items: center;
  gap: 4px;
  min-height: 22px;
}
.lbl {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.lbl.in {
  text-align: left;
  padding-left: 2px;
}
.lbl.out {
  text-align: right;
  padding-right: 2px;
}
:deep(.jack) {
  width: 14px !important;
  height: 14px !important;
  border-radius: 50%;
  background: radial-gradient(circle at 30% 30%, #c9a227, #4a3a12 70%);
  border: 2px solid #2a2218;
  box-shadow:
    inset 0 1px 2px rgba(255, 255, 200, 0.35),
    0 1px 2px rgba(0, 0, 0, 0.6);
}
:deep(.jack.hot) {
  background: radial-gradient(circle at 30% 30%, #ffe566, #a67c00 70%);
  box-shadow:
    0 0 8px rgba(255, 200, 80, 0.7),
    inset 0 1px 2px rgba(255, 255, 220, 0.5);
}
</style>
