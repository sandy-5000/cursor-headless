<script setup lang="ts">
import { RouterLink } from "vue-router";
import AppLayout from "@/layouts/AppLayout.vue";
import PageHeader from "@/components/PageHeader.vue";
import PostCard from "@/components/PostCard.vue";
import FeedSkeleton from "@/components/FeedSkeleton.vue";
import EmptyState from "@/components/EmptyState.vue";
import RightRail from "@/components/RightRail.vue";
import { ref, onMounted } from "vue";
import { api } from "@/api/client";
import type { Post } from "@/types";

const posts = ref<Post[]>([]);
const loading = ref(true);
const page = ref(1);
const hasMore = ref(false);
const loadingMore = ref(false);

async function loadFeed(reset = false) {
  if (reset) {
    page.value = 1;
    loading.value = true;
  } else {
    loadingMore.value = true;
  }

  try {
    const res = await api.feed(page.value);
    posts.value = reset ? res.posts : [...posts.value, ...res.posts];
    hasMore.value = res.hasMore;
  } finally {
    loading.value = false;
    loadingMore.value = false;
  }
}

function updatePost(updated: Post) {
  const idx = posts.value.findIndex((p) => p._id === updated._id);
  if (idx !== -1) posts.value[idx] = updated;
}

async function loadMore() {
  page.value++;
  await loadFeed();
}

onMounted(() => loadFeed(true));
</script>

<template>
  <AppLayout>
    <div>
      <PageHeader title="Home" subtitle="Posts from people you follow" />

      <FeedSkeleton v-if="loading" />

      <template v-else>
        <EmptyState
          v-if="posts.length === 0"
          title="Your feed is empty"
          description="Follow people or explore to see posts here."
        >
          <template #action>
            <RouterLink to="/explore" class="btn-accent px-6">Explore</RouterLink>
          </template>
        </EmptyState>

        <PostCard
          v-for="post in posts"
          :key="post._id"
          :post="post"
          @update="updatePost"
          @deleted="posts = posts.filter(p => p._id !== post._id)"
        />

        <div v-if="hasMore" class="py-6 text-center">
          <button class="btn-secondary" :disabled="loadingMore" @click="loadMore">
            {{ loadingMore ? "Loading..." : "Show more" }}
          </button>
        </div>
      </template>
    </div>

    <template #sidebar>
      <RightRail />
    </template>
  </AppLayout>
</template>
