#lang racket/gui

;; Run this file is generate the images in the img/ directory, 
;; picked up by image-examples from image.scrbl

(require 2htdp/image
         lang/posn
         racket/runtime-path)

(define-runtime-path image.scrbl "image.scrbl")
(define-runtime-path img "img")

(define-namespace-anchor anchor)
(define ns (namespace-anchor->namespace anchor))
(define expressions
  (parameterize ([current-namespace ns])
    (putenv "PLTSHOWIMAGES" "show")
    (let-values ([(in out) (make-pipe)])
      (thread
       (λ () 
         (parameterize ([current-output-port out])
           (dynamic-require image.scrbl #f))
         (close-output-port out)))
      (let loop ()
        (let ([exp (read in)])
          (if (eof-object? exp)
              '()
              (cons exp (loop))))))))

(define-namespace-anchor image-anchor)
(define image-ns (namespace-anchor->namespace anchor))

(define mapping '())

(define (handle-image exp)
  (printf ".") (flush-output)
  (let ([result 
         (with-handlers ([(λ (x) #t)
                          (λ (x)
                            (printf "\nerror evaluating:\n")
                            (pretty-write exp)
                            (raise x))])
           (parameterize ([current-namespace image-ns])
             (rewrite (eval exp))))])
    (cond
      [(image? result)
       (let ([fn (exp->filename exp)])
         (set! mapping (cons `(list ',exp 'image ,fn) mapping))
         (let ([pth (build-path img fn)])
           (unless (save-image result pth)
             (fprintf (current-error-port) "failed to save ~s\n" pth))))]
      [else
       (unless (equal? result (read/write result))
         (error 'handle-image "expression ~s produced ~s, which I can't write"
                exp result))
       (set! mapping (cons `(list ',exp 'val ',result) mapping))])))

(define (rewrite exp)
  (let loop ([exp exp])
    (cond
      [(list? exp)
       `(list ,@(map loop exp))]
      [(color? exp)
       `(color ,(color-red exp)
               ,(color-green exp)
               ,(color-blue exp))]
      [else exp])))

(define (exp->filename exp)
  (let loop ([prev 0])
    (let ([candidate 
           (format "~a~a.png" 
                   (number->string (exp->number exp) 16)  ;; abs to avoid filenames beginning with hyphens
                   (if (zero? prev) 
                       ""
                       (format "-~a" (number->string prev 16))))])
      (cond
        [(anywhere? candidate mapping)
         (printf "dup!\n")
         (loop (+ prev 1))]
        [else
         candidate]))))

(define (anywhere? x sexp)
  (let loop ([sexp sexp])
    (cond
      [(pair? sexp) (or (loop (car sexp))
                        (loop (cdr sexp)))]
      [else (equal? x sexp)])))

;(define a-prime (- (expt 2 127) 1)) ;; Lucas found this in 1876. (too long filenames)
(define a-prime (/ (- (expt 2 59) 1) 179951)) ;; found by Landry in 1867
;(define a-prime 113) ;; has too many collisions
(define base 256)

(define (exp->number exp)
  (let ([digits (map char->integer (string->list (format "~s" exp)))])
    (when (ormap (λ (x) (not (<= 0 x (- base 1)))) digits)
      (error 'exp->number "found a char that was bigger than ~a in ~s" (- base 1) exp))
    (let loop ([n 1]
               [digits digits])
      (cond
        [(null? digits) (modulo n a-prime)]
        [else (loop (+ (car digits) (* n base))
                    (cdr digits))]))))

(define (read/write result)
  (let-values ([(in out) (make-pipe)])
    (thread (λ () (write result out) (close-output-port out)))
    (read in)))

(for-each handle-image expressions)
(cond
  [(null? mapping)
   (printf "image-gen: didn't find any images; probably this means that you need to delete .zo files and try again\n")]
  [else
   (printf "\n")
   (call-with-output-file "image-toc.rkt"
     (λ (port)
       (fprintf port "#lang racket/base\n(provide mapping)\n")
       (fprintf port ";; this file is generated by image-gen.ss -- do not edit\n;; note that the file that creates this file depends on this file\n;; it is always safe to simply define (and provide) mapping as the empty list\n\n")
       (pretty-write
        `(define mapping (list ,@mapping))
        port))
     #:exists 'truncate)])