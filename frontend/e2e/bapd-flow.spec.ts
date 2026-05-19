import { test, expect } from "./fixtures";

test.describe("BAPD Flow", () => {
  test("BAPD list page loads", async ({ authenticatedPage: page }) => {
    await page.goto("/bapd");
    await expect(page.getByRole("heading", { name: /Data Extermination/i })).toBeVisible();
  });

  test("new BAPD form shows danger banner", async ({ authenticatedPage: page }) => {
    await page.goto("/bapd/new");
    await expect(page.getByText(/irreversible/i)).toBeVisible();
  });

  test("BAPD form requires confirmation checkbox", async ({ authenticatedPage: page }) => {
    await page.goto("/bapd/new");
    const submitButton = page.getByRole("button", { name: /submit/i });
    // Submit should be disabled without confirmation
    await expect(submitButton).toBeDisabled();
  });
});
