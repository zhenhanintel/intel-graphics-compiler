;=========================== begin_copyright_notice ============================
;
; Copyright (C) 2022 Intel Corporation
;
; SPDX-License-Identifier: MIT
;
;============================ end_copyright_notice =============================
;
; RUN: igc_opt --igc-loop-canonicalization -S < %s | FileCheck %s
; ------------------------------------------------
; LoopCanonicalization
; ------------------------------------------------
; This test checks that LoopCanonicalization pass follows
; 'How to Update Debug Info' llvm guideline.
;
; Debug MD for this test was created with debugify pass.
; ------------------------------------------------
;
; Check that header and backedge have proper line info
; Check that updated phi node didn't lose MD.

; CHECK: define spir_kernel void @test_loop
; CHECK-SAME: !dbg [[SCOPE:![0-9]*]]
;
; CHECK: entry:
; CHECK-NEXT: [[CMP0_V:%[A-z0-9.]*]] = icmp {{.*}} !dbg [[CMP0_LOC:![0-9]*]]
; CHECK-NEXT: @llvm.dbg.value(metadata i1 [[CMP0_V]], metadata [[CMP0_MD:![0-9]*]], metadata !DIExpression()), !dbg [[CMP0_LOC]]
;
; CHECK: for.body.preheader:
; CHECK: br {{.*}} !dbg [[PREHEADER_LOC:![0-9]*]]
;
; CHECK: for.body:
; CHECK: [[PHI0_V:%[A-z0-9.]*]] = phi i32* {{.*}} !dbg [[PHI0_LOC:![0-9]*]]
; CHECK: [[PHI1_V:%[A-z0-9.]*]] = phi i32 {{.*}} !dbg [[PHI1_LOC:![0-9]*]]
; CHECK: @llvm.dbg.value(metadata i32* [[PHI0_V]], metadata [[PHI0_MD:![0-9]*]], metadata !DIExpression()), !dbg [[PHI0_LOC]]
; CHECK: @llvm.dbg.value(metadata i32 [[PHI1_V]], metadata [[PHI1_MD:![0-9]*]], metadata !DIExpression()), !dbg [[PHI1_LOC]]
; CHECK: br {{.*}} !dbg [[PREHEADER_LOC]]
;
; CHECK: for.if:
; CHECK: br {{.*}} !dbg [[FORIF_LOC:![0-9]*]]
;
; First line in for.body
; CHECK: for.body.backedge:
; CHECK: br {{.*}} !dbg [[PHI0_LOC]]
;
; CHECK: for.else:
; CHECK: br {{.*}} !dbg [[FORELSE_LOC:![0-9]*]]

define spir_kernel void @test_loop(i32* %a, i32* %b, i32 %c) !dbg !6 {
entry:
  %cmp.0 = icmp eq i32* %a, %b, !dbg !19
  call void @llvm.dbg.value(metadata i1 %cmp.0, metadata !9, metadata !DIExpression()), !dbg !19
  br i1 %cmp.0, label %for.end, label %for.body, !dbg !20

for.body:                                         ; preds = %for.else, %for.if, %entry
  %p.0 = phi i32* [ %inc.p, %for.else ], [ %a, %entry ], [ %b, %for.if ], !dbg !21
  %p.1 = phi i32 [ 42, %entry ], [ %p.1, %for.else ], [ %p.1, %for.if ], !dbg !22
  call void @llvm.dbg.value(metadata i32* %p.0, metadata !11, metadata !DIExpression()), !dbg !21
  call void @llvm.dbg.value(metadata i32 %p.1, metadata !13, metadata !DIExpression()), !dbg !22
  %0 = load i32, i32* %p.0, align 4, !dbg !23
  call void @llvm.dbg.value(metadata i32 %0, metadata !15, metadata !DIExpression()), !dbg !23
  %cmp.1 = icmp eq i32 %0, %p.1, !dbg !24
  call void @llvm.dbg.value(metadata i1 %cmp.1, metadata !16, metadata !DIExpression()), !dbg !24
  br i1 %cmp.1, label %for.if, label %for.else, !dbg !25

for.if:                                           ; preds = %for.body
  br label %for.body, !dbg !26

for.else:                                         ; preds = %for.body
  %inc.p = getelementptr inbounds i32, i32* %p.0, i64 1, !dbg !27
  call void @llvm.dbg.value(metadata i32* %inc.p, metadata !17, metadata !DIExpression()), !dbg !27
  %cmp.2 = icmp eq i32* %inc.p, %b, !dbg !28
  call void @llvm.dbg.value(metadata i1 %cmp.2, metadata !18, metadata !DIExpression()), !dbg !28
  br i1 %cmp.2, label %for.end, label %for.body, !dbg !29

for.end:                                          ; preds = %for.else, %entry
  ret void, !dbg !30
}

