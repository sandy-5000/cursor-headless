<script setup lang="ts">
import { ref } from "vue";
import { useRouter } from "vue-router";
import AppLayout from "@/layouts/AppLayout.vue";
import PageHeader from "@/components/PageHeader.vue";
import UserAvatar from "@/components/UserAvatar.vue";
import RightRail from "@/components/RightRail.vue";
import { api } from "@/api/client";
import { useAuthStore } from "@/stores/auth";
import { ImageIcon } from "@lucide/vue";

const router = useRouter();
const auth = useAuthStore();
const content = ref("");
const imageUrl = ref("");
const imagePreview = ref("");
const uploading = ref(false);
const posting = ref(false);
const error = ref("");
const maxLength = 500;

async function onFileSelect(e: Event) {
  const file = (e.target as HTMLInputElement).files?.[0];
  if (!file) return;

  uploading.value = true;
  error.value = "";
  try {
    const { url } = await api.uploadImage(file);
    imageUrl.value = url;
    imagePreview.value = url;
  } catch (e) {
    error.value = e instanceof Error ? e.message : "Upload failed";
  } finally {
    uploading.value = false;
  }
}

function removeImage() {
  imageUrl.value = "";
  imagePreview.value = "";
}

async function submit() {
  if (!content.value.trim() && !imageUrl.value) return;

  posting.value = true;
  error.value = "";
  try {
    await api.createPost({
      content: content.value.trim(),
      imageUrl: imageUrl.value || undefined,
    });
    router.push("/");
  } catch (e) {
    error.value = e instanceof Error ? e.message : "Failed to post";
  } finally {
    posting.value = false;
  }
}
</script>

<template>
  <AppLayout>
    <div>
      <PageHeader title="New post" />

      <div class="px-4 py-4 sm:px-5">
        <div class="flex gap-3">
          <UserAvatar
            v-if="auth.user"
            :src="auth.user.avatar"
            :alt="auth.user.displayName"
            size="sm"
          />
          <div class="flex-1">
            <textarea
              v-model="content"
              rows="4"
              placeholder="What's happening?"
              class="w-full resize-none bg-transparent text-[17px] leading-relaxed text-zinc-100 placeholder:text-zinc-600 outline-none"
              :maxlength="maxLength"
            />

            <div
              v-if="imagePreview"
              class="relative mt-3 overflow-hidden rounded-lg ring-1 ring-zinc-800"
            >
              <img :src="imagePreview" alt="Preview" class="max-h-72 w-full object-cover" />
              <button
                class="absolute right-2 top-2 flex h-8 w-8 items-center justify-center rounded-md bg-black/70 text-zinc-300 backdrop-blur hover:text-white"
                @click="removeImage"
              >
                ✕
              </button>
            </div>

            <div class="mt-4 flex items-center justify-between border-t border-zinc-800 pt-4">
              <label class="btn-ghost cursor-pointer text-zinc-500 hover:text-accent-light">
                <ImageIcon class="h-5 w-5" :stroke-width="1.5" />
                <span class="text-sm">{{ uploading ? "Uploading..." : "Photo" }}</span>
                <input type="file" accept="image/*" class="hidden" :disabled="uploading" @change="onFileSelect" />
              </label>

              <div class="flex items-center gap-3">
                <span class="text-xs text-zinc-600">{{ content.length }}/{{ maxLength }}</span>
                <button
                  class="btn-accent px-5"
                  :disabled="posting || (!content.trim() && !imageUrl)"
                  @click="submit"
                >
                  {{ posting ? "Posting..." : "Post" }}
                </button>
              </div>
            </div>

            <p v-if="error" class="mt-3 text-sm text-red-400">{{ error }}</p>
          </div>
        </div>
      </div>
    </div>

    <template #sidebar>
      <RightRail />
    </template>
  </AppLayout>
</template>
