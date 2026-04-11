<script setup lang="ts">
import { getBezierPath, type EdgeProps } from "@vue-flow/core";
import { computed } from "vue";

const props = defineProps<EdgeProps>();

const path = computed(() => {
  const [d] = getBezierPath({
    sourceX: props.sourceX,
    sourceY: props.sourceY,
    sourcePosition: props.sourcePosition,
    targetX: props.targetX,
    targetY: props.targetY,
    targetPosition: props.targetPosition,
  });
  return d;
});

const stroke = computed(() =>
  props.data?.highlight ? "#d4a62a" : "#7a5230",
);
const sw = computed(() => (props.data?.highlight ? 5 : 3.5));
</script>

<template>
  <path
    :id="id"
    class="vue-flow__edge-path tele-cord"
    :d="path"
    fill="none"
    :stroke="stroke"
    :stroke-width="sw"
    :marker-end="markerEnd"
  />
</template>

<style scoped>
.tele-cord {
  filter: drop-shadow(0 1px 1px rgba(0, 0, 0, 0.4));
}
</style>
