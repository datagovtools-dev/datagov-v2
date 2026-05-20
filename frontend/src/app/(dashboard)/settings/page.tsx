"use client";

import Link from "next/link";
import { Bell, Bot, Shield, Users } from "lucide-react";

import { Card, CardContent } from "@/components/ui/Card";

const SETTINGS_ITEMS = [
  { href: "/settings/ai", label: "AI Setup", description: "Ollama Cloud provider, model, and API key", icon: Bot },
  { href: "/settings/users", label: "Users", description: "User access and role assignments", icon: Users },
  { href: "/settings/roles", label: "Roles", description: "Platform role catalogue", icon: Shield },
  { href: "/settings/notifications", label: "Notifications", description: "In-app and email preferences", icon: Bell },
];

export default function SettingsPage() {
  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Settings</h1>
          <p className="text-sm text-surface-500 mt-0.5">System configuration and administration</p>
        </div>
      </div>

      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        {SETTINGS_ITEMS.map((item) => (
          <Link key={item.href} href={item.href}>
            <Card className="h-full hover:border-primary-200 hover:shadow-card-hover transition">
              <CardContent className="flex items-start gap-3">
                <div className="flex h-9 w-9 items-center justify-center rounded-md bg-primary-50 text-primary-600">
                  <item.icon className="h-4 w-4" />
                </div>
                <div>
                  <h2 className="text-base font-semibold text-surface-900">{item.label}</h2>
                  <p className="text-sm text-surface-500 mt-1">{item.description}</p>
                </div>
              </CardContent>
            </Card>
          </Link>
        ))}
      </div>
    </div>
  );
}
