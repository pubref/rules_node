import os
import json
import argparse

def get_default_excludes():
    return [
        "_args",
        "_from",
        "_inCache",
        "_installable",
        "_nodeVersion",
        "_npmOperationalInternal",
        "_npmUser",
        "_npmVersion",
        "_phantomChildren",
        "_resolved",
        "_requested",
        "_requiredBy",
        "_where",
    ]

class Rewriter:
    def __init__(self, verbose, filenames, excludes):
        self.verbose = verbose
        self.filenames = filenames
        self.excludes = excludes
        self._current_filename = ""
        if verbose > 1:
            print("rewriter filenames: %s" % self.filenames)
            print("rewriter excludes: %s" % self.excludes)
        if verbose > 2:
            self.union = {}

    def walk_path(self, path):
        for subdir, dirs, files in os.walk(path):
            for file in files:
                if file in self.filenames:
                    if self.verbose > 2:
                        print("hit: file %s" % file)
                    filepath = os.path.join(subdir, file)
                    self.process_json_file(filepath)
                else:
                    if self.verbose > 2:
                        print("miss: file %s not in %s" % (file, self.filenames))


    def process_json_file(self, file):
        self._current_filename = file
        if self.verbose > 1:
            print "File: " + file
        json_obj = None
        with open(file, "r") as f:
            obj = json.load(f)
            if isinstance(obj, dict):
                json_obj = obj
                self.strip_excludes(json_obj)
        if json_obj:
            with open(file, "w") as f:
                json.dump(json_obj, f, sort_keys=True, indent=2)

    def strip_excludes(self, obj):
        """Remove all top-level json entries having a key in EXCLUDES.  The
           json argument will be modified in place."""
        if not isinstance(obj, dict):
            raise ValueError("json argument must be a dict")
        excludes = self.excludes

        for key in obj.keys():
            val = obj[key]
            if key in excludes:
                del obj[key]
                if self.verbose:
                    print "excluding: %s=%s from %s" % (key, val, self._current_filename)
            if hasattr(self, "union"):
                if key in vals:
                    self.union[key] += [val]
                else:
                    self.union[key] = [val]

        return obj

    def report(self):
        """Show output of the union of all top-level json objects."""
        if hasattr(self, "union"):
            for k, v in self.union.items():
                print k + ' ****************************************************************'
                print v


def main():
    parser = argparse.ArgumentParser(
        description='Rewrite all json files deterministically within a file tree.')
    parser.add_argument("--path", nargs="+", default = [],
                        help='The root path to start file walk.')
    parser.add_argument("--exclude", nargs="*", action="append", default = [],
                        help='Top-level key names to exclude from matching json files.')
    parser.add_argument("--filename", nargs=1, action="append", default = [],
                        help='Json filenames to match (exact match) when traversing path, example "package.json" or "bower.json"')
    parser.add_argument("--verbose", action="count", default=0,
                        help='Print more debug messages.')
    args = parser.parse_args()

    excludes = []
    for keys in args.exclude:
        excludes += keys
    if not excludes:
        excludes = get_default_excludes()

    filenames = []
    for files in args.filename:
        filenames += files
    if not filenames:
        filename = ["package.json"]

    rewriter = Rewriter(args.verbose, filenames, excludes)

    for path in args.path:
        print("walking " + path)
        rewriter.walk_path(path)

    rewriter.report

if __name__ == '__main__':
  main()
