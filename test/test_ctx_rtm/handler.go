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
	"math/rand"
	"time"

	"github.com/eawsy/aws-lambda-go-core/service/lambda/runtime"
)

func Handle(evt interface{}, ctx *runtime.Context) (interface{}, error) {
	resc := make(chan int64, 100)
	for i := 0; i < 100; i++ {
		go func(resc chan<- int64) {
			time.Sleep(time.Duration(rand.Intn(2)) * time.Millisecond)
			resc <- ctx.RemainingTimeInMillis()
		}(resc)
	}
	res := int64(0)
	for i := 0; i < 100; i++ {
		res += <-resc
	}
	return res, nil
}
