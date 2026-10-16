"use client";

import { useRef, useState } from "react";

export type { FinalApprovalSignOffValue } from "@/lib/bapdSignOff";
import type { FinalApprovalSignOffValue } from "@/lib/bapdSignOff";

interface SignaturePadProps {
  value?: string;
  onSign: (signature: string) => void;
  onClear: () => void;
  disabled?: boolean;
}

function SignaturePad({ value, onSign, onClear, disabled }: SignaturePadProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const drawing = useRef(false);
  const lastPos = useRef<{ x: number; y: number } | null>(null);
  const [isDragging, setIsDragging] = useState(false);

  function loadImageFile(file: File) {
    if (!file.type.startsWith("image/")) return;
    const reader = new FileReader();
    reader.onload = (event) => onSign(event.target?.result as string);
    reader.readAsDataURL(file);
  }

  function getPos(event: React.MouseEvent<HTMLCanvasElement> | React.TouchEvent<HTMLCanvasElement>) {
    const rect = canvasRef.current!.getBoundingClientRect();
    if ("touches" in event) {
      return { x: event.touches[0].clientX - rect.left, y: event.touches[0].clientY - rect.top };
    }
    return {
      x: event.clientX - rect.left,
      y: event.clientY - rect.top,
    };
  }

  function beginDraw(event: React.MouseEvent<HTMLCanvasElement> | React.TouchEvent<HTMLCanvasElement>) {
    if ("touches" in event) event.preventDefault();
    drawing.current = true;
    lastPos.current = getPos(event);
  }

  function stroke(event: React.MouseEvent<HTMLCanvasElement> | React.TouchEvent<HTMLCanvasElement>) {
    if (!drawing.current) return;
    if ("touches" in event) event.preventDefault();
    const canvas = canvasRef.current!;
    const ctx = canvas.getContext("2d")!;
    const pos = getPos(event);
    ctx.strokeStyle = "#1e293b";
    ctx.lineWidth = 1.8;
    ctx.lineCap = "round";
    ctx.lineJoin = "round";
    ctx.beginPath();
    ctx.moveTo(lastPos.current!.x, lastPos.current!.y);
    ctx.lineTo(pos.x, pos.y);
    ctx.stroke();
    lastPos.current = pos;
  }

  function endDraw() {
    if (!drawing.current) return;
    drawing.current = false;
    lastPos.current = null;
    onSign(canvasRef.current!.toDataURL("image/png"));
  }

  function clearCanvas() {
    const canvas = canvasRef.current;
    if (canvas) canvas.getContext("2d")!.clearRect(0, 0, canvas.width, canvas.height);
    onClear();
  }

  if (disabled) {
    return value ? (
      <div className="border border-slate-200 rounded-md bg-white p-1 h-14">
        <img src={value} alt="signature" className="h-full w-full object-contain" />
      </div>
    ) : (
      <div className="border border-dashed border-slate-200 rounded-md h-14 flex items-center justify-center bg-slate-50">
        <span className="text-xs text-slate-400">Not signed</span>
      </div>
    );
  }

  if (value) {
    return (
      <div>
        <div className="border border-green-300 rounded-md bg-green-50 p-1 h-14 relative">
          <img src={value} alt="signature" className="h-full w-full object-contain" />
          <span className="absolute top-1 right-1 text-xs text-green-600 font-medium">✓ Signed</span>
        </div>
        <button type="button" onClick={clearCanvas} className="text-xs text-red-500 hover:text-red-700 mt-0.5 hover:underline">
          Clear &amp; re-sign
        </button>
      </div>
    );
  }

  return (
    <div>
      <div
        className={`relative border rounded-md bg-white overflow-hidden h-14 transition-colors ${
          isDragging ? "border-blue-400 bg-blue-50 cursor-copy" : "border-slate-300 cursor-crosshair"
        }`}
        onDragOver={(event) => { event.preventDefault(); setIsDragging(true); }}
        onDragEnter={(event) => { event.preventDefault(); setIsDragging(true); }}
        onDragLeave={(event) => { event.preventDefault(); setIsDragging(false); }}
        onDrop={(event) => {
          event.preventDefault();
          setIsDragging(false);
          const file = event.dataTransfer.files[0];
          if (file) loadImageFile(file);
        }}
      >
        <span className="absolute inset-0 flex items-center justify-center text-xs pointer-events-none select-none">
          {isDragging ? <span className="text-blue-500 font-medium">Drop image here</span> : <span className="text-slate-300">Draw signature here</span>}
        </span>
        <canvas
          ref={canvasRef}
          width={500}
          height={56}
          className={`w-full h-full touch-none ${isDragging ? "pointer-events-none" : ""}`}
          onMouseDown={beginDraw}
          onMouseMove={stroke}
          onMouseUp={endDraw}
          onMouseLeave={endDraw}
          onTouchStart={beginDraw}
          onTouchMove={stroke}
          onTouchEnd={endDraw}
        />
      </div>
      <div className="flex items-center gap-1 mt-1">
        <span className="text-xs text-slate-400">or</span>
        <button type="button" onClick={() => fileInputRef.current?.click()} className="text-xs text-blue-600 hover:underline">
          upload signature image
        </button>
        <input
          ref={fileInputRef}
          type="file"
          accept="image/*"
          className="hidden"
          onChange={(event) => {
            const file = event.target.files?.[0];
            if (file) loadImageFile(file);
            event.target.value = "";
          }}
        />
      </div>
    </div>
  );
}

