import { cn, formatDateTime } from "@/lib/utils";

describe("cn (classname utility)", () => {
  it("merges class names", () => {
    expect(cn("foo", "bar")).toContain("foo");
    expect(cn("foo", "bar")).toContain("bar");
  });

  it("handles conditional classes", () => {
    expect(cn("foo", false && "bar")).not.toContain("bar");
    expect(cn("foo", true && "baz")).toContain("baz");
  });

  it("resolves tailwind conflicts (last wins)", () => {
    // tailwind-merge should keep the last conflicting utility
    const result = cn("px-2", "px-4");
    expect(result).toContain("px-4");
    expect(result).not.toContain("px-2");
  });
});

describe("formatDateTime", () => {
  it("formats a valid ISO timestamp", () => {
    const result = formatDateTime("2024-01-15T10:30:00.000Z");
    expect(typeof result).toBe("string");
    expect(result.length).toBeGreaterThan(0);
  });

  it("returns dash placeholder for empty input", () => {
    expect(formatDateTime("")).toBe("—");
  });
});
