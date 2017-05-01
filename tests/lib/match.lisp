(import extra/test ())
(import extra/assert ())
(import lua/basic (pcall))

(describe "The matcher"
  (it "can match for a specified amount of list values"
    (affirm (eq? 2 (destructuring-bind [[?x ?y] '(1 2)] y))
            (eq? false (pcall (lambda () (destructuring-bind [[?x ?y] '(1 2 3)] y))))))
  (may "compile variable patterns"
    (destructuring-bind [(let* ((?value-sym ?value-val))
                           (if ?test (let* (as list? ?binds) .
                                       ?body)
                             (error (.. . ?failure))))
                         ((id destructuring-bind) '(?x y) '(print! x))]
      (will-not "compile a test"
        (affirm (eq? test 'true)))
      (will "compile a binding"
        (affirm (elem? 'x (cars binds))))
      (will "compile a binding to the correct value"
        (affirm (eq? (assoc binds 'x) value-sym)))
      (will "compile a failure indicating the pattern"
        (affirm (string/find (car failure) "?x")))
      (will "compile a failure referencing the binding"
        (affirm (elem? `(pretty ,value-sym) failure)))
      (will "include the body in the compiled result"
        (affirm (elem? '(print! x) body)))
      )))
