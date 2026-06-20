<script setup lang="ts">
import type { Post } from "@/types";
import { RouterLink } from "vue-router";
import UserAvatar from "./UserAvatar.vue";
import { ref } from "vue";
import { api } from "@/api/client";
import { useAuthStore } from "@/stores/auth";
import { Trash2, Heart, MessageCircle, Share2, Check } from "@lucide/vue";

const props = defineProps<{ post: Post; bordered?: boolean }>();
const emit = defineEmits<{ update: [post: Post]; deleted: [] }>();

const auth = useAuthStore();
const liking = ref(false);
const likeBurst = ref(false);
const copied = ref(false);

function timeAgo(date: string) {
  const seconds = Math.floor((Date.now() - new Date(date).getTime()) / 1000);
  if (seconds < 60) return "now";
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m`;
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}h`;
  if (seconds < 604800) return `${Math.floor(seconds / 86400)}d`;
  return new Date(date).toLocaleDateString(undefined, { month: "short", day: "numeric" });
}

async function toggleLike() {
  if (!auth.isLoggedIn) return;
  liking.value = true;
  if (!props.post.liked) {
    likeBurst.value = true;
    setTimeout(() => (likeBurst.value = false), 350);
  }
  try {
    const { post } = await api.toggleLike(props.post._id);
    emit("update", post);
  } finally {
    liking.value = false;
  }
}

async function share() {
  const url = `${window.location.origin}/post/${props.post._id}`;
  try {
    await navigator.clipboard.writeText(url);
    copied.value = true;
    setTimeout(() => (copied.value = false), 1600);
  } catch {
    /* ignore */
  }
}

async function deletePost() {
  if (!confirm("Delete this post?")) return;
  await api.deletePost(props.post._id);
  emit("deleted");
}
</script>

<template>
  <article
    class="group relative px-4 py-4 transition-colors duration-200 hover:bg-white/[0.02] sm:px-5"
    :class="bordered !== false ? 'feed-divider' : ''"
  >
    <div class="flex gap-3">
      <div class="flex flex-col items-center">
        <RouterLink :to="`/profile/${post.author.username}`" class="shrink-0">
          <UserAvatar :src="post.author.avatar" :alt="post.author.displayName" size="md" />
        </RouterLink>
        <div class="mt-2 w-px flex-1 bg-line/50 group-last:hidden" />
      </div>

      <div class="min-w-0 flex-1 pb-1">
        <div class="flex items-center gap-1.5">
          <RouterLink
            :to="`/profile/${post.author.username}`"
            class="font-semibold text-[15px] text-white hover:underline truncate"
          >
            {{ post.author.displayName }}
          </RouterLink>
          <span class="text-zinc-600 text-[14px] truncate">@{{ post.author.username }}</span>
          <span class="text-zinc-700">·</span>
          <RouterLink
            :to="`/post/${post._id}`"
            class="text-[14px] text-zinc-500 hover:text-zinc-300 transition-colors shrink-0"
          >
            {{ timeAgo(post.createdAt) }}
          </RouterLink>

          <button
            v-if="auth.user?._id === post.userId"
            class="ml-auto -mr-1 rounded-md p-1.5 text-zinc-600 opacity-0 transition-all hover:bg-like/10 hover:text-like group-hover:opacity-100"
            title="Delete"
            @click="deletePost"
          >
            <Trash2 class="h-4 w-4" :stroke-width="2" />
          </button>
        </div>

        <RouterLink v-if="post.content" :to="`/post/${post._id}`" class="mt-1 block">
          <p class="text-[15px] leading-[1.5] text-zinc-100 whitespace-pre-wrap break-words">
            {{ post.content }}
          </p>
        </RouterLink>

        <RouterLink
          v-if="post.imageUrl"
          :to="`/post/${post._id}`"
          class="mt-3 block overflow-hidden rounded-lg border border-line/70"
        >
          <img
            :src="post.imageUrl"
            alt=""
            class="max-h-[460px] w-full bg-surface-3 object-cover transition-transform duration-500 group-hover:scale-[1.02]"
            loading="lazy"
          />
        </RouterLink>

        <div class="-ml-2.5 mt-2 flex items-center gap-1">
          <button
            class="action-btn hover:bg-like/10"
            :class="post.liked ? 'text-like' : 'hover:text-like'"
            :disabled="liking || !auth.isLoggedIn"
            @click.stop="toggleLike"
          >
            <Heart
              class="h-[19px] w-[19px] transition-transform"
              :class="{ 'animate-pop': likeBurst }"
              :fill="post.liked ? 'currentColor' : 'none'"
              :stroke-width="2"
            />
            <span v-if="post.likeCount" class="tabular-nums">{{ post.likeCount }}</span>
          </button>

          <RouterLink :to="`/post/${post._id}`" class="action-btn hover:bg-accent/10 hover:text-accent-light">
            <MessageCircle class="h-[19px] w-[19px]" :stroke-width="2" />
            <span v-if="post.commentCount" class="tabular-nums">{{ post.commentCount }}</span>
          </RouterLink>

          <button class="action-btn hover:bg-white/5 hover:text-zinc-200" @click.stop="share">
            <Share2 v-if="!copied" class="h-[19px] w-[19px]" :stroke-width="2" />
            <span v-else class="flex items-center gap-1 text-accent-light">
              <Check class="h-[18px] w-[18px]" :stroke-width="2.2" />
              Copied
            </span>
          </button>
        </div>
      </div>
    </div>
  </article>
</template>
