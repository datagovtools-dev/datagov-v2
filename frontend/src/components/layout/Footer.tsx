export function Footer() {
  return (
    <footer className="h-8 flex items-center justify-between px-6 border-t border-slate-200 bg-white text-[10px] text-slate-400 font-mono shrink-0">
      <span>AI Governance Control Plane v1.0</span>
      <span>© {new Date().getFullYear()} Enterprise Governance</span>
    </footer>
  );
}
