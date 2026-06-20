<script setup lang="ts">
import type { User } from "@/types";
import UserAvatar from "./UserAvatar.vue";
import { RouterLink } from "vue-router";
import { ref } from "vue";
import { api } from "@/api/client";

defineProps<{ user: User }>();
const emit = defineEmits<{ follow: [user: User] }>();

const following = ref(false);

async function toggleFollow(user: User) {
  following.value = true;
  try {
    const { user: updated } = await api.followUser(user.username);
    emit("follow", updated);
  } finally {
    following.value = false;
  }
}
</script>

<template>
  <div class="-mx-2 flex items-center gap-3 rounded-lg px-2 py-2.5 transition-colors hover:bg-white/[0.03]">
    <RouterLink :to="`/profile/${user.username}`">
      <UserAvatar :src="user.avatar" :alt="user.displayName" size="sm" />
    </RouterLink>
    <div class="min-w-0 flex-1">
      <RouterLink
        :to="`/profile/${user.username}`"
        class="block truncate text-sm font-semibold text-white hover:underline"
      >
        {{ user.displayName }}
      </RouterLink>
      <p class="truncate text-xs text-zinc-500">@{{ user.username }}</p>
    </div>
    <button
      v-if="user.isFollowing !== undefined"
      class="shrink-0 rounded-lg px-4 py-1.5 text-xs font-bold transition-all active:scale-95"
      :class="
        user.isFollowing
          ? 'border border-line text-zinc-400 hover:border-like/50 hover:text-like'
          : 'bg-white text-black hover:bg-zinc-200'
      "
      :disabled="following"
      @click="toggleFollow(user)"
    >
      {{ user.isFollowing ? "Following" : "Follow" }}
    </button>
  </div>
</template>
