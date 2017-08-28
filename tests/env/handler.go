//
// Copyright 2017 Alsanium, SAS. or its affiliates. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

package main

import (
	"errors"
	"os"

	"github.com/eawsy/aws-lambda-go-core/service/lambda/runtime"
)

var ok = true

func init() {
	ok = ok && os.Getenv("AWS_ACCESS_KEY_ID") == "i1"
	ok = ok && os.Getenv("AWS_SECRET_ACCESS_KEY") == "i2"
	ok = ok && os.Getenv("AWS_SESSION_TOKEN") == "i3"
	ok = ok && os.Getenv("AWS_SECURITY_TOKEN") == "i4"
}

func Handle(interface{}, *runtime.Context) (interface{}, error) {
	if !ok {
		return nil, errors.New("env not intialized")
	}

	return []string{
		os.Getenv("AWS_ACCESS_KEY_ID"),
		os.Getenv("AWS_SECRET_ACCESS_KEY"),
		os.Getenv("AWS_SESSION_TOKEN"),
		os.Getenv("AWS_SECURITY_TOKEN"),
	}, nil
}
