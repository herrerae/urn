(import base (defmacro defun with for let when if and
              get-idx gensym
              ==))

(import list (for-each push-cdr! any map))
(import types (symbol? list?))

;; Checks if this symbol is a wildcard
(defun slot? (symb) (and (symbol? symb) (== (get-idx symb "contents") "<>")))

;; Partially apply a function, where <> is replaced by an argument to a function.
;; Values are evaluated every time the resulting function is called.
(defmacro cut (&func)
  (let ((args '())
        (call '()))
    (for-each item func
      (if (slot? item)
        (with (symb (gensym))
          (push-cdr! args symb)
          (push-cdr! call symb))
        (push-cdr! call item)))
    `(lambda ,args ,call)))

;; Partially apply a function, where <> is replaced by an argument to a function.
;; Values are evaluated when this function is defined.
(defmacro cute (&func)
  (let ((args '())
        (vals '())
        (call '()))
    (for-each item func
      (with (symb (gensym))
        (push-cdr! call symb)
        (if (slot? item)
          (push-cdr! args symb)
          (push-cdr! vals `(,symb ,item)))))
    `(let ,vals (lambda ,args ,call))))

;; Chain a series of method calls together.
;; If the list contains <> then the value is placed there, otherwise the expression is invoked
;; with the previous entry as an argument
(defmacro -> (x &funcs)
  (with (res x)
    (for-each form funcs
      (if (and (list? form) (any slot? form))
        (set! res (map (lambda (x) (if (slot? x) res x)) form))
        (set! res `(,form ,res))))
    res))