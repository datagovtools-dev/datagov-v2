/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: ["class"],
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    screens: {
      sm: "640px",
      md: "768px",
      lg: "1024px",
      xl: "1280px",
      "2xl": "1536px",
    },
    extend: {
      colors: {
        // Monochromatic foundation (Zinc / Slate)
        ink: {
          primary:   "#0F172A", // slate-900
          secondary: "#475569", // slate-600
          muted:     "#94A3B8", // slate-400
        },
        surface: {
          base:  "#F8FAFC", // slate-50
          card:  "#FFFFFF",
          muted: "#F1F5F9", // slate-100
          hover: "#F8FAFC",
          50:  "#F8FAFC",
          100: "#F1F5F9",
          200: "#E2E8F0",
          300: "#CBD5E1",
          400: "#94A3B8",
          500: "#64748B",
          600: "#475569",
          700: "#334155",
          800: "#1E293B",
          900: "#0F172A",
        },
        border: {
          subtle: "#E2E8F0",
          DEFAULT: "#E2E8F0",
        },
        // Functional Semantic Accents (Muted & Tool-oriented)
        governance: {
          amber:        "#D97706",
          "amber-soft": "#FEF3C7",
          "amber-hover":"#B45309",
          "amber-dark": "#92400E",
        },
        metadata: {
          blue:        "#2563EB",
          "blue-soft": "#EFF6FF",
          "blue-dark": "#1E40AF",
        },
        quality: {
          green:        "#059669",
          "green-soft": "#ECFDF5",
          "green-dark": "#065F46",
        },
        lineage: {
          purple:        "#7C3AED",
          "purple-soft": "#F5F3FF",
          "purple-dark": "#5B21B6",
        },
        risk: {
          red:        "#DC2626",
          "red-soft": "#FEF2F2",
          "red-dark": "#991B1B",
        },
        warning: {
          orange:        "#D97706",
          "orange-soft": "#FEF3C7",
        },
        info: {
          cyan:        "#0284C7",
          "cyan-soft": "#F0F9FF",
        },
        // Enterprise Slate Primary
        primary: {
          50:  "#F8FAFC",
          100: "#F1F5F9",
          200: "#E2E8F0",
          300: "#CBD5E1",
          400: "#94A3B8",
          500: "#64748B",
          600: "#475569",
          700: "#334155",
          800: "#1E293B",
          900: "#0F172A",
          950: "#020617",
        },
        // Status colors
        status: {
          draft:       "#64748B",
          pending:     "#D97706",
          "in-review": "#2563EB",
          approved:    "#059669",
          rejected:    "#DC2626",
          done:        "#059669",
          active:      "#059669",
          inactive:    "#64748B",
        },
      },
      fontFamily: {
        sans: ["Inter", "system-ui", "sans-serif"],
        mono: ["JetBrains Mono", "ui-monospace", "monospace"],
      },
      fontSize: {
        "2xs": ["0.6875rem", { lineHeight: "0.875rem" }],
      },
      borderRadius: {
        DEFAULT: "0.375rem", // 6px (rounded-md strict token)
        sm: "0.25rem",
        md: "0.375rem",
        lg: "0.5rem",
        xl: "0.5rem",
        "2xl": "0.5rem",
        "3xl": "0.5rem",
        full: "9999px",
      },
      boxShadow: {
        "2xs":   "0 1px 2px 0 rgb(0 0 0 / 0.03)",
        xs:      "0 1px 2px 0 rgb(0 0 0 / 0.05)",
        subtle:  "0 1px 2px 0 rgb(0 0 0 / 0.04)",
        card:    "0 1px 3px 0 rgb(0 0 0 / 0.04), 0 1px 2px -1px rgb(0 0 0 / 0.02)",
        "card-hover": "0 2px 6px -1px rgb(0 0 0 / 0.06), 0 1px 4px -1px rgb(0 0 0 / 0.03)",
        floating: "0 8px 20px -4px rgb(0 0 0 / 0.08), 0 2px 6px -2px rgb(0 0 0 / 0.04)",
        modal:   "0 16px 40px -8px rgb(0 0 0 / 0.12)",
        sidebar: "1px 0 0 0 rgb(226 232 240)",
      },
      transitionDuration: {
        fast: "120ms",
        standard: "180ms",
      },
    },
  },
  plugins: [
    require("tailwindcss-animate"),
  ],
};
