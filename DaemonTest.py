#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import unittest
import os, sys
import subprocess
from subprocess import PIPE
import json
import re

workdir = os.path.dirname( os.path.abspath( __file__ ) )
binary = os.path.join(workdir, ".build/release/sourcekitten")
# binary = '/Users/wang/Library/Developer/Xcode/DerivedData/SourceKitten-bdimekzhqqypmbfawhzegqyikdcv/Build/Products/Debug/sourcekitten.app/Contents/MacOS/sourcekitten'
header_pattern = re.compile(rb'(\S+)\s*:\s*(\S+)')


requestID = 0
class DaemonTest(unittest.TestCase):

    def test_Valid(self):
        sourcekitten = subprocess.Popen([binary, "daemon"], stdin=PIPE, stdout=PIPE, stderr=sys.stderr)
        response = self.request(sourcekitten, "yaml", '{key.request: source.request.protocol_version}') # type: dict
        print(response)
        self.assertTrue( "result" in response )
        self.notification(sourcekitten, "end")
        sourcekitten.communicate()

    def request(self, process, method, param=None):
        global requestID;
        requestID = requestID + 1
        r = {"id": requestID, "method": method}
        if param: r["params"] = param
        d = json.dumps(r).encode()
        print(f"request {d}")
        process.stdin.write(b'Content-Length:%d\r\n\r\n'%(len(d)))
        process.stdin.write(d)
        process.stdin.flush()
        return self.response(process)

    def notification(self, process, method, param=None):
        r = {"method": method}
        if param: r["params"] = param
        d = json.dumps(r).encode()
        print(f"notification {d}")
        process.stdin.write(b'Content-Length:%d\r\n\r\n'%(len(d)))
        process.stdin.write(d)

    def response(self, process):
        headers = {}
        while True:
            line = process.stdout.readline()
            if len(line) < 3: break

            m = header_pattern.search(line)
            if m: headers[m.group(1)] = m.group(2)

        try:
            content_length = int(headers[b'Content-Length'])
            return json.loads( process.stdout.read(content_length))
        except (KeyError, ValueError) as e:
            raise e


def main():
    unittest.main()

if __name__ == "__main__":
    main()
