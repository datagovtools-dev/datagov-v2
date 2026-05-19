import { test, expect } from "./fixtures";

test.describe("DSR Flow", () => {
  test("DSR list page loads", async ({ authenticatedPage: page }) => {
    await page.goto("/dsr");
    await expect(page.getByRole("heading", { name: /Data Sharing Requests/i })).toBeVisible();
  });

  test("new DSR form is accessible", async ({ authenticatedPage: page }) => {
    await page.goto("/dsr/new");
    await expect(page.getByRole("heading", { name: /New.*Request/i })).toBeVisible();
    await expect(page.getByLabelText(/requester/i)).toBeVisible();
  });

  test("submitting empty DSR form shows validation", async ({ authenticatedPage: page }) => {
    await page.goto("/dsr/new");
    await page.getByRole("button", { name: /submit/i }).click();
    // Form fields should be required — at least one error visible
    const errors = await page.locator("[aria-invalid='true'], .text-red-500").count();
    expect(errors).toBeGreaterThan(0);
  });
});
