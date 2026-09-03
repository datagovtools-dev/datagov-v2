import { render, screen } from "@testing-library/react";
import { Badge } from "@/components/ui/Badge";

describe("Badge", () => {
  it("renders children", () => {
    render(<Badge>Hello</Badge>);
    expect(screen.getByText("Hello")).toBeInTheDocument();
  });

  it("applies variant class for success", () => {
    const { container } = render(<Badge variant="success">Done</Badge>);
    expect(container.firstChild).toHaveClass("bg-green-100");
  });

  it("applies variant class for danger", () => {
    const { container } = render(<Badge variant="danger">Error</Badge>);
    expect(container.firstChild).toHaveClass("bg-red-100");
  });

  it("renders without variant (default)", () => {
    render(<Badge variant="default">Default</Badge>);
    expect(screen.getByText("Default")).toBeInTheDocument();
  });
});
