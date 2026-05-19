export function Footer() {
  return (
    <footer className="h-10 flex items-center justify-between px-6 border-t border-surface-100 bg-white text-2xs text-surface-400 shrink-0">
      <span>AI Governance Tools v1.0</span>
      <span>© {new Date().getFullYear()} All rights reserved</span>
    </footer>
  );
}
