// RUN: mlir-opt %s -transform-interpreter -split-input-file | FileCheck %s

func.func @vectorize_dynamic_identity(%arg0: tensor<?xf32>,
                                      %arg1: tensor<?xf32>,
                                      %arg2: tensor<?xf32>) -> tensor<?xf32> {
  %0 = linalg.generic { indexing_maps = [affine_map<(d0) -> (d0)>,
                                         affine_map<(d0) -> (d0)>,
                                         affine_map<(d0) -> (d0)>],
                   iterator_types = ["parallel"] }
    ins(%arg0, %arg1 : tensor<?xf32>, tensor<?xf32>)
    outs(%arg2 : tensor<?xf32>) {
    ^bb(%in0: f32, %in1: f32, %out: f32) :
      %0 = arith.addf %in0, %in1 : f32
      linalg.yield %0 : f32
    } -> tensor<?xf32>
  return %0 : tensor<?xf32>
}

// CHECK-LABEL:   @vectorize_dynamic_identity
// CHECK:           %[[VAL_3:.*]] = arith.constant 0 : index
// CHECK:           %[[VAL_4:.*]] = tensor.dim %{{.*}}, %[[VAL_3]] : tensor<?xf32>
// CHECK:           %[[VAL_7:.*]] = vector.create_mask %[[VAL_4]] : vector<[4]xi1>
// CHECK:           %[[VAL_8:.*]] = vector.mask %[[VAL_7]] { vector.transfer_read %{{.*}} {in_bounds = [true]} : tensor<?xf32>, vector<[4]xf32> } : vector<[4]xi1> -> vector<[4]xf32>
// CHECK:           %[[VAL_10:.*]] = vector.mask %[[VAL_7]] { vector.transfer_read %{{.*}} {in_bounds = [true]} : tensor<?xf32>, vector<[4]xf32> } : vector<[4]xi1> -> vector<[4]xf32>
// CHECK:           %[[VAL_12:.*]] = vector.mask %[[VAL_7]] { vector.transfer_read %{{.*}} {in_bounds = [true]} : tensor<?xf32>, vector<[4]xf32> } : vector<[4]xi1> -> vector<[4]xf32>
// CHECK:           %[[VAL_13:.*]] = arith.addf %[[VAL_8]], %[[VAL_10]] : vector<[4]xf32>
// CHECK:           %[[VAL_14:.*]] = vector.mask %[[VAL_7]] { vector.transfer_write %{{.*}} {in_bounds = [true]} : vector<[4]xf32>, tensor<?xf32> } : vector<[4]xi1> -> tensor<?xf32>

module attributes {transform.with_named_sequence} {
  transform.named_sequence @__transform_main(%arg1: !transform.any_op {transform.readonly}) {
    %0 = transform.structured.match ops{["linalg.generic"]} in %arg1 : (!transform.any_op) -> !transform.any_op
    transform.structured.vectorize %0 vector_sizes [[4]] : !transform.any_op
    transform.yield
  }
}

// -----

func.func @vectorize_partial_dynamic_identity(%arg0: tensor<8x?xf32>,
                                              %arg1: tensor<8x?xf32>,
                                              %arg2: tensor<8x?xf32>) -> tensor<8x?xf32> {
  %0 = linalg.generic { indexing_maps = [affine_map<(d0, d1) -> (d0, d1)>,
                                         affine_map<(d0, d1) -> (d0, d1)>,
                                         affine_map<(d0, d1) -> (d0, d1)>],
                   iterator_types = ["parallel", "parallel"] }
    ins(%arg0, %arg1 : tensor<8x?xf32>, tensor<8x?xf32>)
    outs(%arg2 : tensor<8x?xf32>) {
    ^bb(%in0: f32, %in1: f32, %out: f32) :
      %0 = arith.addf %in0, %in1 : f32
      linalg.yield %0 : f32
    } -> tensor<8x?xf32>
  return %0 : tensor<8x?xf32>
}

