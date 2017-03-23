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

/*
#cgo pkg-config: python2.7

extern void 	 runtime_log(char *);
extern long long runtime_rtm();
*/
import "C"

import (
	"encoding/json"
	"log"
	"os"
	"plugin"
	"reflect"
	"sync"
)

var (
	lock sync.Mutex
	plug *plugin.Plugin
	hval reflect.Value
	etyp reflect.Type
	ctyp reflect.Type
)

type logger struct{}

func (l *logger) Write(p []byte) (int, error) {
	lock.Lock()
	defer lock.Unlock()
	C.runtime_log(C.CString(string(p)))
	return len(p), nil
}

func populate(raw []byte) error {
	env := make(map[string]string)
	if err := json.Unmarshal(raw, &env); err != nil {
		return err
	}
	for k, v := range env {
		os.Setenv(k, v)
	}
	return nil
}

//export open
func open(cpath *C.char, cenv *C.char) *C.char {
	var err error
	err = populate([]byte(C.GoString(cenv)))
	if err != nil {
		return C.CString(err.Error())
	}
	plug, err = plugin.Open(C.GoString(cpath) + ".so")
	if err != nil {
		return C.CString(err.Error())
	}
	return nil
}

//export lookup
func lookup(cname *C.char) *C.char {
	hnme := C.GoString(cname)

	hsym, err := plug.Lookup(hnme)
	if err != nil {
		return C.CString(err.Error())
	}

	htyp := reflect.TypeOf(hsym)
	hval = reflect.ValueOf(hsym)
	for hval.Kind() == reflect.Ptr && !hval.IsNil() {
		htyp = htyp.Elem()
		hval = hval.Elem()
	}
	if hval.Kind() != reflect.Func || hval.IsNil() {
		return C.CString("runtime: symbol " + hnme + " is not a function")
	}

	errt := reflect.TypeOf((*error)(nil)).Elem()
	if htyp.NumIn() != 2 || htyp.NumOut() != 2 || !htyp.Out(1).Implements(errt) {
		return C.CString("runtime: symbol " + hnme + " is not valid")
	}
	etyp = htyp.In(0)
	ctyp = htyp.In(1)

	return nil
}

func errorf(err error) (*C.char, *C.char, *C.char) {
	errt := reflect.TypeOf(err)
	for errt.Kind() == reflect.Ptr {
		errt = errt.Elem()
	}
	return nil, C.CString("runtime." + errt.Name()), C.CString(err.Error())
}

//export handle
func handle(cevt, cctx, cenv *C.char) (*C.char, *C.char, *C.char) {
	var err error
	err = populate([]byte(C.GoString(cenv)))
	if err != nil {
		return errorf(err)
	}

	evt := reflect.New(etyp)
	err = json.Unmarshal([]byte(C.GoString(cevt)), evt.Interface())
	if err != nil {
		return errorf(err)
	}

	ctx := reflect.New(ctyp)
	err = json.Unmarshal([]byte(C.GoString(cctx)), ctx.Interface())
	if err != nil {
		return errorf(err)
	}
	ctx.Elem().Elem().FieldByName("RemainingTimeInMillis").Set(reflect.ValueOf(func() int64 {
		lock.Lock()
		defer lock.Unlock()
		return int64(C.runtime_rtm())
	}))

	res := hval.Call([]reflect.Value{evt.Elem(), ctx.Elem()})
	if !res[1].IsNil() {
		return errorf(res[1].Interface().(error))
	}

	cres, err := json.Marshal(res[0].Interface())
	if err != nil {
		return errorf(err)
	}
	return C.CString(string(cres)), nil, nil
}

func init() {
	log.SetFlags(log.Ldate | log.Ltime | log.Lmicroseconds | log.LUTC)
	log.SetOutput(new(logger))
}

func main() {}
