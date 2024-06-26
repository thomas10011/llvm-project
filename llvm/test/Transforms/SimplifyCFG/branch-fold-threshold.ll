; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --version 5
; RUN: opt %s -passes=simplifycfg -simplifycfg-require-and-preserve-domtree=1 -S | FileCheck %s --check-prefixes=NORMAL,BASELINE
; RUN: opt %s -passes=simplifycfg -simplifycfg-require-and-preserve-domtree=1 -S -bonus-inst-threshold=2 | FileCheck %s --check-prefixes=NORMAL,AGGRESSIVE
; RUN: opt %s -passes=simplifycfg -simplifycfg-require-and-preserve-domtree=1 -S -bonus-inst-threshold=4 | FileCheck %s --check-prefixes=WAYAGGRESSIVE
; RUN: opt %s -passes=simplifycfg -S | FileCheck %s --check-prefixes=NORMAL,BASELINE
; RUN: opt %s -passes="simplifycfg<bonus-inst-threshold=2>" -S | FileCheck %s --check-prefixes=NORMAL,AGGRESSIVE
; RUN: opt %s -passes="simplifycfg<bonus-inst-threshold=4>" -S | FileCheck %s --check-prefixes=WAYAGGRESSIVE

define i32 @foo(i32 %a, i32 %b, i32 %c, i32 %d, ptr %input) {
; BASELINE-LABEL: define i32 @foo(
; BASELINE-SAME: i32 [[A:%.*]], i32 [[B:%.*]], i32 [[C:%.*]], i32 [[D:%.*]], ptr [[INPUT:%.*]]) {
; BASELINE-NEXT:  [[ENTRY:.*]]:
; BASELINE-NEXT:    [[CMP:%.*]] = icmp sgt i32 [[D]], 3
; BASELINE-NEXT:    br i1 [[CMP]], label %[[COND_END:.*]], label %[[LOR_LHS_FALSE:.*]]
; BASELINE:       [[LOR_LHS_FALSE]]:
; BASELINE-NEXT:    [[MUL:%.*]] = shl i32 [[C]], 1
; BASELINE-NEXT:    [[ADD:%.*]] = add nsw i32 [[MUL]], [[A]]
; BASELINE-NEXT:    [[CMP1:%.*]] = icmp slt i32 [[ADD]], [[B]]
; BASELINE-NEXT:    br i1 [[CMP1]], label %[[COND_FALSE:.*]], label %[[COND_END]]
; BASELINE:       [[COND_FALSE]]:
; BASELINE-NEXT:    [[TMP0:%.*]] = load i32, ptr [[INPUT]], align 4
; BASELINE-NEXT:    br label %[[COND_END]]
; BASELINE:       [[COND_END]]:
; BASELINE-NEXT:    [[COND:%.*]] = phi i32 [ [[TMP0]], %[[COND_FALSE]] ], [ 0, %[[LOR_LHS_FALSE]] ], [ 0, %[[ENTRY]] ]
; BASELINE-NEXT:    ret i32 [[COND]]
;
; AGGRESSIVE-LABEL: define i32 @foo(
; AGGRESSIVE-SAME: i32 [[A:%.*]], i32 [[B:%.*]], i32 [[C:%.*]], i32 [[D:%.*]], ptr [[INPUT:%.*]]) {
; AGGRESSIVE-NEXT:  [[ENTRY:.*]]:
; AGGRESSIVE-NEXT:    [[CMP:%.*]] = icmp sle i32 [[D]], 3
; AGGRESSIVE-NEXT:    [[MUL:%.*]] = shl i32 [[C]], 1
; AGGRESSIVE-NEXT:    [[ADD:%.*]] = add nsw i32 [[MUL]], [[A]]
; AGGRESSIVE-NEXT:    [[CMP1:%.*]] = icmp slt i32 [[ADD]], [[B]]
; AGGRESSIVE-NEXT:    [[OR_COND:%.*]] = select i1 [[CMP]], i1 [[CMP1]], i1 false
; AGGRESSIVE-NEXT:    br i1 [[OR_COND]], label %[[COND_FALSE:.*]], label %[[COND_END:.*]]
; AGGRESSIVE:       [[COND_FALSE]]:
; AGGRESSIVE-NEXT:    [[TMP0:%.*]] = load i32, ptr [[INPUT]], align 4
; AGGRESSIVE-NEXT:    br label %[[COND_END]]
; AGGRESSIVE:       [[COND_END]]:
; AGGRESSIVE-NEXT:    [[COND:%.*]] = phi i32 [ [[TMP0]], %[[COND_FALSE]] ], [ 0, %[[ENTRY]] ]
; AGGRESSIVE-NEXT:    ret i32 [[COND]]
;
; WAYAGGRESSIVE-LABEL: define i32 @foo(
; WAYAGGRESSIVE-SAME: i32 [[A:%.*]], i32 [[B:%.*]], i32 [[C:%.*]], i32 [[D:%.*]], ptr [[INPUT:%.*]]) {
; WAYAGGRESSIVE-NEXT:  [[ENTRY:.*]]:
; WAYAGGRESSIVE-NEXT:    [[CMP:%.*]] = icmp sle i32 [[D]], 3
; WAYAGGRESSIVE-NEXT:    [[MUL:%.*]] = shl i32 [[C]], 1
; WAYAGGRESSIVE-NEXT:    [[ADD:%.*]] = add nsw i32 [[MUL]], [[A]]
; WAYAGGRESSIVE-NEXT:    [[CMP1:%.*]] = icmp slt i32 [[ADD]], [[B]]
; WAYAGGRESSIVE-NEXT:    [[OR_COND:%.*]] = select i1 [[CMP]], i1 [[CMP1]], i1 false
; WAYAGGRESSIVE-NEXT:    br i1 [[OR_COND]], label %[[COND_FALSE:.*]], label %[[COND_END:.*]]
; WAYAGGRESSIVE:       [[COND_FALSE]]:
; WAYAGGRESSIVE-NEXT:    [[TMP0:%.*]] = load i32, ptr [[INPUT]], align 4
; WAYAGGRESSIVE-NEXT:    br label %[[COND_END]]
; WAYAGGRESSIVE:       [[COND_END]]:
; WAYAGGRESSIVE-NEXT:    [[COND:%.*]] = phi i32 [ [[TMP0]], %[[COND_FALSE]] ], [ 0, %[[ENTRY]] ]
; WAYAGGRESSIVE-NEXT:    ret i32 [[COND]]
;
entry:
  %cmp = icmp sgt i32 %d, 3
  br i1 %cmp, label %cond.end, label %lor.lhs.false

lor.lhs.false:
  %mul = shl i32 %c, 1
  %add = add nsw i32 %mul, %a
  %cmp1 = icmp slt i32 %add, %b
  br i1 %cmp1, label %cond.false, label %cond.end

cond.false:
  %0 = load i32, ptr %input, align 4
  br label %cond.end

cond.end:
  %cond = phi i32 [ %0, %cond.false ], [ 0, %lor.lhs.false ], [ 0, %entry ]
  ret i32 %cond
}

declare void @distinct_a();
declare void @distinct_b();

;; Like foo, but have to duplicate into multiple predecessors
define i32 @bar(i32 %a, i32 %b, i32 %c, i32 %d, ptr %input) {
; NORMAL-LABEL: define i32 @bar(
; NORMAL-SAME: i32 [[A:%.*]], i32 [[B:%.*]], i32 [[C:%.*]], i32 [[D:%.*]], ptr [[INPUT:%.*]]) {
; NORMAL-NEXT:  [[ENTRY:.*:]]
; NORMAL-NEXT:    [[CMP_SPLIT:%.*]] = icmp slt i32 [[D]], [[B]]
; NORMAL-NEXT:    [[CMP:%.*]] = icmp sgt i32 [[D]], 3
; NORMAL-NEXT:    br i1 [[CMP_SPLIT]], label %[[PRED_A:.*]], label %[[PRED_B:.*]]
; NORMAL:       [[PRED_A]]:
; NORMAL-NEXT:    call void @distinct_a()
; NORMAL-NEXT:    br i1 [[CMP]], label %[[COND_END:.*]], label %[[LOR_LHS_FALSE:.*]]
; NORMAL:       [[PRED_B]]:
; NORMAL-NEXT:    call void @distinct_b()
; NORMAL-NEXT:    br i1 [[CMP]], label %[[COND_END]], label %[[LOR_LHS_FALSE]]
; NORMAL:       [[LOR_LHS_FALSE]]:
; NORMAL-NEXT:    [[MUL:%.*]] = shl i32 [[C]], 1
; NORMAL-NEXT:    [[ADD:%.*]] = add nsw i32 [[MUL]], [[A]]
; NORMAL-NEXT:    [[CMP1:%.*]] = icmp slt i32 [[ADD]], [[B]]
; NORMAL-NEXT:    br i1 [[CMP1]], label %[[COND_FALSE:.*]], label %[[COND_END]]
; NORMAL:       [[COND_FALSE]]:
; NORMAL-NEXT:    [[TMP0:%.*]] = load i32, ptr [[INPUT]], align 4
; NORMAL-NEXT:    br label %[[COND_END]]
; NORMAL:       [[COND_END]]:
; NORMAL-NEXT:    [[COND:%.*]] = phi i32 [ [[TMP0]], %[[COND_FALSE]] ], [ 0, %[[LOR_LHS_FALSE]] ], [ 0, %[[PRED_A]] ], [ 0, %[[PRED_B]] ]
; NORMAL-NEXT:    ret i32 [[COND]]
;
; WAYAGGRESSIVE-LABEL: define i32 @bar(
; WAYAGGRESSIVE-SAME: i32 [[A:%.*]], i32 [[B:%.*]], i32 [[C:%.*]], i32 [[D:%.*]], ptr [[INPUT:%.*]]) {
; WAYAGGRESSIVE-NEXT:  [[ENTRY:.*:]]
; WAYAGGRESSIVE-NEXT:    [[CMP_SPLIT:%.*]] = icmp slt i32 [[D]], [[B]]
; WAYAGGRESSIVE-NEXT:    [[CMP:%.*]] = icmp sgt i32 [[D]], 3
; WAYAGGRESSIVE-NEXT:    br i1 [[CMP_SPLIT]], label %[[PRED_A:.*]], label %[[PRED_B:.*]]
; WAYAGGRESSIVE:       [[PRED_A]]:
; WAYAGGRESSIVE-NEXT:    call void @distinct_a()
; WAYAGGRESSIVE-NEXT:    [[CMP_NOT1:%.*]] = xor i1 [[CMP]], true
; WAYAGGRESSIVE-NEXT:    [[MUL_OLD:%.*]] = shl i32 [[C]], 1
; WAYAGGRESSIVE-NEXT:    [[ADD_OLD:%.*]] = add nsw i32 [[MUL_OLD]], [[A]]
; WAYAGGRESSIVE-NEXT:    [[CMP1_OLD:%.*]] = icmp slt i32 [[ADD_OLD]], [[B]]
; WAYAGGRESSIVE-NEXT:    [[OR_COND2:%.*]] = select i1 [[CMP_NOT1]], i1 [[CMP1_OLD]], i1 false
; WAYAGGRESSIVE-NEXT:    br i1 [[OR_COND2]], label %[[COND_FALSE:.*]], label %[[COND_END:.*]]
; WAYAGGRESSIVE:       [[PRED_B]]:
; WAYAGGRESSIVE-NEXT:    call void @distinct_b()
; WAYAGGRESSIVE-NEXT:    [[CMP_NOT:%.*]] = xor i1 [[CMP]], true
; WAYAGGRESSIVE-NEXT:    [[MUL:%.*]] = shl i32 [[C]], 1
; WAYAGGRESSIVE-NEXT:    [[ADD:%.*]] = add nsw i32 [[MUL]], [[A]]
; WAYAGGRESSIVE-NEXT:    [[CMP1:%.*]] = icmp slt i32 [[ADD]], [[B]]
; WAYAGGRESSIVE-NEXT:    [[OR_COND:%.*]] = select i1 [[CMP_NOT]], i1 [[CMP1]], i1 false
; WAYAGGRESSIVE-NEXT:    br i1 [[OR_COND]], label %[[COND_FALSE]], label %[[COND_END]]
; WAYAGGRESSIVE:       [[COND_FALSE]]:
; WAYAGGRESSIVE-NEXT:    [[TMP0:%.*]] = load i32, ptr [[INPUT]], align 4
; WAYAGGRESSIVE-NEXT:    br label %[[COND_END]]
; WAYAGGRESSIVE:       [[COND_END]]:
; WAYAGGRESSIVE-NEXT:    [[COND:%.*]] = phi i32 [ [[TMP0]], %[[COND_FALSE]] ], [ 0, %[[PRED_A]] ], [ 0, %[[PRED_B]] ]
; WAYAGGRESSIVE-NEXT:    ret i32 [[COND]]
;
entry:
  %cmp_split = icmp slt i32 %d, %b
  %cmp = icmp sgt i32 %d, 3
  br i1 %cmp_split, label %pred_a, label %pred_b

pred_a:
  call void @distinct_a();
  br i1 %cmp, label %cond.end, label %lor.lhs.false

pred_b:
  call void @distinct_b();
  br i1 %cmp, label %cond.end, label %lor.lhs.false

lor.lhs.false:
  %mul = shl i32 %c, 1
  %add = add nsw i32 %mul, %a
  %cmp1 = icmp slt i32 %add, %b
  br i1 %cmp1, label %cond.false, label %cond.end

cond.false:
  %0 = load i32, ptr %input, align 4
  br label %cond.end

cond.end:
  %cond = phi i32 [ %0, %cond.false ], [ 0, %lor.lhs.false ],[ 0, %pred_a ],[ 0, %pred_b ]
  ret i32 %cond
}
