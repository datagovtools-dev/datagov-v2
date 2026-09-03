"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import {
  Search,
  FolderOpen,
  Share2,
  ShieldCheck,
  ShieldAlert,
  BarChart2,
  Database,
  Sliders,
  Users,
  Settings,
  Plus,
  ArrowRight,
  X,
  FileSpreadsheet,
} from "lucide-react";
import { cn } from "@/lib/utils";

interface CommandItem {
  id: string;
  category: "Navigation" | "Actions" | "Governance";
  title: string;
  subtitle?: string;
  href: string;
  icon: React.ComponentType<{ className?: string }>;
}

const COMMANDS: CommandItem[] = [
  // Navigation
  { id: "nav-dash", category: "Navigation", title: "Overview Dashboard", subtitle: "Executive Control Plane", href: "/dashboard", icon: Sliders },
  { id: "nav-projects", category: "Navigation", title: "Data Assets & Projects", subtitle: "Project Registry & Asset Catalog", href: "/projects", icon: FolderOpen },
  { id: "nav-metadata", category: "Navigation", title: "Metadata Management", subtitle: "Data Dictionary & Auto-Enrichment", href: "/metadata", icon: Database },
  { id: "nav-dq", category: "Navigation", title: "Data Quality Control", subtitle: "4-Dimension Inspection & Rules", href: "/dq", icon: BarChart2 },
  { id: "nav-dsr", category: "Navigation", title: "Data Sharing Requests (DSR)", subtitle: "Approval Workflow & E-Sign", href: "/dsr", icon: Share2 },
  { id: "nav-aick", category: "Navigation", title: "AI/ML Compliance Checklist", subtitle: "GEN AI Assessment", href: "/ai-checklist", icon: ShieldCheck },
  { id: "nav-dpia", category: "Navigation", title: "Data Protection Impact Assessment", subtitle: "5x5 Privacy Risk Matrix", href: "/dpia", icon: ShieldAlert },
  { id: "nav-ropa", category: "Navigation", title: "Record of Processing (ROPA)", subtitle: "Legal Basis & Processing Logs", href: "/ropa", icon: FileSpreadsheet },
  { id: "nav-bapd", category: "Navigation", title: "Data Extermination (BAPD)", subtitle: "Retention & Disposal Requests", href: "/bapd", icon: ShieldAlert },
  { id: "nav-settings-ai", category: "Navigation", title: "AI Provider Settings", subtitle: "Local/Cloud Ollama Setup", href: "/settings/ai", icon: Settings },
  { id: "nav-settings-users", category: "Navigation", title: "User & Role Management", subtitle: "RBAC Access Control", href: "/settings/users", icon: Users },

  // Actions
  { id: "act-new-project", category: "Actions", title: "Create New Project", subtitle: "Register governance project", href: "/projects/new", icon: Plus },
  { id: "act-new-dsr", category: "Actions", title: "New Data Sharing Request", subtitle: "Initiate sharing workflow", href: "/dsr/new", icon: Plus },
  { id: "act-new-dq", category: "Actions", title: "Run New Data Quality Check", subtitle: "Inspect project source files", href: "/dq/new", icon: Plus },
  { id: "act-new-dpia", category: "Actions", title: "Create New DPIA Record", subtitle: "Assess data privacy impact", href: "/dpia/new", icon: Plus },
  { id: "act-new-bapd", category: "Actions", title: "New Disposal Request (BAPD)", subtitle: "Exterminate expired data", href: "/bapd/new", icon: Plus },
];

export interface CommandPaletteProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function CommandPalette({ open, onOpenChange }: CommandPaletteProps) {
  const router = useRouter();
  const [query, setQuery] = React.useState("");
  const [selectedIndex, setSelectedIndex] = React.useState(0);
  const inputRef = React.useRef<HTMLInputElement>(null);

