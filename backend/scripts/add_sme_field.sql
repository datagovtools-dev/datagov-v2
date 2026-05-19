-- Step 1: Add sme_id column to projects table
ALTER TABLE projects
ADD COLUMN IF NOT EXISTS sme_id UUID REFERENCES users(id);

-- Step 2: Assign a random active user as SME to the trial project (PRJ-2026-001)
UPDATE projects
SET sme_id = (
    SELECT id FROM users
    WHERE is_active = true
      AND id NOT IN (
          SELECT delivery_manager_id FROM projects WHERE project_code = 'PRJ-2026-001' AND delivery_manager_id IS NOT NULL
          UNION
          SELECT project_manager_id  FROM projects WHERE project_code = 'PRJ-2026-001' AND project_manager_id IS NOT NULL
      )
    ORDER BY random()
    LIMIT 1
)
WHERE project_code = 'PRJ-2026-001';

-- Verify
SELECT p.project_code, p.project_name,
       u.full_name AS sme_name, u.email AS sme_email
FROM projects p
LEFT JOIN users u ON u.id = p.sme_id
WHERE p.project_code = 'PRJ-2026-001';