// CHECK-LABEL:   func.func @vectorize_partial_dynamic_identity(
// CHECK-SAME:      %[[VAL_0:.*]]: tensor<8x?xf32>, %[[VAL_1:.*]]: tensor<8x?xf32>, %[[VAL_2:.*]]: tensor<8x?xf32>) -> tensor<8x?xf32> {
// CHECK-DAG:       %[[VAL_3:.*]] = arith.constant 1 : index
// CHECK-DAG:       %[[VAL_4:.*]] = tensor.dim %[[VAL_0]], %[[VAL_3]] : tensor<8x?xf32>
// CHECK-DAG:       %[[VAL_5:.*]] = arith.constant 0 : index
// CHECK-DAG:       %[[VAL_6:.*]] = arith.constant 0.000000e+00 : f32
// CHECK-DAG:       %[[VAL_7:.*]] = arith.constant 8 : index
// CHECK:           %[[VAL_8:.*]] = vector.create_mask %[[VAL_7]], %[[VAL_4]] : vector<8x[32]xi1>
// CHECK:           %[[VAL_9:.*]] = vector.mask %[[VAL_8]] { vector.transfer_read %[[VAL_0]][%[[VAL_5]], %[[VAL_5]]], %[[VAL_6]] {in_bounds = [true, true]} : tensor<8x?xf32>, vector<8x[32]xf32> } : vector<8x[32]xi1> -> vector<8x[32]xf32>
// CHECK:           %[[VAL_10:.*]] = arith.constant 0.000000e+00 : f32
// CHECK:           %[[VAL_11:.*]] = vector.mask %[[VAL_8]] { vector.transfer_read %[[VAL_1]][%[[VAL_5]], %[[VAL_5]]], %[[VAL_10]] {in_bounds = [true, true]} : tensor<8x?xf32>, vector<8x[32]xf32> } : vector<8x[32]xi1> -> vector<8x[32]xf32>
// CHECK:           %[[VAL_12:.*]] = arith.constant 0.000000e+00 : f32
// CHECK:           %[[VAL_13:.*]] = vector.mask %[[VAL_8]] { vector.transfer_read %[[VAL_2]][%[[VAL_5]], %[[VAL_5]]], %[[VAL_12]] {in_bounds = [true, true]} : tensor<8x?xf32>, vector<8x[32]xf32> } : vector<8x[32]xi1> -> vector<8x[32]xf32>
// CHECK:           %[[VAL_14:.*]] = arith.addf %[[VAL_9]], %[[VAL_11]] : vector<8x[32]xf32>
// CHECK:           %[[VAL_15:.*]] = arith.constant 0 : index
// CHECK:           %[[VAL_16:.*]] = vector.mask %[[VAL_8]] { vector.transfer_write %[[VAL_14]], %[[VAL_2]][%[[VAL_15]], %[[VAL_15]]] {in_bounds = [true, true]} : vector<8x[32]xf32>, tensor<8x?xf32> } : vector<8x[32]xi1> -> tensor<8x?xf32>


module attributes {transform.with_named_sequence} {
  transform.named_sequence @__transform_main(%arg1: !transform.any_op {transform.readonly}) {
    %0 = transform.structured.match ops{["linalg.generic"]} in %arg1 : (!transform.any_op) -> !transform.any_op
    transform.structured.vectorize %0 vector_sizes [8, [32]] : !transform.any_op
    transform.yield
  }
}

// -----

func.func @vectorize_static_shape_with_mask(%arg0: tensor<8x30xf32>,
                                            %arg1: tensor<8x30xf32>,
                                            %arg2: tensor<8x30xf32>) -> tensor<8x30xf32> {
  %0 = linalg.generic { indexing_maps = [affine_map<(d0, d1) -> (d0, d1)>,
                                         affine_map<(d0, d1) -> (d0, d1)>,
                                         affine_map<(d0, d1) -> (d0, d1)>],
                   iterator_types = ["parallel", "parallel"] }
    ins(%arg0, %arg1 : tensor<8x30xf32>, tensor<8x30xf32>)
    outs(%arg2 : tensor<8x30xf32>) {
    ^bb(%in0: f32, %in1: f32, %out: f32) :
      %0 = arith.addf %in0, %in1 : f32
      linalg.yield %0 : f32
    } -> tensor<8x30xf32>
  return %0 : tensor<8x30xf32>
}

