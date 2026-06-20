<script setup lang="ts">
import { ref, watch } from "vue";
import { RouterLink } from "vue-router";
import { api } from "@/api/client";
import type { User } from "@/types";
import { Search } from "@lucide/vue";

const query = defineModel<string>({ default: "" });
const results = ref<User[]>([]);
const open = ref(false);
let timer: ReturnType<typeof setTimeout>;

watch(query, (q) => {
  clearTimeout(timer);
  if (!q.trim()) {
    results.value = [];
    open.value = false;
    return;
  }
  timer = setTimeout(async () => {
    const { users } = await api.searchUsers(q.trim());
    results.value = users;
    open.value = users.length > 0;
  }, 300);
});

function close() {
  open.value = false;
}

function onBlur() {
  window.setTimeout(close, 200);
}
</script>

<template>
  <div class="relative">
    <div class="relative">
      <Search
        class="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-zinc-600"
        :stroke-width="2"
      />
      <input
        v-model="query"
        type="search"
        placeholder="Search people"
        class="input-field pl-11 py-2.5 text-sm"
        @focus="query.trim() && results.length && (open = true)"
        @blur="onBlur"
      />
    </div>

    <div
      v-if="open"
      class="absolute z-50 top-full mt-2 w-full card overflow-hidden shadow-soft animate-fade-in"
    >
      <RouterLink
        v-for="user in results"
        :key="user._id"
        :to="`/profile/${user.username}`"
        class="flex items-center gap-3 px-4 py-3 transition-colors hover:bg-white/5"
        @mousedown.prevent
      >
        <img :src="user.avatar" class="h-9 w-9 rounded-full bg-surface-3 ring-1 ring-line" :alt="user.displayName" />
        <div class="min-w-0">
          <p class="truncate text-sm font-semibold text-white">{{ user.displayName }}</p>
          <p class="truncate text-xs text-zinc-500">@{{ user.username }}</p>
        </div>
      </RouterLink>
    </div>
  </div>
</template>
