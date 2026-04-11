<script setup lang="ts">
defineProps<{
  playback: string;
  capture: string;
  error?: string;
}>();
</script>

<template>
  <aside class="alsa">
    <h3>ALSA hardware</h3>
    <p class="hint">
      PipeWire nodes often mirror these cards. Match USB vendor names with
      <code>alsa_output.*</code> / <code>alsa_input.*</code> node names in the graph.
    </p>
    <p v-if="error" class="err">{{ error }}</p>
    <section>
      <h4>Playback (aplay -l)</h4>
      <pre>{{ playback || "—" }}</pre>
    </section>
    <section>
      <h4>Capture (arecord -l)</h4>
      <pre>{{ capture || "—" }}</pre>
    </section>
  </aside>
</template>

<style scoped>
.alsa {
  width: 320px;
  flex-shrink: 0;
  padding: 12px;
  background: linear-gradient(180deg, #1e1a14 0%, #14110e 100%);
  border-left: 3px solid #5c4d3a;
  font-size: 11px;
  color: #d8ccb8;
  overflow: auto;
  max-height: 100%;
}
h3 {
  margin: 0 0 8px;
  font-size: 14px;
  letter-spacing: 0.04em;
}
h4 {
  margin: 12px 0 4px;
  font-size: 11px;
  opacity: 0.85;
}
.hint {
  margin: 0 0 8px;
  line-height: 1.35;
  opacity: 0.8;
}
pre {
  margin: 0;
  padding: 8px;
  background: rgba(0, 0, 0, 0.35);
  border: 1px solid #3d3428;
  border-radius: 4px;
  white-space: pre-wrap;
  word-break: break-word;
  font-size: 10px;
  line-height: 1.3;
}
.err {
  color: #e07060;
  margin: 0 0 8px;
}
code {
  font-size: 10px;
  background: rgba(0, 0, 0, 0.3);
  padding: 1px 4px;
  border-radius: 2px;
}
</style>
