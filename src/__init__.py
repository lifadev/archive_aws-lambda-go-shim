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

import dl
import json
import os
import sys

sys.setdlopenflags(sys.getdlopenflags() | dl.RTLD_NOW | dl.RTLD_GLOBAL)

import runtime

runtime.open(
    __name__,
    json.dumps({k: v for k, v in ((k, os.getenv(k)) for k in (
        "AWS_ACCESS_KEY_ID",
        "AWS_SECRET_ACCESS_KEY",
        "AWS_SESSION_TOKEN",
        "AWS_SECURITY_TOKEN",
        "_X_AMZN_TRACE_ID",
    )) if v})
)

import proxy

sys.modules[__name__] = proxy.Proxy()