  React.useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault();
        onOpenChange(!open);
      }
      if (e.key === "Escape" && open) {
        onOpenChange(false);
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [open, onOpenChange]);

  React.useEffect(() => {
    if (open) {
      setTimeout(() => inputRef.current?.focus(), 50);
      setSelectedIndex(0);
    }
  }, [open]);

  const filteredCommands = React.useMemo(() => {
    if (!query.trim()) return COMMANDS;
    const lower = query.toLowerCase();
    return COMMANDS.filter(
      (c) =>
        c.title.toLowerCase().includes(lower) ||
        c.subtitle?.toLowerCase().includes(lower) ||
        c.category.toLowerCase().includes(lower)
    );
  }, [query]);

  const handleSelect = (item: CommandItem) => {
    onOpenChange(false);
    router.push(item.href);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "ArrowDown") {
      e.preventDefault();
      setSelectedIndex((prev) => (prev + 1) % filteredCommands.length);
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      setSelectedIndex((prev) => (prev - 1 + filteredCommands.length) % filteredCommands.length);
    } else if (e.key === "Enter" && filteredCommands[selectedIndex]) {
      e.preventDefault();
      handleSelect(filteredCommands[selectedIndex]);
    }
  };

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center pt-20 px-4">
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-ink-primary/30 backdrop-blur-sm transition-opacity duration-fast animate-fade-in"
        onClick={() => onOpenChange(false)}
      />

      {/* Palette Container */}
      <div className="relative w-full max-w-xl rounded-2xl border border-border-subtle bg-white shadow-modal overflow-hidden z-10 animate-slide-in">
        {/* Search Header */}
        <div className="flex items-center px-4 border-b border-border-subtle bg-surface-base">
          <Search className="h-4 w-4 text-ink-muted shrink-0" />
          <input
            ref={inputRef}
            type="text"
            value={query}
            onChange={(e) => {
              setQuery(e.target.value);
              setSelectedIndex(0);
            }}
            onKeyDown={handleKeyDown}
            placeholder="Search data assets, terms, rules, workflows... (Esc to close)"
            className="w-full bg-transparent px-3 py-3.5 text-sm text-ink-primary placeholder:text-ink-muted focus:outline-none"
          />
          <kbd className="hidden sm:inline-flex items-center px-2 py-0.5 text-2xs font-mono text-ink-muted bg-white border border-border-subtle rounded">
            ESC
          </kbd>
        </div>

        {/* Results List */}
        <div className="max-h-80 overflow-y-auto p-2 divide-y divide-border-subtle/50">
          {filteredCommands.length === 0 ? (
            <div className="py-8 text-center text-xs text-ink-muted">
              No matching governance assets or commands found.
            </div>
          ) : (
            filteredCommands.map((item, idx) => {
              const Icon = item.icon;
              const isSelected = idx === selectedIndex;
              return (
                <div
                  key={item.id}
                  onClick={() => handleSelect(item)}
                  onMouseEnter={() => setSelectedIndex(idx)}
                  className={cn(
                    "flex items-center justify-between px-3 py-2.5 rounded-lg cursor-pointer transition-colors duration-fast",
                    isSelected ? "bg-governance-amber-soft text-governance-amber-dark" : "hover:bg-surface-hover text-ink-primary"
                  )}
                >
                  <div className="flex items-center gap-3 min-w-0">
                    <div
                      className={cn(
                        "p-1.5 rounded-md shrink-0 transition-colors",
                        isSelected ? "bg-governance-amber text-white" : "bg-surface-muted text-ink-secondary"
                      )}
                    >
                      <Icon className="h-4 w-4" />
                    </div>
                    <div className="min-w-0">
                      <div className="text-xs font-semibold truncate">{item.title}</div>
                      {item.subtitle && (
                        <div className="text-2xs text-ink-secondary truncate">{item.subtitle}</div>
                      )}
                    </div>
                  </div>
                  <span className="text-2xs text-ink-muted shrink-0 flex items-center gap-1 font-mono uppercase">
                    {item.category} <ArrowRight className="h-3 w-3" />
                  </span>
                </div>
              );
            })
          )}
        </div>

        {/* Footer info */}
        <div className="flex items-center justify-between px-4 py-2 bg-surface-muted border-t border-border-subtle text-2xs text-ink-muted">
          <span>Navigate with ↑ ↓ and Enter</span>
          <span className="font-semibold text-governance-amber-dark">Governance in Motion</span>
        </div>
      </div>
    </div>
  );
}
