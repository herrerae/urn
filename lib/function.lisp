(import base (defmacro defun with for when if and or
              get-idx gensym unpack =))
(import binders (let))
(import list (for-each push-cdr! any map traverse))
(import type (symbol? list? function? table?))
(import table (.> getmetatable))
(import lua/os (clock))

;; Checks if this symbol is a wildcard
(defun slot? (symb)
  "Test whether SYMB is a slot. For this, it must be a symbol, whose contents
   are `<>`."
  (and (symbol? symb) (= (get-idx symb "contents") "<>")))

;; Partially apply a function, where <> is replaced by an argument to a function.
;; Values are evaluated every time the resulting function is called.
(defmacro cut (&func)
  (let [(args '())
        (call '())]
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

;; Predicate for determining whether something can safely be invoked, that is,
;; be at `car` position on an unquoted list.
(defun invokable? (x)
  "Test if the expression X makes sense as something that can be applied to a set
   of arguments.

   Example:
   ```
   > (invokable? invokable?)
   true
   > (invokable? nil)
   false
   > (invokable? (setmetatable (empty-struct) (struct :__call (lambda (x) (print! \"hello\")))))
   true
   ```"
  (or (function? x)
      (and (table? x)
           (table? (getmetatable x))
           (function? (.> (getmetatable x) :__call)))))

(defun compose (f g)
  "Return the pointwise composition of functions F and G. This corresponds to
   the mathematical operator `∘`, i.e. `(compose f g)` corresponds to
   `h(x) = f (g x)` (`(lambda (x) (f (g x)))`)."
  (if (and (invokable? f)
           (invokable? g))
    (lambda (x) (f (g x)))
    nil))
