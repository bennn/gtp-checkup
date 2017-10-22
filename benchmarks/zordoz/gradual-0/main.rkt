#lang racket/base

(require require-typed-check)

(require "zo-shell.rkt")

(define SMALL-TEST "test.zo")
(define (small-test)
  (init (vector SMALL-TEST "branch")))

;; -----------------------------------------------------------------------------

(define-syntax-rule (main test)
  (with-output-to-file "/dev/null" test #:exists 'append))

(time (main small-test))
