#
# Copyright 2017 Alsanium, SAS. or its affiliates. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

import os
import unittest

os.environ["AWS_ACCESS_KEY_ID"] = "i1"
os.environ["AWS_SECRET_ACCESS_KEY"] = "i2"
os.environ["AWS_SESSION_TOKEN"] = "i3"
os.environ["AWS_SECURITY_TOKEN"] = "i4"

import handler

class Context:

    def get_remaining_time_in_millis(self):
        pass

    def log(self):
        pass

class TestCase(unittest.TestCase):

    def test_case(self):
        try:
            self.assertEqual(["i1", "i2", "i3", "i4"], handler.Handle({}, Context()))
            os.environ["AWS_ACCESS_KEY_ID"] = "h1"
            os.environ["AWS_SECRET_ACCESS_KEY"] = "h2"
            os.environ["AWS_SESSION_TOKEN"] = "h3"
            os.environ["AWS_SECURITY_TOKEN"] = "h4"
            self.assertEqual(["h1", "h2", "h3", "h4"], handler.Handle({}, Context()))
        except Exception:
            self.fail("should not raise")