// CHECK-LABEL:   func.func @vectorize_static_shape_with_mask(
// CHECK-SAME:      %[[VAL_0:.*]]: tensor<8x30xf32>, %[[VAL_1:.*]]: tensor<8x30xf32>, %[[VAL_2:.*]]: tensor<8x30xf32>) -> tensor<8x30xf32> {
// CHECK-DAG:       %[[VAL_3:.*]] = arith.constant 0 : index
// CHECK-DAG:       %[[VAL_4:.*]] = arith.constant 0.000000e+00 : f32
// CHECK-DAG:       %[[VAL_5:.*]] = arith.constant 8 : index
// CHECK-DAG:       %[[VAL_6:.*]] = arith.constant 30 : index
// CHECK:           %[[VAL_7:.*]] = vector.create_mask %[[VAL_5]], %[[VAL_6]] : vector<8x[32]xi1>
// CHECK:           %[[VAL_8:.*]] = vector.mask %[[VAL_7]] { vector.transfer_read %[[VAL_0]][%[[VAL_3]], %[[VAL_3]]], %[[VAL_4]] {in_bounds = [true, true]} : tensor<8x30xf32>, vector<8x[32]xf32> } : vector<8x[32]xi1> -> vector<8x[32]xf32>
// CHECK:           %[[VAL_9:.*]] = arith.constant 0.000000e+00 : f32
// CHECK:           %[[VAL_10:.*]] = vector.mask %[[VAL_7]] { vector.transfer_read %[[VAL_1]][%[[VAL_3]], %[[VAL_3]]], %[[VAL_9]] {in_bounds = [true, true]} : tensor<8x30xf32>, vector<8x[32]xf32> } : vector<8x[32]xi1> -> vector<8x[32]xf32>
// CHECK:           %[[VAL_11:.*]] = arith.constant 0.000000e+00 : f32
// CHECK:           %[[VAL_12:.*]] = vector.mask %[[VAL_7]] { vector.transfer_read %[[VAL_2]][%[[VAL_3]], %[[VAL_3]]], %[[VAL_11]] {in_bounds = [true, true]} : tensor<8x30xf32>, vector<8x[32]xf32> } : vector<8x[32]xi1> -> vector<8x[32]xf32>
// CHECK:           %[[VAL_13:.*]] = arith.addf %[[VAL_8]], %[[VAL_10]] : vector<8x[32]xf32>
// CHECK:           %[[VAL_14:.*]] = arith.constant 0 : index
// CHECK:           %[[VAL_15:.*]] = vector.mask %[[VAL_7]] { vector.transfer_write %[[VAL_13]], %[[VAL_2]][%[[VAL_14]], %[[VAL_14]]] {in_bounds = [true, true]} : vector<8x[32]xf32>, tensor<8x30xf32> } : vector<8x[32]xi1> -> tensor<8x30xf32>

module attributes {transform.with_named_sequence} {
  transform.named_sequence @__transform_main(%arg1: !transform.any_op {transform.readonly}) {
    %0 = transform.structured.match ops{["linalg.generic"]} in %arg1 : (!transform.any_op) -> !transform.any_op
    transform.structured.vectorize %0 vector_sizes [8, [32]] : !transform.any_op
    transform.yield
  }
}

// -----

func.func @vectorize_dynamic_fill(%A : tensor<?x?xf32>, %arg0 : f32) -> tensor<?x?xf32> {
  %0 = linalg.fill ins(%arg0 : f32) outs(%A : tensor<?x?xf32>) -> tensor<?x?xf32>
  return %0 : tensor<?x?xf32>
}

// CHECK-LABEL: func.func @vectorize_dynamic_fill
//   CHECK: %[[DIM0:.*]] = tensor.dim
//   CHECK: %[[DIM1:.*]] = tensor.dim
//   CHECK: %[[MASK:.*]] = vector.create_mask %[[DIM0]], %[[DIM1]] : vector<8x[16]xi1>
//   CHECK: %[[BCAST:.*]] = vector.broadcast %{{.*}} : f32 to vector<8x[16]xf32>
//   CHECK: vector.mask %[[MASK]] { vector.transfer_write %[[BCAST]], {{.*}} {in_bounds = [true, true]} : vector<8x[16]xf32>, tensor<?x?xf32> } : vector<8x[16]xi1>

