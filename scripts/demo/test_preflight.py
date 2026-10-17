import unittest
from scripts.demo.db_safety import is_safe_local_database
from scripts.demo.preflight import (
    CheckResult,
    format_check_line,
    check_demo_profile_setting,
    check_razorpay_keys,
)


class TestPreflightAndSafety(unittest.TestCase):
    def test_database_safety_allows_local_docker(self):
        safe_urls = [
            "postgresql://warmpath:secretpassword@localhost:5432/warmpath_db",
            "postgresql+asyncpg://warmpath:secretpassword@localhost:5432/warmpath_db",
            "postgresql://warmpath:secretpassword@127.0.0.1:5432/warmpath_demo",
            "postgresql://warmpath:secretpassword@postgres:5432/warmpath_test",
            "postgresql://warmpath:secretpassword@localhost:5432/warmpath_dev",
        ]
        for url in safe_urls:
            safe, reason = is_safe_local_database(url)
            self.assertTrue(safe, f"Expected '{url}' to be safe, got: {reason}")
            self.assertIn("Verified safe local database", reason)

    def test_database_safety_refuses_remote_and_production(self):
        unsafe_urls = [
            "postgresql://admin:secret@warmpath.c3xyz.us-east-1.rds.amazonaws.com:5432/warmpath_db",
            "postgresql://postgres:secret@db.xyz.supabase.co:5432/warmpath_db",
            "postgresql://admin:secret@app-db.railway.app:5432/warmpath_demo",
            "postgresql://admin:secret@my-remote-server.com:5432/warmpath_db",
            "postgresql://admin:secret@192.168.1.105:5432/warmpath_db",
            "postgresql://warmpath:secretpassword@localhost:5432/production_live_data",
            "",
            "   ",
        ]
        for url in unsafe_urls:
            safe, reason = is_safe_local_database(url)
            self.assertFalse(safe, f"Expected '{url}' to be refused, but got safe.")
            self.assertIn("Refused", reason)

    def test_format_check_line_pass(self):
        res = CheckResult(
            name="Mailpit Web API",
            passed=True,
            details="Mailpit API reachable on port 8025.",
            fix_hint="",
        )
        line = format_check_line(res)
        self.assertIn("[PASS]", line)
        self.assertIn("Mailpit Web API", line)
        self.assertIn("Mailpit API reachable on port 8025.", line)
        self.assertNotIn("Fix Hint", line)

    def test_format_check_line_fail_with_hint(self):
        res = CheckResult(
            name="Razorpay Test Keys",
            passed=False,
            details="Key ID 'rzp_live_999' is NOT a test key.",
            fix_hint="Set RAZORPAY_KEY_ID=rzp_test_... in backend/.env",
        )
        line = format_check_line(res)
        self.assertIn("[FAIL]", line)
        self.assertIn("Razorpay Test Keys", line)
        self.assertIn("Key ID 'rzp_live_999' is NOT a test key.", line)
        self.assertIn("Fix Hint: Set RAZORPAY_KEY_ID=rzp_test_...", line)


if __name__ == "__main__":
    unittest.main()
