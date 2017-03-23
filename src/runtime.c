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

#ifdef __cplusplus
extern "C" {
#endif

struct handle_return { char* r0; char* r1; char* r2; };

extern char * open(const char *, const char *);
extern char * lookup(const char *);
extern struct handle_return handle(const char *, const char *, const char *);

static PyObject *runtime_log_fn,
                *runtime_rtm_fn;

void
runtime_log(char *msg)
{
    if (runtime_log_fn == NULL) {
        free(msg);
        return;
    }
    PyObject *tmp = PyObject_CallFunction(runtime_log_fn, "s", msg);
    if (tmp != NULL) {
        Py_DECREF(tmp);
    }
    free(msg);
}

long long
runtime_rtm()
{
    long long res = 0;

    PyObject *tmp = PyObject_CallFunction(runtime_rtm_fn, NULL);
    if (tmp != NULL) {
        res = PyLong_AsLongLong(tmp);
        Py_DECREF(tmp);
    }

    return res;
}

static PyObject *
runtime_open(PyObject *self, PyObject *args)
{
    const char *cnme, *cenv;
    char *err;

    if (!PyArg_ParseTuple(args, "ss", &cnme, &cenv)) {
        return NULL;
    }

    if (!(err = open(cnme, cenv))) {
        Py_RETURN_NONE;
    }

    PyErr_SetString(PyExc_ImportError, err);
    free(err);
    return NULL;
}

static PyObject *
runtime_lookup(PyObject *self, PyObject *arg)
{
    char *err;

    if (!(err = lookup(PyString_AS_STRING(arg)))) {
        Py_RETURN_NONE;
    }

    PyErr_SetString(PyExc_AttributeError, err);
    free(err);
    return NULL;
}

static PyObject *
runtime_handle(PyObject *self, PyObject *args)
{
    const char *cevt, *cctx, *cenv;

    if (!PyArg_ParseTuple(args, "sssOO",
                          &cevt, &cctx, &cenv,
                          &runtime_log_fn, &runtime_rtm_fn)) {
        return NULL;
    }

    struct handle_return gres = handle(cevt, cctx, cenv);

    if (gres.r2 != NULL) {
        PyObject* err = PyErr_NewException(gres.r1, NULL, NULL);
        PyErr_SetString(err, gres.r2);
        free(gres.r2);
        return NULL;
    }

    if (gres.r0 != NULL) {
        PyObject* res = PyString_FromString(gres.r0);
        free(gres.r0);
        return res;
    }

    Py_RETURN_NONE;
}

static PyMethodDef runtime_methods[] = {
    {"open",   runtime_open,   METH_VARARGS},
    {"lookup", runtime_lookup, METH_O},
    {"handle", runtime_handle, METH_VARARGS},
    {NULL, NULL}
};

PyMODINIT_FUNC
initruntime(void)
{
    Py_InitModule("runtime", runtime_methods);
}

#ifdef __cplusplus
}
#endif
