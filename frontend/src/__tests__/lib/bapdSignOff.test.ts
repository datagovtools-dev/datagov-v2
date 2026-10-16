import { buildActorSignOffPayload, type FinalApprovalSignOffValue } from "@/lib/bapdSignOff";

describe("buildActorSignOffPayload", () => {
  const draft: FinalApprovalSignOffValue = {
    approved: "Yes",
    prepared_by: "Amelia Brooks",
    prepared_position: "Project Data Owner",
    prepared_signature: "prepared-image",
    prepared_date: "2026-10-16",
    prepared_signed_by: "data-owner-id",
    acknowledged_by: "Citra Nirmala",
    acknowledged_position: "Product Manager",
    acknowledged_signature: "sme-image",
    acknowledged_date: "2026-10-16",
    acknowledged_signed_by: "sme-id",
  };

  it("sends only approval fields when the assigned SME submits", () => {
    expect(buildActorSignOffPayload(draft, { isProjectSme: true, isConfiguredDataOwner: false })).toEqual({
      approved: "Yes",
      acknowledged_by: "Citra Nirmala",
      acknowledged_position: "Product Manager",
      acknowledged_signature: "sme-image",
      acknowledged_date: "2026-10-16",
      acknowledged_signed_by: "sme-id",
    });
  });

  it("sends both sign-off sections when the SME is delegated for an unregistered data owner", () => {
    expect(buildActorSignOffPayload(draft, {
      isProjectSme: true,
      isConfiguredDataOwner: false,
      canPrepareOnBehalf: true,
    })).toEqual(draft);
  });
  it("sends only prepared fields when the configured data owner saves", () => {
    expect(buildActorSignOffPayload(draft, { isProjectSme: false, isConfiguredDataOwner: true })).toEqual({
      prepared_by: "Amelia Brooks",
      prepared_position: "Project Data Owner",
      prepared_signature: "prepared-image",
      prepared_date: "2026-10-16",
      prepared_signed_by: "data-owner-id",
    });
  });
});
