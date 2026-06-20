/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{vue,js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        ink: "#000000",
        surface: "#0a0a0b",
        "surface-1": "#0e0e10",
        "surface-2": "#141417",
        "surface-3": "#1b1b1f",
        "surface-4": "#26262b",
        line: "#26262b",
        accent: "#7c5cff",
        "accent-light": "#9d86ff",
        "accent-dim": "#2a2342",
        like: "#ff3b5c",
      },
      fontFamily: {
        sans: ['"Inter"', "system-ui", "-apple-system", "sans-serif"],
      },
      letterSpacing: {
        tightest: "-0.03em",
      },
      animation: {
        "fade-in": "fadeIn 0.4s ease-out forwards",
        "slide-up": "slideUp 0.45s cubic-bezier(0.16, 1, 0.3, 1) forwards",
        "scale-in": "scaleIn 0.2s ease-out forwards",
        "pop": "pop 0.3s cubic-bezier(0.34, 1.56, 0.64, 1)",
        shimmer: "shimmer 1.8s infinite linear",
        "orb-1": "orb1 22s ease-in-out infinite",
        "orb-2": "orb2 26s ease-in-out infinite",
      },
      keyframes: {
        fadeIn: {
          "0%": { opacity: "0" },
          "100%": { opacity: "1" },
        },
        slideUp: {
          "0%": { opacity: "0", transform: "translateY(14px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        scaleIn: {
          "0%": { opacity: "0", transform: "scale(0.96)" },
          "100%": { opacity: "1", transform: "scale(1)" },
        },
        pop: {
          "0%": { transform: "scale(1)" },
          "40%": { transform: "scale(1.25)" },
          "100%": { transform: "scale(1)" },
        },
        shimmer: {
          "0%": { backgroundPosition: "-200% 0" },
          "100%": { backgroundPosition: "200% 0" },
        },
        orb1: {
          "0%, 100%": { transform: "translate(0, 0) scale(1)" },
          "50%": { transform: "translate(40px, -30px) scale(1.15)" },
        },
        orb2: {
          "0%, 100%": { transform: "translate(0, 0) scale(1)" },
          "50%": { transform: "translate(-30px, 40px) scale(0.9)" },
        },
      },
      boxShadow: {
        soft: "0 1px 2px rgba(0,0,0,0.4), 0 8px 24px -8px rgba(0,0,0,0.6)",
        elevated:
          "0 1px 0 0 rgba(255,255,255,0.04) inset, 0 2px 8px rgba(0,0,0,0.5), 0 20px 50px -20px rgba(0,0,0,0.8)",
        glow: "0 0 0 1px rgba(124,92,255,0.3), 0 8px 40px -8px rgba(124,92,255,0.5)",
        fab: "0 8px 30px -6px rgba(124,92,255,0.6)",
      },
      backgroundImage: {
        "gradient-radial": "radial-gradient(var(--tw-gradient-stops))",
        shimmer:
          "linear-gradient(90deg, transparent 0%, rgba(255,255,255,0.05) 50%, transparent 100%)",
      },
    },
  },
  plugins: [],
};
