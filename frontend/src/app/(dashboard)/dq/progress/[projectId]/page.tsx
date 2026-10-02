"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, ArrowRight, BarChart2, Plus } from "lucide-react";
import { api } from "@/lib/api";
import { ProjectInfoStrip } from "@/components/details/ProjectInfoStrip";
import { Button } from "@/components/ui/Button";
import {
  DONE_STATUSES, RunProgressRow, formatDuration, secondsLeft, type RunStatusInfo,
} from "@/components/dq/RunProgress";

// GET /dq/project/{id}/progress: queued/running runs plus runs finished in the last 12 hours
interface ProgressRun { run_id: string; dataset_name: string; version: number; status: string; created_at: string }
interface ProjectProgress { project_id: string; active_count: number; eta_seconds: number | null; runs: ProgressRun[] }

const POLL_MS = 5000;

export default function DQProgressPage() {
  const { projectId } = useParams<{ projectId: string }>();
  const [statuses, setStatuses] = useState<Record<string, RunStatusInfo>>({});
  const [now, setNow] = useState(() => Date.now());

  const { data: progress, isLoading } = useQuery<ProjectProgress>({
    queryKey: ["dq-progress", projectId],
    queryFn: () => api.get<ProjectProgress>(`/dq/project/${projectId}/progress`),
    refetchInterval: (q) => ((q.state.data?.active_count ?? 0) > 0 ? POLL_MS : false),
  });
  const runs = progress?.runs ?? [];

  // Detailed status (columns, countdown, failure reason): each run once, then only while it is not finished
  const statusesRef = useRef(statuses);
  statusesRef.current = statuses;
  useEffect(() => {
    if (!runs.length) return;
    let cancelled = false;
    const load = async () => {
      const todo = runs.filter((r) => {
        const known = statusesRef.current[r.run_id];
        return !known || !DONE_STATUSES.includes(known.status);
      });
      if (!todo.length) return;
      const answers = await Promise.all(todo.map((r) =>
        api.get<RunStatusInfo>(`/dq/${r.run_id}/status`).then((s) => [r.run_id, { ...s, fetchedAt: Date.now() }] as const).catch(() => null)));
      if (cancelled) return;
      setStatuses((prev) => {
        const next = { ...prev };
        for (const a of answers) if (a) next[a[0]] = a[1];
        return next;
      });
    };
    load();
    const t = setInterval(load, POLL_MS);
    return () => { cancelled = true; clearInterval(t); };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [progress]);

  useEffect(() => {
    const t = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(t);
  }, []);

  const statusOf = (r: ProgressRun) => statuses[r.run_id]?.status ?? r.status;
  const completed = runs.filter((r) => statusOf(r) === "completed").length;
  const failed = runs.filter((r) => statusOf(r) === "failed").length;
  const active = runs.filter((r) => ["pending", "running"].includes(statusOf(r))).length;
  const timeLeft = runs.reduce<number | null>((max, r) => {
    const left = secondsLeft(statuses[r.run_id], now);
    return left === null ? max : Math.max(max ?? 0, left);
  }, null);
  const title = active > 0
    ? `Processing — ${runs.length - active} / ${runs.length} done${failed ? ` (${failed} failed)` : ""}`
    : failed === 0 ? `All ${runs.length} runs completed`
    : completed === 0 ? `${failed === 1 ? "The run" : `All ${failed} runs`} failed`
    : `Finished — ${completed} completed, ${failed} failed`;

  return (
    <div className="space-y-4">
      <div className="flex items-start gap-3 pb-3 border-b border-slate-200">
        <Link href={`/dq?project=${projectId}`} className="inline-flex items-center justify-center h-8 w-8 rounded-md border border-slate-200 hover:bg-slate-100 shrink-0 mt-0.5 text-slate-600">
          <ArrowLeft className="h-4 w-4" />
        </Link>
        <div className="flex-1 min-w-0">
          <h1 className="text-lg sm:text-xl font-bold tracking-tight text-slate-900">DQ Progress</h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Queued and running DQ checks of this project, and the runs finished in the last 12 hours. The runs continue when you leave this page.
          </p>
        </div>
      </div>

      <ProjectInfoStrip projectId={projectId} />

      <div className="rounded-md border border-slate-200 bg-white p-4 shadow-2xs space-y-4">
        {isLoading ? (
          <p className="text-sm text-slate-500 text-center py-6">Loading…</p>
        ) : runs.length === 0 ? (
          <div className="text-center py-8 space-y-3">
            <p className="text-sm font-medium text-slate-700">No DQ run is queued or running for this project</p>
            <p className="text-xs text-slate-500">Nothing was run in the last 12 hours either.</p>
            <Link href={`/dq/new?project=${projectId}`}>
              <Button size="sm"><Plus className="h-3.5 w-3.5 mr-1" /> Run All Data</Button>
            </Link>
          </div>
        ) : (
          <>
            <div className="flex items-center justify-between gap-4">
              <div>
                <p className={`font-semibold ${active === 0 && failed ? "text-red-700" : "text-slate-800"}`}>{title}</p>
                <p className="text-xs text-slate-400 mt-0.5">
                  Files are checked one after another (the local AI model handles one file at a time), about 1 minute per column.
                </p>
              </div>
              <div className="flex items-center gap-3 shrink-0">
                {active > 0 && timeLeft !== null && (
                  <div className="text-right" title="Estimated time until all files of this project are finished">
                    <p className="text-[10px] uppercase tracking-wider text-slate-400 font-mono">Time left</p>
                    <p className="text-lg font-bold font-mono text-slate-800">≈ {formatDuration(timeLeft)}</p>
                  </div>
                )}
                {completed > 0 && (
                  <Link href={`/dq/project/${projectId}`}>
                    <Button size="sm" variant="outline"><BarChart2 className="h-3.5 w-3.5 mr-1" /> Project Report</Button>
                  </Link>
                )}
              </div>
            </div>

            {active > 0 && (
              <div className="h-1.5 rounded-full bg-slate-100 overflow-hidden">
                <div className="h-full bg-blue-600 transition-all duration-500"
                  style={{ width: `${Math.round((100 * (runs.length - active)) / runs.length)}%` }} />
              </div>
            )}

            <div className="space-y-2">
              {runs.map((r) => (
                <div key={r.run_id}>
                  <RunProgressRow filename={`${r.dataset_name} · v${r.version}`} info={statuses[r.run_id]} now={now} />
                  {DONE_STATUSES.includes(statusOf(r)) && (
                    <div className="text-right mt-1">
                      <Link href={`/dq/${r.run_id}`} className="inline-flex items-center gap-1 text-xs font-medium text-slate-700 hover:text-slate-900">
                        Open run <ArrowRight className="h-3 w-3" />
                      </Link>
                    </div>
                  )}
                </div>
              ))}
            </div>
          </>
        )}
      </div>
    </div>
  );
}
