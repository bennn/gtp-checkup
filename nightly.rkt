#lang racket/base

(require
  basedir
  file/tar
  gtp-checkup
  gtp-util
  gtp-util/system
  racket/os
  racket/runtime-path
  racket/string
  racket/system)

;; =============================================================================

(define-runtime-path CWD ".")
(define SRC (writable-data-dir #:program "gtp-checkup"))
(define DATA "data")
(define RACKET "racket")
(define BIN "bin")
(define RACO "raco")
(define MAIN.rkt "main.rkt")
(define NIGHTLY.log "nightly.log")
(define BUILD.log "build-nightly.log")

(define PROGRAM 'nightly)

(module+ main
  (parameterize ((current-directory CWD))
    (define rkt-dir (download-racket))
    (unless (is-new-commit? rkt-dir)
      (raise-user-error PROGRAM "data for today already exists"))
    (unless (install-racket rkt-dir)
      (raise-user-error PROGRAM "failed to install racket, see log in '~a'" BUILD.log))
    (unless (install-gtp-checkup rkt-dir)
      (raise-user-error PROGRAM "failed to install gtp-checkup, see log in '~a'" BUILD.log))
    (run-checkup rkt-dir)
    (save-results rkt-dir)))

;; -----------------------------------------------------------------------------

(define (download-racket)
  (define today (timestamp #false))
  (define rkt-dir (build-path SRC today))
  (when (directory-exists? rkt-dir)
    (raise-user-error PROGRAM "directory for today already exists (~a), goodbye" today))
  (unless (system (format "git clone https://github.com/racket/racket ~a"
                          (path-string->string rkt-dir)))
    (raise-user-error PROGRAM "git clone <RACKET> failed, sorry"))
  rkt-dir)

(define (is-new-commit? rkt-dir)
  (define commit-file (directory->data-path rkt-dir))
  (not (file-exists? commit-file)))

(define (install-racket rkt-dir)
  (with-output-to-file BUILD.log #:exists 'replace
    (lambda ()
      (parameterize ((current-directory rkt-dir)
                     (current-error-port (current-output-port)))
        (system "make")))))

(define (install-gtp-checkup rkt-dir)
  (with-output-to-file BUILD.log #:exists 'append
    (lambda ()
      (parameterize ((current-directory CWD)
                     (current-error-port (current-output-port)))
        (system* (build-path rkt-dir RACKET BIN RACO) "pkg" "install" "--auto")))))

(define (run-checkup rkt-dir)
  (write-pkg-table rkt-dir)
  (define bin-dir (build-path rkt-dir RACKET BIN))
  (gtp-checkup bin-dir #:iterations 10))

(define (write-pkg-table rkt-dir)
  (system* (build-path rkt-dir RACKET BIN RACKET)
           "--eval"
           "(begin (require pkg/lib) (writeln (installed-pkg-table #:scope (quote installation))))"))

(define (save-results rkt-dir)
  (define commit-file (directory->data-path rkt-dir))
  (unless (file-exists? NIGHTLY.log)
    (raise-argument-error 'save-results "file-exists?" NIGHTLY.log))
  (copy-file (build-path CWD NIGHTLY.log) commit-file)
  (with-output-to-file BUILD.log #:exists 'append
    (lambda ()
      (parameterize ((current-error-port (current-output-port)))
        (shell "git" (list "add" (path-string->string commit-file)))
        (define commit-msg
          (format "data/~a: snapshot" (find-machine-name)))
        (shell "git" (list "commit" "-m" commit-msg))
        (shell "git" (list "pull" "-r" "upstream" "master"))
        (shell "git" (list "push" "upstream" "master")))))
  (void))

(define (directory->HEAD dir)
  (parameterize ((current-directory dir))
    (shell "git" '("rev-parse" "HEAD"))))

(define (find-machine-data-dir)
  (define machine-name (find-machine-name))
  (or (for/or ((transform (in-list (list values string-downcase  string-upcase))))
        (define m-dir (build-path CWD DATA (transform machine-name)))
        (and (directory-exists? m-dir)
             m-dir))
      (raise-user-error PROGRAM "failed to find data directory for machine '~a'" machine-name)))

(define (find-machine-name)
  (gethostname))

(define (hash->timestamp hash dir)
  (timestamp-pretty (hash->raw-timestamp hash dir)))

(define (hash->raw-timestamp hash dir)
  (parameterize ((current-directory dir))
    (shell "git" (list "log" "--no-walk" "--pretty=format:'%ci'" hash))))

(define (timestamp-pretty str)
  (define str* (string-split (string-replace (string-trim str) "'" "")))
  (unless (= 3 (length str*))
    (raise-argument-error 'timestamp-remove-spaces "(list str str str)" str*))
  (string-append (car str*) "T" (cadr str*) "Z" (caddr str*)))

(define (directory->data-filename dir)
  (define hash (directory->HEAD dir))
  (define ts (hash->timestamp hash dir))
  (make-new-data-filename hash ts))

(define (make-new-data-filename h t)
  (format "~a_~a.txt" t h))

(define (directory->data-path rkt-dir)
  (define rkt-filename (directory->data-filename rkt-dir))
  (define machine-data-dir (find-machine-data-dir))
  (build-path machine-data-dir rkt-filename))
