export interface FinalApprovalSignOffValue {
  approved?: string;
  prepared_by?: string;
  prepared_position?: string;
  prepared_signature?: string;
  prepared_date?: string;
  acknowledged_by?: string;
  acknowledged_position?: string;
  acknowledged_signature?: string;
  acknowledged_date?: string;
  prepared_signed_by?: string;
  acknowledged_signed_by?: string;
}

interface SignOffActorState {
  isProjectSme: boolean;
  isConfiguredDataOwner: boolean;
  canPrepareOnBehalf?: boolean;
}

export function buildActorSignOffPayload(
  value: FinalApprovalSignOffValue,
  actor: SignOffActorState,
): FinalApprovalSignOffValue {
  const payload = { ...value };
  if (!actor.isConfiguredDataOwner && !actor.canPrepareOnBehalf) {
    delete payload.prepared_by;
    delete payload.prepared_position;
    delete payload.prepared_signature;
    delete payload.prepared_date;
    delete payload.prepared_signed_by;
  }
  if (!actor.isProjectSme) {
    delete payload.approved;
    delete payload.acknowledged_by;
    delete payload.acknowledged_position;
    delete payload.acknowledged_signature;
    delete payload.acknowledged_date;
    delete payload.acknowledged_signed_by;
  }
  return payload;
}
