#!/usr/bin/python
from __future__ import with_statement
import os, sys, re

# This is a helper script for make-pretty-timed.sh and
# make-pretty-timed-diff.sh.

# This script parses the output of `make TIMED=1` into a dictionary
# mapping names of compiled files to the number of minutes and seconds
# that they took to compile.

STRIP_REG = re.compile('^(coq/|contrib/|)(?:theories/|src/)?')
STRIP_REP = r'\1'

def get_times(file_name):
    '''
    Reads the contents of file_name, which should be the output of
    'make TIMED=1', and parses it to construct a dict mapping file
    names to compile durations, as strings.  Removes common prefixes
    using STRIP_REG and STRIP_REP.
    '''
    with open(file_name, 'r') as f:
        lines = f.read()
    reg = re.compile(r'^([^\s]*) \([^\)]*?user: ([0-9\.]+)[^\)]*?\)$', re.MULTILINE)
    times = reg.findall(lines)
    if all(time in ('0.00', '0.01') for name, time in times):
        reg = re.compile(r'^([^\s]*) \([^\)]*?real: ([0-9\.]+)[^\)]*?\)$', re.MULTILINE)
        times = reg.findall(lines)
    times_dict = {}
    if all(STRIP_REG.search(name.strip()) for name, time in times):
        times = tuple((STRIP_REG.sub(STRIP_REP, name.strip()), time) for name, time in times)
    for name, time in times:
        seconds, milliseconds = time.split('.')
        seconds = int(seconds)
        minutes, seconds = int(seconds / 60), seconds % 60
        times_dict[name] = '%dm%02d.%ss' % (minutes, seconds, milliseconds)
    return times_dict

def get_single_file_times(file_name):
    '''
    Reads the contents of file_name, which should be the output of
    'coqc -time', and parses it to construct a dict mapping lines to
    to compile durations, as strings.
    '''
    with open(file_name, 'r') as f:
        lines = f.read()
    reg = re.compile(r'^(Chars [0-9]+ - [0-9]+ [^ ]+) ([0-9\.]+) secs (.*)$', re.MULTILINE)
    times = reg.findall(lines)
    times_dict = {}
    for name, time, extra in times:
        seconds, milliseconds = time.split('.')
        seconds = int(seconds)
        minutes, seconds = int(seconds / 60), seconds % 60
        times_dict[name] = '%dm%02d.%ss' % (minutes, seconds, milliseconds)
    return times_dict

def get_sorted_file_list_from_times_dict(times_dict, descending=True):
    '''
    Takes the output dict of get_times and returns the list of keys,
    sorted by duration.
    '''
    def get_key(name):
        minutes, seconds = times_dict[name].replace('s', '').split('m')
        return (int(minutes), float(seconds))
    return sorted(times_dict.keys(), key=get_key, reverse=descending)

def to_seconds(time):
    '''
    Converts a string time into a number of seconds.
    '''
    minutes, seconds = time.replace('s', '').split('m')
    sign = -1 if time[0] == '-' else 1
    return sign * (abs(int(minutes)) * 60 + float(seconds))

def from_seconds(seconds, signed=False):
    '''
    Converts a number of seconds into a string time.
    '''
    sign = ('-' if seconds < 0 else '+') if signed else ''
    seconds = abs(seconds)
    minutes = int(seconds) / 60
    seconds -= minutes * 60
    full_seconds = int(seconds)
    partial_seconds = int(100 * (seconds - full_seconds))
    return sign + '%dm%02d.%02ds' % (minutes, full_seconds, partial_seconds)

def sum_times(times, signed=False):
    '''
    Takes the values of an output from get_times, parses the time
    strings, and returns their sum, in the same string format.
    '''
    return from_seconds(sum(map(to_seconds, times)), signed=signed)


def make_diff_table_string(left_times_dict, right_times_dict,
                      descending=True,
                      left_tag="After", tag="File Name", right_tag="Before"):
    # We first get the names of all of the compiled files: all files
    # that were compiled either before or after.
    all_names_dict = dict()
    all_names_dict.update(right_times_dict)
    all_names_dict.update(left_times_dict) # do the left (after) last, so that we give precedence to those ones
    diff_times_dict = dict((name, from_seconds(to_seconds(left_times_dict.get(name,'0m0.0s')) - to_seconds(right_times_dict.get(name,'0m0.0s')), signed=True))
                           for name in all_names_dict.keys())
    # update to sort by approximate difference, first
    for name in all_names_dict.keys():
        all_names_dict[name] = (abs(int(to_seconds(diff_times_dict[name]))), to_seconds(all_names_dict[name]))

    names = sorted(all_names_dict.keys(), key=all_names_dict.get, reverse=descending)
    #names = get_sorted_file_list_from_times_dict(all_names_dict, descending=descending)
    # set the widths of each of the columns by the longest thing to go in that column
    left_sum = sum_times(left_times_dict.values())
    right_sum = sum_times(right_times_dict.values())
    diff_sum = from_seconds(sum(map(to_seconds, left_times_dict.values())) - sum(map(to_seconds, right_times_dict.values())), signed=True)
    left_width = max(max(map(len, ['N/A'] + list(left_times_dict.values()))), len(left_sum))
    right_width = max(max(map(len, ['N/A'] + list(right_times_dict.values()))), len(right_sum))
    far_right_width = max(max(map(len, ['N/A'] + list(diff_times_dict.values()))), len(diff_sum))
    middle_width = max(map(len, names + [tag, "Total"]))
    format_string = "%%-%ds | %%-%ds | %%-%ds || %%-%ds" % (left_width, middle_width, right_width, far_right_width)
    header = format_string % (left_tag, "File Name", right_tag, "Change")
    total = format_string % (left_sum,
                             "Total",
                             right_sum,
                             diff_sum)
    # separator to go between headers and body
    sep = '-' * len(header)
    # the representation of the default value (0), to get replaced by N/A
    left_rep, right_rep, far_right_rep = ("%%-%ds | " % left_width) % 0, (" | %%-%ds || " % right_width) % 0, ("|| %%-%ds" % far_right_width) % 0
    return '\n'.join([header, sep, total, sep] +
                     [format_string % (left_times_dict.get(name, 0),
                                       name,
                                       right_times_dict.get(name, 0),
                                       diff_times_dict.get(name, 0))
                      for name in names]).replace(left_rep, 'N/A'.center(len(left_rep) - 3) + ' | ').replace(right_rep, ' | ' + 'N/A'.center(len(right_rep) - 7) + ' || ').replace(far_right_rep, '|| ' + 'N/A'.center(len(far_right_rep) - 3))
