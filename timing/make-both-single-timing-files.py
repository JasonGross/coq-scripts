#!/usr/bin/python
from __future__ import with_statement
import os, sys, re
from TimeFileMaker import *

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print('Usage: %s LEFT_FILE_NAME RIGHT_FILE_NAME [OUTPUT_FILE_NAME]' % sys.argv[0])
        sys.exit(1)
    else:
        left_dict = get_single_file_times(sys.argv[1])
        right_dict = get_single_file_times(sys.argv[2])
        table = make_diff_table_string(left_dict, right_dict, tag="Code")
        if len(sys.argv) == 3 or sys.argv[3] == '-':
            print(table)
        else:
            with open(sys.argv[3], 'w') as f:
                f.write(table)
