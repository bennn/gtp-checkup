#lang info
(define collection "gtp-checkup")
(define deps '(
  "base"
  "data-lib"
  "draw-lib"
  "math-lib"
  "memoize"
  "pict-lib"
  "plot-lib"
  "rackunit-lib"
  "require-typed-check"
  "sandbox-lib"
  "typed-racket-lib"
  "typed-racket-more"
  "zo-lib"))
(define build-deps '("scribble-lib" "racket-doc" "rackunit-lib" "gtp-benchmarks"))
(define pkg-desc "Gradual typing correctness check")
(define version "0.1")
(define pkg-authors '(ben))
(define scribblings '(("scribblings/gtp-checkup.scrbl" ())))
(define compile-omit-paths '("benchmarks/"))
