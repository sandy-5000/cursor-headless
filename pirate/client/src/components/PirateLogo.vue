<script setup lang="ts">
import { Skull } from "@lucide/vue";
</script>

<template>
  <div
    class="flex items-center justify-center rounded-lg text-white shadow-glow"
    style="background-image: linear-gradient(135deg, #9d86ff 0%, #7c5cff 55%, #4f46e5 100%)"
  >
    <Skull class="h-[60%] w-[60%]" :stroke-width="2" />
  </div>
</template>
