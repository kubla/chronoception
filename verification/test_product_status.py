import copy
import unittest
from product_status import assess, BROWSER_TRAIN, NATIVE_TRAIN, NATIVE_TEST


class ProductStatusTests(unittest.TestCase):
    def setUp(self):
        self.run = {"id": 42, "conclusion": "success"}
        self.receipts = {name: {"run": "42", "candidate_tree": "tree", "result": "passed"}
                         for name in ["purpose-browser", "purpose-phone", "purpose-watch", "purpose-release"]}
        self.receipts["purpose-browser"]["journeys"] = [BROWSER_TRAIN]
        for kind in ["phone", "watch"]:
            self.receipts["purpose-" + kind]["media"] = [{"journey": name} for name in [NATIVE_TRAIN, NATIVE_TEST]]

    def test_green_slice_does_not_complete_product(self):
        result = assess(self.run, self.receipts, "tree")
        self.assertEqual(result["change_acceptance"], "passed")
        self.assertEqual(result["product_status"], "incomplete")
        self.assertEqual(result["outcomes"][0]["status"], "verified")
        self.assertTrue(all(item["next"] for item in result["outcomes"]))

    def test_estimation_only_is_rejected_even_with_green_checks(self):
        self.receipts["purpose-browser"]["journeys"] = []
        for kind in ["phone", "watch"]:
            self.receipts["purpose-" + kind]["media"] = [{"journey": NATIVE_TEST}]
        result = assess(self.run, self.receipts, "tree")
        self.assertEqual(result["outcomes"][0]["status"], "unverified")
        self.assertEqual(len(result["problems"]), 3)

    def test_missing_failed_or_stale_evidence_is_not_accepted(self):
        for name in self.receipts:
            for field, value in [("run", "old"), ("candidate_tree", "old"), ("result", "failed")]:
                changed = copy.deepcopy(self.receipts)
                changed[name][field] = value
                self.assertTrue(assess(self.run, changed, "tree")["problems"])
            changed = copy.deepcopy(self.receipts)
            del changed[name]
            self.assertTrue(assess(self.run, changed, "tree")["problems"])

    def test_failed_change_cannot_verify_foreground_product(self):
        self.run["conclusion"] = "failure"
        result = assess(self.run, self.receipts, "tree")
        self.assertEqual(result["change_acceptance"], "failed")
        self.assertEqual(result["outcomes"][0]["status"], "unverified")
