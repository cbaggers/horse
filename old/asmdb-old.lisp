
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

(defun trim (str)
  (string-trim '(#\space #\tab) str))

(defun string-prefix-p (prefix str)
  (let ((prefix-len (length prefix)))
    (and (>= (length str) prefix-len)
         (string= str prefix :end1 prefix-len :end2 prefix-len))))

(defmacro string-case (form &body cases)
  (let ((var (gensym "form")))
    `(let ((,var ,form))
       (cond
         ,@(loop
             for (match . rest) in cases
             collect
             (cond
               ((and (listp match)
                     (= (length match) 2)
                     (eq (first match) :starts)
                     (stringp (second match)))
                (let ((len (length (second match))))
                  `((and
                     (>= (length ,var) ,len)
                     (string= ,var ,(second match) :end1 ,len :end2 ,len))
                    ,@rest)))
               ((eq match 'cl:otherwise)
                `(t ,@rest))
               ((not (stringp match))
                (error "invalid string-case match ~s" match))
               (t
                `((string= ,var ,match) ,@rest))))))))

(defparameter *foo*
  (cl-json:decode-json-from-string
   (uiop:read-file-string "~/quicklisp/local-projects/horse/x64.json")))

(defparameter *instructions*
  (assoc :instructions *foo*))

(defparameter *example*
  (assocr :instructions (nth 3 *instructions*)))

(defun try-stuff (n)
  (mapcar #'process-thing
          (assocr :instructions (nth n *instructions*))))

