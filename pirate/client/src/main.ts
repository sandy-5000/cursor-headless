import { createApp } from "vue";
import { createPinia } from "pinia";
import App from "./App.vue";
import router from "./router";
import { useAuthStore } from "./stores/auth";
import "./assets/main.css";

const app = createApp(App);
const pinia = createPinia();

app.config.errorHandler = (err, _instance, info) => {
  console.error("[Pirate] Vue error:", info, err);
};

app.use(pinia);
app.use(router);

const auth = useAuthStore();
auth.init().then(() => {
  app.mount("#app");
});
