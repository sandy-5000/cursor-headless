<script setup lang="ts">
import { Clock } from "@lucide/vue";

defineProps<{
  title: string;
  description?: string;
}>();
</script>

<template>
  <div class="flex flex-col items-center justify-center px-6 py-20 text-center animate-fade-in">
    <div
      class="mb-5 flex h-16 w-16 items-center justify-center rounded-lg border border-white/[0.06] bg-gradient-to-br from-accent/20 via-surface-3 to-surface-2 shadow-elevated"
    >
      <slot name="icon">
        <Clock class="h-7 w-7 text-accent-light" :stroke-width="1.5" />
      </slot>
    </div>
    <h2 class="text-lg font-bold tracking-tightest text-white">{{ title }}</h2>
    <p v-if="description" class="mt-2 max-w-xs text-[15px] leading-relaxed text-zinc-500">
      {{ description }}
    </p>
    <div v-if="$slots.action" class="mt-6">
      <slot name="action" />
    </div>
  </div>
</template>
