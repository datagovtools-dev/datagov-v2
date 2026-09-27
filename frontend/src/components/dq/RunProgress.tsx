// Shared by the New DQ Run wizard (Generate step) and the project progress page (/dq/progress/[projectId])

// GET /dq/{id}/status: progress, time estimate and failure explanation
export interface RunStatusInfo {
  status: string;
  progress_pct: number;
  overall_score: string | null;
  message: string;
  columns_total?: number | null;
  columns_done?: number | null;
  started_at?: string | null;
  completed_at?: string | null;
  queue_position?: number | null;
  eta_seconds?: number | null;
  error_category?: string | null;
  error_title?: string | null;
  error_explanation?: string | null;
  error_action?: string | null;
  error_detail?: string | null;
  will_retry?: boolean;
  fetchedAt?: number; // client time of this answer, for the countdown between polls
}

export const DONE_STATUSES = ["completed", "failed"];

export function formatDuration(totalSeconds: number): string {
  const s = Math.max(Math.round(totalSeconds), 0);
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  const sec = s % 60;
  return h > 0 ? `${h}:${String(m).padStart(2, "0")}:${String(sec).padStart(2, "0")}` : `${m}:${String(sec).padStart(2, "0")}`;
}

// Seconds left for a run, counted down locally between polls
export function secondsLeft(info: RunStatusInfo | undefined, now: number): number | null {
  if (!info || info.eta_seconds == null || DONE_STATUSES.includes(info.status)) return null;
  const elapsed = info.fetchedAt ? (now - info.fetchedAt) / 1000 : 0;
  return Math.max(info.eta_seconds - elapsed, 0);
}

export function FailureBox({ info }: { info: RunStatusInfo }) {
  return (
    <div className="mt-2 rounded-md border border-red-200 bg-red-50 px-3 py-2 text-xs text-red-800 space-y-1">
      <p className="font-semibold">{info.error_title ?? "Run failed"}</p>
      {info.error_explanation && <p>{info.error_explanation}</p>}
      {info.error_action && <p><span className="font-semibold">What to do:</span> {info.error_action}</p>}
      {info.error_detail && <p className="font-mono text-[11px] text-red-600 break-all">{info.error_detail}</p>}
    </div>
  );
}

// A run the API refused to create, in the same shape as a failed run
export function launchFailure(err: unknown): RunStatusInfo {
  const detail = err instanceof Error ? err.message : String(err);
  const missing = detail.includes("no longer in the uploads folder");
  return {
    status: "failed", progress_pct: 0, overall_score: null, message: "Not started",
    error_title: missing ? "Source file not found" : "Run could not be started",
    error_explanation: missing
      ? "The Excel file registered for this dataset is no longer in the uploads folder."
      : "The DQ run could not be created.",
    error_action: missing
      ? "Re-upload the file in Metadata for this project, then start a new DQ run."
      : "Try again; if it keeps failing, send the detail below to the tech team.",
    error_detail: detail,
  };
}

// One file's line on the Generate step: status, columns done, countdown, score or failure reason
export function RunProgressRow({ filename, info, now }: { filename: string; info?: RunStatusInfo; now: number }) {
  const status = info?.status ?? "queuing";
  const left = secondsLeft(info, now);
  const total = info?.columns_total ?? null;
  const done = info?.columns_done ?? 0;
  let detail = "";
  if (status === "queuing") detail = "Creating the run…";
  else if (status === "pending" && info?.will_retry) detail = `${info.error_title ?? "Temporary problem"} — retrying automatically`;
  else if (status === "pending") detail = info?.queue_position ? `Waiting — ${info.queue_position} file${info.queue_position > 1 ? "s" : ""} ahead` : "Starting…";
  else if (status === "running") detail = total ? `${done} / ${total} columns checked` : "Reading the file…";
  else if (status === "completed") {
    const took = info?.started_at && info?.completed_at
      ? (new Date(info.completed_at).getTime() - new Date(info.started_at).getTime()) / 1000 : null;
    detail = `Score ${info?.overall_score ? parseFloat(info.overall_score).toFixed(1) : "—"}%${took ? ` · took ${formatDuration(took)}` : ""}`;
  }
  return (
    <div className="px-4 py-3 rounded-lg border border-gray-100 bg-gray-50">
      <div className="flex items-center gap-3">
        <div className="w-5 flex-shrink-0 flex items-center justify-center">
          {status === "completed" && <span className="text-green-600 font-bold">✓</span>}
          {status === "failed" && <span className="text-red-500 font-bold">✗</span>}
          {(status === "running" || status === "queuing") &&
            <div className="w-4 h-4 rounded-full border-2 border-blue-200 border-t-blue-600 animate-spin" />}
          {status === "pending" && <div className="w-4 h-4 rounded-full border-2 border-gray-300 bg-white" />}
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-sm text-gray-700 truncate">📄 {filename}</p>
          {detail && <p className="text-xs text-gray-500 mt-0.5">{detail}</p>}
        </div>
        {left !== null && (
          <span className="text-xs font-mono text-gray-600 whitespace-nowrap" title="Estimated time until this file is finished">
            ≈ {formatDuration(left)} left
          </span>
        )}
        <span className={`text-xs font-medium px-2 py-0.5 rounded-full capitalize whitespace-nowrap ${
          status === "completed" ? "bg-green-100 text-green-700" :
          status === "failed"    ? "bg-red-100 text-red-700" :
          status === "running"   ? "bg-blue-100 text-blue-700" :
          status === "queuing"   ? "bg-yellow-100 text-yellow-700" :
          "bg-gray-100 text-gray-500"
        }`}>{status}</span>
      </div>
      {status === "running" && total ? (
        <div className="mt-2 ml-8 bg-gray-200 rounded-full h-1.5 overflow-hidden">
          <div className="bg-blue-500 h-full transition-all duration-500" style={{ width: `${(100 * done) / total}%` }} />
        </div>
      ) : null}
      {status === "failed" && info && <div className="ml-8"><FailureBox info={info} /></div>}
    </div>
  );
}
