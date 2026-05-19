-- Fix approval steps for DSR-2026-0001
-- Run this in pgAdmin or any PostgreSQL client connected to ag_db
-- It replaces existing steps with 4 fully-approved steps.

DO $$
DECLARE
  v_dsr_id   UUID;
  v_user_id  UUID;
  v_now      TIMESTAMPTZ := NOW();
BEGIN

  -- Get the trial DSR id
  SELECT id INTO v_dsr_id
  FROM data_sharing_requests
  WHERE tracking_id = 'DSR-2026-0001';

  IF v_dsr_id IS NULL THEN
    RAISE EXCEPTION 'DSR-2026-0001 not found';
  END IF;

  -- Get the first active user (Super Administrator)
  SELECT id INTO v_user_id
  FROM users
  WHERE is_active = TRUE
  ORDER BY created_at
  LIMIT 1;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'No active user found';
  END IF;

  -- Remove existing steps
  DELETE FROM dsr_approvals WHERE dsr_id = v_dsr_id;

  -- Insert 4 approved steps
  INSERT INTO dsr_approvals (id, dsr_id, approver_id, approver_role, step_order, status, actioned_at, comments)
  VALUES
    (gen_random_uuid(), v_dsr_id, v_user_id, 'data_governance_officer', 1, 'approved', v_now, NULL),
    (gen_random_uuid(), v_dsr_id, v_user_id, 'dm_pm',                   2, 'approved', v_now, NULL),
    (gen_random_uuid(), v_dsr_id, v_user_id, 'sme',                     3, 'approved', v_now, NULL),
    (gen_random_uuid(), v_dsr_id, v_user_id, 'client',                  4, 'approved', v_now, NULL);

  RAISE NOTICE 'Done — 4 approved steps inserted for DSR-2026-0001 (DSR id: %)', v_dsr_id;

END $$;
