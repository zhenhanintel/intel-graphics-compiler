;=========================== begin_copyright_notice ============================
;
; Copyright (C) 2022 Intel Corporation
;
; SPDX-License-Identifier: MIT
;
;============================ end_copyright_notice =============================
;
; The test checks printf with phi input
;
; RUN: igc_opt %s -S -o - -igc-opencl-printf-resolution | FileCheck %s

@.str.1 = internal unnamed_addr addrspace(2) constant [9 x i8] c"string 1\00"
@.str.2 = internal unnamed_addr addrspace(2) constant [9 x i8] c"string 2\00"
@.str.3 = internal unnamed_addr addrspace(2) constant [9 x i8] c"string 3\00"

define spir_kernel void @printf_test(i64, i8 addrspace(1)* %printfBuffer) #0 {
  %2 = icmp eq i64 %0, 1
  %3 = trunc i64 %0 to i32
  %4 = getelementptr inbounds [9 x i8], [9 x i8] addrspace(2)* @.str.1, i64 0, i64 0
  %5 = getelementptr inbounds [9 x i8], [9 x i8] addrspace(2)* @.str.2, i64 0, i64 0
  switch i32 %3, label %b5 [
    i32 0, label %b2
    i32 1, label %b3
    i32 2, label %b3
    i32 3, label %b4
  ]

b2:
  %6 = getelementptr inbounds [9 x i8], [9 x i8] addrspace(2)* @.str.3, i64 0, i64 0
  br label %b4

b3:
  %7 = select i1 %2, i8 addrspace(2)* %4, i8 addrspace(2)* %5
  br label %b5

b4:
  %8 = phi i8 addrspace(2)* [ %6, %b2 ], [ %5, %1 ]
  br label %b5

b5:
  %9 = phi i8 addrspace(2)* [ %7, %b3 ], [ %8, %b4 ], [ %4, %1 ]
  %10 = call spir_func i32 (i8 addrspace(2)*, ...) @printf(i8 addrspace(2)* %9)
  br label %b6

b6:
  ret void
}

; CHECK-LABEL: b3:                                               ; preds = %1, %1
; CHECK:         %7 = select i1 %2, i32 1, i32 0
; CHECK-NEXT:    %8 = select i1 %2, i8 addrspace(2)* %4, i8 addrspace(2)* %5
; CHECK-NEXT:    br label %b5

; CHECK:      b4:                                               ; preds = %b2, %1
; CHECK-NEXT:    %9 = phi i32 [ 2, %b2 ], [ 0, %1 ]
; CHECK-NEXT:    %10 = phi i8 addrspace(2)* [ %6, %b2 ], [ %5, %1 ]
; CHECK-NEXT:    br label %b5

; CHECK:      b5:                                               ; preds = %b4, %b3, %1
; CHECK-NEXT:    %11 = phi i32 [ %7, %b3 ], [ %9, %b4 ], [ 1, %1 ]
; CHECK-NEXT:    %12 = phi i8 addrspace(2)* [ %8, %b3 ], [ %10, %b4 ], [ %4, %1 ]
; CHECK-NEXT:    %ptrBC = bitcast i8 addrspace(1)* %printfBuffer to i32 addrspace(1)*
; CHECK-NEXT:    %write_offset = call i32 @__builtin_IB_atomic_add_global_i32(i32 addrspace(1)* %ptrBC, i32 4)
; CHECK-NEXT:    %end_offset = add i32 %write_offset, 4
; CHECK-NEXT:    %write_offset1 = zext i32 %write_offset to i64
; CHECK-NEXT:    %buffer_ptr = ptrtoint i8 addrspace(1)* %printfBuffer to i64
; CHECK-NEXT:    %write_offset2 = add i64 %buffer_ptr, %write_offset1
; CHECK-NEXT:    %13 = icmp ule i32 %end_offset, 4194304
; CHECK-NEXT:    br i1 %13, label %write_offset_true, label %write_offset_false

; CHECK:      write_offset_true:                                ; preds = %b5
; CHECK-NEXT:    %write_offset_ptr = inttoptr i64 %write_offset2 to i32 addrspace(1)*
; CHECK-NEXT:    store i32 %11, i32 addrspace(1)* %write_offset_ptr, align 4
; CHECK-NEXT:    %write_offset3 = add i64 %write_offset2, 4
; CHECK-NEXT:    br label %bblockJoin

; CHECK:      write_offset_false:                               ; preds = %b5
; CHECK-NEXT:    %end_offset4 = add i32 %write_offset, 4
; CHECK-NEXT:    %14 = icmp ule i32 %end_offset4, 4194304
; CHECK-NEXT:    br i1 %14, label %write_error_string, label %bblockFalseJoin

; CHECK:      write_error_string:                               ; preds = %write_offset_false
; CHECK-NEXT:    %write_offset_ptr5 = inttoptr i64 %write_offset2 to i32 addrspace(1)*
; CHECK-NEXT:    store i32 -1, i32 addrspace(1)* %write_offset_ptr5, align 4
; CHECK-NEXT:    br label %bblockFalseJoin

; CHECK:      bblockFalseJoin:                                  ; preds = %write_error_string, %write_offset_false
; CHECK-NEXT:    br label %bblockJoin

; CHECK:      bblockJoin:                                       ; preds = %bblockFalseJoin, %write_offset_true
; CHECK-NEXT:    %printf_ret_val = select i1 %13, i32 0, i32 -1
; CHECK-NEXT:    br label %b6


declare spir_func i32 @printf(i8 addrspace(2)*, ...)

; CHECK-LABEL:  declare spir_func i32 @printf(i8 addrspace(2)*, ...)
; CHECK:        declare i32 @__builtin_IB_atomic_add_global_i32(i32 addrspace(1)*, i32)

!igc.functions = !{!0}

; CHECK-LABEL: !igc.functions = !{!0}
; CHECK:       !printf.strings = !{!5, !6, !7}

!0 = !{void (i64, i8 addrspace(1)*)* @printf_test, !1}
!1 = !{!2, !3}
!2 = !{!"function_type", i32 0}
!3 = !{!"implicit_arg_desc", !4}
!4 = !{i32 13}

; CHECK-LABEL: !4 = !{i32 13}
; CHECK:       !5 = !{i32 0, !"string 2"}
; CHECK-NEXT:  !6 = !{i32 1, !"string 1"}
; CHECK-NEXT:  !7 = !{i32 2, !"string 3"}
