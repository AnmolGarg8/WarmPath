import shutil
import tempfile
import unittest
from pathlib import Path

from scripts.check_no_mock import (
    load_banned_strings,
    run_scanner,
    scan_file_lines,
    is_test_or_excluded_path,
)


class TestCheckNoMock(unittest.TestCase):
    def setUp(self):
        self.temp_dir = Path(tempfile.mkdtemp())
        self.banned_strings_file = self.temp_dir / "banned_strings.txt"
        self.banned_strings_file.write_text(
            "Recommended Mentor\nJohn Doe\nJane Doe\nReact & Node expertise match\n",
            encoding="utf-8",
        )
        self.banned_strings = load_banned_strings(self.banned_strings_file)

    def tearDown(self):
        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_catches_banned_words(self):
        test_patterns = [
            ("const mockService = 1;", "mock"),
            ("let dummy_id = 42;", "dummy"),
            ("final loremText = 'ipsum';", "lorem"),
            ("def fake_data(): pass", "fake_data"),
            ("return sample_data", "sample_data"),
            ("current_user = sample_user", "sample_user"),
            ("publish(sample_event)", "sample_event"),
            ("mentor = sample_mentor", "sample_mentor"),
            ("const fakeData = {};", "fakeData"),
            ("final sampleUser = User();", "sampleUser"),
        ]

        for code_line, expected_word in test_patterns:
            f = self.temp_dir / f"test_{expected_word}.dart"
            # Note: name does not end with _test.dart so it scans
            f = self.temp_dir / "service.dart"
            f.write_text(code_line, encoding="utf-8")
            violations, _ = scan_file_lines(f, self.temp_dir, self.banned_strings)
            self.assertGreater(
                len(violations),
                0,
                f"Expected line '{code_line}' to trigger violation for '{expected_word}'",
            )
            self.assertIn(expected_word.lower(), violations[0].message.lower())

    def test_catches_future_delayed_without_comment(self):
        f = self.temp_dir / "page.dart"
        f.write_text("await Future.delayed(const Duration(seconds: 2));\n", encoding="utf-8")
        violations, _ = scan_file_lines(f, self.temp_dir, self.banned_strings)
        self.assertEqual(len(violations), 1)
        self.assertIn("Future.delayed used in non-test code", violations[0].message)

    def test_respects_allow_delay_comment(self):
        f = self.temp_dir / "page.dart"
        f.write_text(
            "await Future.delayed(const Duration(milliseconds: 300)); // allow-delay: debounce keystrokes\n",
            encoding="utf-8",
        )
        violations, allow_logs = scan_file_lines(f, self.temp_dir, self.banned_strings)
        self.assertEqual(len(violations), 0)
        self.assertEqual(len(allow_logs), 1)
        self.assertIn("debounce keystrokes", allow_logs[0])

    def test_catches_banned_strings(self):
        banned_cases = [
            "const title = 'Recommended Mentor';",
            "final author = 'John Doe';",
            "final receiver = 'Jane Doe';",
            "Text('React & Node expertise match');",
        ]
        for line in banned_cases:
            f = self.temp_dir / "view.dart"
            f.write_text(line, encoding="utf-8")
            violations, _ = scan_file_lines(f, self.temp_dir, self.banned_strings)
            self.assertGreater(len(violations), 0, f"Expected violation for line: {line}")
            self.assertIn("Banned string found", violations[0].message)

    def test_respects_allow_mock_comment(self):
        f = self.temp_dir / "service.dart"
        f.write_text(
            "const mockUserData = {'name': 'John Doe'}; // allow-mock: local offline developer preview\n",
            encoding="utf-8",
        )
        violations, allow_logs = scan_file_lines(f, self.temp_dir, self.banned_strings)
        self.assertEqual(len(violations), 0)
        self.assertEqual(len(allow_logs), 1)
        self.assertIn("local offline developer preview", allow_logs[0])

    def test_ignores_test_folders_and_files(self):
        test_paths = [
            self.temp_dir / "backend" / "app" / "tests" / "test_auth.py",
            self.temp_dir / "app" / "test" / "widget_test.dart",
            self.temp_dir / "app" / "lib" / "features" / "auth" / "auth_test.dart",
            self.temp_dir / "docs" / "example.md",
            self.temp_dir / "data" / "users.example.csv",
        ]
        for p in test_paths:
            self.assertTrue(
                is_test_or_excluded_path(p),
                f"Expected {p} to be identified as test or excluded path",
            )

    def test_catches_prohibited_data_files(self):
        app_assets = self.temp_dir / "app" / "assets"
        app_assets.mkdir(parents=True)
        prohibited_json = app_assets / "mock_mentors.json"
        prohibited_json.write_text('{"mentors": []}', encoding="utf-8")

        admin_public = self.temp_dir / "admin" / "public"
        admin_public.mkdir(parents=True)
        prohibited_csv = admin_public / "sample_users.csv"
        prohibited_csv.write_text("name,email\n", encoding="utf-8")

        violations, _, _ = run_scanner(self.temp_dir, self.banned_strings_file)
        self.assertEqual(len(violations), 2)
        messages = [v.message for v in violations]
        self.assertTrue(any("mock_mentors.json" in m for m in messages))
        self.assertTrue(any("sample_users.csv" in m for m in messages))

    def test_allows_example_data_files(self):
        app_assets = self.temp_dir / "app" / "assets"
        app_assets.mkdir(parents=True)
        example_json = app_assets / "config.example.json"
        example_json.write_text('{"key": "value"}', encoding="utf-8")

        violations, _, _ = run_scanner(self.temp_dir, self.banned_strings_file)
        self.assertEqual(len(violations), 0)


if __name__ == "__main__":
    unittest.main()