module attributes {transform.with_named_sequence} {
  transform.named_sequence @__transform_main(%arg1: !transform.any_op {transform.readonly}) {
    %0 = transform.structured.match ops{["linalg.fill"]} in %arg1 : (!transform.any_op) -> !transform.any_op
    transform.structured.vectorize %0 vector_sizes [8, [16]] : !transform.any_op
    transform.yield
  }
}

// -----

#map = affine_map<(d0, d1, d2) -> (d0, d1, d2)>
func.func @vectorize_linalg_index(%arg0: tensor<3x3x?xf32>, %arg1: tensor<1x1x?xf32>) -> tensor<1x1x?xf32> {
  %0 = linalg.generic {
    indexing_maps = [#map],
    iterator_types = ["parallel", "parallel", "parallel"]
  } outs(%arg1 : tensor<1x1x?xf32>) {
  ^bb0(%in: f32):
    %1 = linalg.index 0 : index
    %2 = linalg.index 1 : index
    %3 = linalg.index 2 : index
    %4 = tensor.extract %arg0[%1, %2, %3] : tensor<3x3x?xf32>
    linalg.yield %4 : f32
  } -> tensor<1x1x?xf32>
  return %0 : tensor<1x1x?xf32>
}

// CHECK-LABEL: @vectorize_linalg_index
// CHECK-SAME: %[[SRC:.*]]: tensor<3x3x?xf32>, %[[DST:.*]]: tensor<1x1x?xf32>
// CHECK-DAG:    %[[PASSTHRU:.*]] = arith.constant dense<0.000000e+00> : vector<1x1x[4]xf32>
// CHECK-DAG:        %[[MASK:.*]] = arith.constant dense<true> : vector<1x1x[4]xi1>
// CHECK-DAG:          %[[C0:.*]] = arith.constant 0 : index
// CHECK-DAG:          %[[C1:.*]] = arith.constant 1 : index
// CHECK-DAG:          %[[C2:.*]] = arith.constant 2 : index
// CHECK:        %[[DST_DIM2:.*]] = tensor.dim %[[DST]], %[[C2]] : tensor<1x1x?xf32>
// CHECK:        %[[DST_MASK:.*]] = vector.create_mask %[[C1]], %[[C1]], %[[DST_DIM2]] : vector<1x1x[4]xi1>
// CHECK:       %[[INDEX_VEC:.*]] = vector.step : vector<[4]xindex>
// CHECK: %[[INDEX_VEC_BCAST:.*]] = vector.broadcast %[[INDEX_VEC]] : vector<[4]xindex> to vector<1x1x[4]xindex>
// CHECK:          %[[GATHER:.*]] = vector.mask %[[DST_MASK]] { vector.gather %[[SRC]]{{\[}}%[[C0]], %[[C0]], %[[C0]]] {{\[}}%[[INDEX_VEC_BCAST]]], %[[MASK]], %[[PASSTHRU]] : tensor<3x3x?xf32>, vector<1x1x[4]xindex>, vector<1x1x[4]xi1>, vector<1x1x[4]xf32> into vector<1x1x[4]xf32> } : vector<1x1x[4]xi1> -> vector<1x1x[4]xf32>
// CHECK:             %[[OUT:.*]] = vector.mask %[[DST_MASK]] { vector.transfer_write %[[GATHER]], %[[DST]]{{\[}}%[[C0]], %[[C0]], %[[C0]]] {in_bounds = [true, true, true]} : vector<1x1x[4]xf32>, tensor<1x1x?xf32> } : vector<1x1x[4]xi1> -> tensor<1x1x?xf32>
// CHECK:           return %[[OUT]] : tensor<1x1x?xf32>

module attributes {transform.with_named_sequence} {
  transform.named_sequence @__transform_main(%arg1: !transform.any_op {transform.readonly}) {
    %0 = transform.structured.match ops{["linalg.generic"]} in %arg1 : (!transform.any_op) -> !transform.any_op
    transform.structured.vectorize %0 vector_sizes [1, 1, [4]] {vectorize_nd_extract} : !transform.any_op

    %func = transform.structured.match ops{["func.func"]} in %arg1
      : (!transform.any_op) -> !transform.any_op
    transform.apply_patterns to %func {
      transform.apply_patterns.canonicalization
      transform.apply_patterns.linalg.tiling_canonicalization
    } : !transform.any_op
    transform.yield
  }
}
