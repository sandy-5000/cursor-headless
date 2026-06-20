<template>
  <div>
    <div v-for="i in count" :key="i" class="feed-divider px-4 py-4 sm:px-5">
      <div class="flex gap-3">
        <div class="skel h-11 w-11 shrink-0 rounded-full" />
        <div class="flex-1 space-y-2.5 pt-1">
          <div class="skel h-3.5 w-32 rounded-full" />
          <div class="skel h-3 w-full max-w-[80%] rounded-full" />
          <div class="skel h-3 w-full max-w-[55%] rounded-full" />
          <div class="skel mt-3 h-40 w-full rounded-lg" />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
withDefaults(defineProps<{ count?: number }>(), { count: 4 });
</script>

<style scoped>
.skel {
  background: linear-gradient(
    90deg,
    rgb(27 27 31) 0%,
    rgb(38 38 43) 50%,
    rgb(27 27 31) 100%
  );
  background-size: 200% 100%;
  animation: shimmer 1.6s infinite linear;
}
@keyframes shimmer {
  0% {
    background-position: 200% 0;
  }
  100% {
    background-position: -200% 0;
  }
}
</style>
