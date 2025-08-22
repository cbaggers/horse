;;;; asmdb.lisp

(in-package #:asmdb)

(defun assocr (item alist)
  (cdr (assoc item alist)))

(defmacro with-aref ((&rest indices) array &body body)
  (let ((rest-pos (position-if (lambda (x) (equal (symbol-name x) "&REST"))
			       indices))
	(a (gensym)))
    (assert (or (null rest-pos) (= (- (length indices) rest-pos) 2)))
    (let ((indices-no-rest (if rest-pos
			       (subseq indices 0 rest-pos)
			       indices)))
      `(let ((,a ,array))
	 (declare (ignorable ,a))
	 (symbol-macrolet
             ,(append
	       (loop
		 for n from 0
		 for i in indices-no-rest
		 when (not (null i))
		   collect (list i `(aref ,a ,n)))
	       (when rest-pos
		 (list (list (nth (1+ rest-pos) indices)
			     `(subseq ,a ,rest-pos)))))
           ,@body)))))

(defparameter *foo*
  (cl-json:decode-json-from-string
   (uiop:read-file-string "~/quicklisp/local-projects/asmdb/x64.json")))

(defparameter *instructions*
  (assoc :instructions *foo*))

(defparameter *example*
  (assocr :instructions (second *instructions*)))

(defparameter *thing* (first *example*))


(defun process-thing (thing)
  (destructuring-bind ((arch . instruction-signature) &rest rest) thing
    (let* ((alt (assocr :alt rest))
	   (op (assocr :op rest))
	   (io (assocr :io rest)))

      (multiple-value-bind (str parts)
	  (ppcre:scan-to-strings "(\\[.*\\] +|)(\\w+) (.*)"
				 instruction-signature)
	(declare (ignore str))
	(with-aref (prefixes-str instruction-name operands-str)
		   (or parts (vector nil instruction-signature nil))
	  (list arch
		(cons (parse-prefixes prefixes-str)
		      (cons instruction-name
			    (parse-operands operands-str)))
		(parse-encoding op)
		(parse-io io)
		alt))))))

(defun parse-prefixes (prefixes-str)
  (let* ((plen (length prefixes-str)))
    (cl-ppcre:split "\\|"
		    (subseq prefixes-str (min 1 plen) (max 0 (- plen 2))))))

(defun parse-operands (operands-str)
  (mapcar #'parse-operand (cl-ppcre:split ", *" operands-str)))

(defun parse-operand (operand-str)
  (multiple-value-bind (str parts)
      (ppcre:scan-to-strings "(\\w+:)?([\\w|~]+/\\w+|\\w+)(\\(.*\\))?"
			     operand-str)
    (declare (ignore str))
    parts))


(defun parse-io (io-str)
  (loop for str in (uiop:split-string io-str)
	collect (loop for x in (uiop:split-string str :separator '(#\=))
		      collect
		      (handler-case (parse-integer x)
			(error () (intern x :keyword))))))

(defun parse-encoding (op-str)
  (let* ((header (when (eql #\[ (aref op-str 0))
		   (subseq op-str 0 4)))
	 (op-str (if header
		     (subseq op-str 4)
		     op-str)))
    (let* ((rest-split (uiop:split-string op-str))
	   (rex-w (equal (first rest-split) "REX.W"))
	   (rest-split (if rex-w
			   (rest rest-split)
			   rest-split)))
      (list header
	    rex-w
	    rest-split))))
