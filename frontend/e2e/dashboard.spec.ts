import { test, expect } from "./fixtures";

test.describe("Dashboard (authenticated)", () => {
  test("shows KPI cards", async ({ authenticatedPage: page }) => {
    await page.goto("/dashboard");
    await expect(page.getByText(/Active Projects/i)).toBeVisible();
    await expect(page.getByText(/Open DSRs/i)).toBeVisible();
    await expect(page.getByText(/Pending DPIAs/i)).toBeVisible();
  });

  test("shows recent activity section", async ({ authenticatedPage: page }) => {
    await page.goto("/dashboard");
    await expect(page.getByText(/Recent Activity/i)).toBeVisible();
  });

  test("shows quick actions", async ({ authenticatedPage: page }) => {
    await page.goto("/dashboard");
    await expect(page.getByText(/New Data Sharing Request/i)).toBeVisible();
    await expect(page.getByText(/Run Data Quality Check/i)).toBeVisible();
  });
});
