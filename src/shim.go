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

#include <stdlib.h>

extern void PySys_WriteStdout(const char*);
extern void PySys_WriteStderr(const char*);
extern long long shim_crtm();
*/
import "C"

import (
	"bufio"
	"bytes"
	"fmt"
	"os"
	"plugin"
	"reflect"
	"runtime"
	"strconv"
	"sync"
	"time"
	"unsafe"

	"encoding/json"

	"log"

	lruntime "github.com/eawsy/aws-lambda-go-core/service/lambda/runtime"
)

var (
	hnm string
	plg *plugin.Plugin
	sym plugin.Symbol
)

type logger struct {
	rid string
}

func (l *logger) Write(info []byte) (int, error) {
	now := time.Now().UTC().Format("2006-01-02T15:04:05.999Z")
	fmt.Printf("%s\t%s\t%s", now, l.rid, string(info))
	return len(info), nil
}

//export shim_goopen
func shim_goopen(cpath *C.char) *C.char {
	var err error
	plg, err = plugin.Open(C.GoString(cpath) + ".so")
	if err != nil {
		return C.CString(err.Error())
	}
	return nil
}

//export shim_golookup
func shim_golookup(cname *C.char) *C.char {
	var err error
	sym, err = plg.Lookup(C.GoString(cname))
	if err != nil {
		return C.CString(err.Error())
	}
	hnm = C.GoString(cname)
	return nil
}

func errorf(format string, a ...interface{}) *C.char {
	err := fmt.Sprintf(format, a...)
	return C.CString(fmt.Sprintf(`{"errorMessage":%s}`, strconv.QuoteToASCII(err)))
}

func scan(data []byte, atEOF bool) (advance int, token []byte, err error) {
	if atEOF && len(data) == 0 {
		return 0, nil, nil
	}
	if i := bytes.IndexByte(data, '\n'); i >= 0 {
		return i + 1, data[0 : i+1], nil
	}
	if atEOF {
		return len(data), data, nil
	}
	return 0, nil, nil
}

//export shim_gohandle
func shim_gohandle(cevt, cctx, cenv *C.char) (cres *C.char) {
	var ctx *lruntime.Context

	defer func() {
		r := recover()
		if r == nil {
			return
		}

		buf := make([]byte, 64<<10)
		buf = buf[:runtime.Stack(buf, false)]

		d := C.CString(fmt.Sprintf("%s\n%s", r, buf))
		C.PySys_WriteStdout(d)
		C.free(unsafe.Pointer(d))

		if ctx != nil {
			cres = errorf("RequestId: %s Process exited before completing request", ctx.AWSRequestID)
			return
		}
		cres = errorf("Process exited before completing request")
	}()

	hval := reflect.ValueOf(sym)
	htyp := reflect.TypeOf(sym)
	if htyp.Kind() == reflect.Ptr {
		hval = hval.Elem()
		htyp = htyp.Elem()
	}
	ctyp := reflect.TypeOf((*lruntime.Context)(nil))

	knd := htyp.Kind()
	if knd != reflect.Func {
		return errorf("Cannot use handler '%s' with type '%s'", hnm, knd)
	}

	if hval.IsNil() {
		return errorf("Cannot call nil handler '%s'", hnm)
	}

	if htyp.NumIn() != 2 || htyp.In(1) != ctyp ||
		htyp.NumOut() != 2 || !htyp.Out(1).Implements(reflect.TypeOf((*error)(nil)).Elem()) {
		return errorf("Cannot use handler '%s' with invalid signature", hnm)
	}

	eval := reflect.New(htyp.In(0))
	if err := json.Unmarshal([]byte(C.GoString(cevt)), eval.Interface()); err != nil {
		return errorf(err.Error())
	}

	ctx = new(lruntime.Context)
	if err := json.Unmarshal([]byte(C.GoString(cctx)), ctx); err != nil {
		return errorf(err.Error())
	}
	ctx.RemainingTimeInMillis = func() int64 {
		return int64(C.shim_crtm())
	}

	var env map[string]string
	if err := json.Unmarshal([]byte(C.GoString(cenv)), &env); err != nil {
		return errorf(err.Error())
	}
	for k, v := range env {
		os.Setenv(k, v)
	}

	var wg sync.WaitGroup
	outputr, outputw, err := os.Pipe()
	if err != nil {
		return errorf(err.Error())
	}
	stdouto := os.Stdout
	stderro := os.Stderr
	os.Stdout = outputw
	os.Stderr = outputw
	wg.Add(1)
	go func() {
		defer wg.Done()
		s := bufio.NewScanner(outputr)
		s.Split(scan)
		for s.Scan() {
			d := C.CString(s.Text())
			C.PySys_WriteStdout(d)
			C.free(unsafe.Pointer(d))
		}
	}()

	log.SetOutput(&logger{ctx.AWSRequestID})

	args := make([]reflect.Value, 2)
	args[0] = eval.Elem()
	args[1] = reflect.ValueOf(ctx)
	res := hval.Call(args)
	if !res[1].IsNil() {
		cres = errorf(res[1].Interface().(error).Error())
	} else {
		bres, err := json.Marshal(res[0].Interface())
		if err != nil {
			cres = errorf(err.Error())
		} else {
			cres = C.CString(string(bres))
		}
	}

	outputw.Close()
	os.Stdout = stdouto
	os.Stderr = stderro
	wg.Wait()

	return
}

func init() {
	log.SetFlags(0)
}

func main() {}
