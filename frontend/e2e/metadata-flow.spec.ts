import { test, expect } from "./fixtures";

test.describe("Metadata Management Flow", () => {
  test("metadata home page loads", async ({ authenticatedPage: page }) => {
    await page.goto("/metadata");
    await expect(page.getByRole("heading", { name: /Metadata Management/i })).toBeVisible();
    await expect(page.getByText(/Source Configuration/i)).toBeVisible();
  });

  test("discover tables button exists", async ({ authenticatedPage: page }) => {
    await page.goto("/metadata");
    await expect(page.getByRole("button", { name: /Discover Tables/i })).toBeVisible();
  });

  test("source type toggle works", async ({ authenticatedPage: page }) => {
    await page.goto("/metadata");
    await page.getByRole("button", { name: /Excel/i }).click();
    await expect(page.getByRole("button", { name: /Excel/i })).toHaveClass(/bg-blue/);
  });
});
