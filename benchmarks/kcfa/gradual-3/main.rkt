#lang racket/base

;; Create a few examples and run abstract interpretation

(require
  "structs.rkt"
  "ui.rkt"
)

;; =============================================================================

(define new-label gensym)

;(: make-ref (-> Var Exp))
(define (make-ref var)
  (Ref (new-label) var))

;(: make-lambda (-> (Listof Var) Exp Exp))
(define (make-lambda formals call)
  (Lam (new-label) formals call))

;(: make-call (-> Exp Exp * Exp))
(define (make-call fun . args)
  (Call (new-label) fun args))

(define (make-let var exp call)
  (make-call (make-lambda (list var) call) exp))

;; -- main

(define standard-example
 (make-let
  'id
  (make-lambda '(x k) (make-call (make-ref 'k) (make-ref 'x)))
  (make-call (make-ref 'id)
   (make-lambda '(z) (make-ref 'z))
   (make-lambda '(a) 
    (make-call (make-ref 'id)
     (make-lambda '(y) (make-ref 'y))
     (make-lambda '(b)
      (make-ref 'b)))))))

(define (main N e)
  (for ([a-k (in-range N)])
    (analyze e)))

(time (main 5 standard-example))