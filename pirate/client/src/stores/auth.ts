import { defineStore } from "pinia";
import { ref, computed } from "vue";
import { api, setToken, clearToken, getToken } from "@/api/client";
import type { User } from "@/types";

export const useAuthStore = defineStore("auth", () => {
  const user = ref<User | null>(null);
  const loading = ref(false);
  const initialized = ref(false);

  const isLoggedIn = computed(() => !!user.value);

  async function init() {
    if (!getToken()) {
      initialized.value = true;
      return;
    }
    try {
      const { user: me } = await api.me();
      user.value = me;
    } catch {
      clearToken();
    } finally {
      initialized.value = true;
    }
  }

  async function register(data: {
    username: string;
    email: string;
    password: string;
    displayName?: string;
    gender?: "female" | "male";
  }) {
    loading.value = true;
    try {
      const res = await api.register(data);
      setToken(res.token);
      user.value = res.user;
      return res;
    } finally {
      loading.value = false;
    }
  }

  async function login(login: string, password: string) {
    loading.value = true;
    try {
      const res = await api.login({ login, password });
      setToken(res.token);
      user.value = res.user;
      return res;
    } finally {
      loading.value = false;
    }
  }

  function logout() {
    clearToken();
    user.value = null;
  }

  async function refreshUser() {
    const { user: me } = await api.me();
    user.value = me;
  }

  return {
    user,
    loading,
    initialized,
    isLoggedIn,
    init,
    register,
    login,
    logout,
    refreshUser,
  };
});
