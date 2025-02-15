// RUN: mlir-opt %s --lower-sparse-iteration-to-scf | FileCheck %s
// RUN: mlir-opt %s --sparse-space-collapse --lower-sparse-iteration-to-scf | FileCheck %s --check-prefix COLLAPSED
// RUN: mlir-opt %s --sparsification-and-bufferization="sparse-emit-strategy=sparse-iterator" | FileCheck %s --check-prefix COLLAPSED

#COO = #sparse_tensor.encoding<{
  map = (i, j) -> (
    i : compressed(nonunique),
    j : singleton(soa)
  )
}>

// CHECK-LABEL:   @sparse_iteration_to_scf
//                  // deduplication
// CHECK:           scf.while {{.*}} {
// CHECK:           } do {
// CHECK:           }
// CHECK:           scf.while {{.*}} {
// CHECK:           } do {
//                    // actual computation
// CHECK:             scf.for {{.*}} {
// CHECK:               arith.addi
// CHECK:             }
//                    // deduplication
// CHECK:             scf.while {{.*}} {
// CHECK:             } do {
// CHECK:             }
// CHECK:             scf.yield
// CHECK:           }
// CHECK:           return

// COLLAPSED-LABEL:   @sparse_iteration_to_scf
// COLLAPSED:           %[[RET:.*]] = scf.for {{.*}} {
// COLLAPSED:             %[[VAL:.*]] = arith.addi
// COLLAPSED:             scf.yield %[[VAL]] : index
// COLLAPSED:           }
// COLLAPSED:           return %[[RET]] : index
func.func @sparse_iteration_to_scf(%sp : tensor<4x8xf32, #COO>) -> index {
  %i = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %l1 = sparse_tensor.extract_iteration_space %sp lvls = 0
      : tensor<4x8xf32, #COO> -> !sparse_tensor.iter_space<#COO, lvls = 0>
  %r1 = sparse_tensor.iterate %it1 in %l1 iter_args(%outer = %i): !sparse_tensor.iter_space<#COO, lvls = 0 to 1> -> index {
    %l2 = sparse_tensor.extract_iteration_space %sp at %it1 lvls = 1
        : tensor<4x8xf32, #COO>, !sparse_tensor.iterator<#COO, lvls = 0 to 1> -> !sparse_tensor.iter_space<#COO, lvls = 1>
    %r2 = sparse_tensor.iterate %it2 in %l2 iter_args(%inner = %outer): !sparse_tensor.iter_space<#COO, lvls = 1 to 2> -> index {
      %k = arith.addi %inner, %c1 : index
      sparse_tensor.yield %k : index
    }
    sparse_tensor.yield %r2 : index
  }
  return %r1 : index
}
