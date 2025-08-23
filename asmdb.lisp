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
   (uiop:read-file-string "~/quicklisp/local-projects/horse/x64.json")))

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
          (list :arch arch
                :instruction
                (append (list :prefixes (parse-prefixes prefixes-str))
                        (list :instruction-name instruction-name)
                        (cons :operands (parse-operands operands-str)))
                :encoding (parse-encoding op)
                :io (parse-io io)
                :alt alt))))))

(defun parse-prefixes (prefixes-str)
  (let* ((plen (length prefixes-str)))
    (cl-ppcre:split "\\|"
                    (subseq prefixes-str (min 1 plen) (max 0 (- plen 2))))))

(defun parse-operands (operands-str)
  (mapcar #'parse-operand (cl-ppcre:split ", *" operands-str)))

(defun parse-operand (operand-str)
  (multiple-value-bind (operand-str wip) (split-left #\( operand-str)
    (let ((bar (when wip (subseq wip 0 (1- (length wip))))))
      (multiple-value-bind (access-str places)
          (split-right #\: operand-str)
        (list (parse-operand-access access-str)
              (handler-case (parse-integer places)
                (error () (parse-operand-places places)))
              bar)))))

(defun split-left (char str)
  (let ((pos (position char str :test #'char=)))
    (if pos
        (values (subseq str 0 pos)
                (subseq str (1+ pos)))
        (values str nil))))

(defun split-right (char str)
  (let ((pos (position char str :test #'char=)))
    (if pos
        (values (subseq str 0 pos)
                (subseq str (1+ pos)))
        (values nil str))))


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

(defparameter *registers*
  '(("al" . :al)
    ("cl" . :cl)
    ("dl" . :dl)
    ("bl" . :bl)
    ("ah" . :ah)
    ("ch" . :ch)
    ("dh" . :dh)
    ("bh" . :bh)
    ("ax" . :ax)
    ("cx" . :cx)
    ("dx" . :dx)
    ("bx" . :bx)
    ("sp" . :sp)
    ("bp1" . :bp1)
    ("si" . :si)
    ("di" . :di)
    ("eax" . :eax)
    ("ecx" . :ecx)
    ("edx" . :edx)
    ("ebx" . :ebx)
    ("esp" . :esp)
    ("ebp" . :ebp)
    ("esi" . :esi)
    ("edi" . :edi)
    ("rax" . :rax)
    ("rcx" . :rcx)
    ("rdx" . :rdx)
    ("rbx" . :rbx)
    ("rsp" . :rsp)
    ("rbp" . :rbp)
    ("rsi" . :rsi)
    ("rdi" . :rdi)
    ("mm0" . :mm0)
    ("mm1" . :mm1)
    ("mm2" . :mm2)
    ("mm3" . :mm3)
    ("mm4" . :mm4)
    ("mm5" . :mm5)
    ("mm6" . :mm6)
    ("mm7" . :mm7)
    ("xmm0" . :xmm0)
    ("xmm1" . :xmm1)
    ("xmm2" . :xmm2)
    ("xmm3" . :xmm3)
    ("xmm4" . :xmm4)
    ("xmm5" . :xmm5)
    ("xmm6" . :xmm6)
    ("xmm7" . :xmm7)
    ("ymm0" . :ymm0)
    ("ymm1" . :ymm1)
    ("ymm2" . :ymm2)
    ("ymm3" . :ymm3)
    ("ymm4" . :ymm4)
    ("ymm5" . :ymm5)
    ("ymm6" . :ymm6)
    ("ymm7" . :ymm7)
    ("zmm0" . :zmm0)
    ("zmm1" . :zmm1)
    ("zmm2" . :zmm2)
    ("zmm3" . :zmm3)
    ("zmm4" . :zmm4)
    ("zmm5" . :zmm5)
    ("zmm6" . :zmm6)
    ("zmm7" . :zmm7)
    ("cs" . :cs)
    ("ds" . :ds)
    ("ss" . :ss)
    ("es" . :es)
    ("fs" . :fs)
    ("gs" . :gs)))

(defparameter *operand-places*
  (append *registers*
          '(("r8" . :r8)
            ("r16" . :r16)
            ("r32" . :r32)
            ("r64" . :r64)
            ("mm" . :mm)
            ("xmm" . :xmm)
            ("ymm" . :ymm)
            ("zmm" . :zmm)
            ("k" . :k)
            ("tmm" . :tmm)
            ("creg" . :creg)
            ("dreg" . :dreg)
            ("sreg" . :sreg)
            ("st" . :st)
            ("rip" . :rip)
            ("bnd" . :bnd)
            ("mem" . :mem)
            ("m8-m512" . :m8-m512)
            ("m8" :m8)
            ("m16" :m16)
            ("m32" :m32)
            ("m64" :m64)
            ("imm4" . :imm4)
            ("imm8" . :imm8)
            ("imm16" . :imm16)
            ("imm32" . :imm32)
            ("imm64" . :imm64)
            ("imms8" . :imms8)
            ("immu8" . :immu8)
            ("immu16" . :immu16)
            ("imms32" . :imms32)
            ("immu32" . :immu32)
            ("rel8" . :rel8)
            ("rel16" . :rel16)
            ("rel32" . :rel32)
            ("ry" . :ry)
            ("my" . :my)
            ("rv" . :rv)
            ("mv" . :mv)
            ("immv" . :immv)
            ("dxv" . :dxv)
            ("xy" . :xy)
            ("xyz" . :xyz)
            ("xxx" . :xxx)
            ("xxy" . :xxy)
            ("mxy" . :mxy)
            ("mxxx" . :mxxx)
            ("mxxy" . :mxxy)
            ("mxyz" . :mxyz)
            ("axv" . :axv)
            ("m16_16" . :m16_16)
            ("m16_32" . :m16_32)
            ("m16_64" . :m16_64)
            ("moff8" . :moff8)
            ("moff16" . :moff16)
            ("moff32" . :moff32)
            ("moff64" . :moff64)

            )))


(defparameter *operand-access*
  '(("R" . :read)
    ("W" . :write)
    ("w" . :write-part)
    ("X" . :read-write)
    ("x" . :read-write-part)))


(defun parse-operand-access (str)
  (or (cdr (assoc (or str "R") *operand-access* :test #'equal))
      (error "no dice")))

(defun parse-operand-place (str)
  (let* ((commutative (char= (aref str 0) #\~))
         (str (if commutative (subseq str 1) str))
         (implicit (char= (aref str 0) #\<))
         (str (if implicit (subseq str 1 (1- (length str))) str)))
    (vector
     (or (cdr (assoc str *operand-places* :test #'equal))
         (error "no doice"))
     :commutative commutative
     :implicit implicit)))

(defun parse-operand-places (str)
  (mapcar #'parse-operand-place
          (uiop:split-string str :separator '(#\/))))
