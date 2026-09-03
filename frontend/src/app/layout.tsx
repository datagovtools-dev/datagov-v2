import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "@/styles/globals.css";
import { QueryProvider } from "@/components/providers/QueryProvider";
import { ToastContainer } from "@/components/ui/Toast";
import { TopProgressBar } from "@/components/ui/TopProgressBar";

const inter = Inter({ subsets: ["latin"], variable: "--font-inter" });

export const metadata: Metadata = {
  title: "AI Governance Tools",
  description: "Integrated Data Governance Platform",
  icons: {
    icon: [{ url: "/favicon.svg", type: "image/svg+xml" }],
    shortcut: ["/favicon.svg"],
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={inter.variable}>
      <body>
        <QueryProvider>
          <TopProgressBar />
          {children}
          <ToastContainer />
        </QueryProvider>
      </body>
    </html>
  );
}