; CHECK-DAG: [[FILE:![0-9]*]] = !DIFile(filename: "LoopCanonicalization.ll", directory: "/")
; CHECK-DAG: [[SCOPE]] = distinct !DISubprogram(name: "test_loop", linkageName: "test_loop", scope: null, file: [[FILE]], line: 1
; CHECK-DAG: [[CMP0_MD]] = !DILocalVariable(name: "1", scope: [[SCOPE]], file: [[FILE]], line: 1
; CHECK-DAG: [[CMP0_LOC]] = !DILocation(line: 1, column: 1, scope: [[SCOPE]])
; CHECK-DAG: [[PREHEADER_LOC]] = !DILocation(line: 7, column: 1, scope: [[SCOPE]])
; CHECK-DAG: [[PHI0_MD]] = !DILocalVariable(name: "2", scope: [[SCOPE]], file: [[FILE]], line: 3
; CHECK-DAG: [[PHI0_LOC]] = !DILocation(line: 3, column: 1, scope: [[SCOPE]])
; CHECK-DAG: [[PHI1_MD]] = !DILocalVariable(name: "3", scope: [[SCOPE]], file: [[FILE]], line: 4
; CHECK-DAG: [[PHI1_LOC]] = !DILocation(line: 4, column: 1, scope: [[SCOPE]])
; CHECK-DAG: [[FORIF_LOC]] = !DILocation(line: 8, column: 1, scope: [[SCOPE]])
; CHECK-DAG: [[FORELSE_LOC]] = !DILocation(line: 11, column: 1, scope: [[SCOPE]])


; Function Attrs: nounwind readnone speculatable
declare void @llvm.dbg.value(metadata, metadata, metadata) #0

attributes #0 = { nounwind readnone speculatable }

!llvm.dbg.cu = !{!0}
!llvm.debugify = !{!3, !4}
!llvm.module.flags = !{!5}

!0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "debugify", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !2)
!1 = !DIFile(filename: "LoopCanonicalization.ll", directory: "/")
!2 = !{}
!3 = !{i32 12}
!4 = !{i32 7}
!5 = !{i32 2, !"Debug Info Version", i32 3}
!6 = distinct !DISubprogram(name: "test_loop", linkageName: "test_loop", scope: null, file: !1, line: 1, type: !7, scopeLine: 1, unit: !0, retainedNodes: !8)
!7 = !DISubroutineType(types: !2)
!8 = !{!9, !11, !13, !15, !16, !17, !18}
!9 = !DILocalVariable(name: "1", scope: !6, file: !1, line: 1, type: !10)
!10 = !DIBasicType(name: "ty8", size: 8, encoding: DW_ATE_unsigned)
!11 = !DILocalVariable(name: "2", scope: !6, file: !1, line: 3, type: !12)
!12 = !DIBasicType(name: "ty64", size: 64, encoding: DW_ATE_unsigned)
!13 = !DILocalVariable(name: "3", scope: !6, file: !1, line: 4, type: !14)
!14 = !DIBasicType(name: "ty32", size: 32, encoding: DW_ATE_unsigned)
!15 = !DILocalVariable(name: "4", scope: !6, file: !1, line: 5, type: !14)
!16 = !DILocalVariable(name: "5", scope: !6, file: !1, line: 6, type: !10)
!17 = !DILocalVariable(name: "6", scope: !6, file: !1, line: 9, type: !12)
!18 = !DILocalVariable(name: "7", scope: !6, file: !1, line: 10, type: !10)
!19 = !DILocation(line: 1, column: 1, scope: !6)
!20 = !DILocation(line: 2, column: 1, scope: !6)
!21 = !DILocation(line: 3, column: 1, scope: !6)
!22 = !DILocation(line: 4, column: 1, scope: !6)
!23 = !DILocation(line: 5, column: 1, scope: !6)
!24 = !DILocation(line: 6, column: 1, scope: !6)
!25 = !DILocation(line: 7, column: 1, scope: !6)
!26 = !DILocation(line: 8, column: 1, scope: !6)
!27 = !DILocation(line: 9, column: 1, scope: !6)
!28 = !DILocation(line: 10, column: 1, scope: !6)
!29 = !DILocation(line: 11, column: 1, scope: !6)
!30 = !DILocation(line: 12, column: 1, scope: !6)
