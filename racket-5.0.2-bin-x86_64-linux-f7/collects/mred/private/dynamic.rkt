#lang scheme/base

;; This module is for use by scheme/gui/dynamic.
;; It is required by mred/mred so that it gets carried
;; along when mred/mred is attached to a new namespace.

(provide kernel-initialized)

(dynamic-require ''#%mred-kernel #f)

(define kernel-initialized 'done)
