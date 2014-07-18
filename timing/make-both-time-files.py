#!/usr/bin/python
from __future__ import with_statement
import os, sys, re
from TimeFileMaker import *

# This is a helper script for make-pretty-timed-diff.sh.

# This uses TimeFileMaker.py to format timing information.

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print('Usage: %s LEFT_FILE_NAME RIGHT_FILE_NAME [OUTPUT_FILE_NAME]' % sys.argv[0])
        sys.exit(1)
    else:
        left_dict = get_times(sys.argv[1])
        right_dict = get_times(sys.argv[2])
        table = make_diff_table_string(left_dict, right_dict)
        if len(sys.argv) == 3 or sys.argv[3] == '-':
            print(table)
        else:
            with open(sys.argv[3], 'w') as f:
                f.write(table)
