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
	"log"
	"math/rand"
	"time"

	"github.com/eawsy/aws-lambda-go-core/service/lambda/runtime"
)

func Handle(evt interface{}, ctx *runtime.Context) (interface{}, error) {
	done := make(chan struct{}, 100)
	log.SetFlags(0)
	for i := 0; i < 100; i++ {
		go func(done chan<- struct{}) {
			time.Sleep(time.Duration(rand.Intn(2)) * time.Millisecond)
			log.Println("x")
			done <- struct{}{}
		}(done)
	}
	for i := 0; i < 100; i++ {
		<-done
	}
	return nil, nil
}
