(import urn/backend/writer writer)
(import urn/documentation doc)
(import urn/range (get-source format-position))
(import urn/resolve/scope scope)
(import urn/resolve/builtins (builtins))

(import lua/table table)

(defun format-range (range)
  "Format a range."
  :hidden
  (string/format "%s:%s" (.> range :name) (format-position (.> range :start))))

(defun sort-vars! (list)
  "Sort a list of variables"
  :hidden
  (table/sort list (lambda (a b)
                        (< (car a) (car b)))))

(defun format-definition (var)
  "Format a variable VAR, including it's kind and the position it was defined at."
  :hidden
  (with (ty (type var))
    (cond
      [(= ty "builtin")
       "Builtin term"]
      [(= ty "macro")
       (.. "Macro defined at " (format-range (get-source (.> var :node))))]
      [(= ty "native")
       (.. "Native defined at " (format-range (get-source (.> var :node))))]
      [(= ty "defined")
       (.. "Defined at " (format-range (get-source (.> var :node))))])))

(defun format-signature (name var)
  "Attempt to extract the function signature from VAR"
  :hidden
  (with (sig (doc/extract-signature var))
    (cond
      [(= sig nil) name]
      [(empty? sig)
       (.. "(" name ")")]
      [true
        (.. "(" name " " (concat (map (cut get-idx <> "contents") sig) " ") ")")])))

(defun write-docstring (out str scope)
  (for-each tok (doc/parse-docstring str)
    (with (ty (type tok))
      (cond
        [(= ty "text") (writer/append! out (.> tok :contents))]
        [(= ty "boldic") (writer/append! out (.> tok :contents))]
        [(= ty "bold") (writer/append! out (.> tok :contents))]
        [(= ty "italic") (writer/append! out (.> tok :contents))]
        [(= ty "arg")  (writer/append! out (.. "`" (.> tok :contents) "`"))]
        [(= ty "mono") (writer/append! out (.> tok :whole))]
        [(= ty "link")
         (let* [(name (.> tok :contents))
                (ovar (scope/get scope name))]
           (if (and ovar (.> ovar :node))
             (let* [(loc (-> (.> ovar :node)
                             get-source
                             (.> <> :name)
                             (string/gsub <> "%.lisp$" "")
                             (string/gsub <> "/" ".")))
                    (sig (doc/extract-signature ovar))
                    (hash (cond
                            [(= sig nil) (.> ovar :name)]
                            [(empty? sig) (.> ovar :name)]
                            [true (.. name " " (concat (map (cut get-idx <> "contents") sig) " "))]))]
               (writer/append! out (string/format "[`%s`](%s.md#%s)" name loc (string/gsub hash "%A+" "-"))))
             (writer/append! out (string/format "`%s`" name))))])))
  (writer/line! out))

(defun exported (out title primary vars scope)
  "Print out a list of all exported variables"
  (let* [(documented '())
         (undocumented '())]
    (iter-pairs vars (lambda (name var)
                       (push-cdr!
                         (if (.> var :doc) documented undocumented)
                         (list name var))))

    (sort-vars! documented)
    (sort-vars! undocumented)

    (writer/line! out "---")
    (writer/line! out (.. "title: " title))
    (writer/line! out "---")

    (writer/line! out (.. "# " title))
    (when primary
      (write-docstring out primary scope)
      (writer/line! out "" true))

    (for-each entry documented
      (let* [(name (car entry))
             (var  (nth entry 2))]

        (writer/line! out (.. "## `" (format-signature name var) "`"))
        (writer/line! out (.. "*" (format-definition var) "*"))
        (writer/line! out "" true)

        (when (.> var :deprecated)
          (writer/line! out
            (if (string? (.> var :deprecated))
              (string/format "> **Warning:** %s is deprecated: %s" name (.> var :deprecated))
              (string/format "> **Warning:** %s is deprecated." name)))
          (writer/line! out "" true))


        (write-docstring out (.> var :doc) (.> var :scope))
        (writer/line! out "" true)))

    (unless (empty? undocumented)
      (writer/line! out "## Undocumented symbols"))
    (for-each entry undocumented
       (let* [(name (car entry))
             (var  (nth entry 2))]
         (writer/line! out (.. " - `" (format-signature name var) "` *" (format-definition var) "*"))))))
