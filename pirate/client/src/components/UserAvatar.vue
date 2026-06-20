<script setup lang="ts">
defineProps<{
  src: string;
  alt: string;
  size?: "xs" | "sm" | "md" | "lg" | "xl" | "2xl";
}>();

const sizes = {
  xs: "w-8 h-8",
  sm: "w-10 h-10",
  md: "w-11 h-11",
  lg: "w-16 h-16",
  xl: "w-[88px] h-[88px]",
  "2xl": "w-28 h-28",
};
</script>

<template>
  <img
    :src="src"
    :alt="alt"
    :class="[
      sizes[size ?? 'md'],
      'rounded-full object-cover bg-surface-3 ring-1 ring-line shrink-0',
    ]"
  />
</template>
