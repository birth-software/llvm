# RUN: %PYTHON %s | FileCheck %s

from mlir.ir import *
import mlir.dialects.gpu as gpu
import mlir.dialects.gpu.passes
from mlir.passmanager import *


def run(f):
    print("\nTEST:", f.__name__)
    with Context(), Location.unknown():
        f()
    return f


# CHECK-LABEL: testGPUPass
#       CHECK: SUCCESS
@run
def testGPUPass():
    PassManager.parse("any(gpu-kernel-outlining)")
    print("SUCCESS")


# CHECK-LABEL: testMMAElementWiseAttr
@run
def testMMAElementWiseAttr():
    module = Module.create()
    with InsertionPoint(module.body):
        gpu.BlockDimOp(gpu.Dimension.y)
    # CHECK: %block_dim_y = gpu.block_dim  y
    print(module)
    pass


# CHECK-LABEL: testObjectAttr
@run
def testObjectAttr():
    target = Attribute.parse("#nvvm.target")
    format = gpu.CompilationTarget.Fatbin
    object = b"BC\xc0\xde5\x14\x00\x00\x05\x00\x00\x00b\x0c0$MY\xbef"
    properties = DictAttr.get({"O": IntegerAttr.get(IntegerType.get_signless(32), 2)})
    o = gpu.ObjectAttr.get(target, format, object, properties)
    # CHECK: #gpu.object<#nvvm.target, properties = {O = 2 : i32}, "BC\C0\DE5\14\00\00\05\00\00\00b\0C0$MY\BEf">
    print(o)
    assert o.object == object

    o = gpu.ObjectAttr.get(target, format, object)
    # CHECK: #gpu.object<#nvvm.target, "BC\C0\DE5\14\00\00\05\00\00\00b\0C0$MY\BEf">
    print(o)

    object = (
        b"//\n// Generated by LLVM NVPTX Back-End\n//\n\n.version 6.0\n.target sm_50"
    )
    o = gpu.ObjectAttr.get(target, format, object)
    # CHECK: #gpu.object<#nvvm.target, "//\0A// Generated by LLVM NVPTX Back-End\0A//\0A\0A.version 6.0\0A.target sm_50">
    print(o)
    assert o.object == object
