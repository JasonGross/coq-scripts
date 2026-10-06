#!/usr/bin/env python3
"""Regression tests for compiler diagnostics forwarded to GitHub Actions."""
from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ReportifyTests(unittest.TestCase):
    def report(self, text, *args, warnerr="Warning"):
        result = subprocess.run(
            ["bash", str(ROOT / "reportify-coq-errors-gen.sh"), *args, warnerr],
            input=text, text=True, capture_output=True, check=True,
        )
        self.assertEqual(result.stderr, "")
        return result.stdout

    def test_multiline_warning_categories(self):
        for tags in ("category,default",
                     "missing-scheme,deprecated-since-9.2,deprecated,default",
                     "non-boolean-if,deprecated-since-9.3,deprecated,default"):
            with self.subTest(tags=tags):
                source = ('File "./theories/Foo.v", line 12, characters 3-8:\n'
                          'Warning:\nThe first line.\nThe second line.\n'
                          f'[{tags}]\n')
                expected = ("::warning file=./theories/Foo.v,line=12,col=3-8,"
                            f"code={tags.replace(',', '%2C')}::%0A"
                            "The first line.%0AThe second line.%0A\n")
                self.assertEqual(self.report(source), expected)

    def test_consecutive_warnings(self):
        warning = ('File "Foo.v", line 1, characters 0-1:\n'
                   'Warning: text [category,default]\n')
        result = self.report(warning + warning)
        self.assertEqual(result.count("::warning file=Foo.v"), 2)
        self.assertNotIn("terminator", result)

    def test_rocq_boundary_does_not_consume_command(self):
        for command in ("ROCQ compile Foo.v", "ROCQ dep Foo.v", "COQC Foo.v"):
            with self.subTest(command=command):
                source = ('File "Foo.v", line 1, characters 0-1:\n'
                          'Warning: incomplete\n' + command + '\n'
                          'File "Bar.v", line 2, characters 1-3:\n'
                          'Warning: complete [category,default]\n')
                result = self.report(source)
                self.assertIn("terminator for 2-line warning", result)
                self.assertIn("\n" + command + "\n", result)
                self.assertIn("::warning file=Bar.v", result)

    def test_error_to_eof(self):
        source = ('File "Foo.v", line 1, characters 0-1:\n'
                  'Error: the first line\nthe second line\n')
        self.assertIn("::error file=Foo.v", self.report(source, warnerr="Error"))
        self.assertNotIn("terminator", self.report(source, warnerr="Error"))

    def test_unterminated_warning(self):
        source = ('File "Foo.v", line 1, characters 0-1:\n'
                  'Warning: unfinished\nmore text\n')
        self.assertIn("terminator for 3-line warning", self.report(source))
        self.assertIn("::warning file=Foo.v", self.report(source))

    def test_passthrough(self):
        self.assertEqual(self.report("ordinary output\n"), "ordinary output\n")


if __name__ == "__main__":
    unittest.main()
