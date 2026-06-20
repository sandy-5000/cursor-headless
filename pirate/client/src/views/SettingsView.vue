<script setup lang="ts">
import { ref } from "vue";
import { useRouter } from "vue-router";
import AppLayout from "@/layouts/AppLayout.vue";
import PageHeader from "@/components/PageHeader.vue";
import UserAvatar from "@/components/UserAvatar.vue";
import RightRail from "@/components/RightRail.vue";
import { useAuthStore } from "@/stores/auth";
import { api } from "@/api/client";

const auth = useAuthStore();
const router = useRouter();

const displayName = ref(auth.user?.displayName ?? "");
const bio = ref(auth.user?.bio ?? "");
const gender = ref<"female" | "male">(auth.user?.gender ?? "female");
const avatarPreview = ref(auth.user?.avatar ?? "");
const generating = ref(false);
const saving = ref(false);
const message = ref("");
const error = ref("");

async function generateAvatar() {
  generating.value = true;
  error.value = "";
  try {
    const { avatar } = await api.generateAvatar(gender.value);
    avatarPreview.value = avatar;
  } catch (e) {
    error.value = e instanceof Error ? e.message : "Failed to generate avatar";
  } finally {
    generating.value = false;
  }
}

async function setGender(value: "female" | "male") {
  if (gender.value === value) return;
  gender.value = value;
  // Keep the preview in sync with the selected gender.
  await generateAvatar();
}

async function save() {
  saving.value = true;
  message.value = "";
  error.value = "";
  try {
    await api.updateProfile({
      displayName: displayName.value.trim(),
      bio: bio.value.trim(),
      gender: gender.value,
      avatar: avatarPreview.value || undefined,
    });
    await auth.refreshUser();
    message.value = "Saved successfully";
  } catch (e) {
    error.value = e instanceof Error ? e.message : "Failed to save";
  } finally {
    saving.value = false;
  }
}

function logout() {
  auth.logout();
  router.push("/login");
}
</script>

<template>
  <AppLayout>
    <div>
      <PageHeader title="Settings" subtitle="Manage your profile" />

      <div class="px-4 py-4 sm:px-5">
        <div class="card p-6 space-y-6">
          <div class="flex items-center gap-4 pb-6 border-b border-zinc-800">
            <UserAvatar
              :src="avatarPreview"
              :alt="auth.user?.displayName ?? ''"
              size="lg"
              :class="{ 'opacity-50': generating }"
            />
            <div class="min-w-0">
              <p class="font-semibold text-white">{{ auth.user?.displayName }}</p>
              <p class="text-sm text-zinc-500">@{{ auth.user?.username }}</p>
              <button
                type="button"
                class="btn-secondary mt-2 px-3 py-1.5 text-xs"
                :disabled="generating"
                @click="generateAvatar"
              >
                {{ generating ? "Generating..." : "Generate new avatar" }}
              </button>
            </div>
          </div>

          <div>
            <label class="mb-2 block text-sm font-medium text-zinc-400">Display name</label>
            <input v-model="displayName" type="text" class="input-field" maxlength="50" />
          </div>

          <div>
            <label class="mb-2 block text-sm font-medium text-zinc-400">Gender</label>
            <div class="grid grid-cols-2 gap-2">
              <button
                type="button"
                class="rounded-lg border px-4 py-2.5 text-sm font-semibold transition-all active:scale-[0.98]"
                :class="gender === 'female'
                  ? 'border-accent bg-accent/10 text-white'
                  : 'border-line text-zinc-400 hover:border-zinc-600 hover:text-zinc-200'"
                @click="setGender('female')"
              >
                Female
              </button>
              <button
                type="button"
                class="rounded-lg border px-4 py-2.5 text-sm font-semibold transition-all active:scale-[0.98]"
                :class="gender === 'male'
                  ? 'border-accent bg-accent/10 text-white'
                  : 'border-line text-zinc-400 hover:border-zinc-600 hover:text-zinc-200'"
                @click="setGender('male')"
              >
                Male
              </button>
            </div>
            <p class="mt-1.5 text-xs text-zinc-600">Changing this updates your generated avatar.</p>
          </div>

          <div>
            <label class="mb-2 block text-sm font-medium text-zinc-400">Bio</label>
            <textarea
              v-model="bio"
              rows="3"
              class="input-field resize-none"
              maxlength="160"
              placeholder="Tell people about yourself..."
            />
            <p class="mt-1.5 text-right text-xs text-zinc-600">{{ bio.length }}/160</p>
          </div>

          <button class="btn-primary w-full py-3" :disabled="saving" @click="save">
            {{ saving ? "Saving..." : "Save changes" }}
          </button>

          <p v-if="message" class="text-center text-sm text-emerald-400">{{ message }}</p>
          <p v-if="error" class="text-center text-sm text-red-400">{{ error }}</p>

          <button
            class="w-full rounded-lg border border-red-500/20 py-2.5 text-sm font-medium text-red-400 transition-colors hover:bg-red-500/10"
            @click="logout"
          >
            Sign out
          </button>
        </div>
      </div>
    </div>

    <template #sidebar>
      <RightRail />
    </template>
  </AppLayout>
</template>
