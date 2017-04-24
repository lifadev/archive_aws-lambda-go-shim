#!/usr/bin/env bash

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

base=$PWD
handler=$1
binary=$2
package=$3

mkdir -p /package/$handler
cp $binary /package/$handler.so
cp /shim/__init__.pyc /package/$handler/__init__.pyc
cp /shim/proxy.pyc /package/$handler/proxy.pyc
cp /shim/runtime.so /package/$handler/runtime.so

cd /package; find . -exec touch -t 201302210800 {} +;  zip -qrX $package *; cd $base
mv /package/$package .
