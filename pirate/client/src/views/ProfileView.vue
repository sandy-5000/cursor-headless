<script setup lang="ts">
import { RouterLink } from "vue-router";
import { ref, watch, computed } from "vue";
import { useRoute, useRouter } from "vue-router";
import AppLayout from "@/layouts/AppLayout.vue";
import PostCard from "@/components/PostCard.vue";
import UserAvatar from "@/components/UserAvatar.vue";
import FeedSkeleton from "@/components/FeedSkeleton.vue";
import EmptyState from "@/components/EmptyState.vue";
import RightRail from "@/components/RightRail.vue";
import { api } from "@/api/client";
import type { Post, User } from "@/types";
import { useAuthStore } from "@/stores/auth";
import { MessageSquare, ArrowLeft } from "@lucide/vue";

const route = useRoute();
const router = useRouter();
const auth = useAuthStore();
const startingChat = ref(false);

const profileUser = ref<User | null>(null);
const posts = ref<Post[]>([]);
const loading = ref(true);
const following = ref(false);
const error = ref("");

const username = computed(() =>
  (route.params.username as string) || auth.user?.username || ""
);

const isOwnProfile = computed(
  () => auth.user?.username === profileUser.value?.username
);

async function loadProfile() {
  if (!username.value) return;
  loading.value = true;
  error.value = "";
  try {
    const res = await api.getUser(username.value);
    profileUser.value = res.user;
    posts.value = res.posts;
  } catch {
    error.value = "User not found";
    profileUser.value = null;
  } finally {
    loading.value = false;
  }
}

async function toggleFollow() {
  if (!profileUser.value) return;
  following.value = true;
  try {
    const { user } = await api.followUser(profileUser.value.username);
    profileUser.value = user;
  } finally {
    following.value = false;
  }
}

async function messageUser() {
  if (!profileUser.value || startingChat.value) return;
  startingChat.value = true;
  try {
    const { conversationId } = await api.startConversation(profileUser.value.username);
    router.push(`/messages/${conversationId}`);
  } finally {
    startingChat.value = false;
  }
}

function updatePost(updated: Post) {
  const idx = posts.value.findIndex((p) => p._id === updated._id);
  if (idx !== -1) posts.value[idx] = updated;
}

watch(username, loadProfile, { immediate: true });
</script>

<template>
  <AppLayout>
    <div>
      <FeedSkeleton v-if="loading" />

      <EmptyState
        v-else-if="error"
        title="User not found"
        description="This profile doesn't exist or was removed."
      />

      <template v-else-if="profileUser">
        <!-- Top bar -->
        <header
          class="sticky-header flex items-center gap-4 px-4 pb-2 sm:px-5"
          style="padding-top: calc(env(safe-area-inset-top, 0px) + 1.25rem)"
        >
          <button
            class="rounded-lg p-2 text-zinc-400 transition-colors hover:bg-white/5 hover:text-white"
            title="Back"
            @click="$router.back()"
          >
            <ArrowLeft class="h-5 w-5" :stroke-width="2" />
          </button>
          <div class="min-w-0 leading-tight">
            <h1 class="truncate text-[17px] font-extrabold tracking-tightest text-white">
              {{ profileUser.displayName }}
            </h1>
            <p class="text-xs text-zinc-500">
              {{ posts.length }} {{ posts.length === 1 ? "post" : "posts" }}
            </p>
          </div>
        </header>

        <!-- Identity -->
        <div class="px-4 pt-6 sm:px-5">
          <div class="flex items-start justify-between gap-4">
            <UserAvatar
              :src="profileUser.avatar"
              :alt="profileUser.displayName"
              size="2xl"
            />
            <div class="flex items-center gap-2 pt-2">
              <RouterLink v-if="isOwnProfile" to="/settings" class="btn-secondary text-sm">
                Edit profile
              </RouterLink>
              <template v-else-if="auth.isLoggedIn">
                <button
                  class="flex h-10 w-10 items-center justify-center rounded-lg border border-line text-zinc-200 transition-all hover:border-zinc-600 hover:bg-surface-3 active:scale-95"
                  title="Message"
                  :disabled="startingChat"
                  @click="messageUser"
                >
                  <MessageSquare class="h-5 w-5" :stroke-width="1.8" />
                </button>
                <button
                  class="text-sm"
                  :class="profileUser.isFollowing ? 'btn-secondary' : 'btn-primary'"
                  :disabled="following"
                  @click="toggleFollow"
                >
                  {{ profileUser.isFollowing ? "Following" : "Follow" }}
                </button>
              </template>
            </div>
          </div>

          <div class="mt-4">
            <h2 class="text-[23px] font-extrabold leading-tight tracking-tightest text-white">
              {{ profileUser.displayName }}
            </h2>
            <p class="text-[15px] text-zinc-500">@{{ profileUser.username }}</p>
            <p v-if="profileUser.bio" class="mt-3 max-w-lg text-[15px] leading-relaxed text-zinc-200">
              {{ profileUser.bio }}
            </p>

            <div class="mt-4 flex gap-6 text-sm">
              <span class="flex items-baseline gap-1.5">
                <strong class="font-bold text-white">{{ profileUser.followingCount }}</strong>
                <span class="text-zinc-500">Following</span>
              </span>
              <span class="flex items-baseline gap-1.5">
                <strong class="font-bold text-white">{{ profileUser.followerCount }}</strong>
                <span class="text-zinc-500">Followers</span>
              </span>
            </div>
          </div>
        </div>

        <!-- Tabs -->
        <div class="mt-5 flex border-b border-line/60 px-4 sm:px-5">
          <span class="-mb-px border-b-2 border-accent pb-3 text-[15px] font-bold text-white">
            Posts
          </span>
        </div>

        <EmptyState
          v-if="posts.length === 0"
          title="No posts yet"
          :description="isOwnProfile ? 'Share your first post with the world.' : 'This user hasn\'t posted anything yet.'"
        >
          <template v-if="isOwnProfile" #action>
            <RouterLink to="/compose" class="btn-accent px-6">Create post</RouterLink>
          </template>
        </EmptyState>

        <PostCard
          v-for="post in posts"
          :key="post._id"
          :post="post"
          @update="updatePost"
          @deleted="posts = posts.filter(p => p._id !== post._id)"
        />
      </template>
    </div>

    <template #sidebar>
      <RightRail />
    </template>
  </AppLayout>
</template>
