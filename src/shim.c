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

#include <Python.h>
#include <frameobject.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

extern char * shim_goopen(const char *);

extern char * shim_golookup(const char *);

extern char * shim_gohandle(const char*, const char*, const char *);

static PyObject *shim_rtmfn;

static PyObject *
shim_copen(PyObject *self, PyObject *arg)
{
    char *err;

    if (!(err = shim_goopen(PyString_AS_STRING(arg)))) {
        Py_INCREF(Py_None);
        return Py_None;
    }

    PyErr_SetString(PyExc_ImportError, err);
    free(err);
    return NULL;
}

static PyObject *
shim_clookup(PyObject *self, PyObject *arg) {
    char *err;

    if (!(err = shim_golookup(PyString_AS_STRING(arg)))) {
        Py_INCREF(Py_None);
        return Py_None;
    }

    PyErr_SetString(PyExc_AttributeError, err);
    free(err);
    return NULL;
}

static PyObject *
shim_chandle(PyObject *self, PyObject *args)
{
    const char *cevt, *cctx, *cenv;
    char *ret;
    PyObject *res;

    if (!PyArg_ParseTuple(args, "sssO", &cevt, &cctx, &cenv, &shim_rtmfn)) {
        return NULL;
    }

    if (!(ret = shim_gohandle(cevt, cctx, cenv))) {
        Py_INCREF(Py_None);
        return Py_None;
    }

    res = PyString_FromString(ret);
    free(ret);
    return res;
}

long long
shim_crtm()
{
  PyObject* tmp = PyObject_CallFunctionObjArgs(shim_rtmfn, NULL);
  unsigned long ms = PyLong_AsLongLong(tmp);
  Py_DECREF(tmp);
  return ms;
}

static PyMethodDef shim_methods[] = {
    {"open", shim_copen, METH_O},
    {"lookup", shim_clookup, METH_O},
    {"handle", shim_chandle, METH_VARARGS},
    {NULL, NULL}
};

PyMODINIT_FUNC
initshim(void)
{
    Py_InitModule("shim", shim_methods);
}

#ifdef __cplusplus
}
#endif