(defun coverage-check ()
  (loop for x in *instructions*
        for i from 0
        collect (handler-case
                    (let ((instrs (assocr :instructions x)))
                      (if instrs
                          (handler-case
                              (progn (mapcar #'process-thing instrs)
                                     (list i :success))
                            (error () (list i :some-failures)))
                          (error () (list i :wrong-layout-a))))
                  (error () (list i :wrong-layout-b)))))


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
  (let ((operand-str (trim operand-str)))
    (multiple-value-bind (operand-str wip) (split-left #\( operand-str)
      (let ((bar (when wip (subseq wip 0 (1- (length wip))))))
        (multiple-value-bind (access-str places)
            (split-right #\: operand-str)
          (list (parse-operand-access access-str)
                (handler-case (parse-integer places)
                  (error () (parse-operand-places places)))
                bar))))))


(defun parse-io (io-str)
  (loop for str in (uiop:split-string io-str)
        collect (loop for x in (uiop:split-string str :separator '(#\=))
                      collect
                      (handler-case (parse-integer x)
                        (error () (intern x :keyword))))))

(defun parse-encoding (op-str)
  ;; we consider the 'header' to be the bit in the square brackets
  ;; before the op info
  (multiple-value-bind (wip-header op-str) (split-right #\] op-str)
    (let* ((header (when wip-header
                     (subseq wip-header 1)))
           (rest-split (uiop:split-string (trim op-str))))
      (let* ((rex-w (equal (first rest-split) "REX.W"))
             (vex-prefix
               (when (string-prefix-p "VEX" (first rest-split))
                 (parse-vex-prefix (subseq (first rest-split) 4))))
             (evex-prefix
               (when (string-prefix-p "EVEX" (first rest-split))
                 (parse-evex-prefix (subseq (first rest-split) 5))))
             (rest-split (if (or rex-w vex-prefix evex-prefix)
                             (rest rest-split)
                             rest-split))
             (bytes-and-other (mapcar #'parse-op-part rest-split))
             (other-start (position-if #'keywordp bytes-and-other))
             (op-bytes (if other-start
                           (subseq bytes-and-other 0 other-start)
                           bytes-and-other))
             (other (when other-start
                      (subseq bytes-and-other other-start))))
        (list :header header
              :rex-w rex-w
              :vex-prefix vex-prefix
              :evex-prefix evex-prefix
              :op-bytes op-bytes
              :todo other)))))

(defun parse-vex-prefix (str)
  (multiple-value-bind (substr rest) (split-left #\. str)
    (cons
     (string-case substr
       ("ND=0" :nd0)
       ("ND=1" :nd1)
       ("256" :256)
       ("128" :128)
       ("LZ" :lz)
       ("L0" :l0)
       ("L1" :l1)
       ("LIG" :l-ignored)
       ("Lxy" :lxy)
       ("66" :66)
       ("F2" :f2)
       ("F3" :f3)
       ("0F" :0f)
       ("0F3A" :0f3a)
       ("0F38" :0f38)
       ("NP" :np)
       ("MAP5" :map5)
       ("MAP7" :map7)
       ("W0" :w0)
       ("W1" :w1)
       ("WIG" :w-ignored)
       ("Wy" :wy)
       (otherwise (error "unknown vex-prefix part ~s" substr)))
     (when rest (parse-vex-prefix rest)))))

(defun parse-evex-prefix (str)
  (multiple-value-bind (substr rest) (split-left #\. str)
    (cons
     (string-case substr
       ("ND=0" :nd0)
       ("ND=1" :nd1)
       ("128" :128)
       ("256" :256)
       ("512" :512)
       ("xyz" :xyz)
       ("LIG" :l-ignored)
       ("LLZ" :llz)

       ("0F" :0f)
       ("66" :66)
       ("F2" :f2)
       ("F3" :f3)
       ("NF=0" :nd0)
       ("NF=1" :nd1)
       ("SCC=0" :SCC=0)
       ("SCC=1" :SCC=1)
       ("SCC=2" :SCC=2)
       ("SCC=3" :SCC=3)
       ("SCC=4" :SCC=4)
       ("SCC=5" :SCC=5)
       ("SCC=6" :SCC=6)
       ("SCC=7" :SCC=7)
       ("SCC=8" :SCC=8)
       ("SCC=9" :SCC=9)
       ("SCC=A" :SCC=A)
       ("SCC=B" :SCC=B)
       ("SCC=C" :SCC=C)
       ("SCC=D" :SCC=D)
       ("SCC=E" :SCC=E)
       ("SCC=F" :SCC=F)

       ("0F3A" :0f3a)
       ("MAP4" :map4)
       ("MAP5" :map5)
       ("MAP6" :map6)
       ("MAP7" :map7)
       ("Pv" :pv)
       ("NP" :np)

       ("W0" :w0)
       ("W1" :w1)
       ("W?" :w?)
       ("0F38" :0f38)
       ("WIG" :w-ignored)
       ("Wy" :wy)
       ("Wv" :wv)
       (otherwise (error "unknown evex-prefix part ~s" substr)))
     (when rest (parse-evex-prefix rest)))))

(defun parse-op-part (x)
  (multiple-value-bind (a b) (split-left #\+ x)
    (handler-case
        (let ((i (parse-integer a :radix 16)))
          (declare (ignore i))
          (if b
              (list a (cond
                        ((equal b "r") :r)
                        (t (error "beans"))))
              a))
      (error () (parse-encoding-other x)))))

(defun parse-encoding-other (str)
  (string-case str
    ((:starts "/")
     (if (char= (aref str 1) #\r)
         (list :modrm-contains-register-and-rm-operand t)
         (let ((int (parse-integer (subseq str 1))))
           (list :only-use-rm int))))
    ("cw" :cw)
    ("ib" :ib)
    ("id" :id)
    ("iq" :iq)
    ("iv" :iv)
    ("iw" :iw)
    ("moff" :moff)
    ("NP" :no-prefix)
    (otherwise (error "blerp"))))

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
            ("m128" :m128)
            ("m256" :m256)
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
            ("moff64" . :moff64))))


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

(defun parse-place-operand-decorators (str)
  ;; this needs to find multiple
  (string-case str
    ("kz" :kz-masking)
    ("k" :k-masking)
    ("er" :er-embeded-rounding)
    (otherwise (error "unknown place operand decorator: ~s" str))))

(defun parse-operand-places (str)
  (multiple-value-bind (left right) (split-left #\{ str)
    (let ((str (if right (trim left) str))
          (decorators
            (when right
              (parse-place-operand-decorators (split-left #\} right)))))
      (list (mapcar #'parse-operand-place
                    (uiop:split-string str :separator '(#\/)))
            :decorators decorators))))
