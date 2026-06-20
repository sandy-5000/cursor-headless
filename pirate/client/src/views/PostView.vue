<script setup lang="ts">
import { ref, onMounted } from "vue";
import { useRoute, RouterLink } from "vue-router";
import AppLayout from "@/layouts/AppLayout.vue";
import PostCard from "@/components/PostCard.vue";
import FeedSkeleton from "@/components/FeedSkeleton.vue";
import RightRail from "@/components/RightRail.vue";
import { api } from "@/api/client";
import type { Post } from "@/types";
import { useAuthStore } from "@/stores/auth";
import { ArrowLeft } from "@lucide/vue";

const route = useRoute();
const auth = useAuthStore();
const post = ref<Post | null>(null);
const loading = ref(true);
const comment = ref("");
const submitting = ref(false);

async function loadPost() {
  loading.value = true;
  try {
    const res = await api.getPost(route.params.id as string);
    post.value = res.post;
  } finally {
    loading.value = false;
  }
}

async function submitComment() {
  if (!comment.value.trim() || !post.value) return;
  submitting.value = true;
  try {
    const { post: updated } = await api.addComment(post.value._id, comment.value.trim());
    post.value = updated;
    comment.value = "";
  } finally {
    submitting.value = false;
  }
}

onMounted(loadPost);
</script>

<template>
  <AppLayout>
    <div>
      <header class="sticky-header safe-top flex items-center gap-4 px-4 py-3 sm:px-5">
        <RouterLink to="/" class="rounded-lg p-2 text-zinc-400 transition-colors hover:bg-zinc-800 hover:text-white">
          <ArrowLeft class="h-5 w-5" :stroke-width="2" />
        </RouterLink>
        <span class="text-lg font-extrabold tracking-tightest text-white">Post</span>
      </header>

      <FeedSkeleton v-if="loading" :count="1" />

      <template v-else-if="post">
        <PostCard :post="post" :bordered="false" @update="(p) => (post = p)" />

        <div class="feed-divider px-4 py-5 sm:px-5">
          <h2 class="mb-4 text-sm font-semibold text-zinc-400">
            {{ post.commentCount }} {{ post.commentCount === 1 ? "Reply" : "Replies" }}
          </h2>

          <div v-if="auth.isLoggedIn" class="mb-6 flex gap-3">
            <input
              v-model="comment"
              type="text"
              placeholder="Write a reply..."
              class="input-field flex-1 py-2.5 text-sm"
              @keyup.enter="submitComment"
            />
            <button
              class="btn-accent shrink-0 px-5"
              :disabled="submitting || !comment.trim()"
              @click="submitComment"
            >
              Reply
            </button>
          </div>

          <div v-if="post.comments.length === 0" class="py-8 text-center text-sm text-zinc-600">
            No replies yet. Start the conversation.
          </div>

          <div v-else class="space-y-3">
            <div
              v-for="c in [...post.comments].reverse()"
              :key="c._id"
              class="rounded-lg bg-surface-2 px-4 py-3 ring-1 ring-zinc-800/80"
            >
              <p class="text-[15px] text-zinc-200">{{ c.content }}</p>
              <p class="mt-1.5 text-xs text-zinc-600">
                {{ new Date(c.createdAt).toLocaleString() }}
              </p>
            </div>
          </div>
        </div>
      </template>
    </div>

    <template #sidebar>
      <RightRail />
    </template>
  </AppLayout>
</template>
