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

CUR=$PWD
HLD=$1
BIN=$2
PKG=$3
TMP=`mktemp -d`

mkdir $TMP/$HLD

cp $BIN $TMP/$HLD.so
cp /shim/__init__.pyc $TMP/$HLD/__init__.pyc
cp /shim/proxy.pyc $TMP/$HLD/proxy.pyc
cp /shim/runtime.so $TMP/$HLD/runtime.so

cd $TMP
find . -exec touch -t 201302210800 {} +
zip -qrX $PKG *

mv $PKG $CUR/.

rm -rf $TMP
