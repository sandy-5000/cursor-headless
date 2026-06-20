<script setup lang="ts">
defineProps<{
  title: string;
  subtitle?: string;
}>();
</script>

<template>
  <header class="sticky-header safe-top px-4 py-3.5 sm:px-5">
    <h1 class="mt-5 text-[20px] font-extrabold tracking-tightest text-white sm:text-[22px]">
      {{ title }}
    </h1>
    <p v-if="subtitle" class="mt-0.5 text-[13px] text-zinc-500">{{ subtitle }}</p>
  </header>
</template>
