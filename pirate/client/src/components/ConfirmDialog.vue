<script setup lang="ts">
defineProps<{
  open: boolean;
  title: string;
  message?: string;
  confirmText?: string;
  cancelText?: string;
  destructive?: boolean;
  busy?: boolean;
}>();

const emit = defineEmits<{ confirm: []; cancel: [] }>();
</script>

<template>
  <Teleport to="body">
    <Transition name="confirm">
      <div
        v-if="open"
        class="fixed inset-0 z-[100] flex items-center justify-center p-4"
        role="dialog"
        aria-modal="true"
      >
        <div class="absolute inset-0 bg-black/60 backdrop-blur-sm" @click="emit('cancel')" />

        <div class="relative z-10 w-full max-w-sm card-glow p-6 animate-scale-in">
          <h3 class="text-lg font-bold tracking-tightest text-white">{{ title }}</h3>
          <p v-if="message" class="mt-2 text-sm leading-relaxed text-zinc-400">{{ message }}</p>

          <div class="mt-6 flex justify-end gap-2">
            <button class="btn-secondary" :disabled="busy" @click="emit('cancel')">
              {{ cancelText ?? "Cancel" }}
            </button>
            <button
              class="inline-flex items-center justify-center gap-2 rounded-lg px-5 py-2 text-sm font-semibold text-white transition-all active:scale-[0.96] disabled:opacity-40 disabled:pointer-events-none"
              :class="destructive ? 'bg-like hover:bg-like/90' : 'bg-accent hover:bg-accent-light'"
              :disabled="busy"
              @click="emit('confirm')"
            >
              {{ confirmText ?? "Confirm" }}
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.confirm-enter-active,
.confirm-leave-active {
  transition: opacity 0.18s ease;
}
.confirm-enter-from,
.confirm-leave-to {
  opacity: 0;
}
</style>
