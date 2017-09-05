(import urn/analysis/nodes (builtins builtin? zip-args))
(import urn/analysis/pass ())
(import urn/analysis/usage usage)
(import urn/logger logger)

(defun transform (nodes transformers lookup)
  "Transform a list of NODES using the given TRANSFORMERS.

   TRANSFORMERS should be a struct with the following fields: `:pre`,
   `:post`, `:pre-block`, `:post-block`, `:pre-bind`, `:post-bind`. Each
   of these should be a list of functions, which accept a node as input
   and return the modified node.

   Each time a symbol or list is visited, all `:pre` transformers are
   applied, the child nodes are transformed, and then all `:post` nodes
   are visited on the modified node.

   The `:*-bind` transformers will be invoked when hitting a directly
   called lambda. These will be passed the *outer* node as an
   argument. Normal traversal of the lambda node will not occur, with
   just the body and arguments being visited instead.

   The `:*-block` nodes are called on lambda bodies, conditions and the
   top level - anywhere where all nodes will need to be transformed.

   The return value of these block and bind transformers is ignored. One
   should directly mutate the provide node.

   The `:post-*` transformers are invoked in reverse order to the
   `:pre-*` ones, following a LFIO sequence.

   Usage information generated by [[usage/tag-usage]] should also be
   provided in LOOKUP, so definitions can be reassigned correctly."
  (letrec [(pre        (.> transformers :pre))
           (post       (.> transformers :post))
           (pre-block  (.> transformers :pre-block))
           (post-block (.> transformers :post-block))
           (pre-bind   (.> transformers :pre-bind))
           (post-bind  (.> transformers :post-bind))

           (transform-quote
             (lambda (node level)
               (if (= level 0)
                 (transform-node node)
                 (with (tag (type node))
                   (cond
                     [(or (= tag "string") (= tag "number") (= tag "key") (= tag "symbol"))]
                     [(= tag "list")
                      (with (first (nth node 1))
                        (if (and first (symbol? first))
                          (cond
                            [(or (= (.> first :contents) "unquote") (= (.> first :contents) "unquote-splice"))
                             (.<! node 2 (transform-quote (nth node 2) (pred level)))]
                            [(= (.> first :contents) "syntax-quote")
                             (.<! node 2 (transform-quote (nth node 2) (succ level)))]
                            [else
                             (for i 1 (n node) 1
                               (.<! node i (transform-quote (nth node i) level)))])
                          (for i 1 (n node) 1
                            (.<! node i (transform-quote (nth node i) level)))))]
                     [else (error! (.. "Unknown tag " tag))])
                   node))))

           (transform-node
             (lambda (node)
               (for-each visitor pre (set! node (visitor node)))
               (case (type node)
                 ["string"]
                 ["number"]
                 ["key"]
                 ["symbol"]

                 ["list"
                  (with (head (car node))
                    (case (type head)
                      ["symbol"
                       (with (func (.> head :var))
                         (cond
                           [(/= (.> func :kind) "builtin")
                            (for i 1 (n node) 1
                              (.<! node i (transform-node (nth node i))))]

                           [(= func (.> builtins :lambda))
                            (for-each visitor pre-block (visitor node 3))
                            (for i 3 (n node) 1
                              (.<! node i (transform-node (nth node i))))
                            (for-each visitor post-block (visitor node 3))]

                           [(= func (.> builtins :cond))
                            (for i 2 (n node) 1
                              (with (branch (nth node i))
                                (.<! branch 1 (transform-node (nth branch 1)))

                                (for-each visitor pre-block (visitor branch 2))
                                (for i 2 (n branch) 1
                                  (.<! branch i (transform-node (nth branch i))))
                                (for-each visitor post-block (visitor branch 2))))]

                           ;; When iterating over set!, make sure to replace the definition with the
                           ;; new one. As this is an expensive operation, we only do this if changed.
                           [(= func (.> builtins :set!))
                            (let* [(old (nth node 3))
                                   (new (transform-node old))]
                              (when (/= old new)
                                (usage/replace-definition! lookup (.> (nth node 2) :var) old "val" new)
                                (.<! node 3 new)))]

                           [(= func (.> builtins :quote))]

                           [(= func (.> builtins :syntax-quote)) (.<! node 2 (transform-quote (nth node 2) 1))]

                           [(or (= func (.> builtins :unquote)) (= func (.> builtins :unquote-splice)))
                            (fail! "unquote/unquote-splice should never appear head")]

                           [(or (= func (.> builtins :define)) (= func (.> builtins :define-macro)))
                            (let* [(len (n node))
                                   (old (nth node len))
                                   (new (transform-node old))]
                              (when (/= old new)
                                (usage/replace-definition! lookup (.> node :def-var) old "val" new)
                                (.<! node len new)))]

                           [(= func (.> builtins :define-native))]
                           [(= func (.> builtins :import))]
                           [(= func (.> builtins :struct-literal))
                            (for i 1 (n node) 1
                              (.<! node i (transform-node (nth node i))))]
                           [else (fail! (.. "Unknown variable " (.> func :name)))]))]
                      ["list"
                       (if (builtin? (car head) :lambda)
                         (progn
                           (for-each visitor pre-bind (visitor node))

                           (with (val-i 2)
                             (for-each zipped (zip-args (nth head 2) 1 node 2)
                               (let [(args (car zipped))
                                     (vals (cadr zipped))]
                                 (if (and (= (n args) 1) (= (n vals) 1) (not (.> (car args) :var :is-variadic)))
                                   ;; If we've just got one argument and one value then we'll have defined it,
                                   ;; so it can be replaced.
                                   (let* [(old (car vals))
                                          (new (transform-node old))]
                                     (when (/= old new)
                                       (usage/replace-definition! lookup (.> (car args) :var) old "val" new)
                                       (.<! node val-i new))
                                     (inc! val-i))
                                   ;; Otherwise just visit each variable
                                   (for-each val vals
                                     (.<! node val-i (transform-node val))
                                     (inc! val-i))))))

                           (for-each visitor pre-block (visitor head 3))
                           (for i 3 (n head) 1
                             (.<! head i (transform-node (nth head i))))
                           (for-each visitor post-block (visitor head 2))

                           (for-each visitor post-bind (visitor node)))
                         (progn
                           (for i 1 (n node) 1
                             (.<! node i (transform-node (nth node i))))))]

                      [_
                       (for i 1 (n node) 1
                         (.<! node i (transform-node (nth node i))))]))])
               (for-each visitor post (set! node (visitor node)))
               node))]


    (for-each visitor pre-block (visitor nodes 1))
    (for i 1 (n nodes) 1
      (.<! nodes i (transform-node (nth nodes i))))
    (for-each visitor post-block (visitor nodes 1))))

