<script setup lang="ts">
import { ref, onMounted } from "vue";
import { RouterLink } from "vue-router";
import SearchBar from "@/components/SearchBar.vue";
import SuggestedUser from "@/components/SuggestedUser.vue";
import { api } from "@/api/client";
import type { User } from "@/types";
import { useAuthStore } from "@/stores/auth";

const auth = useAuthStore();
const search = ref("");
const suggested = ref<User[]>([]);
const loading = ref(true);

onMounted(async () => {
  if (!auth.isLoggedIn) {
    loading.value = false;
    return;
  }
  try {
    const { users } = await api.suggestedUsers();
    suggested.value = users;
  } finally {
    loading.value = false;
  }
});

function onFollow(u: User) {
  const i = suggested.value.findIndex((s) => s._id === u._id);
  if (i !== -1) suggested.value[i] = u;
}
</script>

<template>
  <div class="space-y-4">
    <SearchBar v-model="search" />

    <div v-if="auth.isLoggedIn" class="card p-4">
      <h2 class="mb-1 px-1 text-base font-extrabold tracking-tightest text-white">Who to follow</h2>

      <div v-if="loading" class="space-y-3 py-2">
        <div v-for="i in 3" :key="i" class="flex items-center gap-3">
          <div class="h-10 w-10 rounded-full bg-surface-3" />
          <div class="flex-1 space-y-2">
            <div class="h-3 w-24 rounded-full bg-surface-3" />
            <div class="h-2.5 w-16 rounded-full bg-surface-3/70" />
          </div>
        </div>
      </div>

      <p v-else-if="!suggested.length" class="px-1 py-2 text-sm text-zinc-500">
        You're following everyone already.
      </p>

      <SuggestedUser
        v-for="user in suggested"
        :key="user._id"
        :user="user"
        @follow="onFollow"
      />
    </div>

    <div v-else class="card p-5 text-center">
      <p class="text-sm text-zinc-400">Sign in to follow people and join the conversation.</p>
      <RouterLink to="/login" class="btn-primary mt-4 w-full py-2.5">Sign in</RouterLink>
    </div>

    <p class="px-2 text-xs leading-relaxed text-zinc-600">
      Pirate · Built for small crews · {{ new Date().getFullYear() }}
    </p>
  </div>
</template>
