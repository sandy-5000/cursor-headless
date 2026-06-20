import { createRouter, createWebHistory, RouterView } from "vue-router";
import { h } from "vue";
import { getToken } from "@/api/client";

// Each view wraps itself in <AppLayout>, so the parent route is just a
// passthrough outlet. (Using AppLayout here would double-wrap and leave
// the page with no <router-view> to render into.)
const RouterPassthrough = {
  name: "RouterPassthrough",
  render: () => h(RouterView),
};

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: "/",
      component: RouterPassthrough,
      children: [
        {
          path: "",
          name: "home",
          component: () => import("@/views/HomeView.vue"),
          meta: { requiresAuth: true },
        },
        {
          path: "explore",
          name: "explore",
          component: () => import("@/views/ExploreView.vue"),
        },
        {
          path: "compose",
          name: "compose",
          component: () => import("@/views/ComposeView.vue"),
          meta: { requiresAuth: true },
        },
        {
          path: "messages",
          name: "messages",
          component: () => import("@/views/ChatView.vue"),
          meta: { requiresAuth: true },
        },
        {
          path: "messages/:id",
          name: "conversation",
          component: () => import("@/views/ChatView.vue"),
          meta: { requiresAuth: true },
        },
        {
          path: "profile/:username?",
          name: "profile",
          component: () => import("@/views/ProfileView.vue"),
        },
        {
          path: "post/:id",
          name: "post",
          component: () => import("@/views/PostView.vue"),
        },
        {
          path: "settings",
          name: "settings",
          component: () => import("@/views/SettingsView.vue"),
          meta: { requiresAuth: true },
        },
      ],
    },
    {
      path: "/login",
      name: "login",
      component: () => import("@/views/LoginView.vue"),
      meta: { guest: true },
    },
    {
      path: "/register",
      name: "register",
      component: () => import("@/views/RegisterView.vue"),
      meta: { guest: true },
    },
  ],
  scrollBehavior() {
    return { top: 0 };
  },
});

router.beforeEach(async (to) => {
  const hasToken = !!getToken();

  if (to.meta.requiresAuth && !hasToken) {
    return { name: "login", query: { redirect: to.fullPath } };
  }

  if (to.meta.guest && hasToken) {
    return { name: "home" };
  }
});

export default router;
