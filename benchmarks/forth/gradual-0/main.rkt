#lang typed/racket/base

(require
  "../base/command-types.rkt")
(require/typed "eval.rkt"
  (forth-eval* (-> Input-Port (Values Any Any)))
)

;; =============================================================================

(define (main)
  (call-with-input-file* (ann "../base/history.txt" Path-String)
    (lambda ([p : Input-Port])
      (let-values ([(_e _s) (forth-eval* p)]) (void))))
  (void))

(time (main))
