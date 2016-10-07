import json
import unittest
from dson import Rewriter, get_default_excludes

class RewriteTest(unittest.TestCase):
    def __init__(self, *args, **kwargs):
        super(RewriteTest, self).__init__(*args, **kwargs)
        self.rewriter = Rewriter(verbose=0,
                                 filenames = ["package.json"],
                                 excludes=get_default_excludes())

    def strip(self, s):
        return self.rewriter.strip_excludes(json.loads(s))

    def test_invalid_json_args(self):
        with self.assertRaises(ValueError) as context:
            self.strip("[]")
        with self.assertRaises(ValueError) as context:
            self.strip("''")
        with self.assertRaises(ValueError) as context:
            self.strip("1")

    def test_blacklist(self):
        self.assertEqual({}, self.strip('{"_where": "foo"}'))
        self.assertEqual({}, self.strip('{"_npmOperationalInternal": "foo"}'))


if __name__ == '__main__':
    unittest.main()
