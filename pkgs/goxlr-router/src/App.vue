<script setup lang="ts">
import { invoke } from "@tauri-apps/api/core";
import { computed, onMounted, onUnmounted, ref, shallowRef } from "vue";
import AlsaPanel from "./components/AlsaPanel.vue";
import FlowGraph from "./components/FlowGraph.vue";
import { parsePwDump, reachablePortIds } from "./pwParse";
import type { GraphModel } from "./pwTypes";

const rawDump = ref("");
const lastError = ref<string | undefined>();
const pollMs = ref(2000);
const filterText = ref("");
const goxlrOnly = ref(false);
const selectedPortId = ref<number | null>(null);

const alsaPlayback = ref("");
const alsaCapture = ref("");
const alsaError = ref<string | undefined>();

const graph = computed<GraphModel>(() => parsePwDump(rawDump.value));

const highlightPortIds = computed(() => {
  if (selectedPortId.value === null) return new Set<number>();
  return reachablePortIds(graph.value, selectedPortId.value);
});

let pollTimer: ReturnType<typeof setInterval> | null = null;
const refreshing = shallowRef(false);

async function refreshPw() {
  refreshing.value = true;
  try {
    const s = await invoke<string>("get_pw_dump");
    rawDump.value = s;
    lastError.value = undefined;
  } catch (e) {
    lastError.value = String(e);
  } finally {
    refreshing.value = false;
  }
}

async function refreshAlsa() {
  try {
    alsaPlayback.value = await invoke<string>("get_alsa_playback");
    alsaCapture.value = await invoke<string>("get_alsa_capture");
    alsaError.value = undefined;
  } catch (e) {
    alsaError.value = String(e);
  }
}

async function refreshAll() {
  await Promise.all([refreshPw(), refreshAlsa()]);
}

function restartPoll() {
  if (pollTimer) clearInterval(pollTimer);
  pollTimer = setInterval(refreshAll, Math.max(500, pollMs.value));
}

function onSelectPort(id: number | null) {
  selectedPortId.value = id;
}

async function onConnect(fromSpec: string, toSpec: string) {
  try {
    await invoke("pw_link_connect", { fromSpec, toSpec });
    await refreshPw();
  } catch (e) {
    alert(`pw-link failed: ${e}`);
  }
}

async function onDisconnect(fromSpec: string, toSpec: string) {
  try {
    await invoke("pw_link_disconnect", { fromSpec, toSpec });
    await refreshPw();
  } catch (e) {
    alert(`pw-link -d failed: ${e}`);
  }
}

onMounted(async () => {
  await refreshAll();
  restartPoll();
});

onUnmounted(() => {
  if (pollTimer) clearInterval(pollTimer);
});

function onPollInput() {
  restartPoll();
}
</script>

<template>
  <div class="app">
    <header class="bar">
      <h1>goxlr-router</h1>
      <span class="sub">PipeWire switchboard</span>
      <label class="lbl">
        Poll (ms)
        <input
          v-model.number="pollMs"
          type="number"
          min="500"
          step="100"
          @change="onPollInput"
        />
      </label>
      <button type="button" :disabled="refreshing" @click="refreshAll">
        Refresh now
      </button>
      <label class="lbl chk">
        <input v-model="goxlrOnly" type="checkbox" />
        GoXLR-related only
      </label>
      <input
        v-model="filterText"
        class="search"
        type="search"
        placeholder="Filter nodes…"
      />
      <button type="button" @click="onSelectPort(null)">Clear path highlight</button>
    </header>
    <p v-if="lastError" class="global-err">{{ lastError }}</p>
    <div class="main">
      <div class="graph-pane">
        <FlowGraph
          :graph="graph"
          :highlight-port-ids="highlightPortIds"
          :filter="filterText"
          :goxlr-only="goxlrOnly"
          @connect-ports="onConnect"
          @disconnect-link="onDisconnect"
          @select-port="onSelectPort"
        />
      </div>
      <AlsaPanel
        :playback="alsaPlayback"
        :capture="alsaCapture"
        :error="alsaError"
      />
    </div>
    <footer class="foot">
      Click a jack to highlight all linked ports. Drag from an output (right) to
      an input (left) to run <code>pw-link</code>. Click a cable to disconnect.
    </footer>
  </div>
</template>

<style>
*,
*::before,
*::after {
  box-sizing: border-box;
}
html,
body,
#app {
  margin: 0;
  height: 100%;
}
.app {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: #0f0c09;
  color: #e8dcc8;
  font-family: "Segoe UI", system-ui, sans-serif;
}
.bar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px 16px;
  padding: 10px 14px;
  background: linear-gradient(180deg, #2a2218 0%, #1a1510 100%);
  border-bottom: 2px solid #5c4d3a;
}
.bar h1 {
  margin: 0;
  font-size: 18px;
  font-weight: 700;
}
.sub {
  opacity: 0.65;
  font-size: 12px;
}
.lbl {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
}
.lbl.chk input {
  margin: 0;
}
.lbl input[type="number"] {
  width: 72px;
  padding: 4px 6px;
  background: #120e0a;
  border: 1px solid #5c4d3a;
  color: inherit;
  border-radius: 3px;
}
.search {
  min-width: 160px;
  padding: 6px 10px;
  background: #120e0a;
  border: 1px solid #5c4d3a;
  color: inherit;
  border-radius: 3px;
}
button {
  padding: 6px 12px;
  background: #5c4d3a;
  border: 1px solid #7a6a52;
  color: #f5ecd8;
  border-radius: 4px;
  cursor: pointer;
  font-size: 12px;
}
button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
.global-err {
  margin: 0;
  padding: 8px 14px;
  background: #3a1818;
  color: #f0a0a0;
  font-size: 12px;
}
.main {
  flex: 1;
  display: flex;
  min-height: 0;
}
.graph-pane {
  flex: 1;
  min-width: 0;
  min-height: 0;
}
.foot {
  padding: 8px 14px;
  font-size: 11px;
  opacity: 0.75;
  border-top: 1px solid #3d3428;
}
.foot code {
  font-size: 10px;
  background: rgba(0, 0, 0, 0.35);
  padding: 1px 5px;
  border-radius: 2px;
}
</style>