interface FinalApprovalSignOffProps {
  value: FinalApprovalSignOffValue;
  onChange: (field: keyof FinalApprovalSignOffValue, value: string) => void;
  disabled?: boolean;
  showErrors?: boolean;
  acknowledgedReadOnly?: boolean;
  acknowledgedSignatureReadOnly?: boolean;
  acknowledgedNameReadOnly?: boolean;
  acknowledgedPositionReadOnly?: boolean;
  approvalOnly?: boolean;
  approvedReadOnly?: boolean;
  preparedReadOnly?: boolean;
  prepareOnBehalf?: boolean;
  preparedNameReadOnly?: boolean;
  preparedPositionReadOnly?: boolean;
}

export function FinalApprovalSignOff({
  value,
  onChange,
  disabled,
  showErrors,
  acknowledgedReadOnly,
  acknowledgedSignatureReadOnly,
  acknowledgedNameReadOnly,
  acknowledgedPositionReadOnly,
  approvalOnly,
  approvedReadOnly,
  preparedReadOnly,
  prepareOnBehalf,
  preparedNameReadOnly,
  preparedPositionReadOnly,
}: FinalApprovalSignOffProps) {
  function errorClass(field: keyof FinalApprovalSignOffValue) {
    return showErrors && !String(value[field] ?? "").trim() ? "border-red-500 ring-1 ring-red-400" : "";
  }

  function handleSign(prefix: "prepared" | "acknowledged", signature: string) {
    onChange(`${prefix}_signature` as keyof FinalApprovalSignOffValue, signature);
    onChange(`${prefix}_date` as keyof FinalApprovalSignOffValue, new Date().toISOString().slice(0, 10));
  }

  function handleClear(prefix: "prepared" | "acknowledged") {
    onChange(`${prefix}_signature` as keyof FinalApprovalSignOffValue, "");
    onChange(`${prefix}_date` as keyof FinalApprovalSignOffValue, "");
  }

  return (
    <div>
      <h2 className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800 border-b border-slate-100 pb-2 mb-3">
        Final Approval &amp; Sign Off
      </h2>
      <p className="text-xs text-slate-500 mb-3">
        {approvalOnly
          ? prepareOnBehalf
            ? "The configured Project Data Owner is not registered on this platform. As the assigned Project SME, complete both signatures on behalf of the named Data Owner and submit the final approval."
            : "Review the BAPD and complete the final approval. The prepared sign-off is owned by the configured Project Data Owner."
          : "The Project Data Owner completes the prepared sign-off; the assigned Project SME submits the final approval."}
      </p>
      <div className="flex items-center gap-3 mb-3">
        <span className="text-sm font-medium text-slate-700 w-28 shrink-0">Approved? <span className="text-red-500">*</span></span>
        <select
          value={value.approved ?? ""}
          onChange={(event) => onChange("approved", event.target.value)}
          disabled={disabled || approvedReadOnly}
          className={`input-base text-sm w-24 ${value.approved === "Yes" ? "border-green-400 bg-green-50 text-green-700" : value.approved === "No" ? "border-red-300 bg-red-50 text-red-700" : showErrors && !value.approved ? "border-red-500 ring-1 ring-red-400 bg-red-50" : ""}`}
        >
          <option value="" disabled hidden>Yes/No</option>
          <option value="Yes">Yes</option>
          <option value="No">No</option>
        </select>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="space-y-2">
          <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide">
            Prepared By {preparedNameReadOnly ? <span className="text-blue-500 normal-case font-normal">(auto-filled · Project Data Owner)</span> : null}
            {prepareOnBehalf ? <span className="text-amber-600 normal-case font-normal">(SME signing on behalf)</span> : null}
          </p>
          <input type="text" placeholder="Full name" value={value.prepared_by ?? ""} disabled={disabled || preparedNameReadOnly} onChange={(event) => onChange("prepared_by", event.target.value)} className={`input-base text-sm w-full ${disabled || preparedNameReadOnly ? "bg-slate-50 text-slate-600" : errorClass("prepared_by")}`} />
          <input type="text" placeholder="Position" value={value.prepared_position ?? ""} disabled={disabled || preparedPositionReadOnly} onChange={(event) => onChange("prepared_position", event.target.value)} className={`input-base text-sm w-full ${disabled || preparedPositionReadOnly ? "bg-slate-50 text-slate-600" : errorClass("prepared_position")}`} />
          <SignaturePad value={value.prepared_signature} onSign={(signature) => handleSign("prepared", signature)} onClear={() => handleClear("prepared")} disabled={disabled || preparedReadOnly} />
          {showErrors && !value.prepared_signature && <p className="text-[11px] text-rose-600">Signature required for final approval.</p>}
          {value.prepared_signature && value.prepared_date && <p className="text-xs text-slate-400">Signed on: <span className="font-medium text-slate-600">{value.prepared_date}</span></p>}
        </div>

        <div className="space-y-2">
          <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide">
            Acknowledged By {acknowledgedReadOnly || acknowledgedNameReadOnly || acknowledgedPositionReadOnly ? <span className="text-blue-500 normal-case font-normal">(auto-filled · Project SME)</span> : null}
          </p>
          <input type="text" placeholder="Full name" value={value.acknowledged_by ?? ""} disabled={disabled || acknowledgedReadOnly || acknowledgedNameReadOnly} onChange={(event) => onChange("acknowledged_by", event.target.value)} className={`input-base text-sm w-full ${disabled || acknowledgedReadOnly || acknowledgedNameReadOnly ? "bg-slate-50 text-slate-600" : errorClass("acknowledged_by")}`} />
          <input type="text" placeholder="Position" value={value.acknowledged_position ?? ""} disabled={disabled || acknowledgedReadOnly || acknowledgedPositionReadOnly} onChange={(event) => onChange("acknowledged_position", event.target.value)} className={`input-base text-sm w-full ${disabled || acknowledgedReadOnly || acknowledgedPositionReadOnly ? "bg-slate-50 text-slate-600" : errorClass("acknowledged_position")}`} />
          <SignaturePad value={value.acknowledged_signature} onSign={(signature) => handleSign("acknowledged", signature)} onClear={() => handleClear("acknowledged")} disabled={disabled || acknowledgedReadOnly || acknowledgedSignatureReadOnly} />
          {showErrors && !value.acknowledged_signature && <p className="text-[11px] text-rose-600">Signature required for final approval.</p>}
          {value.acknowledged_signature && value.acknowledged_date && <p className="text-xs text-slate-400">Signed on: <span className="font-medium text-slate-600">{value.acknowledged_date}</span></p>}
        </div>
      </div>
    </div>
  );
}