(defun empty-transformers ()
  "An empty transformer state, in which nodes can be inserted."
  { :pre  '() :pre-block  '() :pre-bind  '()
    :post '() :post-block '() :post-bind '() })

(defpass transformer (state nodes lookup transformers)
  "Run the given TRANSFORMERS on the provides NODES with the given
   LOOKUP information."
  :cat '("opt" "usage")
  (let* [(trackers '())
         (trans-lookup (empty-transformers))]

    ;; Build a struct of transformers
    (for-each trans transformers
      (let* [(tracker (create-tracker))
             (run (.> trans :run))]
        (push-cdr! trackers tracker)

        (for-each cat (.> trans :cat)
          (when-with (group (string/match cat "^transform%-(.*)"))
            (unless (.> trans-lookup group)
              (error! (.. "Unknown category " cat " for " (.> trans :name))))
            (if (string/ends-with? group "-block")
              (push-cdr! (.> trans-lookup group)
                (lambda (node start) (run tracker state node start lookup)))
              (push-cdr! (.> trans-lookup group)
                (lambda (node) (run tracker state node lookup))))))))

    (transform nodes trans-lookup lookup)

    (for i 1 (n trackers) 1
      (changed! (.> (nth trackers i) :changed))
      (when (.> state :track)
        (logger/put-verbose! (.> state :logger)
          (sprintf "%s made %d changes"
            (.. "[" (concat (.> (nth transformers i) :cat) " ") "] " (.> (nth transformers i) :name))
            (.> (nth trackers i) :changed)))))))
