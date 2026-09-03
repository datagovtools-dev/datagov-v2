BEGIN TRANSACTION;
CREATE TABLE ai_checklist_approvals (
	id VARCHAR(36) NOT NULL, 
	checklist_id VARCHAR(36) NOT NULL, 
	approver_id VARCHAR(36) NOT NULL, 
	approver_role VARCHAR(80) NOT NULL, 
	step_order SMALLINT NOT NULL, 
	status VARCHAR(20) NOT NULL, 
	comments TEXT, 
	actioned_at DATETIME, 
	CONSTRAINT pk_ai_checklist_approvals PRIMARY KEY (id), 
	CONSTRAINT fk_ai_checklist_approvals_checklist_id_ai_compliance_checklists FOREIGN KEY(checklist_id) REFERENCES ai_compliance_checklists (id) ON DELETE CASCADE, 
	CONSTRAINT fk_ai_checklist_approvals_approver_id_users FOREIGN KEY(approver_id) REFERENCES users (id)
);
INSERT INTO "ai_checklist_approvals" VALUES('0dbed0fbdb7c40cdb9a69c99c7db2075','50ca96cab80745bc9cbe449f80b9ce2f','92d40357c37041bd843ca09f0abc31a6','pic_compliance',1,'approved','','2026-08-30 06:35:44.417566');
INSERT INTO "ai_checklist_approvals" VALUES('ae3d9c595847444c856e75e112a24ea3','50ca96cab80745bc9cbe449f80b9ce2f','2c8b080e236f4808ba5024c9f6a3c494','dm',2,'approved','','2026-08-30 06:36:43.415611');
INSERT INTO "ai_checklist_approvals" VALUES('1eddd8dfcae74c0ca3bc0c9702a64d0e','50ca96cab80745bc9cbe449f80b9ce2f','eb2cf472bae34648b444ac549055b410','sme',3,'requested',NULL,NULL);
INSERT INTO "ai_checklist_approvals" VALUES('24beba09319943a3b0a80aa506583971','46d43dc52b1a40c9acc8db2e7a1ec615','92d40357c37041bd843ca09f0abc31a6','pic_compliance',1,'pending',NULL,NULL);
INSERT INTO "ai_checklist_approvals" VALUES('be2a20ecbd224b568c1c73aeba9d7e41','46d43dc52b1a40c9acc8db2e7a1ec615','2c8b080e236f4808ba5024c9f6a3c494','dm',2,'pending',NULL,NULL);
INSERT INTO "ai_checklist_approvals" VALUES('3b30e1c2cdcf4bb988c8fa63a330fba3','46d43dc52b1a40c9acc8db2e7a1ec615','eb2cf472bae34648b444ac549055b410','sme',3,'pending',NULL,NULL);
CREATE TABLE ai_compliance_checklists (
	id VARCHAR(36) NOT NULL, 
	dsr_id VARCHAR(36) NOT NULL, 
	checklist_json JSON NOT NULL, 
	status VARCHAR(30) NOT NULL, 
	validated_by VARCHAR(36), 
	validated_at DATETIME, 
	CONSTRAINT pk_ai_compliance_checklists PRIMARY KEY (id), 
	CONSTRAINT uq_ai_compliance_checklists_dsr_id UNIQUE (dsr_id), 
	CONSTRAINT fk_ai_compliance_checklists_dsr_id_data_sharing_requests FOREIGN KEY(dsr_id) REFERENCES data_sharing_requests (id), 
	CONSTRAINT fk_ai_compliance_checklists_validated_by_users FOREIGN KEY(validated_by) REFERENCES users (id)
);
INSERT INTO "ai_compliance_checklists" VALUES('50ca96cab80745bc9cbe449f80b9ce2f','4472b214d38548ee8be3ef42ee81c49b','{"sign_off": {"approved": "No", "acknowledged_by": "Ahmad Fauzi", "acknowledged_position": "Delivery Manager"}, "A_i_1": {"answer": "No", "remarks": "-"}, "A_i_2": {"answer": "No", "remarks": "-"}, "A_i_3": {"answer": "No", "remarks": "-"}, "A_ii_1": {"answer": "No", "remarks": "-"}, "A_ii_2": {"answer": "No", "remarks": "-"}, "A_ii_3": {"answer": "No", "remarks": "-"}, "A_ii_4": {"answer": "No", "remarks": "-"}, "B_i": {"answer": "No", "remarks": "-"}, "B_ii": {"answer": "No", "remarks": "-"}, "B_iii": {"answer": "No", "remarks": "-"}, "B_iv": {"answer": "No", "remarks": "-"}, "B_v": {"answer": "No", "remarks": "-"}, "B_vi": {"answer": "No", "remarks": "-"}, "C_i_1": {"answer": "No", "remarks": "-"}, "C_i_2": {"answer": "No", "remarks": "-"}, "C_i_3": {"answer": "No", "remarks": "-"}, "D_i": {"answer": "Yes", "remarks": "Yes using AI"}, "ai_assessment": {"items": {"before_use_1": {"status": "No", "remarks": "yes"}, "before_use_2": {"status": "Yes", "remarks": "yes"}, "before_use_3": {"status": "Yes", "remarks": "yes"}, "input_1": {"status": "Yes", "remarks": "yes"}, "input_2": {"status": "Yes", "remarks": "yes"}, "input_3": {"status": "Yes", "remarks": "yes"}, "output_1": {"status": "Yes", "remarks": "yes"}, "output_2": {"status": "Yes", "remarks": "yes"}, "utilization_1": {"status": "Yes", "remarks": "yes"}, "utilization_2": {"status": "Yes", "remarks": "yes"}}, "sign_off": {"prepared_by": "Anisa Putri", "prepared_position": "Data Governance Officer (DGO)", "acknowledged_by": "Ahmad Fauzi", "acknowledged_position": "Delivery Manager", "approved": "No"}}}','under_review',NULL,NULL);
INSERT INTO "ai_compliance_checklists" VALUES('46d43dc52b1a40c9acc8db2e7a1ec615','79475b6756674da5a5ad7bd028c0895c','{}','draft',NULL,NULL);
CREATE TABLE ai_provider_configs (
	id VARCHAR(36) NOT NULL, 
	provider VARCHAR(40) NOT NULL, 
	mode VARCHAR(40) NOT NULL, 
	enabled BOOLEAN NOT NULL, 
	base_url VARCHAR(500) NOT NULL, 
	model_name VARCHAR(160) NOT NULL, 
	timeout_seconds INTEGER NOT NULL, 
	batch_size INTEGER NOT NULL, 
	encrypted_api_key TEXT, 
	api_key_last4 VARCHAR(12), 
	updated_by VARCHAR(36), 
	created_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL, 
	updated_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL, 
	CONSTRAINT pk_ai_provider_configs PRIMARY KEY (id), 
	CONSTRAINT fk_ai_provider_configs_updated_by_users FOREIGN KEY(updated_by) REFERENCES users (id)
);
CREATE TABLE audit_logs (
	id INTEGER NOT NULL, 
	user_id VARCHAR(36), 
	module VARCHAR(60) NOT NULL, 
	action VARCHAR(80) NOT NULL, 
	entity_type VARCHAR(80), 
	entity_id TEXT, 
	details JSON, 
	ip_address VARCHAR(45), 
	user_agent TEXT, 
	created_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL, 
	CONSTRAINT pk_audit_logs PRIMARY KEY (id), 
	CONSTRAINT fk_audit_logs_user_id_users FOREIGN KEY(user_id) REFERENCES users (id)
);
INSERT INTO "audit_logs" VALUES(1,'ac6a037060964450a5a923c9a534e6b9','auth','login','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-30 05:28:23');
INSERT INTO "audit_logs" VALUES(2,'ac6a037060964450a5a923c9a534e6b9','auth','login','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-30 05:28:27');
INSERT INTO "audit_logs" VALUES(3,'ac6a037060964450a5a923c9a534e6b9','auth','login','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-30 05:28:32');
INSERT INTO "audit_logs" VALUES(4,'ac6a037060964450a5a923c9a534e6b9','auth','login','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 05:58:05');
INSERT INTO "audit_logs" VALUES(5,'ac6a037060964450a5a923c9a534e6b9','auth','login','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 05:58:19');
INSERT INTO "audit_logs" VALUES(6,'ac6a037060964450a5a923c9a534e6b9','project','create','project','6bda7780-1b7e-4178-ad23-a1cbb180ea47','{"project_name": "DIDX", "customer_name": "TAM"}',NULL,NULL,'2026-08-30 06:00:33');
INSERT INTO "audit_logs" VALUES(7,'ac6a037060964450a5a923c9a534e6b9','dsr','create','dsr','4472b214-d385-48ee-8be3-ef42ee81c49b','{"tracking_id": "DSR-2026-0001"}',NULL,NULL,'2026-08-30 06:00:49');
INSERT INTO "audit_logs" VALUES(8,'ac6a037060964450a5a923c9a534e6b9','dsr','update_checklist','ai_checklist','4472b214-d385-48ee-8be3-ef42ee81c49b',NULL,NULL,NULL,'2026-08-30 06:01:00');
INSERT INTO "audit_logs" VALUES(9,'ac6a037060964450a5a923c9a534e6b9','dsr','update','dsr','4472b214-d385-48ee-8be3-ef42ee81c49b',NULL,NULL,NULL,'2026-08-30 06:01:01');
INSERT INTO "audit_logs" VALUES(10,'ac6a037060964450a5a923c9a534e6b9','dsr','update_checklist','ai_checklist','4472b214-d385-48ee-8be3-ef42ee81c49b',NULL,NULL,NULL,'2026-08-30 06:02:17');
INSERT INTO "audit_logs" VALUES(11,'ac6a037060964450a5a923c9a534e6b9','dsr','update','dsr','4472b214-d385-48ee-8be3-ef42ee81c49b',NULL,NULL,NULL,'2026-08-30 06:02:17');
INSERT INTO "audit_logs" VALUES(12,'ac6a037060964450a5a923c9a534e6b9','dsr','update_checklist','ai_checklist','4472b214-d385-48ee-8be3-ef42ee81c49b',NULL,NULL,NULL,'2026-08-30 06:03:59');
INSERT INTO "audit_logs" VALUES(13,'ac6a037060964450a5a923c9a534e6b9','dsr','submit_ai_checklist','ai_checklist','50ca96ca-b807-45bc-9cbe-449f80b9ce2f','{"tracking_id": "DSR-2026-0001"}',NULL,NULL,'2026-08-30 06:04:00');
INSERT INTO "audit_logs" VALUES(14,'92d40357c37041bd843ca09f0abc31a6','auth','login','user','92d40357-c370-41bd-843c-a09f0abc31a6',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 06:17:53');
INSERT INTO "audit_logs" VALUES(15,'92d40357c37041bd843ca09f0abc31a6','auth','login','user','92d40357-c370-41bd-843c-a09f0abc31a6',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-30 06:21:15');
INSERT INTO "audit_logs" VALUES(16,'92d40357c37041bd843ca09f0abc31a6','auth','login','user','92d40357-c370-41bd-843c-a09f0abc31a6',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-30 06:24:10');
INSERT INTO "audit_logs" VALUES(17,'92d40357c37041bd843ca09f0abc31a6','auth','token_refresh','user','92d40357-c370-41bd-843c-a09f0abc31a6',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 06:35:32');
INSERT INTO "audit_logs" VALUES(18,'92d40357c37041bd843ca09f0abc31a6','auth','token_refresh','user','92d40357-c370-41bd-843c-a09f0abc31a6',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 06:35:32');
INSERT INTO "audit_logs" VALUES(19,'92d40357c37041bd843ca09f0abc31a6','auth','token_refresh','user','92d40357-c370-41bd-843c-a09f0abc31a6',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 06:35:33');
INSERT INTO "audit_logs" VALUES(20,'92d40357c37041bd843ca09f0abc31a6','dsr','ai_checklist_approval_approve','ai_checklist','50ca96ca-b807-45bc-9cbe-449f80b9ce2f','{"step": 1, "comments": ""}',NULL,NULL,'2026-08-30 06:35:44');
INSERT INTO "audit_logs" VALUES(21,'92d40357c37041bd843ca09f0abc31a6','auth','token_refresh','user','92d40357-c370-41bd-843c-a09f0abc31a6',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 06:36:03');
INSERT INTO "audit_logs" VALUES(22,'92d40357c37041bd843ca09f0abc31a6','auth','token_refresh','user','92d40357-c370-41bd-843c-a09f0abc31a6',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 06:36:03');
INSERT INTO "audit_logs" VALUES(23,'2c8b080e236f4808ba5024c9f6a3c494','auth','login','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 06:36:35');
INSERT INTO "audit_logs" VALUES(24,'2c8b080e236f4808ba5024c9f6a3c494','dsr','ai_checklist_approval_approve','ai_checklist','50ca96ca-b807-45bc-9cbe-449f80b9ce2f','{"step": 2, "comments": ""}',NULL,NULL,'2026-08-30 06:36:43');
INSERT INTO "audit_logs" VALUES(25,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 06:36:56');
INSERT INTO "audit_logs" VALUES(26,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 06:36:56');
INSERT INTO "audit_logs" VALUES(27,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 07:40:31');
INSERT INTO "audit_logs" VALUES(28,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 07:40:31');
INSERT INTO "audit_logs" VALUES(29,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 09:36:09');
INSERT INTO "audit_logs" VALUES(30,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 09:36:09');
INSERT INTO "audit_logs" VALUES(31,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 09:36:09');
INSERT INTO "audit_logs" VALUES(32,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 09:36:10');
INSERT INTO "audit_logs" VALUES(33,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 09:36:13');
INSERT INTO "audit_logs" VALUES(34,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 09:36:13');
INSERT INTO "audit_logs" VALUES(35,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 09:53:11');
INSERT INTO "audit_logs" VALUES(36,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 09:53:11');
INSERT INTO "audit_logs" VALUES(37,'ac6a037060964450a5a923c9a534e6b9','auth','login','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-30 10:00:11');
INSERT INTO "audit_logs" VALUES(38,'ac6a037060964450a5a923c9a534e6b9','auth','login','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-30 10:04:39');
INSERT INTO "audit_logs" VALUES(39,'ac6a037060964450a5a923c9a534e6b9','auth','login','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-30 10:04:48');
INSERT INTO "audit_logs" VALUES(40,'ac6a037060964450a5a923c9a534e6b9','auth','login','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-30 10:06:22');
INSERT INTO "audit_logs" VALUES(41,'ac6a037060964450a5a923c9a534e6b9','ropa','create','ropa','0e9a0da5-0124-4e83-a5b6-af156357a222',NULL,NULL,NULL,'2026-08-30 10:06:22');
INSERT INTO "audit_logs" VALUES(42,'ac6a037060964450a5a923c9a534e6b9','ropa','transition_submitted','ropa','0e9a0da5-0124-4e83-a5b6-af156357a222','{"from": "draft", "to": "submitted", "comments": "Ready for DGO compliance review"}',NULL,NULL,'2026-08-30 10:06:22');
INSERT INTO "audit_logs" VALUES(43,'eb2cf472bae34648b444ac549055b410','auth','login','user','eb2cf472-bae3-4648-b444-ac549055b410',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-30 10:06:30');
INSERT INTO "audit_logs" VALUES(44,'eb2cf472bae34648b444ac549055b410','ropa','transition_under_review','ropa','0e9a0da5-0124-4e83-a5b6-af156357a222','{"from": "submitted", "to": "under_review", "comments": null}',NULL,NULL,'2026-08-30 10:06:30');
INSERT INTO "audit_logs" VALUES(45,'eb2cf472bae34648b444ac549055b410','ropa','transition_approved','ropa','0e9a0da5-0124-4e83-a5b6-af156357a222','{"from": "under_review", "to": "approved", "comments": "Fully compliant with PDP Law Article 30"}',NULL,NULL,'2026-08-30 10:06:31');
INSERT INTO "audit_logs" VALUES(46,'ac6a037060964450a5a923c9a534e6b9','auth','login','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-30 10:08:37');
INSERT INTO "audit_logs" VALUES(47,'ac6a037060964450a5a923c9a534e6b9','ropa','create','ropa','e0f941a4-0390-486b-9efd-dd5c96524dc0',NULL,NULL,NULL,'2026-08-30 10:08:40');
INSERT INTO "audit_logs" VALUES(48,'ac6a037060964450a5a923c9a534e6b9','ropa','transition_submitted','ropa','e0f941a4-0390-486b-9efd-dd5c96524dc0','{"from": "draft", "to": "submitted", "comments": "Ready for DGO compliance review"}',NULL,NULL,'2026-08-30 10:08:41');
INSERT INTO "audit_logs" VALUES(49,'eb2cf472bae34648b444ac549055b410','auth','login','user','eb2cf472-bae3-4648-b444-ac549055b410',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-30 10:08:59');
INSERT INTO "audit_logs" VALUES(50,'eb2cf472bae34648b444ac549055b410','ropa','transition_under_review','ropa','e0f941a4-0390-486b-9efd-dd5c96524dc0','{"from": "submitted", "to": "under_review", "comments": null}',NULL,NULL,'2026-08-30 10:09:00');
INSERT INTO "audit_logs" VALUES(51,'eb2cf472bae34648b444ac549055b410','ropa','transition_approved','ropa','e0f941a4-0390-486b-9efd-dd5c96524dc0','{"from": "under_review", "to": "approved", "comments": "Fully compliant with PDP Law Article 30"}',NULL,NULL,'2026-08-30 10:09:00');
INSERT INTO "audit_logs" VALUES(52,'5b5a78847ea44fbcb7dd0c9d44567ab1','auth','login','user','5b5a7884-7ea4-4fbc-b7dd-0c9d44567ab1',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-30 10:10:03');
INSERT INTO "audit_logs" VALUES(53,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 10:12:17');
INSERT INTO "audit_logs" VALUES(54,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 10:12:17');
INSERT INTO "audit_logs" VALUES(55,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 10:12:17');
INSERT INTO "audit_logs" VALUES(56,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 10:14:57');
INSERT INTO "audit_logs" VALUES(57,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 10:14:57');
INSERT INTO "audit_logs" VALUES(58,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 15:31:59');
INSERT INTO "audit_logs" VALUES(59,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 15:31:59');
INSERT INTO "audit_logs" VALUES(60,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 15:31:59');
INSERT INTO "audit_logs" VALUES(61,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 15:32:00');
INSERT INTO "audit_logs" VALUES(62,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 15:32:00');
INSERT INTO "audit_logs" VALUES(63,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 15:32:03');
INSERT INTO "audit_logs" VALUES(64,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 15:32:04');
INSERT INTO "audit_logs" VALUES(65,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 15:38:49');
INSERT INTO "audit_logs" VALUES(66,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 15:38:49');
INSERT INTO "audit_logs" VALUES(67,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 15:39:07');
INSERT INTO "audit_logs" VALUES(68,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-30 15:39:07');
INSERT INTO "audit_logs" VALUES(69,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 00:29:03');
INSERT INTO "audit_logs" VALUES(70,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 00:29:03');
INSERT INTO "audit_logs" VALUES(71,'ac6a037060964450a5a923c9a534e6b9','auth','login','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 00:35:45');
INSERT INTO "audit_logs" VALUES(72,'ac6a037060964450a5a923c9a534e6b9','ropa','create','ropa','ea005aba-0beb-43a1-ade8-81c19dbd1c21',NULL,NULL,NULL,'2026-08-31 00:35:45');
INSERT INTO "audit_logs" VALUES(73,'ac6a037060964450a5a923c9a534e6b9','auth','login','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 00:36:08');
INSERT INTO "audit_logs" VALUES(74,'ac6a037060964450a5a923c9a534e6b9','ropa','create','ropa','ddfb7044-9a65-45a3-a1f8-c2bca570e73b',NULL,NULL,NULL,'2026-08-31 00:36:08');
INSERT INTO "audit_logs" VALUES(75,'d37a17105d9f4f8fb3a3b2510317b7d6','auth','login','user','d37a1710-5d9f-4f8f-b3a3-b2510317b7d6',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 00:38:01');
INSERT INTO "audit_logs" VALUES(76,'ac6a037060964450a5a923c9a534e6b9','auth','login','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 00:38:02');
INSERT INTO "audit_logs" VALUES(77,'5b5a78847ea44fbcb7dd0c9d44567ab1','auth','login','user','5b5a7884-7ea4-4fbc-b7dd-0c9d44567ab1',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 00:38:02');
INSERT INTO "audit_logs" VALUES(78,'eb2cf472bae34648b444ac549055b410','auth','login','user','eb2cf472-bae3-4648-b444-ac549055b410',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 00:38:03');
INSERT INTO "audit_logs" VALUES(79,'92d40357c37041bd843ca09f0abc31a6','auth','login','user','92d40357-c370-41bd-843c-a09f0abc31a6',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 00:38:03');
INSERT INTO "audit_logs" VALUES(80,'2c8b080e236f4808ba5024c9f6a3c494','auth','login','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 00:38:04');
INSERT INTO "audit_logs" VALUES(81,'c42140f876ff4c9cbbe3a741ca63e3fa','auth','login','user','c42140f8-76ff-4c9c-bbe3-a741ca63e3fa',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 00:38:05');
INSERT INTO "audit_logs" VALUES(82,'458d255ea9f04ad5bed64bbb31fe9cc0','auth','login','user','458d255e-a9f0-4ad5-bed6-4bbb31fe9cc0',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 00:38:05');
INSERT INTO "audit_logs" VALUES(83,'ac6a037060964450a5a923c9a534e6b9','auth','login','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 00:38:06');
INSERT INTO "audit_logs" VALUES(84,'d37a17105d9f4f8fb3a3b2510317b7d6','auth','login','user','d37a1710-5d9f-4f8f-b3a3-b2510317b7d6',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 00:38:20');
INSERT INTO "audit_logs" VALUES(85,'ac6a037060964450a5a923c9a534e6b9','auth','login','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 00:38:21');
INSERT INTO "audit_logs" VALUES(86,'5b5a78847ea44fbcb7dd0c9d44567ab1','auth','login','user','5b5a7884-7ea4-4fbc-b7dd-0c9d44567ab1',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 00:38:22');
INSERT INTO "audit_logs" VALUES(87,'eb2cf472bae34648b444ac549055b410','auth','login','user','eb2cf472-bae3-4648-b444-ac549055b410',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 00:38:23');
INSERT INTO "audit_logs" VALUES(88,'92d40357c37041bd843ca09f0abc31a6','auth','login','user','92d40357-c370-41bd-843c-a09f0abc31a6',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 00:38:23');
INSERT INTO "audit_logs" VALUES(89,'2c8b080e236f4808ba5024c9f6a3c494','auth','login','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 00:38:24');
INSERT INTO "audit_logs" VALUES(90,'c42140f876ff4c9cbbe3a741ca63e3fa','auth','login','user','c42140f8-76ff-4c9c-bbe3-a741ca63e3fa',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 00:38:24');
INSERT INTO "audit_logs" VALUES(91,'458d255ea9f04ad5bed64bbb31fe9cc0','auth','login','user','458d255e-a9f0-4ad5-bed6-4bbb31fe9cc0',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 00:38:25');
INSERT INTO "audit_logs" VALUES(92,'ac6a037060964450a5a923c9a534e6b9','auth','login','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 00:38:26');
INSERT INTO "audit_logs" VALUES(93,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 00:41:36');
INSERT INTO "audit_logs" VALUES(94,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 00:41:36');
INSERT INTO "audit_logs" VALUES(95,'ac6a037060964450a5a923c9a534e6b9','ropa','create','ropa','4c028957-e839-43ca-9f48-6d3acc53eb7e',NULL,NULL,NULL,'2026-08-31 00:46:15');
INSERT INTO "audit_logs" VALUES(96,'d37a17105d9f4f8fb3a3b2510317b7d6','auth','login','user','d37a1710-5d9f-4f8f-b3a3-b2510317b7d6',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 00:57:18');
INSERT INTO "audit_logs" VALUES(97,'d37a17105d9f4f8fb3a3b2510317b7d6','auth','login','user','d37a1710-5d9f-4f8f-b3a3-b2510317b7d6',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 00:59:09');
INSERT INTO "audit_logs" VALUES(98,'d37a17105d9f4f8fb3a3b2510317b7d6','auth','login','user','d37a1710-5d9f-4f8f-b3a3-b2510317b7d6',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 01:03:38');
INSERT INTO "audit_logs" VALUES(99,'ac6a037060964450a5a923c9a534e6b9','auth','login','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 01:03:38');
INSERT INTO "audit_logs" VALUES(100,'5b5a78847ea44fbcb7dd0c9d44567ab1','auth','login','user','5b5a7884-7ea4-4fbc-b7dd-0c9d44567ab1',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 01:03:39');
INSERT INTO "audit_logs" VALUES(101,'2c8b080e236f4808ba5024c9f6a3c494','auth','login','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 01:03:39');
INSERT INTO "audit_logs" VALUES(102,'ac6a037060964450a5a923c9a534e6b9','bapd','create','bapd','008bbc25-9e7d-4898-883c-e216ad4fa1d5',NULL,NULL,NULL,'2026-08-31 01:03:40');
INSERT INTO "audit_logs" VALUES(103,'d37a17105d9f4f8fb3a3b2510317b7d6','bapd','create','bapd','f0300016-f431-4801-9b34-b53b9d7a9843',NULL,NULL,NULL,'2026-08-31 01:03:53');
INSERT INTO "audit_logs" VALUES(104,'d37a17105d9f4f8fb3a3b2510317b7d6','auth','login','user','d37a1710-5d9f-4f8f-b3a3-b2510317b7d6',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 01:05:09');
INSERT INTO "audit_logs" VALUES(105,'ac6a037060964450a5a923c9a534e6b9','auth','login','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 01:05:09');
INSERT INTO "audit_logs" VALUES(106,'5b5a78847ea44fbcb7dd0c9d44567ab1','auth','login','user','5b5a7884-7ea4-4fbc-b7dd-0c9d44567ab1',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 01:05:10');
INSERT INTO "audit_logs" VALUES(107,'2c8b080e236f4808ba5024c9f6a3c494','auth','login','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 01:05:10');
INSERT INTO "audit_logs" VALUES(108,'ac6a037060964450a5a923c9a534e6b9','bapd','create','bapd','d86407b1-99c9-49c3-bee0-009777360112',NULL,NULL,NULL,'2026-08-31 01:05:11');
INSERT INTO "audit_logs" VALUES(109,'ac6a037060964450a5a923c9a534e6b9','bapd','transition_submitted','bapd','d86407b1-99c9-49c3-bee0-009777360112','{"from": "draft", "to": "submitted"}',NULL,NULL,'2026-08-31 01:05:11');
INSERT INTO "audit_logs" VALUES(110,'d37a17105d9f4f8fb3a3b2510317b7d6','bapd','approval_approve','bapd','d86407b1-99c9-49c3-bee0-009777360112','{"step": 1, "comments": "Data disposal approved. Expiration validated."}',NULL,NULL,'2026-08-31 01:05:15');
INSERT INTO "audit_logs" VALUES(111,'d37a17105d9f4f8fb3a3b2510317b7d6','auth','login','user','d37a1710-5d9f-4f8f-b3a3-b2510317b7d6',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 01:07:07');
INSERT INTO "audit_logs" VALUES(112,'ac6a037060964450a5a923c9a534e6b9','auth','login','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 01:07:08');
INSERT INTO "audit_logs" VALUES(113,'5b5a78847ea44fbcb7dd0c9d44567ab1','auth','login','user','5b5a7884-7ea4-4fbc-b7dd-0c9d44567ab1',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 01:07:08');
INSERT INTO "audit_logs" VALUES(114,'2c8b080e236f4808ba5024c9f6a3c494','auth','login','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 01:07:09');
INSERT INTO "audit_logs" VALUES(115,'ac6a037060964450a5a923c9a534e6b9','bapd','create','bapd','2e13d628-b031-422b-9658-c6a2a3d883cf',NULL,NULL,NULL,'2026-08-31 01:07:09');
INSERT INTO "audit_logs" VALUES(116,'ac6a037060964450a5a923c9a534e6b9','bapd','transition_submitted','bapd','2e13d628-b031-422b-9658-c6a2a3d883cf','{"from": "draft", "to": "submitted"}',NULL,NULL,'2026-08-31 01:07:09');
INSERT INTO "audit_logs" VALUES(117,'d37a17105d9f4f8fb3a3b2510317b7d6','bapd','approval_approve','bapd','2e13d628-b031-422b-9658-c6a2a3d883cf','{"step": 1, "comments": "Data disposal approved. Expiration validated."}',NULL,NULL,'2026-08-31 01:07:14');
INSERT INTO "audit_logs" VALUES(118,'5b5a78847ea44fbcb7dd0c9d44567ab1','bapd','approval_approve','bapd','2e13d628-b031-422b-9658-c6a2a3d883cf','{"step": 2, "comments": "Compliance check completed. Ready for physical/logical purge."}',NULL,NULL,'2026-08-31 01:07:18');
INSERT INTO "audit_logs" VALUES(119,'5b5a78847ea44fbcb7dd0c9d44567ab1','bapd','execute','bapd','2e13d628-b031-422b-9658-c6a2a3d883cf','{"pod_path": "gs://bapd-evidence/2e13d628-b031-422b-9658-c6a2a3d883cf/pod_20260831_010722.pdf"}',NULL,NULL,'2026-08-31 01:07:22');
INSERT INTO "audit_logs" VALUES(120,'d37a17105d9f4f8fb3a3b2510317b7d6','auth','login','user','d37a1710-5d9f-4f8f-b3a3-b2510317b7d6',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 01:09:32');
INSERT INTO "audit_logs" VALUES(121,'ac6a037060964450a5a923c9a534e6b9','auth','login','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 01:09:33');
INSERT INTO "audit_logs" VALUES(122,'5b5a78847ea44fbcb7dd0c9d44567ab1','auth','login','user','5b5a7884-7ea4-4fbc-b7dd-0c9d44567ab1',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 01:09:34');
INSERT INTO "audit_logs" VALUES(123,'2c8b080e236f4808ba5024c9f6a3c494','auth','login','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 01:09:34');
INSERT INTO "audit_logs" VALUES(124,'ac6a037060964450a5a923c9a534e6b9','bapd','create','bapd','15f4665a-cd4d-4e27-b7ba-360c4c42b252',NULL,NULL,NULL,'2026-08-31 01:09:35');
INSERT INTO "audit_logs" VALUES(125,'ac6a037060964450a5a923c9a534e6b9','bapd','transition_submitted','bapd','15f4665a-cd4d-4e27-b7ba-360c4c42b252','{"from": "draft", "to": "submitted"}',NULL,NULL,'2026-08-31 01:09:35');
INSERT INTO "audit_logs" VALUES(126,'d37a17105d9f4f8fb3a3b2510317b7d6','bapd','approval_approve','bapd','15f4665a-cd4d-4e27-b7ba-360c4c42b252','{"step": 1, "comments": "Data disposal approved. Expiration validated."}',NULL,NULL,'2026-08-31 01:09:39');
INSERT INTO "audit_logs" VALUES(127,'5b5a78847ea44fbcb7dd0c9d44567ab1','bapd','approval_approve','bapd','15f4665a-cd4d-4e27-b7ba-360c4c42b252','{"step": 2, "comments": "Compliance check completed. Ready for physical/logical purge."}',NULL,NULL,'2026-08-31 01:09:44');
INSERT INTO "audit_logs" VALUES(128,'5b5a78847ea44fbcb7dd0c9d44567ab1','bapd','execute','bapd','15f4665a-cd4d-4e27-b7ba-360c4c42b252','{"pod_path": "gs://bapd-evidence/15f4665a-cd4d-4e27-b7ba-360c4c42b252/pod_20260831_010948.pdf"}',NULL,NULL,'2026-08-31 01:09:48');
INSERT INTO "audit_logs" VALUES(129,'d37a17105d9f4f8fb3a3b2510317b7d6','auth','login','user','d37a1710-5d9f-4f8f-b3a3-b2510317b7d6',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 01:10:03');
INSERT INTO "audit_logs" VALUES(130,'ac6a037060964450a5a923c9a534e6b9','auth','login','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 01:10:04');
INSERT INTO "audit_logs" VALUES(131,'5b5a78847ea44fbcb7dd0c9d44567ab1','auth','login','user','5b5a7884-7ea4-4fbc-b7dd-0c9d44567ab1',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 01:10:04');
INSERT INTO "audit_logs" VALUES(132,'eb2cf472bae34648b444ac549055b410','auth','login','user','eb2cf472-bae3-4648-b444-ac549055b410',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 01:10:05');
INSERT INTO "audit_logs" VALUES(133,'92d40357c37041bd843ca09f0abc31a6','auth','login','user','92d40357-c370-41bd-843c-a09f0abc31a6',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 01:10:05');
INSERT INTO "audit_logs" VALUES(134,'2c8b080e236f4808ba5024c9f6a3c494','auth','login','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 01:10:06');
INSERT INTO "audit_logs" VALUES(135,'c42140f876ff4c9cbbe3a741ca63e3fa','auth','login','user','c42140f8-76ff-4c9c-bbe3-a741ca63e3fa',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 01:10:06');
INSERT INTO "audit_logs" VALUES(136,'458d255ea9f04ad5bed64bbb31fe9cc0','auth','login','user','458d255e-a9f0-4ad5-bed6-4bbb31fe9cc0',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 01:10:07');
INSERT INTO "audit_logs" VALUES(137,'ac6a037060964450a5a923c9a534e6b9','auth','login','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Python-urllib/3.12','2026-08-31 01:10:07');
INSERT INTO "audit_logs" VALUES(138,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 05:09:24');
INSERT INTO "audit_logs" VALUES(139,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 05:09:24');
INSERT INTO "audit_logs" VALUES(140,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 05:09:24');
INSERT INTO "audit_logs" VALUES(141,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 05:09:55');
INSERT INTO "audit_logs" VALUES(142,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 05:09:55');
INSERT INTO "audit_logs" VALUES(143,'ac6a037060964450a5a923c9a534e6b9','bapd','create','bapd','9fbe80b6-f9ab-4a9a-b8af-5f490a984d5e',NULL,NULL,NULL,'2026-08-31 05:11:43');
INSERT INTO "audit_logs" VALUES(144,'5b5a78847ea44fbcb7dd0c9d44567ab1','auth','login','user','5b5a7884-7ea4-4fbc-b7dd-0c9d44567ab1',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 05:12:44');
INSERT INTO "audit_logs" VALUES(145,'5b5a78847ea44fbcb7dd0c9d44567ab1','auth','login','user','5b5a7884-7ea4-4fbc-b7dd-0c9d44567ab1',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 05:13:33');
INSERT INTO "audit_logs" VALUES(146,'ac6a037060964450a5a923c9a534e6b9','auth','login','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 05:13:51');
INSERT INTO "audit_logs" VALUES(147,'ac6a037060964450a5a923c9a534e6b9','bapd','transition_submitted','bapd','9fbe80b6-f9ab-4a9a-b8af-5f490a984d5e','{"from": "draft", "to": "submitted"}',NULL,NULL,'2026-08-31 05:14:10');
INSERT INTO "audit_logs" VALUES(148,'5b5a78847ea44fbcb7dd0c9d44567ab1','auth','login','user','5b5a7884-7ea4-4fbc-b7dd-0c9d44567ab1',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 05:14:35');
INSERT INTO "audit_logs" VALUES(149,'5b5a78847ea44fbcb7dd0c9d44567ab1','bapd','approval_approve','bapd','9fbe80b6-f9ab-4a9a-b8af-5f490a984d5e','{"step": 1, "comments": ""}',NULL,NULL,'2026-08-31 05:14:45');
INSERT INTO "audit_logs" VALUES(150,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 05:26:37');
INSERT INTO "audit_logs" VALUES(151,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 05:26:37');
INSERT INTO "audit_logs" VALUES(152,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 05:26:37');
INSERT INTO "audit_logs" VALUES(153,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 05:26:37');
INSERT INTO "audit_logs" VALUES(154,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 05:26:37');
INSERT INTO "audit_logs" VALUES(155,'92d40357c37041bd843ca09f0abc31a6','auth','login','user','92d40357-c370-41bd-843c-a09f0abc31a6',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 05:27:12');
INSERT INTO "audit_logs" VALUES(156,'92d40357c37041bd843ca09f0abc31a6','bapd','approval_approve','bapd','9fbe80b6-f9ab-4a9a-b8af-5f490a984d5e','{"step": 2, "comments": ""}',NULL,NULL,'2026-08-31 05:27:23');
INSERT INTO "audit_logs" VALUES(157,'92d40357c37041bd843ca09f0abc31a6','auth','token_refresh','user','92d40357-c370-41bd-843c-a09f0abc31a6',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 07:52:06');
INSERT INTO "audit_logs" VALUES(158,'92d40357c37041bd843ca09f0abc31a6','auth','token_refresh','user','92d40357-c370-41bd-843c-a09f0abc31a6',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 07:52:06');
INSERT INTO "audit_logs" VALUES(159,'92d40357c37041bd843ca09f0abc31a6','auth','token_refresh','user','92d40357-c370-41bd-843c-a09f0abc31a6',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 07:52:06');
INSERT INTO "audit_logs" VALUES(160,'d37a17105d9f4f8fb3a3b2510317b7d6','auth','login','user','d37a1710-5d9f-4f8f-b3a3-b2510317b7d6',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 07:52:40');
INSERT INTO "audit_logs" VALUES(161,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 13:35:28');
INSERT INTO "audit_logs" VALUES(162,'d37a17105d9f4f8fb3a3b2510317b7d6','auth','token_refresh','user','d37a1710-5d9f-4f8f-b3a3-b2510317b7d6',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 13:35:30');
INSERT INTO "audit_logs" VALUES(163,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 13:35:30');
INSERT INTO "audit_logs" VALUES(164,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 13:35:30');
INSERT INTO "audit_logs" VALUES(165,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 13:35:30');
INSERT INTO "audit_logs" VALUES(166,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 13:35:30');
INSERT INTO "audit_logs" VALUES(167,'d37a17105d9f4f8fb3a3b2510317b7d6','auth','token_refresh','user','d37a1710-5d9f-4f8f-b3a3-b2510317b7d6',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-08-31 13:35:30');
INSERT INTO "audit_logs" VALUES(168,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 02:11:24');
INSERT INTO "audit_logs" VALUES(169,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 02:11:24');
INSERT INTO "audit_logs" VALUES(170,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 02:11:25');
INSERT INTO "audit_logs" VALUES(171,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 02:11:25');
INSERT INTO "audit_logs" VALUES(172,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 02:11:25');
INSERT INTO "audit_logs" VALUES(173,'d37a17105d9f4f8fb3a3b2510317b7d6','auth','token_refresh','user','d37a1710-5d9f-4f8f-b3a3-b2510317b7d6',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 02:11:44');
INSERT INTO "audit_logs" VALUES(174,'d37a17105d9f4f8fb3a3b2510317b7d6','auth','token_refresh','user','d37a1710-5d9f-4f8f-b3a3-b2510317b7d6',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 02:11:44');
INSERT INTO "audit_logs" VALUES(175,'d37a17105d9f4f8fb3a3b2510317b7d6','auth','token_refresh','user','d37a1710-5d9f-4f8f-b3a3-b2510317b7d6',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 02:51:45');
INSERT INTO "audit_logs" VALUES(176,'d37a17105d9f4f8fb3a3b2510317b7d6','auth','token_refresh','user','d37a1710-5d9f-4f8f-b3a3-b2510317b7d6',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 02:51:45');
INSERT INTO "audit_logs" VALUES(177,'d37a17105d9f4f8fb3a3b2510317b7d6','bapd','execute','bapd','9fbe80b6-f9ab-4a9a-b8af-5f490a984d5e','{"pod_path": "gs://bapd-evidence/9fbe80b6-f9ab-4a9a-b8af-5f490a984d5e/pod_20260901_025241.pdf"}',NULL,NULL,'2026-09-01 02:52:41');
INSERT INTO "audit_logs" VALUES(178,'d37a17105d9f4f8fb3a3b2510317b7d6','auth','token_refresh','user','d37a1710-5d9f-4f8f-b3a3-b2510317b7d6',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 02:56:34');
INSERT INTO "audit_logs" VALUES(179,'d37a17105d9f4f8fb3a3b2510317b7d6','auth','token_refresh','user','d37a1710-5d9f-4f8f-b3a3-b2510317b7d6',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 02:56:34');
INSERT INTO "audit_logs" VALUES(180,'d37a17105d9f4f8fb3a3b2510317b7d6','auth','token_refresh','user','d37a1710-5d9f-4f8f-b3a3-b2510317b7d6',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 02:56:44');
INSERT INTO "audit_logs" VALUES(181,'d37a17105d9f4f8fb3a3b2510317b7d6','auth','token_refresh','user','d37a1710-5d9f-4f8f-b3a3-b2510317b7d6',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 02:56:44');
INSERT INTO "audit_logs" VALUES(182,'ac6a037060964450a5a923c9a534e6b9','auth','login','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 02:58:49');
INSERT INTO "audit_logs" VALUES(183,'ac6a037060964450a5a923c9a534e6b9','project','create','project','ecca2cac-550e-47fe-8f97-5a666b40bee6','{"project_name": "A-Infra", "customer_name": "PT Astra Infra"}',NULL,NULL,'2026-09-01 03:05:05');
INSERT INTO "audit_logs" VALUES(184,'ac6a037060964450a5a923c9a534e6b9','dsr','create','dsr','79475b67-5667-4da5-a5ad-7bd028c0895c','{"tracking_id": "DSR-2026-0002"}',NULL,NULL,'2026-09-01 03:05:32');
INSERT INTO "audit_logs" VALUES(185,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 03:58:55');
INSERT INTO "audit_logs" VALUES(186,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 03:58:55');
INSERT INTO "audit_logs" VALUES(187,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 03:58:56');
INSERT INTO "audit_logs" VALUES(188,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 03:58:56');
INSERT INTO "audit_logs" VALUES(189,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 03:58:56');
INSERT INTO "audit_logs" VALUES(190,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 08:10:07');
INSERT INTO "audit_logs" VALUES(191,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 08:10:07');
INSERT INTO "audit_logs" VALUES(192,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 08:10:07');
INSERT INTO "audit_logs" VALUES(193,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 08:10:07');
INSERT INTO "audit_logs" VALUES(194,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 08:10:07');
INSERT INTO "audit_logs" VALUES(195,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 08:10:07');
INSERT INTO "audit_logs" VALUES(196,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 08:10:07');
INSERT INTO "audit_logs" VALUES(197,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 08:10:07');
INSERT INTO "audit_logs" VALUES(198,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 08:10:07');
INSERT INTO "audit_logs" VALUES(199,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 09:52:41');
INSERT INTO "audit_logs" VALUES(200,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 09:52:41');
INSERT INTO "audit_logs" VALUES(201,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 09:52:41');
INSERT INTO "audit_logs" VALUES(202,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 09:52:41');
INSERT INTO "audit_logs" VALUES(203,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 09:52:41');
INSERT INTO "audit_logs" VALUES(204,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 10:02:08');
INSERT INTO "audit_logs" VALUES(205,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 10:02:08');
INSERT INTO "audit_logs" VALUES(206,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 10:02:08');
INSERT INTO "audit_logs" VALUES(207,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 10:02:08');
INSERT INTO "audit_logs" VALUES(208,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 10:02:23');
INSERT INTO "audit_logs" VALUES(209,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 10:02:23');
INSERT INTO "audit_logs" VALUES(210,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 10:09:27');
INSERT INTO "audit_logs" VALUES(211,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 10:09:27');
INSERT INTO "audit_logs" VALUES(212,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 10:09:27');
INSERT INTO "audit_logs" VALUES(213,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 16:43:42');
INSERT INTO "audit_logs" VALUES(214,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 16:43:42');
INSERT INTO "audit_logs" VALUES(215,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 16:43:43');
INSERT INTO "audit_logs" VALUES(216,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 16:43:43');
INSERT INTO "audit_logs" VALUES(217,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 16:43:43');
INSERT INTO "audit_logs" VALUES(218,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 16:43:46');
INSERT INTO "audit_logs" VALUES(219,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 16:43:46');
INSERT INTO "audit_logs" VALUES(220,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-01 16:43:46');
INSERT INTO "audit_logs" VALUES(221,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-02 02:13:46');
INSERT INTO "audit_logs" VALUES(222,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-02 02:13:46');
INSERT INTO "audit_logs" VALUES(223,'ac6a037060964450a5a923c9a534e6b9','auth','token_refresh','user','ac6a0370-6096-4450-a5a9-23c9a534e6b9',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-02 02:13:47');
INSERT INTO "audit_logs" VALUES(224,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-02 02:13:48');
INSERT INTO "audit_logs" VALUES(225,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-02 02:13:50');
INSERT INTO "audit_logs" VALUES(226,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-02 02:13:50');
INSERT INTO "audit_logs" VALUES(227,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-02 02:13:52');
INSERT INTO "audit_logs" VALUES(228,'2c8b080e236f4808ba5024c9f6a3c494','auth','token_refresh','user','2c8b080e-236f-4808-ba50-24c9f6a3c494',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36','2026-09-02 02:14:04');
CREATE TABLE bapd_approvals (
	id VARCHAR(36) NOT NULL, 
	bapd_id VARCHAR(36) NOT NULL, 
	approver_id VARCHAR(36) NOT NULL, 
	approver_role VARCHAR(60) NOT NULL, 
	step_order SMALLINT NOT NULL, 
	status VARCHAR(20) NOT NULL, 
	comments TEXT, 
	actioned_at DATETIME, 
	CONSTRAINT pk_bapd_approvals PRIMARY KEY (id), 
	CONSTRAINT fk_bapd_approvals_bapd_id_bapd_records FOREIGN KEY(bapd_id) REFERENCES bapd_records (id) ON DELETE CASCADE, 
	CONSTRAINT fk_bapd_approvals_approver_id_users FOREIGN KEY(approver_id) REFERENCES users (id)
);
INSERT INTO "bapd_approvals" VALUES('1f7d8879707546728fd49a9e273707cb','008bbc259e7d4898883ce216ad4fa1d5','5b5a78847ea44fbcb7dd0c9d44567ab1','data_owner',1,'pending',NULL,NULL);
INSERT INTO "bapd_approvals" VALUES('96b534373e31406e94da032f7bd5f455','008bbc259e7d4898883ce216ad4fa1d5','92d40357c37041bd843ca09f0abc31a6','compliance_officer',2,'pending',NULL,NULL);
INSERT INTO "bapd_approvals" VALUES('dd92ed05178e408e9e24258f4df70371','f0300016f43148019b34b53b9d7a9843','2c8b080e236f4808ba5024c9f6a3c494','data_owner',1,'pending',NULL,NULL);
INSERT INTO "bapd_approvals" VALUES('94bb565750fa4bdebb514830016547cf','f0300016f43148019b34b53b9d7a9843','5b5a78847ea44fbcb7dd0c9d44567ab1','compliance_officer',2,'pending',NULL,NULL);
INSERT INTO "bapd_approvals" VALUES('e6ec808e8eb34f4f874de5c9b0014367','d86407b199c949c3bee0009777360112','d37a17105d9f4f8fb3a3b2510317b7d6','data_owner',1,'approved','Data disposal approved. Expiration validated.','2026-08-31 01:05:15.716242');
INSERT INTO "bapd_approvals" VALUES('3b577906c18445b9b31bb5e0b25f80f7','d86407b199c949c3bee0009777360112','92d40357c37041bd843ca09f0abc31a6','compliance_officer',2,'requested',NULL,NULL);
INSERT INTO "bapd_approvals" VALUES('779248a35891451dacae09504dcc9dd1','2e13d628b031422b9658c6a2a3d883cf','d37a17105d9f4f8fb3a3b2510317b7d6','data_owner',1,'approved','Data disposal approved. Expiration validated.','2026-08-31 01:07:14.267314');
INSERT INTO "bapd_approvals" VALUES('6ba862ceb6764cc3a7ab240ec21cb509','2e13d628b031422b9658c6a2a3d883cf','5b5a78847ea44fbcb7dd0c9d44567ab1','compliance_officer',2,'approved','Compliance check completed. Ready for physical/logical purge.','2026-08-31 01:07:18.510269');
INSERT INTO "bapd_approvals" VALUES('919d93627eb84a0fa1eb642d830b5474','15f4665acd4d4e27b7ba360c4c42b252','d37a17105d9f4f8fb3a3b2510317b7d6','data_owner',1,'approved','Data disposal approved. Expiration validated.','2026-08-31 01:09:39.948582');
INSERT INTO "bapd_approvals" VALUES('e68c1ba4718547878cf78d22f7432d53','15f4665acd4d4e27b7ba360c4c42b252','5b5a78847ea44fbcb7dd0c9d44567ab1','compliance_officer',2,'approved','Compliance check completed. Ready for physical/logical purge.','2026-08-31 01:09:44.162918');
INSERT INTO "bapd_approvals" VALUES('6140448dcf6e4aae84a41cc411459975','9fbe80b6f9ab4a9ab8af5f490a984d5e','5b5a78847ea44fbcb7dd0c9d44567ab1','data_owner',1,'approved','','2026-08-31 05:14:45.763583');
INSERT INTO "bapd_approvals" VALUES('2b00b1cbe4144430b498f82955279749','9fbe80b6f9ab4a9ab8af5f490a984d5e','92d40357c37041bd843ca09f0abc31a6','compliance_officer',2,'approved','','2026-08-31 05:27:23.241118');
CREATE TABLE bapd_records (
	id VARCHAR(36) NOT NULL, 
	project_id VARCHAR(36) NOT NULL, 
	dataset_name VARCHAR(300) NOT NULL, 
	dataset_location TEXT NOT NULL, 
	retention_policy_id VARCHAR(36), 
	expiry_date DATE NOT NULL, 
	reason TEXT NOT NULL, 
	responsible_party_id VARCHAR(36) NOT NULL, 
	status VARCHAR(30) NOT NULL, 
	pod_file_path TEXT, 
	executed_at DATETIME, 
	executed_by VARCHAR(36), 
	version SMALLINT NOT NULL, 
	created_by VARCHAR(36) NOT NULL, 
	created_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL, 
	updated_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL, 
	CONSTRAINT pk_bapd_records PRIMARY KEY (id), 
	CONSTRAINT fk_bapd_records_project_id_projects FOREIGN KEY(project_id) REFERENCES projects (id), 
	CONSTRAINT fk_bapd_records_retention_policy_id_retention_policies FOREIGN KEY(retention_policy_id) REFERENCES retention_policies (id), 
	CONSTRAINT fk_bapd_records_responsible_party_id_users FOREIGN KEY(responsible_party_id) REFERENCES users (id), 
	CONSTRAINT fk_bapd_records_executed_by_users FOREIGN KEY(executed_by) REFERENCES users (id), 
	CONSTRAINT fk_bapd_records_created_by_users FOREIGN KEY(created_by) REFERENCES users (id)
);
INSERT INTO "bapd_records" VALUES('008bbc259e7d4898883ce216ad4fa1d5','6bda77801b7e4178ad23a1cbb180ea47','expired_customer_audit_logs_2023','gs://archive-governance-backup/logs/2023/','11b37e97e645472c936921b637222efe','2024-01-01','Retention schedule period expired (7 years). Mandatory disposal under UU PDP Pasal 16 and Company Policy.','ac6a037060964450a5a923c9a534e6b9','draft',NULL,NULL,NULL,1,'ac6a037060964450a5a923c9a534e6b9','2026-08-31 01:03:40','2026-08-31 01:03:40');
INSERT INTO "bapd_records" VALUES('f0300016f43148019b34b53b9d7a9843','43e4c48c66bc40cca82aa5f04cfaa9ca','test_ds','gs://test',NULL,'2024-01-01','test reason','d37a17105d9f4f8fb3a3b2510317b7d6','draft',NULL,NULL,NULL,1,'d37a17105d9f4f8fb3a3b2510317b7d6','2026-08-31 01:03:53','2026-08-31 01:03:53');
INSERT INTO "bapd_records" VALUES('d86407b199c949c3bee0009777360112','6bda77801b7e4178ad23a1cbb180ea47','expired_customer_audit_logs_2023','gs://archive-governance-backup/logs/2023/','11b37e97e645472c936921b637222efe','2024-01-01','Retention schedule period expired (7 years). Mandatory disposal under UU PDP Pasal 16 and Company Policy.','ac6a037060964450a5a923c9a534e6b9','under_review',NULL,NULL,NULL,2,'ac6a037060964450a5a923c9a534e6b9','2026-08-31 01:05:11','2026-08-31 01:05:15');
INSERT INTO "bapd_records" VALUES('2e13d628b031422b9658c6a2a3d883cf','6bda77801b7e4178ad23a1cbb180ea47','expired_customer_audit_logs_2023','gs://archive-governance-backup/logs/2023/','11b37e97e645472c936921b637222efe','2024-01-01','Retention schedule period expired (7 years). Mandatory disposal under UU PDP Pasal 16 and Company Policy.','ac6a037060964450a5a923c9a534e6b9','executed','gs://bapd-evidence/2e13d628-b031-422b-9658-c6a2a3d883cf/pod_20260831_010722.pdf','2026-08-31 01:07:22.695265','5b5a78847ea44fbcb7dd0c9d44567ab1',3,'ac6a037060964450a5a923c9a534e6b9','2026-08-31 01:07:09','2026-08-31 01:07:22');
INSERT INTO "bapd_records" VALUES('15f4665acd4d4e27b7ba360c4c42b252','6bda77801b7e4178ad23a1cbb180ea47','expired_customer_audit_logs_2023','gs://archive-governance-backup/logs/2023/','11b37e97e645472c936921b637222efe','2024-01-01','Retention schedule period expired (7 years). Mandatory disposal under UU PDP Pasal 16 and Company Policy.','ac6a037060964450a5a923c9a534e6b9','executed','gs://bapd-evidence/15f4665a-cd4d-4e27-b7ba-360c4c42b252/pod_20260831_010948.pdf','2026-08-31 01:09:48.524615','5b5a78847ea44fbcb7dd0c9d44567ab1',3,'ac6a037060964450a5a923c9a534e6b9','2026-08-31 01:09:35','2026-08-31 01:09:48');
INSERT INTO "bapd_records" VALUES('9fbe80b6f9ab4a9ab8af5f490a984d5e','6bda77801b7e4178ad23a1cbb180ea47','DIDX','https:////',NULL,'2027-01-12','Sesuai kesepakatan dokumen PKS','eb2cf472bae34648b444ac549055b410','executed','gs://bapd-evidence/9fbe80b6-f9ab-4a9a-b8af-5f490a984d5e/pod_20260901_025241.pdf','2026-09-01 02:52:41.184490','d37a17105d9f4f8fb3a3b2510317b7d6',3,'ac6a037060964450a5a923c9a534e6b9','2026-08-31 05:11:43','2026-09-01 02:52:41');
CREATE TABLE data_owner_stewards (
	id VARCHAR(36) NOT NULL, 
	project_id VARCHAR(36) NOT NULL, 
	role_type VARCHAR(50) NOT NULL, 
	full_name VARCHAR(200) NOT NULL, 
	email VARCHAR(200) NOT NULL, 
	created_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL, 
	CONSTRAINT pk_data_owner_stewards PRIMARY KEY (id), 
	CONSTRAINT fk_data_owner_stewards_project_id_projects FOREIGN KEY(project_id) REFERENCES projects (id)
);
INSERT INTO "data_owner_stewards" VALUES('274ebffee4184d15a4492424a5ca3f3d','6bda77801b7e4178ad23a1cbb180ea47','lead_business_steward','John Doe','jon@jon.jon','2026-08-30 06:00:33');
INSERT INTO "data_owner_stewards" VALUES('cf8ff0c2098b4866a8a20fc2ccedce99','6bda77801b7e4178ad23a1cbb180ea47','data_owner','Doe','Doe@doe.doe','2026-08-30 06:00:33');
INSERT INTO "data_owner_stewards" VALUES('8b9b9831e9624156bc560f9254223028','ecca2cac550e47fe8f975a666b40bee6','lead_business_steward','John Doe','john@john.john','2026-09-01 03:05:06');
INSERT INTO "data_owner_stewards" VALUES('828a42b682c943819b847dfa9f2c5280','ecca2cac550e47fe8f975a666b40bee6','data_owner','Jane','Jane@jane.jane','2026-09-01 03:05:06');
CREATE TABLE data_sharing_agreements (
	id VARCHAR(36) NOT NULL, 
	title TEXT NOT NULL, 
	file_path TEXT, 
	validity_start DATE NOT NULL, 
	validity_end DATE, 
	created_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL, 
	CONSTRAINT pk_data_sharing_agreements PRIMARY KEY (id)
);
CREATE TABLE data_sharing_requests (
	id VARCHAR(36) NOT NULL, 
	tracking_id VARCHAR(30) NOT NULL, 
	project_id VARCHAR(36) NOT NULL, 
	requester_id VARCHAR(36) NOT NULL, 
	dataset_name VARCHAR(300) NOT NULL, 
	recipient TEXT NOT NULL, 
	purpose TEXT NOT NULL, 
	is_ai_use BOOLEAN NOT NULL, 
	duration_start DATE NOT NULL, 
	duration_end DATE NOT NULL, 
	dsa_id VARCHAR(36), 
	status VARCHAR(30) NOT NULL, 
	created_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL, 
	updated_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL, 
	CONSTRAINT pk_data_sharing_requests PRIMARY KEY (id), 
	CONSTRAINT fk_data_sharing_requests_project_id_projects FOREIGN KEY(project_id) REFERENCES projects (id), 
	CONSTRAINT fk_data_sharing_requests_requester_id_users FOREIGN KEY(requester_id) REFERENCES users (id), 
	CONSTRAINT fk_data_sharing_requests_dsa_id_data_sharing_agreements FOREIGN KEY(dsa_id) REFERENCES data_sharing_agreements (id)
);
INSERT INTO "data_sharing_requests" VALUES('4472b214d38548ee8be3ef42ee81c49b','DSR-2026-0001','6bda77801b7e4178ad23a1cbb180ea47','ac6a037060964450a5a923c9a534e6b9','DIDX','TAM','Lorem',1,'2026-12-01','2027-12-31',NULL,'draft','2026-08-30 06:00:49','2026-08-30 06:00:49');
INSERT INTO "data_sharing_requests" VALUES('79475b6756674da5a5ad7bd028c0895c','DSR-2026-0002','ecca2cac550e47fe8f975a666b40bee6','ac6a037060964450a5a923c9a534e6b9','DIDX','PT Astra Infra','Lorem',1,'2025-01-01','2027-01-01',NULL,'draft','2026-09-01 03:05:32','2026-09-01 03:05:32');
CREATE TABLE dpia_approvals (
	id VARCHAR(36) NOT NULL, 
	dpia_id VARCHAR(36) NOT NULL, 
	approver_id VARCHAR(36) NOT NULL, 
	approver_role VARCHAR(80) NOT NULL, 
	step_order SMALLINT NOT NULL, 
	status VARCHAR(20) NOT NULL, 
	comments TEXT, 
	actioned_at DATETIME, 
	CONSTRAINT pk_dpia_approvals PRIMARY KEY (id), 
	CONSTRAINT fk_dpia_approvals_dpia_id_dpia_records FOREIGN KEY(dpia_id) REFERENCES dpia_records (id) ON DELETE CASCADE, 
	CONSTRAINT fk_dpia_approvals_approver_id_users FOREIGN KEY(approver_id) REFERENCES users (id)
);
INSERT INTO "dpia_approvals" VALUES('041c4af42036432f8913b3a8df590fbc','e767781750af4a13b150b746e9505f13','92d40357c37041bd843ca09f0abc31a6','pic_compliance',1,'pending',NULL,NULL);
INSERT INTO "dpia_approvals" VALUES('ef21f96c472c433bad1c221f7f77cffb','e767781750af4a13b150b746e9505f13','2c8b080e236f4808ba5024c9f6a3c494','dm_pm',2,'pending',NULL,NULL);
INSERT INTO "dpia_approvals" VALUES('4d018fb9f42c46d6aaf4b91158a0e37e','19d748af720849d58a700727b87d9595','92d40357c37041bd843ca09f0abc31a6','pic_compliance',1,'pending',NULL,NULL);
INSERT INTO "dpia_approvals" VALUES('0528f33728f540d0bd07299a45f54978','19d748af720849d58a700727b87d9595','2c8b080e236f4808ba5024c9f6a3c494','dm_pm',2,'pending',NULL,NULL);
CREATE TABLE dpia_records (
	id VARCHAR(36) NOT NULL, 
	tracking_id VARCHAR(30), 
	project_id VARCHAR(36) NOT NULL, 
	process_name VARCHAR(300) NOT NULL, 
	purpose TEXT NOT NULL, 
	data_category TEXT NOT NULL, 
	risk_description TEXT NOT NULL, 
	mitigation_measures TEXT, 
	residual_risk VARCHAR(20), 
	likelihood_score SMALLINT, 
	impact_score SMALLINT, 
	risk_score SMALLINT, 
	assessment_date DATE NOT NULL, 
	responsible_party_id VARCHAR(36) NOT NULL, 
	status VARCHAR(30) NOT NULL, 
	version SMALLINT NOT NULL, 
	governance_json JSON, 
	created_by VARCHAR(36) NOT NULL, 
	created_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL, 
	updated_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL, 
	CONSTRAINT pk_dpia_records PRIMARY KEY (id), 
	CONSTRAINT ck_dpia_records_ck_dpia_likelihood CHECK (likelihood_score BETWEEN 1 AND 5), 
	CONSTRAINT ck_dpia_records_ck_dpia_impact CHECK (impact_score BETWEEN 1 AND 5), 
	CONSTRAINT fk_dpia_records_project_id_projects FOREIGN KEY(project_id) REFERENCES projects (id), 
	CONSTRAINT fk_dpia_records_responsible_party_id_users FOREIGN KEY(responsible_party_id) REFERENCES users (id), 
	CONSTRAINT fk_dpia_records_created_by_users FOREIGN KEY(created_by) REFERENCES users (id)
);
INSERT INTO "dpia_records" VALUES('e767781750af4a13b150b746e9505f13','DPIA-2026-0001','6bda77801b7e4178ad23a1cbb180ea47','DIDX','','','',NULL,NULL,NULL,NULL,NULL,'2026-08-30','ac6a037060964450a5a923c9a534e6b9','draft',1,'{"access": [{"id": "access_1", "item": "Data Sharing Request Document", "responsible": "Internal", "status": "", "remarks": ""}, {"id": "access_2", "item": "Revoke / Extermination Documentation", "responsible": "Internal", "status": "", "remarks": ""}, {"id": "access_3", "item": "Data Activity Records Documentation (during project)", "responsible": "Internal", "status": "", "remarks": ""}, {"id": "access_4", "item": "Role-Based Access Control Document", "responsible": "Internal", "status": "", "remarks": ""}, {"id": "access_5", "item": "Assess and Approve Documentation Above", "responsible": "Client", "status": "", "remarks": ""}, {"id": "access_6", "item": "Grant Access to Project Team Only (per RBAC document)", "responsible": "Client", "status": "", "remarks": ""}], "secure_data": [{"id": "secure_data_1", "item": "Prepare Mitigated Personal Data (e.g. encrypted, hashed, pseudonymised)", "responsible": "Client", "status": "", "remarks": ""}], "secure_sharing_environment": [{"id": "secure_env_1", "item": "Provide Secure Environment or Schema to Enable Data Sharing", "responsible": "Client", "status": "", "remarks": ""}], "data_definition": [{"id": "data_def_1", "item": "Create Metadata Documentation", "responsible": "Internal", "status": "", "remarks": ""}, {"id": "data_def_2", "item": "Measure Data Quality Index", "responsible": "Internal", "status": "", "remarks": ""}, {"id": "data_def_3", "item": "Assess and Approve Metadata Definition", "responsible": "Client", "status": "", "remarks": ""}, {"id": "data_def_4", "item": "Assess and Approve Data Quality Measurement Approach and Index", "responsible": "Client", "status": "", "remarks": ""}]}','ac6a037060964450a5a923c9a534e6b9','2026-08-30 06:00:49','2026-08-30 06:00:49');
INSERT INTO "dpia_records" VALUES('19d748af720849d58a700727b87d9595','DPIA-2026-0002','ecca2cac550e47fe8f975a666b40bee6','A-Infra','','','',NULL,NULL,NULL,NULL,NULL,'2026-09-01','ac6a037060964450a5a923c9a534e6b9','draft',1,'{"access": [{"id": "access_1", "item": "Data Sharing Request Document", "responsible": "Internal", "status": "", "remarks": ""}, {"id": "access_2", "item": "Revoke / Extermination Documentation", "responsible": "Internal", "status": "", "remarks": ""}, {"id": "access_3", "item": "Data Activity Records Documentation (during project)", "responsible": "Internal", "status": "", "remarks": ""}, {"id": "access_4", "item": "Role-Based Access Control Document", "responsible": "Internal", "status": "", "remarks": ""}, {"id": "access_5", "item": "Assess and Approve Documentation Above", "responsible": "Client", "status": "", "remarks": ""}, {"id": "access_6", "item": "Grant Access to Project Team Only (per RBAC document)", "responsible": "Client", "status": "", "remarks": ""}], "secure_data": [{"id": "secure_data_1", "item": "Prepare Mitigated Personal Data (e.g. encrypted, hashed, pseudonymised)", "responsible": "Client", "status": "", "remarks": ""}], "secure_sharing_environment": [{"id": "secure_env_1", "item": "Provide Secure Environment or Schema to Enable Data Sharing", "responsible": "Client", "status": "", "remarks": ""}], "data_definition": [{"id": "data_def_1", "item": "Create Metadata Documentation", "responsible": "Internal", "status": "", "remarks": ""}, {"id": "data_def_2", "item": "Measure Data Quality Index", "responsible": "Internal", "status": "", "remarks": ""}, {"id": "data_def_3", "item": "Assess and Approve Metadata Definition", "responsible": "Client", "status": "", "remarks": ""}, {"id": "data_def_4", "item": "Assess and Approve Data Quality Measurement Approach and Index", "responsible": "Client", "status": "", "remarks": ""}]}','ac6a037060964450a5a923c9a534e6b9','2026-09-01 03:05:32','2026-09-01 03:05:32');
CREATE TABLE dq_findings (
	id VARCHAR(36) NOT NULL, 
	result_id VARCHAR(36) NOT NULL, 
	severity VARCHAR(20) NOT NULL, 
	description TEXT NOT NULL, 
	recommendation TEXT, 
	status VARCHAR(30) NOT NULL, 
	resolved_by VARCHAR(36), 
	resolved_at DATETIME, 
	created_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL, 
	CONSTRAINT pk_dq_findings PRIMARY KEY (id), 
	CONSTRAINT fk_dq_findings_result_id_dq_results FOREIGN KEY(result_id) REFERENCES dq_results (id), 
	CONSTRAINT fk_dq_findings_resolved_by_users FOREIGN KEY(resolved_by) REFERENCES users (id)
);
CREATE TABLE dq_gcp_archives (
	id VARCHAR(36) NOT NULL, 
	run_id VARCHAR(36) NOT NULL, 
	gcs_report_path TEXT, 
	bq_dataset VARCHAR(200), 
	bq_table VARCHAR(200), 
	archived_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL, 
	archive_status VARCHAR(30) NOT NULL, 
	error_message TEXT, 
	CONSTRAINT pk_dq_gcp_archives PRIMARY KEY (id), 
	CONSTRAINT uq_dq_gcp_archives_run_id UNIQUE (run_id), 
	CONSTRAINT fk_dq_gcp_archives_run_id_dq_runs FOREIGN KEY(run_id) REFERENCES dq_runs (id)
);
CREATE TABLE dq_results (
	id VARCHAR(36) NOT NULL, 
	run_id VARCHAR(36) NOT NULL, 
	check_name VARCHAR(200) NOT NULL, 
	check_type VARCHAR(50) NOT NULL, 
	column_name VARCHAR(200), 
	status VARCHAR(20) NOT NULL, 
	expected_value TEXT, 
	actual_value TEXT, 
	row_count INTEGER, 
	failed_count INTEGER, 
	details JSON, 
	business_rules TEXT, 
	regex_pattern TEXT, 
	ai_model VARCHAR(100), 
	regex_version VARCHAR(50), 
	column_category VARCHAR(50), 
	created_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL, 
	CONSTRAINT pk_dq_results PRIMARY KEY (id), 
	CONSTRAINT fk_dq_results_run_id_dq_runs FOREIGN KEY(run_id) REFERENCES dq_runs (id)
);
CREATE TABLE dq_runs (
	id VARCHAR(36) NOT NULL, 
	project_id VARCHAR(36) NOT NULL, 
	source_file_id VARCHAR(36), 
	run_name VARCHAR(300) NOT NULL, 
	dataset_name VARCHAR(300) NOT NULL, 
	dataset_location TEXT NOT NULL, 
	status VARCHAR(30) NOT NULL, 
	total_checks INTEGER NOT NULL, 
	passed_checks INTEGER NOT NULL, 
	failed_checks INTEGER NOT NULL, 
	overall_score NUMERIC(5, 2), 
	started_at DATETIME, 
	completed_at DATETIME, 
	triggered_by VARCHAR(36) NOT NULL, 
	celery_task_id VARCHAR(200), 
	created_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL, 
	CONSTRAINT pk_dq_runs PRIMARY KEY (id), 
	CONSTRAINT fk_dq_runs_project_id_projects FOREIGN KEY(project_id) REFERENCES projects (id), 
	CONSTRAINT fk_dq_runs_source_file_id_project_source_files FOREIGN KEY(source_file_id) REFERENCES project_source_files (id) ON DELETE SET NULL, 
	CONSTRAINT fk_dq_runs_triggered_by_users FOREIGN KEY(triggered_by) REFERENCES users (id)
);
CREATE TABLE dsr_approvals (
	id VARCHAR(36) NOT NULL, 
	dsr_id VARCHAR(36) NOT NULL, 
	approver_id VARCHAR(36) NOT NULL, 
	approver_role VARCHAR(80) NOT NULL, 
	step_order SMALLINT NOT NULL, 
	status VARCHAR(20) NOT NULL, 
	comments TEXT, 
	actioned_at DATETIME, 
	CONSTRAINT pk_dsr_approvals PRIMARY KEY (id), 
	CONSTRAINT fk_dsr_approvals_dsr_id_data_sharing_requests FOREIGN KEY(dsr_id) REFERENCES data_sharing_requests (id), 
	CONSTRAINT fk_dsr_approvals_approver_id_users FOREIGN KEY(approver_id) REFERENCES users (id)
);
INSERT INTO "dsr_approvals" VALUES('6219187563754ca3b2246de98c4dee7e','4472b214d38548ee8be3ef42ee81c49b','92d40357c37041bd843ca09f0abc31a6','pic_compliance',1,'pending',NULL,NULL);
INSERT INTO "dsr_approvals" VALUES('04bd8da435d8459cb158b096e8266d4e','4472b214d38548ee8be3ef42ee81c49b','2c8b080e236f4808ba5024c9f6a3c494','dm_pm',2,'pending',NULL,NULL);
INSERT INTO "dsr_approvals" VALUES('e7afdc2026e742d5bf2427932a76eb73','4472b214d38548ee8be3ef42ee81c49b','eb2cf472bae34648b444ac549055b410','sme',3,'pending',NULL,NULL);
INSERT INTO "dsr_approvals" VALUES('f3867e504d4d40998f3caa223f872e1c','4472b214d38548ee8be3ef42ee81c49b','5b5a78847ea44fbcb7dd0c9d44567ab1','client',4,'pending',NULL,NULL);
INSERT INTO "dsr_approvals" VALUES('f31add2efc204d97bc421a6205dd2047','79475b6756674da5a5ad7bd028c0895c','92d40357c37041bd843ca09f0abc31a6','pic_compliance',1,'pending',NULL,NULL);
INSERT INTO "dsr_approvals" VALUES('34b831e73ec242d3a111d0ae111e718c','79475b6756674da5a5ad7bd028c0895c','2c8b080e236f4808ba5024c9f6a3c494','dm_pm',2,'pending',NULL,NULL);
INSERT INTO "dsr_approvals" VALUES('cb8236fd54a74c38a8a181f0a79df7a3','79475b6756674da5a5ad7bd028c0895c','eb2cf472bae34648b444ac549055b410','sme',3,'pending',NULL,NULL);
INSERT INTO "dsr_approvals" VALUES('2c8287fd57964c87aedac077c1d4cbac','79475b6756674da5a5ad7bd028c0895c','5b5a78847ea44fbcb7dd0c9d44567ab1','client',4,'pending',NULL,NULL);
CREATE TABLE metadata_records (
	id VARCHAR(36) NOT NULL, 
	project_id VARCHAR(36) NOT NULL, 
	seq_no INTEGER NOT NULL, 
	business_users VARCHAR(200) NOT NULL, 
	data_domain_table VARCHAR(300) NOT NULL, 
	line_of_business VARCHAR(200), 
	table_type VARCHAR(50) NOT NULL, 
	project_name VARCHAR(300) NOT NULL, 
	project_year SMALLINT NOT NULL, 
	data_steward TEXT, 
	data_owner TEXT, 
	data_attribute VARCHAR(300) NOT NULL, 
	data_year SMALLINT, 
	data_sensitivity VARCHAR(30) NOT NULL, 
	data_grouping TEXT, 
	business_term TEXT, 
	business_definition TEXT, 
	definition_status VARCHAR(20) NOT NULL, 
	standard_format TEXT, 
	is_primary_key BOOLEAN, 
	is_nullable BOOLEAN, 
	sample_data TEXT, 
	data_type VARCHAR(30), 
	data_level VARCHAR(30) NOT NULL, 
	updated_date DATE, 
	updated_by TEXT, 
	remarks TEXT NOT NULL, 
	source_type VARCHAR(20) NOT NULL, 
	source_row_count INTEGER, 
	distinct_values TEXT, 
	created_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL, 
	CONSTRAINT pk_metadata_records PRIMARY KEY (id), 
	CONSTRAINT fk_metadata_records_project_id_projects FOREIGN KEY(project_id) REFERENCES projects (id)
);
INSERT INTO "metadata_records" VALUES('061196009b69418eaa9c08dd77623c81','43e4c48c66bc40cca82aa5f04cfaa9ca',1,'Enterprise Analytics','customer_profiles',NULL,'Source','AI-Powered Customer Analytics Platform',2026,NULL,NULL,'customer_id',NULL,'Internal',NULL,'Customer Id','Attribute customer_id','pending',NULL,NULL,NULL,NULL,'VARCHAR','Raw',NULL,NULL,'-','postgresql',45000,NULL,'2026-08-31 00:36:01');
INSERT INTO "metadata_records" VALUES('5f553295cf8e4d2f880e143c9a6f9024','43e4c48c66bc40cca82aa5f04cfaa9ca',2,'Enterprise Analytics','customer_profiles',NULL,'Source','AI-Powered Customer Analytics Platform',2026,NULL,NULL,'full_name',NULL,'Internal',NULL,'Full Name','Attribute full_name','pending',NULL,NULL,NULL,NULL,'VARCHAR','Raw',NULL,NULL,'-','postgresql',45000,NULL,'2026-08-31 00:36:01');
INSERT INTO "metadata_records" VALUES('8aa2ddf2b43145cb8776e54e77bf23b7','43e4c48c66bc40cca82aa5f04cfaa9ca',3,'Enterprise Analytics','customer_profiles',NULL,'Source','AI-Powered Customer Analytics Platform',2026,NULL,NULL,'national_id',NULL,'Confidential',NULL,'National Id','Attribute national_id','pending',NULL,NULL,NULL,NULL,'VARCHAR','Raw',NULL,NULL,'-','postgresql',45000,NULL,'2026-08-31 00:36:01');
INSERT INTO "metadata_records" VALUES('601cc7a7366740da8cde7841011cb630','43e4c48c66bc40cca82aa5f04cfaa9ca',4,'Enterprise Analytics','customer_profiles',NULL,'Source','AI-Powered Customer Analytics Platform',2026,NULL,NULL,'email',NULL,'Confidential',NULL,'Email','Attribute email','pending',NULL,NULL,NULL,NULL,'TIMESTAMP','Raw',NULL,NULL,'-','postgresql',45000,NULL,'2026-08-31 00:36:01');
INSERT INTO "metadata_records" VALUES('c506715f557240099822bccfcbfcaab7','43e4c48c66bc40cca82aa5f04cfaa9ca',5,'Enterprise Analytics','customer_profiles',NULL,'Source','AI-Powered Customer Analytics Platform',2026,NULL,NULL,'phone_number',NULL,'Confidential',NULL,'Phone Number','Attribute phone_number','pending',NULL,NULL,NULL,NULL,'TIMESTAMP','Raw',NULL,NULL,'-','postgresql',45000,NULL,'2026-08-31 00:36:01');
INSERT INTO "metadata_records" VALUES('26ef16aed0ca4fd587c529200537b6c4','43e4c48c66bc40cca82aa5f04cfaa9ca',6,'Enterprise Analytics','customer_profiles',NULL,'Source','AI-Powered Customer Analytics Platform',2026,NULL,NULL,'income_tier',NULL,'Internal',NULL,'Income Tier','Attribute income_tier','pending',NULL,NULL,NULL,NULL,'TIMESTAMP','Raw',NULL,NULL,'-','postgresql',45000,NULL,'2026-08-31 00:36:01');
INSERT INTO "metadata_records" VALUES('b59d064d605542aa90c10e3ae3a3196a','43e4c48c66bc40cca82aa5f04cfaa9ca',7,'Enterprise Analytics','customer_profiles',NULL,'Source','AI-Powered Customer Analytics Platform',2026,NULL,NULL,'created_at',NULL,'Internal',NULL,'Created At','Attribute created_at','pending',NULL,NULL,NULL,NULL,'TIMESTAMP','Raw',NULL,NULL,'-','postgresql',45000,NULL,'2026-08-31 00:36:01');
INSERT INTO "metadata_records" VALUES('359c1437308a4ae9b31da11779c32bb8','43e4c48c66bc40cca82aa5f04cfaa9ca',8,'Enterprise Analytics','transaction_logs',NULL,'Source','AI-Powered Customer Analytics Platform',2026,NULL,NULL,'tx_id',NULL,'Internal',NULL,'Tx Id','Attribute tx_id','pending',NULL,NULL,NULL,NULL,'VARCHAR','Raw',NULL,NULL,'-','postgresql',45000,NULL,'2026-08-31 00:36:01');
INSERT INTO "metadata_records" VALUES('e04f1857417e4890b159a8178be7c620','43e4c48c66bc40cca82aa5f04cfaa9ca',9,'Enterprise Analytics','transaction_logs',NULL,'Source','AI-Powered Customer Analytics Platform',2026,NULL,NULL,'customer_id',NULL,'Internal',NULL,'Customer Id','Attribute customer_id','pending',NULL,NULL,NULL,NULL,'VARCHAR','Raw',NULL,NULL,'-','postgresql',45000,NULL,'2026-08-31 00:36:01');
INSERT INTO "metadata_records" VALUES('827f94eb61494ee38ff1f5ed7d3bd0f9','43e4c48c66bc40cca82aa5f04cfaa9ca',10,'Enterprise Analytics','transaction_logs',NULL,'Source','AI-Powered Customer Analytics Platform',2026,NULL,NULL,'amount',NULL,'Internal',NULL,'Amount','Attribute amount','pending',NULL,NULL,NULL,NULL,'NUMERIC','Raw',NULL,NULL,'-','postgresql',45000,NULL,'2026-08-31 00:36:01');
INSERT INTO "metadata_records" VALUES('c1d37e4cd371405e828315e724f00269','43e4c48c66bc40cca82aa5f04cfaa9ca',11,'Enterprise Analytics','transaction_logs',NULL,'Source','AI-Powered Customer Analytics Platform',2026,NULL,NULL,'currency',NULL,'Internal',NULL,'Currency','Attribute currency','pending',NULL,NULL,NULL,NULL,'TIMESTAMP','Raw',NULL,NULL,'-','postgresql',45000,NULL,'2026-08-31 00:36:01');
INSERT INTO "metadata_records" VALUES('8ff8ce7fd8974fe7a422ca285b74f62a','43e4c48c66bc40cca82aa5f04cfaa9ca',12,'Enterprise Analytics','transaction_logs',NULL,'Source','AI-Powered Customer Analytics Platform',2026,NULL,NULL,'channel',NULL,'Internal',NULL,'Channel','Attribute channel','pending',NULL,NULL,NULL,NULL,'TIMESTAMP','Raw',NULL,NULL,'-','postgresql',45000,NULL,'2026-08-31 00:36:01');
INSERT INTO "metadata_records" VALUES('8d98f3215fc1434e984482daebe6590b','43e4c48c66bc40cca82aa5f04cfaa9ca',13,'Enterprise Analytics','transaction_logs',NULL,'Source','AI-Powered Customer Analytics Platform',2026,NULL,NULL,'merchant_id',NULL,'Internal',NULL,'Merchant Id','Attribute merchant_id','pending',NULL,NULL,NULL,NULL,'VARCHAR','Raw',NULL,NULL,'-','postgresql',45000,NULL,'2026-08-31 00:36:01');
INSERT INTO "metadata_records" VALUES('5fecec34b1a7497f8d626475e55c7a2d','43e4c48c66bc40cca82aa5f04cfaa9ca',14,'Enterprise Analytics','transaction_logs',NULL,'Source','AI-Powered Customer Analytics Platform',2026,NULL,NULL,'tx_timestamp',NULL,'Internal',NULL,'Tx Timestamp','Attribute tx_timestamp','pending',NULL,NULL,NULL,NULL,'TIMESTAMP','Raw',NULL,NULL,'-','postgresql',45000,NULL,'2026-08-31 00:36:01');
INSERT INTO "metadata_records" VALUES('fdebddcce9df422aaceb5a302e60c023','43e4c48c66bc40cca82aa5f04cfaa9ca',15,'Enterprise Analytics','transaction_logs',NULL,'Source','AI-Powered Customer Analytics Platform',2026,NULL,NULL,'status',NULL,'Internal',NULL,'Status','Attribute status','pending',NULL,NULL,NULL,NULL,'TIMESTAMP','Raw',NULL,NULL,'-','postgresql',45000,NULL,'2026-08-31 00:36:01');
INSERT INTO "metadata_records" VALUES('1dbdbcb0b4244bf18492065a5a219aa9','43e4c48c66bc40cca82aa5f04cfaa9ca',16,'Enterprise Analytics','fraud_risk_scores',NULL,'Source','AI-Powered Customer Analytics Platform',2026,NULL,NULL,'score_id',NULL,'Internal',NULL,'Score Id','Attribute score_id','pending',NULL,NULL,NULL,NULL,'VARCHAR','Raw',NULL,NULL,'-','bigquery',45000,NULL,'2026-08-31 00:36:02');
INSERT INTO "metadata_records" VALUES('d8cfb72c5d694cd2b9d6b0c048fa3ef4','43e4c48c66bc40cca82aa5f04cfaa9ca',17,'Enterprise Analytics','fraud_risk_scores',NULL,'Source','AI-Powered Customer Analytics Platform',2026,NULL,NULL,'customer_id',NULL,'Internal',NULL,'Customer Id','Attribute customer_id','pending',NULL,NULL,NULL,NULL,'VARCHAR','Raw',NULL,NULL,'-','bigquery',45000,NULL,'2026-08-31 00:36:02');
INSERT INTO "metadata_records" VALUES('c703f3d287064e4a92520b288f3ce1a3','43e4c48c66bc40cca82aa5f04cfaa9ca',18,'Enterprise Analytics','fraud_risk_scores',NULL,'Source','AI-Powered Customer Analytics Platform',2026,NULL,NULL,'risk_score',NULL,'Internal',NULL,'Risk Score','Attribute risk_score','pending',NULL,NULL,NULL,NULL,'NUMERIC','Raw',NULL,NULL,'-','bigquery',45000,NULL,'2026-08-31 00:36:02');
INSERT INTO "metadata_records" VALUES('e9fe3b9196844021a526158657855999','43e4c48c66bc40cca82aa5f04cfaa9ca',19,'Enterprise Analytics','fraud_risk_scores',NULL,'Source','AI-Powered Customer Analytics Platform',2026,NULL,NULL,'model_version',NULL,'Internal',NULL,'Model Version','Attribute model_version','pending',NULL,NULL,NULL,NULL,'TIMESTAMP','Raw',NULL,NULL,'-','bigquery',45000,NULL,'2026-08-31 00:36:02');
INSERT INTO "metadata_records" VALUES('92db600799ff4b5c99f7409ffaee42c9','43e4c48c66bc40cca82aa5f04cfaa9ca',20,'Enterprise Analytics','fraud_risk_scores',NULL,'Source','AI-Powered Customer Analytics Platform',2026,NULL,NULL,'calculated_at',NULL,'Internal',NULL,'Calculated At','Attribute calculated_at','pending',NULL,NULL,NULL,NULL,'TIMESTAMP','Raw',NULL,NULL,'-','bigquery',45000,NULL,'2026-08-31 00:36:02');
INSERT INTO "metadata_records" VALUES('dfcb7218f2e549d5bf6316847597f88a','43e4c48c66bc40cca82aa5f04cfaa9ca',21,'Enterprise Analytics','fraud_risk_scores',NULL,'Source','AI-Powered Customer Analytics Platform',2026,NULL,NULL,'action_flag',NULL,'Internal',NULL,'Action Flag','Attribute action_flag','pending',NULL,NULL,NULL,NULL,'TIMESTAMP','Raw',NULL,NULL,'-','bigquery',45000,NULL,'2026-08-31 00:36:02');
INSERT INTO "metadata_records" VALUES('2aa7a793f72746d997a1298a9133f2c2','43e4c48c66bc40cca82aa5f04cfaa9ca',22,'Enterprise Analytics','user_device_telemetry',NULL,'Source','AI-Powered Customer Analytics Platform',2026,NULL,NULL,'session_id',NULL,'Internal',NULL,'Session Id','Attribute session_id','pending',NULL,NULL,NULL,NULL,'VARCHAR','Raw',NULL,NULL,'-','bigquery',45000,NULL,'2026-08-31 00:36:02');
INSERT INTO "metadata_records" VALUES('88e97ef477034ebe9e3d3e9c63064d19','43e4c48c66bc40cca82aa5f04cfaa9ca',23,'Enterprise Analytics','user_device_telemetry',NULL,'Source','AI-Powered Customer Analytics Platform',2026,NULL,NULL,'customer_id',NULL,'Internal',NULL,'Customer Id','Attribute customer_id','pending',NULL,NULL,NULL,NULL,'VARCHAR','Raw',NULL,NULL,'-','bigquery',45000,NULL,'2026-08-31 00:36:02');
INSERT INTO "metadata_records" VALUES('c450d03c1ea543639586637a29502155','43e4c48c66bc40cca82aa5f04cfaa9ca',24,'Enterprise Analytics','user_device_telemetry',NULL,'Source','AI-Powered Customer Analytics Platform',2026,NULL,NULL,'ip_address',NULL,'Internal',NULL,'Ip Address','Attribute ip_address','pending',NULL,NULL,NULL,NULL,'TIMESTAMP','Raw',NULL,NULL,'-','bigquery',45000,NULL,'2026-08-31 00:36:02');
INSERT INTO "metadata_records" VALUES('c9805c6ddcda4a1b87924b40adb2b26a','43e4c48c66bc40cca82aa5f04cfaa9ca',25,'Enterprise Analytics','user_device_telemetry',NULL,'Source','AI-Powered Customer Analytics Platform',2026,NULL,NULL,'device_fingerprint',NULL,'Internal',NULL,'Device Fingerprint','Attribute device_fingerprint','pending',NULL,NULL,NULL,NULL,'TIMESTAMP','Raw',NULL,NULL,'-','bigquery',45000,NULL,'2026-08-31 00:36:02');
INSERT INTO "metadata_records" VALUES('f1d97ed770f242008e0d82af1f51bdc5','43e4c48c66bc40cca82aa5f04cfaa9ca',26,'Enterprise Analytics','user_device_telemetry',NULL,'Source','AI-Powered Customer Analytics Platform',2026,NULL,NULL,'os_type',NULL,'Internal',NULL,'Os Type','Attribute os_type','pending',NULL,NULL,NULL,NULL,'VARCHAR','Raw',NULL,NULL,'-','bigquery',45000,NULL,'2026-08-31 00:36:02');
INSERT INTO "metadata_records" VALUES('26ffdff5055c41378ebe1c2db1a56cbf','43e4c48c66bc40cca82aa5f04cfaa9ca',27,'Enterprise Analytics','user_device_telemetry',NULL,'Source','AI-Powered Customer Analytics Platform',2026,NULL,NULL,'last_seen',NULL,'Internal',NULL,'Last Seen','Attribute last_seen','pending',NULL,NULL,NULL,NULL,'TIMESTAMP','Raw',NULL,NULL,'-','bigquery',45000,NULL,'2026-08-31 00:36:02');
CREATE TABLE notification_preferences (
	id VARCHAR(36) NOT NULL, 
	user_id VARCHAR(36) NOT NULL, 
	module VARCHAR(60) NOT NULL, 
	in_app BOOLEAN NOT NULL, 
	email BOOLEAN NOT NULL, 
	CONSTRAINT pk_notification_preferences PRIMARY KEY (id), 
	CONSTRAINT fk_notification_preferences_user_id_users FOREIGN KEY(user_id) REFERENCES users (id) ON DELETE CASCADE
);
CREATE TABLE notifications (
	id VARCHAR(36) NOT NULL, 
	user_id VARCHAR(36) NOT NULL, 
	module VARCHAR(60) NOT NULL, 
	event VARCHAR(80) NOT NULL, 
	title VARCHAR(300) NOT NULL, 
	body TEXT, 
	entity_type VARCHAR(80), 
	entity_id TEXT, 
	is_read BOOLEAN NOT NULL, 
	created_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL, 
	CONSTRAINT pk_notifications PRIMARY KEY (id), 
	CONSTRAINT fk_notifications_user_id_users FOREIGN KEY(user_id) REFERENCES users (id) ON DELETE CASCADE
);
INSERT INTO "notifications" VALUES('d86eaa86e6e24621ba98fa2c9443b1de','92d40357c37041bd843ca09f0abc31a6','ai_checklist','ai_checklist_approval_requested','AI_CHECKLIST Approval Required: DSR-2026-0001','Eko Prasetyo submitted AI_CHECKLIST (DSR-2026-0001) which requires your review and sign-off for Step 1 (PIC Data Compliance Approval).','ai_checklist','4472b214-d385-48ee-8be3-ef42ee81c49b',1,'2026-08-30 06:04:04');
INSERT INTO "notifications" VALUES('c86bdfa6effa4236ad8f8e2c924baa99','2c8b080e236f4808ba5024c9f6a3c494','ai_checklist','ai_checklist_approval_requested','AI_CHECKLIST Approval Required: DSR-2026-0001','Dewi Rahayu submitted AI_CHECKLIST (DSR-2026-0001) which requires your review and sign-off for Step 2 (DM Sign-off).','ai_checklist','4472b214-d385-48ee-8be3-ef42ee81c49b',1,'2026-08-30 06:35:48');
INSERT INTO "notifications" VALUES('28e3e92cdd6047f98c0b0b9e939e3408','eb2cf472bae34648b444ac549055b410','ai_checklist','ai_checklist_approval_requested','AI_CHECKLIST Approval Required: DSR-2026-0001','Anisa Putri submitted AI_CHECKLIST (DSR-2026-0001) which requires your review and sign-off for Step 3 (SME Sign-off).','ai_checklist','4472b214-d385-48ee-8be3-ef42ee81c49b',0,'2026-08-30 06:36:47');
INSERT INTO "notifications" VALUES('a6d18802733a4a1589f13a168441d894','5b5a78847ea44fbcb7dd0c9d44567ab1','ropa','ropa_approval_requested','ROPA Approval Required: Customer Risk Scoring & Fraud Profiling','Eko Prasetyo submitted ROPA (Customer Risk Scoring & Fraud Profiling) which requires your review and sign-off for Step 1 (Compliance Review & Sign-Off).','ropa','0e9a0da5-0124-4e83-a5b6-af156357a222',0,'2026-08-30 10:06:29');
INSERT INTO "notifications" VALUES('9a4946890d434e0ea2d2997bb74e9730','ac6a037060964450a5a923c9a534e6b9','ropa','ropa_approved','ROPA Customer Risk Scoring & Fraud Profiling Approved','Your ROPA request (Customer Risk Scoring & Fraud Profiling) has been approved by Ahmad Fauzi. Comments: Fully compliant with PDP Law Article 30','ropa','0e9a0da5-0124-4e83-a5b6-af156357a222',1,'2026-08-30 10:06:35');
INSERT INTO "notifications" VALUES('9c940b29286243d28ee5ef8e1e633c70','5b5a78847ea44fbcb7dd0c9d44567ab1','ropa','ropa_approval_requested','ROPA Approval Required: Customer Risk Scoring & Fraud Profiling','Eko Prasetyo submitted ROPA (Customer Risk Scoring & Fraud Profiling) which requires your review and sign-off for Step 1 (Compliance Review & Sign-Off).','ropa','e0f941a4-0390-486b-9efd-dd5c96524dc0',0,'2026-08-30 10:08:49');
INSERT INTO "notifications" VALUES('16c4b74cc20442d296771ecaab592b50','92d40357c37041bd843ca09f0abc31a6','ropa','ropa_approval_requested','ROPA Approval Required: Customer Risk Scoring & Fraud Profiling','Eko Prasetyo submitted ROPA (Customer Risk Scoring & Fraud Profiling) which requires your review and sign-off for Step 1 (Compliance Review & Sign-Off).','ropa','e0f941a4-0390-486b-9efd-dd5c96524dc0',0,'2026-08-30 10:08:53');
INSERT INTO "notifications" VALUES('329be4b32cf540e298484db47aff62cb','ac6a037060964450a5a923c9a534e6b9','ropa','ropa_approved','ROPA Customer Risk Scoring & Fraud Profiling Approved','Your ROPA request (Customer Risk Scoring & Fraud Profiling) has been approved by Ahmad Fauzi. Comments: Fully compliant with PDP Law Article 30','ropa','e0f941a4-0390-486b-9efd-dd5c96524dc0',1,'2026-08-30 10:09:04');
INSERT INTO "notifications" VALUES('0a1220bb96b64167887ad6d14e643882','5b5a78847ea44fbcb7dd0c9d44567ab1','bapd','bapd_approval_requested','BAPD Approval Required: BAPD-d86407b1','Eko Prasetyo submitted BAPD (BAPD-d86407b1) which requires your review and sign-off for Step 1 (Data Owner Sign-Off).','bapd','d86407b1-99c9-49c3-bee0-009777360112',0,'2026-08-31 01:05:15');
INSERT INTO "notifications" VALUES('59f45d791f1045379b521994b8dfc9e8','92d40357c37041bd843ca09f0abc31a6','bapd','bapd_approval_requested','BAPD Approval Required: BAPD-d86407b1','Super Administrator submitted BAPD (BAPD-d86407b1) which requires your review and sign-off for Step 2 (Compliance Officer Review).','bapd','d86407b1-99c9-49c3-bee0-009777360112',0,'2026-08-31 01:05:19');
INSERT INTO "notifications" VALUES('dce3c20aaeb5463d8d933a904d791734','5b5a78847ea44fbcb7dd0c9d44567ab1','bapd','bapd_approval_requested','BAPD Approval Required: BAPD-2e13d628','Eko Prasetyo submitted BAPD (BAPD-2e13d628) which requires your review and sign-off for Step 1 (Data Owner Sign-Off).','bapd','2e13d628-b031-422b-9658-c6a2a3d883cf',0,'2026-08-31 01:07:14');
INSERT INTO "notifications" VALUES('3f13af794cab4df38108a31b4368b111','92d40357c37041bd843ca09f0abc31a6','bapd','bapd_approval_requested','BAPD Approval Required: BAPD-2e13d628','Super Administrator submitted BAPD (BAPD-2e13d628) which requires your review and sign-off for Step 2 (Compliance Officer Review).','bapd','2e13d628-b031-422b-9658-c6a2a3d883cf',0,'2026-08-31 01:07:18');
INSERT INTO "notifications" VALUES('b1847fb50c70489d8a5bd4bf409ff6dd','ac6a037060964450a5a923c9a534e6b9','bapd','bapd_approved','BAPD BAPD-2e13d628 Approved','Your BAPD request (BAPD-2e13d628) has been approved by Budi Santoso.','bapd','2e13d628-b031-422b-9658-c6a2a3d883cf',0,'2026-08-31 01:07:22');
INSERT INTO "notifications" VALUES('6e6df0d2c27d48a281cde8e08b776259','5b5a78847ea44fbcb7dd0c9d44567ab1','bapd','bapd_approval_requested','BAPD Approval Required: BAPD-15f4665a','Eko Prasetyo submitted BAPD (BAPD-15f4665a) which requires your review and sign-off for Step 1 (Data Owner Sign-Off).','bapd','15f4665a-cd4d-4e27-b7ba-360c4c42b252',1,'2026-08-31 01:09:39');
INSERT INTO "notifications" VALUES('5a1a04cc3d6b4ee783a634573d35bf5e','92d40357c37041bd843ca09f0abc31a6','bapd','bapd_approval_requested','BAPD Approval Required: BAPD-15f4665a','Super Administrator submitted BAPD (BAPD-15f4665a) which requires your review and sign-off for Step 2 (Compliance Officer Review).','bapd','15f4665a-cd4d-4e27-b7ba-360c4c42b252',0,'2026-08-31 01:09:44');
INSERT INTO "notifications" VALUES('66b8b3facc224ee0a5e9250ebaa48c66','ac6a037060964450a5a923c9a534e6b9','bapd','bapd_approved','BAPD BAPD-15f4665a Approved','Your BAPD request (BAPD-15f4665a) has been approved by Budi Santoso.','bapd','15f4665a-cd4d-4e27-b7ba-360c4c42b252',0,'2026-08-31 01:09:48');
INSERT INTO "notifications" VALUES('b9945e9ac3e0473ca769e9691c462dee','ac6a037060964450a5a923c9a534e6b9','bapd','bapd_executed','BAPD BAPD-15f4665a Rejected','Your BAPD request (BAPD-15f4665a) has been executed by Budi Santoso.','bapd','15f4665a-cd4d-4e27-b7ba-360c4c42b252',0,'2026-08-31 01:09:56');
INSERT INTO "notifications" VALUES('7388d203022b4ef084bea6fc7ad93007','5b5a78847ea44fbcb7dd0c9d44567ab1','bapd','bapd_approval_requested','BAPD Approval Required: BAPD-9fbe80b6','Eko Prasetyo submitted BAPD (BAPD-9fbe80b6) which requires your review and sign-off for Step 1 (Data Owner Sign-Off).','bapd','9fbe80b6-f9ab-4a9a-b8af-5f490a984d5e',0,'2026-08-31 05:14:15');
INSERT INTO "notifications" VALUES('b52344053f0346a193596bd04f99b51f','92d40357c37041bd843ca09f0abc31a6','bapd','bapd_approval_requested','BAPD Approval Required: BAPD-9fbe80b6','Budi Santoso submitted BAPD (BAPD-9fbe80b6) which requires your review and sign-off for Step 2 (Compliance Officer Review).','bapd','9fbe80b6-f9ab-4a9a-b8af-5f490a984d5e',1,'2026-08-31 05:14:49');
INSERT INTO "notifications" VALUES('e2e23d4e850f4fd080c6eecfeef9d8ab','eb2cf472bae34648b444ac549055b410','bapd','bapd_approved','BAPD BAPD-9fbe80b6 Approved','Your BAPD request (BAPD-9fbe80b6) has been approved by Dewi Rahayu.','bapd','9fbe80b6-f9ab-4a9a-b8af-5f490a984d5e',0,'2026-08-31 05:27:27');
INSERT INTO "notifications" VALUES('24e72b0c83a2425093de64e436676878','eb2cf472bae34648b444ac549055b410','bapd','bapd_executed','BAPD BAPD-9fbe80b6 Rejected','Your BAPD request (BAPD-9fbe80b6) has been executed by Super Administrator.','bapd','9fbe80b6-f9ab-4a9a-b8af-5f490a984d5e',0,'2026-09-01 02:52:49');
CREATE TABLE project_source_files (
	id VARCHAR(36) NOT NULL, 
	project_id VARCHAR(36) NOT NULL, 
	source_type VARCHAR(32) NOT NULL, 
	original_filename VARCHAR(512) NOT NULL, 
	stored_path VARCHAR(1024) NOT NULL, 
	file_size BIGINT, 
	uploaded_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL, 
	uploaded_by VARCHAR(256), 
	CONSTRAINT pk_project_source_files PRIMARY KEY (id), 
	CONSTRAINT fk_project_source_files_project_id_projects FOREIGN KEY(project_id) REFERENCES projects (id) ON DELETE CASCADE
);
CREATE TABLE projects (
	id VARCHAR(36) NOT NULL, 
	project_code VARCHAR(50), 
	customer_name VARCHAR(200) NOT NULL, 
	line_of_business VARCHAR(200), 
	project_name VARCHAR(300) NOT NULL, 
	use_case TEXT, 
	project_year SMALLINT NOT NULL, 
	project_category VARCHAR(50) NOT NULL, 
	is_monetized BOOLEAN NOT NULL, 
	start_date DATE, 
	end_date DATE, 
	sme_id VARCHAR(36), 
	delivery_manager_id VARCHAR(36), 
	project_manager_id VARCHAR(36), 
	dgo_id VARCHAR(36), 
	metadata_officer_id VARCHAR(36), 
	dq_officer_id VARCHAR(36), 
	pic_data_compliance_id VARCHAR(36), 
	created_by VARCHAR(36) NOT NULL, 
	created_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL, 
	updated_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL, 
	CONSTRAINT pk_projects PRIMARY KEY (id), 
	CONSTRAINT fk_projects_sme_id_users FOREIGN KEY(sme_id) REFERENCES users (id), 
	CONSTRAINT fk_projects_delivery_manager_id_users FOREIGN KEY(delivery_manager_id) REFERENCES users (id), 
	CONSTRAINT fk_projects_project_manager_id_users FOREIGN KEY(project_manager_id) REFERENCES users (id), 
	CONSTRAINT fk_projects_dgo_id_users FOREIGN KEY(dgo_id) REFERENCES users (id), 
	CONSTRAINT fk_projects_metadata_officer_id_users FOREIGN KEY(metadata_officer_id) REFERENCES users (id), 
	CONSTRAINT fk_projects_dq_officer_id_users FOREIGN KEY(dq_officer_id) REFERENCES users (id), 
	CONSTRAINT fk_projects_pic_data_compliance_id_users FOREIGN KEY(pic_data_compliance_id) REFERENCES users (id), 
	CONSTRAINT fk_projects_created_by_users FOREIGN KEY(created_by) REFERENCES users (id)
);
INSERT INTO "projects" VALUES('43e4c48c66bc40cca82aa5f04cfaa9ca','PRJ-2026-001','Telco Nusantara Group','Enterprise Digital','AI-Powered Customer Analytics Platform','Predictive customer churn and cross-sell recommendation engine',2026,'AI / ML',1,'2026-01-01','2026-12-31','92d40357c37041bd843ca09f0abc31a6','eb2cf472bae34648b444ac549055b410','458d255ea9f04ad5bed64bbb31fe9cc0','2c8b080e236f4808ba5024c9f6a3c494',NULL,NULL,'5b5a78847ea44fbcb7dd0c9d44567ab1','d37a17105d9f4f8fb3a3b2510317b7d6','2026-08-30 05:27:57','2026-08-30 05:27:57');
INSERT INTO "projects" VALUES('6bda77801b7e4178ad23a1cbb180ea47','PRJ-000x','TAM','automotive','DIDX','Lorem ipsum',2026,'Other',1,'2026-12-01','2027-12-31','eb2cf472bae34648b444ac549055b410','2c8b080e236f4808ba5024c9f6a3c494','458d255ea9f04ad5bed64bbb31fe9cc0','5b5a78847ea44fbcb7dd0c9d44567ab1','5b5a78847ea44fbcb7dd0c9d44567ab1','5b5a78847ea44fbcb7dd0c9d44567ab1','92d40357c37041bd843ca09f0abc31a6','ac6a037060964450a5a923c9a534e6b9','2026-08-30 06:00:33','2026-08-30 06:00:33');
INSERT INTO "projects" VALUES('ecca2cac550e47fe8f975a666b40bee6','PRJ-002026-Astra-Infra','PT Astra Infra','Manufacturing','A-Infra','Lorem Ipsum',2026,'Analytics',0,'2025-01-01','2027-01-01','eb2cf472bae34648b444ac549055b410','2c8b080e236f4808ba5024c9f6a3c494','458d255ea9f04ad5bed64bbb31fe9cc0','5b5a78847ea44fbcb7dd0c9d44567ab1','92d40357c37041bd843ca09f0abc31a6','92d40357c37041bd843ca09f0abc31a6','92d40357c37041bd843ca09f0abc31a6','ac6a037060964450a5a923c9a534e6b9','2026-09-01 03:05:05','2026-09-01 03:05:05');
CREATE TABLE retention_policies (
	id VARCHAR(36) NOT NULL, 
	dataset_type VARCHAR(150) NOT NULL, 
	retention_days INTEGER NOT NULL, 
	policy_reference TEXT, 
	created_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL, 
	updated_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL, 
	CONSTRAINT pk_retention_policies PRIMARY KEY (id), 
	CONSTRAINT uq_retention_policies_dataset_type UNIQUE (dataset_type)
);
INSERT INTO "retention_policies" VALUES('436a7b1196aa4fcd862417aec6949e7c','Personal Data',1825,'GDPR Art.5(1)(e) — 5 years','2026-08-31 01:03:39','2026-08-31 01:03:39');
INSERT INTO "retention_policies" VALUES('3edf4e39bf2946d18810217aac39c75f','Financial Records',2555,'Company Act — 7 years','2026-08-31 01:03:39','2026-08-31 01:03:39');
INSERT INTO "retention_policies" VALUES('174f75686bfd4041a736949b24388409','Health Data',3650,'Health Act — 10 years','2026-08-31 01:03:39','2026-08-31 01:03:39');
INSERT INTO "retention_policies" VALUES('d5c95f5043c1435b9c7357fe01db48d7','Operational Logs',365,'IT Policy — 1 year','2026-08-31 01:03:39','2026-08-31 01:03:39');
INSERT INTO "retention_policies" VALUES('11b37e97e645472c936921b637222efe','Audit Logs',2555,'Compliance — 7 years','2026-08-31 01:03:39','2026-08-31 01:03:39');
INSERT INTO "retention_policies" VALUES('9add77d154d04b9bae5c3039af68d559','Marketing Data',730,'PDPA — 2 years','2026-08-31 01:03:39','2026-08-31 01:03:39');
INSERT INTO "retention_policies" VALUES('8fdaf99633b04af095565528eafa5f0c','Employee Records',3650,'Labour Law — 10 years','2026-08-31 01:03:39','2026-08-31 01:03:39');
INSERT INTO "retention_policies" VALUES('84df59e0c32e4b9ba1381c58c402b66e','Contract Data',3650,'Civil Code — 10 years','2026-08-31 01:03:39','2026-08-31 01:03:39');
CREATE TABLE roles (
	id INTEGER NOT NULL, 
	name VARCHAR(100) NOT NULL, 
	description TEXT, 
	permissions JSON, 
	created_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL, 
	CONSTRAINT pk_roles PRIMARY KEY (id), 
	CONSTRAINT uq_roles_name UNIQUE (name)
);
INSERT INTO "roles" VALUES(1,'super_admin','Full access to all modules and settings',NULL,'2026-08-30 05:27:52');
INSERT INTO "roles" VALUES(2,'data_governance_officer','Manages governance policies and approvals',NULL,'2026-08-30 05:27:52');
INSERT INTO "roles" VALUES(3,'compliance_officer','Reviews and approves compliance-related items',NULL,'2026-08-30 05:27:52');
INSERT INTO "roles" VALUES(4,'data_owner','Owns datasets and approves DSRs and BAPDs',NULL,'2026-08-30 05:27:52');
INSERT INTO "roles" VALUES(5,'data_steward','Manages metadata and data quality for assigned domains',NULL,'2026-08-30 05:27:52');
INSERT INTO "roles" VALUES(6,'dpo','Data Protection Officer — reviews DPIAs',NULL,'2026-08-30 05:27:52');
INSERT INTO "roles" VALUES(7,'auditor','Read-only access to audit logs and reports',NULL,'2026-08-30 05:27:52');
INSERT INTO "roles" VALUES(8,'regular_user','Basic access for project members',NULL,'2026-08-30 05:27:52');
INSERT INTO "roles" VALUES(9,'project_manager','Project delivery and milestone approvals',NULL,'2026-08-30 05:27:52');
INSERT INTO "roles" VALUES(10,'viewer','Read-only access across platform',NULL,'2026-08-30 05:27:52');
CREATE TABLE ropa_records (
	id VARCHAR(36) NOT NULL, 
	project_id VARCHAR(36) NOT NULL, 
	process_name VARCHAR(300) NOT NULL, 
	purpose TEXT NOT NULL, 
	data_category TEXT NOT NULL, 
	data_subject TEXT NOT NULL, 
	legal_basis TEXT NOT NULL, 
	retention_period VARCHAR(100) NOT NULL, 
	recipient TEXT, 
	linked_asset_ids JSON, 
	status VARCHAR(30) NOT NULL, 
	version SMALLINT NOT NULL, 
	created_by VARCHAR(36) NOT NULL, 
	created_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL, 
	updated_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL, 
	CONSTRAINT pk_ropa_records PRIMARY KEY (id), 
	CONSTRAINT fk_ropa_records_project_id_projects FOREIGN KEY(project_id) REFERENCES projects (id), 
	CONSTRAINT fk_ropa_records_created_by_users FOREIGN KEY(created_by) REFERENCES users (id)
);
INSERT INTO "ropa_records" VALUES('0e9a0da501244e83a5b6af156357a222','6bda77801b7e4178ad23a1cbb180ea47','Customer Risk Scoring & Fraud Profiling','AI/ML behavioral risk analysis for fraud detection and loan limit evaluation under PDP Law','Personal & Financial Telemetry','Retail Banking Customers','Consent','5 Years from Account Termination','External Credit Bureau & Cloud AI Partner','["customer_profiles", "transaction_logs"]','approved',2,'ac6a037060964450a5a923c9a534e6b9','2026-08-30 10:06:22','2026-08-30 10:06:31');
INSERT INTO "ropa_records" VALUES('e0f941a40390486b9efddd5c96524dc0','6bda77801b7e4178ad23a1cbb180ea47','Customer Risk Scoring & Fraud Profiling','AI/ML behavioral risk analysis for fraud detection and loan limit evaluation under PDP Law','Personal & Financial Telemetry','Retail Banking Customers','Consent','5 Years from Account Termination','External Credit Bureau & Cloud AI Partner','["customer_profiles", "transaction_logs"]','approved',2,'ac6a037060964450a5a923c9a534e6b9','2026-08-30 10:08:40','2026-08-30 10:09:00');
INSERT INTO "ropa_records" VALUES('ea005aba0beb43a1ade881c19dbd1c21','6bda77801b7e4178ad23a1cbb180ea47','Asset Link Test Activity','Testing linked assets selection from catalogue','Financial Data','Customers','Consent','3 Years',NULL,'["customer_profiles", "transaction_logs", "custom_crm_export"]','draft',1,'ac6a037060964450a5a923c9a534e6b9','2026-08-31 00:35:45','2026-08-31 00:35:45');
INSERT INTO "ropa_records" VALUES('ddfb70449a6545a3a1f8c2bca570e73b','6bda77801b7e4178ad23a1cbb180ea47','Asset Link Test Activity','Testing linked assets selection from catalogue','Financial Data','Customers','Consent','3 Years',NULL,'["customer_profiles", "transaction_logs", "custom_crm_export"]','draft',1,'ac6a037060964450a5a923c9a534e6b9','2026-08-31 00:36:08','2026-08-31 00:36:08');
INSERT INTO "ropa_records" VALUES('4c028957e83943ca9f486d3acc53eb7e','6bda77801b7e4178ad23a1cbb180ea47','Profiling Customer','Lorem Ipsum Dolor','PII','Automotive','Consent','2 Months','TAM','["customer_profiles", "transaction_logs", "fraud_risk_scores", "user_device_telemetry"]','draft',1,'ac6a037060964450a5a923c9a534e6b9','2026-08-31 00:46:15','2026-08-31 00:46:15');
CREATE TABLE user_project_roles (
	id VARCHAR(36) NOT NULL, 
	user_id VARCHAR(36) NOT NULL, 
	role_id SMALLINT NOT NULL, 
	project_id VARCHAR(36), 
	assigned_by VARCHAR(36) NOT NULL, 
	assigned_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL, 
	revoked_at DATETIME, 
	CONSTRAINT pk_user_project_roles PRIMARY KEY (id), 
	CONSTRAINT fk_user_project_roles_user_id_users FOREIGN KEY(user_id) REFERENCES users (id), 
	CONSTRAINT fk_user_project_roles_role_id_roles FOREIGN KEY(role_id) REFERENCES roles (id), 
	CONSTRAINT fk_user_project_roles_project_id_projects FOREIGN KEY(project_id) REFERENCES projects (id), 
	CONSTRAINT fk_user_project_roles_assigned_by_users FOREIGN KEY(assigned_by) REFERENCES users (id)
);
INSERT INTO "user_project_roles" VALUES('0fce0d7ca9b34b0cb75ecb27c49244b8','d37a17105d9f4f8fb3a3b2510317b7d6',1,NULL,'d37a17105d9f4f8fb3a3b2510317b7d6','2026-08-30 05:27:53',NULL);
INSERT INTO "user_project_roles" VALUES('37c216df2c224e60b728c10b1c760700','ac6a037060964450a5a923c9a534e6b9',8,NULL,'ac6a037060964450a5a923c9a534e6b9','2026-08-30 05:27:53',NULL);
INSERT INTO "user_project_roles" VALUES('2c440a6116084e67a12c6572db59736a','5b5a78847ea44fbcb7dd0c9d44567ab1',3,NULL,'5b5a78847ea44fbcb7dd0c9d44567ab1','2026-08-30 05:27:54',NULL);
INSERT INTO "user_project_roles" VALUES('dfadc50067fd4c76b25df95545f0fb5b','eb2cf472bae34648b444ac549055b410',9,NULL,'eb2cf472bae34648b444ac549055b410','2026-08-30 05:27:54',NULL);
INSERT INTO "user_project_roles" VALUES('1f6b6bcc23bc4e6fa50babf69e3134c7','92d40357c37041bd843ca09f0abc31a6',5,NULL,'92d40357c37041bd843ca09f0abc31a6','2026-08-30 05:27:55',NULL);
INSERT INTO "user_project_roles" VALUES('e0587487264747718fdd111cb5e06cd7','2c8b080e236f4808ba5024c9f6a3c494',4,NULL,'2c8b080e236f4808ba5024c9f6a3c494','2026-08-30 05:27:55',NULL);
INSERT INTO "user_project_roles" VALUES('2ded3c9f8fc24c80a1c8f74b12677ee4','c42140f876ff4c9cbbe3a741ca63e3fa',3,NULL,'c42140f876ff4c9cbbe3a741ca63e3fa','2026-08-30 05:27:56',NULL);
INSERT INTO "user_project_roles" VALUES('02cbb5bb2ce7494a9a1b80a4d3364a6c','458d255ea9f04ad5bed64bbb31fe9cc0',9,NULL,'458d255ea9f04ad5bed64bbb31fe9cc0','2026-08-30 05:27:57',NULL);
CREATE TABLE users (
	id VARCHAR(36) NOT NULL, 
	full_name VARCHAR(200) NOT NULL, 
	email VARCHAR(200) NOT NULL, 
	password_hash TEXT NOT NULL, 
	position VARCHAR(200), 
	is_active BOOLEAN NOT NULL, 
	last_login_at DATETIME, 
	created_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL, 
	updated_at DATETIME DEFAULT (CURRENT_TIMESTAMP) NOT NULL, 
	CONSTRAINT pk_users PRIMARY KEY (id)
);
INSERT INTO "users" VALUES('d37a17105d9f4f8fb3a3b2510317b7d6','Super Administrator','admin@governance.local','$2b$12$UaNJOyx0UvRYExWOtw2WfeNpIru85AYk1yDNp1wrqg2lIXGosI32e','Chief Data & AI Officer',1,'2026-08-31 07:52:40.054607','2026-08-30 05:27:53','2026-08-31 07:52:40');
INSERT INTO "users" VALUES('ac6a037060964450a5a923c9a534e6b9','Eko Prasetyo','eko.prasetyo@company.com','$2b$12$d81bwDn5.qqrkmcJ.930g.ptTrO1AtzjbFq78fSl/pQJEL1Q6KLuC','Data Analyst / Requester',1,'2026-09-01 02:58:49.403233','2026-08-30 05:27:53','2026-09-01 02:58:49');
INSERT INTO "users" VALUES('5b5a78847ea44fbcb7dd0c9d44567ab1','Budi Santoso','budi.santoso@company.com','$2b$12$vywDnzkbiFs8s3KZfqHHceKO7xX.WZiHE1eElhrZJ5nYEbUfIbUmu','PIC Data Compliance',1,'2026-08-31 05:14:35.287989','2026-08-30 05:27:54','2026-08-31 05:14:35');
INSERT INTO "users" VALUES('eb2cf472bae34648b444ac549055b410','Ahmad Fauzi','ahmad.fauzi@company.com','$2b$12$L4fjPk9stOepG.fCP5tRt.KgHj8hO1s67m2YUbFeSFtl6tRbjWoY6','Delivery Manager',1,'2026-08-31 01:10:05.136505','2026-08-30 05:27:54','2026-08-31 05:08:44');
INSERT INTO "users" VALUES('92d40357c37041bd843ca09f0abc31a6','Dewi Rahayu','dewi.rahayu@company.com','$2b$12$uL9xDPp/eKXS4ljC5c/HX.Op0jyHPp7GM3fycts.s3b/ztlpFvZNS','Subject Matter Expert (SME)',1,'2026-08-31 05:27:12.786101','2026-08-30 05:27:55','2026-08-31 05:27:12');
INSERT INTO "users" VALUES('2c8b080e236f4808ba5024c9f6a3c494','Anisa Putri','anisa.putri@company.com','$2b$12$ZLw8vN.unKz9hW4sqWrPAe9lmnnkLOuQ6itzYkH2weZ1vBWJr6/9a','Data Governance Officer (DGO)',1,'2026-08-31 01:10:06.103674','2026-08-30 05:27:55','2026-08-31 05:08:45');
INSERT INTO "users" VALUES('c42140f876ff4c9cbbe3a741ca63e3fa','Fitri Handayani','fitri.handayani@company.com','$2b$12$Q9dF8ontOfyrj4YBgqB6vusmI.r4F0WfKd3uU7eOnceEoGvNqXrk6','Data Protection Officer (DPO)',1,'2026-08-31 01:10:06.638844','2026-08-30 05:27:56','2026-08-31 05:08:46');
INSERT INTO "users" VALUES('458d255ea9f04ad5bed64bbb31fe9cc0','Bagas Adi Nugraha','bagas.nugraha@company.com','$2b$12$cjH9nlZ1zvLpLhDZ3.xDxe3Vqo/c1HdZQ2Fvm38wIyjXCWKjWASSu','Lead Project Manager',1,'2026-08-31 01:10:07.202405','2026-08-30 05:27:57','2026-08-31 05:08:46');
CREATE UNIQUE INDEX ix_users_email ON users (email);
CREATE INDEX ix_audit_logs_created_at ON audit_logs (created_at);
CREATE INDEX ix_audit_logs_entity_id ON audit_logs (entity_id);
CREATE INDEX ix_audit_logs_module ON audit_logs (module);
CREATE UNIQUE INDEX ix_projects_project_code ON projects (project_code);
CREATE INDEX ix_projects_project_year ON projects (project_year);
CREATE INDEX ix_projects_customer_name ON projects (customer_name);
CREATE INDEX ix_notifications_created_at ON notifications (created_at);
CREATE INDEX ix_notifications_module ON notifications (module);
CREATE INDEX ix_notifications_is_read ON notifications (is_read);
CREATE INDEX ix_notifications_user_id ON notifications (user_id);
CREATE INDEX ix_notification_preferences_user_id ON notification_preferences (user_id);
CREATE INDEX ix_user_project_roles_user_id ON user_project_roles (user_id);
CREATE INDEX ix_data_sharing_requests_project_id ON data_sharing_requests (project_id);
CREATE UNIQUE INDEX ix_data_sharing_requests_tracking_id ON data_sharing_requests (tracking_id);
CREATE INDEX ix_data_sharing_requests_status ON data_sharing_requests (status);
CREATE INDEX ix_dpia_records_project_id ON dpia_records (project_id);
CREATE UNIQUE INDEX ix_dpia_records_tracking_id ON dpia_records (tracking_id);
CREATE INDEX ix_dpia_records_status ON dpia_records (status);
CREATE INDEX ix_ropa_records_status ON ropa_records (status);
CREATE INDEX ix_ropa_records_project_id ON ropa_records (project_id);
CREATE INDEX ix_bapd_records_project_id ON bapd_records (project_id);
CREATE INDEX ix_bapd_records_status ON bapd_records (status);
CREATE INDEX ix_metadata_records_data_attribute ON metadata_records (data_attribute);
CREATE INDEX ix_metadata_records_data_domain_table ON metadata_records (data_domain_table);
CREATE INDEX ix_metadata_records_project_id ON metadata_records (project_id);
CREATE INDEX ix_data_owner_stewards_project_id ON data_owner_stewards (project_id);
CREATE INDEX ix_project_source_files_project_id ON project_source_files (project_id);
CREATE INDEX ix_dsr_approvals_dsr_id ON dsr_approvals (dsr_id);
CREATE INDEX ix_dpia_approvals_dpia_id ON dpia_approvals (dpia_id);
CREATE INDEX ix_bapd_approvals_bapd_id ON bapd_approvals (bapd_id);
CREATE INDEX ix_dq_runs_project_id ON dq_runs (project_id);
CREATE INDEX ix_dq_runs_status ON dq_runs (status);
CREATE INDEX ix_ai_checklist_approvals_checklist_id ON ai_checklist_approvals (checklist_id);
CREATE INDEX ix_dq_results_run_id ON dq_results (run_id);
CREATE INDEX ix_dq_findings_status ON dq_findings (status);
CREATE INDEX ix_dq_findings_result_id ON dq_findings (result_id);
COMMIT;
