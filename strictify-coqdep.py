#!/usr/bin/env python2
import sys, subprocess
import re

if __name__ == '__main__':
    p = subprocess.Popen(sys.argv[1:], stderr=subprocess.PIPE)
    (stdout, stderr) = p.communicate()
    reg = re.compile(r'''Warning(: in file .*?,\s*required library .*? matches several files in path)''')
    if reg.search(stderr):
        sys.stderr.write(reg.sub(r'Error\1', stderr))
        sys.exit(1)
    sys.stderr.write(stderr)
    sys.exit(p.returncode)
