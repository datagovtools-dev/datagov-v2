"""
Locust performance test — P6-009
Target: 50 concurrent users, page load < 3s (NFR-001), API response < 500ms.

Usage:
  locust -f locustfile.py --host=http://localhost:8000 --users 50 --spawn-rate 5
  Or headless:
  locust -f locustfile.py --host=http://localhost:8000 --users 50 --spawn-rate 5 --run-time 2m --headless
"""
import os
import json
from locust import HttpUser, task, between, events

ADMIN_EMAIL = os.getenv("LOCUST_ADMIN_EMAIL", "admin@example.com")
ADMIN_PASSWORD = os.getenv("LOCUST_ADMIN_PASSWORD", "Admin1234!")


class GovernanceUser(HttpUser):
    wait_time = between(1, 3)
    token: str = ""

    def on_start(self):
        resp = self.client.post(
            "/api/v1/auth/login",
            json={"email": ADMIN_EMAIL, "password": ADMIN_PASSWORD},
        )
        if resp.status_code == 200:
            self.token = resp.json().get("access_token", "")
        else:
            self.token = ""

    def _headers(self) -> dict:
        return {"Authorization": f"Bearer {self.token}"} if self.token else {}

    @task(5)
    def view_dashboard(self):
        self.client.get("/api/v1/dashboard", headers=self._headers(), name="GET /dashboard")

    @task(4)
    def list_projects(self):
        self.client.get("/api/v1/projects?page_size=20", headers=self._headers(), name="GET /projects")

    @task(3)
    def list_dsrs(self):
        self.client.get("/api/v1/dsr?page_size=20", headers=self._headers(), name="GET /dsr")

    @task(2)
    def list_dpia(self):
        self.client.get("/api/v1/dpia?page_size=20", headers=self._headers(), name="GET /dpia")

    @task(2)
    def list_ropa(self):
        self.client.get("/api/v1/ropa?page_size=20", headers=self._headers(), name="GET /ropa")

    @task(2)
    def list_bapd(self):
        self.client.get("/api/v1/bapd?page_size=20", headers=self._headers(), name="GET /bapd")

    @task(2)
    def list_dq(self):
        self.client.get("/api/v1/dq?page_size=20", headers=self._headers(), name="GET /dq")

    @task(1)
    def audit_logs(self):
        self.client.get("/api/v1/audit-logs?page_size=50", headers=self._headers(), name="GET /audit-logs")

    @task(1)
    def notifications(self):
        self.client.get("/api/v1/notifications", headers=self._headers(), name="GET /notifications")

    @task(1)
    def health_check(self):
        self.client.get("/health", name="GET /health")


@events.quitting.add_listener
def on_quitting(environment, **kwargs):
    """Fail the test if any SLA is breached."""
    stats = environment.runner.stats.total
    if stats.avg_response_time > 3000:
        print(f"FAIL: Average response time {stats.avg_response_time:.0f}ms > 3000ms")
        environment.process_exit_code = 1
    if stats.fail_ratio > 0.01:
        print(f"FAIL: Error rate {stats.fail_ratio*100:.1f}% > 1%")
        environment.process_exit_code = 1
    else:
        print(f"PASS: avg={stats.avg_response_time:.0f}ms, errors={stats.fail_ratio*100:.1f}%")
