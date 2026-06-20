<script setup lang="ts">
import AppLayout from "@/layouts/AppLayout.vue";
import PageHeader from "@/components/PageHeader.vue";
import PostCard from "@/components/PostCard.vue";
import FeedSkeleton from "@/components/FeedSkeleton.vue";
import SearchBar from "@/components/SearchBar.vue";
import RightRail from "@/components/RightRail.vue";
import { ref, onMounted } from "vue";
import { api } from "@/api/client";
import type { Post } from "@/types";

const posts = ref<Post[]>([]);
const loading = ref(true);
const page = ref(1);
const hasMore = ref(false);
const loadingMore = ref(false);
const searchQuery = ref("");

async function loadExplore(reset = false) {
  if (reset) {
    page.value = 1;
    loading.value = true;
  } else {
    loadingMore.value = true;
  }

  try {
    const res = await api.explore(page.value);
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
  await loadExplore();
}

onMounted(() => loadExplore(true));
</script>

<template>
  <AppLayout>
    <div>
      <PageHeader title="Explore" subtitle="Discover what's happening" />

      <div class="border-b border-line/60 px-4 py-3 sm:px-5 xl:hidden">
        <SearchBar v-model="searchQuery" />
      </div>

      <FeedSkeleton v-if="loading" />

      <template v-else>
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
