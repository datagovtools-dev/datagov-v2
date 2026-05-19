/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: ["class"],
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    // Responsive breakpoints
    screens: {
      sm: "640px",
      md: "768px",
      lg: "1024px",
      xl: "1280px",
      "2xl": "1536px",
    },
    extend: {
      colors: {
        // Brand primaries
        primary: {
          50:  "#eef2ff",
          100: "#e0e7ff",
          200: "#c7d2fe",
          300: "#a5b4fc",
          400: "#818cf8",
          500: "#6366f1",  // default
          600: "#4f46e5",
          700: "#4338ca",
          800: "#3730a3",
          900: "#312e81",
          950: "#1e1b4b",
        },
        // Accent / action
        accent: {
          50:  "#f0fdf4",
          100: "#dcfce7",
          300: "#86efac",
          500: "#22c55e",
          600: "#16a34a",
          700: "#15803d",
        },
        // Status colours
        status: {
          draft:       "#94a3b8",
          pending:     "#f59e0b",
          "in-review": "#3b82f6",
          approved:    "#22c55e",
          rejected:    "#ef4444",
          done:        "#6366f1",
          active:      "#22c55e",
          inactive:    "#94a3b8",
        },
        // Severity
        severity: {
          critical: "#dc2626",
          high:     "#f97316",
          medium:   "#f59e0b",
          low:      "#22c55e",
          info:     "#3b82f6",
        },
        // Data sensitivity
        sensitivity: {
          public:        "#22c55e",
          internal:      "#3b82f6",
          confidential:  "#f59e0b",
          restricted:    "#ef4444",
        },
        // Neutral surface
        surface: {
          50:  "#f8fafc",
          100: "#f1f5f9",
          200: "#e2e8f0",
          300: "#cbd5e1",
          700: "#334155",
          800: "#1e293b",
          900: "#0f172a",
        },
      },
      fontFamily: {
        sans: ["Inter", "ui-sans-serif", "system-ui", "sans-serif"],
        mono: ["JetBrains Mono", "ui-monospace", "monospace"],
      },
      fontSize: {
        "2xs": ["0.625rem", { lineHeight: "0.875rem" }],
      },
      spacing: {
        18: "4.5rem",
        68: "17rem",
        72: "18rem",
        76: "19rem",
        88: "22rem",
      },
      borderRadius: {
        "4xl": "2rem",
      },
      boxShadow: {
        card:    "0 1px 3px 0 rgb(0 0 0 / 0.07), 0 1px 2px -1px rgb(0 0 0 / 0.07)",
        "card-hover": "0 4px 6px -1px rgb(0 0 0 / 0.10), 0 2px 4px -2px rgb(0 0 0 / 0.10)",
        modal:   "0 20px 60px -10px rgb(0 0 0 / 0.25)",
        sidebar: "2px 0 8px 0 rgb(0 0 0 / 0.08)",
      },
      animation: {
        "fade-in":   "fadeIn 150ms ease-out",
        "slide-in":  "slideIn 200ms ease-out",
        "spin-slow": "spin 2s linear infinite",
      },
      keyframes: {
        fadeIn: {
          "0%":   { opacity: "0" },
          "100%": { opacity: "1" },
        },
        slideIn: {
          "0%":   { transform: "translateY(-4px)", opacity: "0" },
          "100%": { transform: "translateY(0)",    opacity: "1" },
        },
      },
      zIndex: {
        60: "60",
        70: "70",
        80: "80",
        90: "90",
      },
    },
  },
  plugins: [
    require("tailwindcss-animate"),
  ],
};
