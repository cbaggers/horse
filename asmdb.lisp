;;;; asmdb.lisp

(in-package #:asmdb)

(defclass |io| ()
  (|OF|
   |SF|
   |ZF|
   |AF|
   |PF|
   |CF|))

(defclass |ext| ()
  (|APX_F|))

(defclass |alias| ()
  (|aliasNames|
   |format|))

(defclass |category| ()
  (|GP|
   |GP_EXT|))

(defclass |prefixes| ()
  (|lock|
   |xacquire|
   |xrelease|))

(defclass |special-regs| () ())

(defclass |instruction| ()
  (|name|
   |arch|
   |encoding|
   |operands|
   |implicit|
   |commutative|
   |opcodeString|
   |opcodeValue|
   |fields|
   |operations|
   |io|
   |ext|
   |category|
   |specialRegs|
   |alt|
   |volatile|
   |control|
   |privilege|
   |aliasOf|
   |opcode|
   |prefix|
   |groupPattern|
   |groupIndex|
   |rel|
   |fpuTop|
   |fpuStack|
   |vsibReg|
   |vsibSize|
   |broadcast|
   |bcstSize|
   |k|
   |kmask|
   |zmask|
   |er|
   |sae|
   |tupleType|
   |elementSize|
   |encodingPreference|
   |consecutiveLead|
   |prefixes|
   |imm|
   ))

(defclass |operand| ()
  (|prototype|
   |type|
   |data|
   |flags|
   |reg|
   |mem|
   |imm|
   |rel|
   |restrict|
   |read|
   |write|
   |regType|
   |regIndexRel|
   |memSize|
   |immSign|
   |immValue|
   |rwxIndex|
   |rwxWidth|
   |groupPattern|
   |memSegment|
   |memOff|
   |memFar|
   |vsibReg|
   |vsibSize|
   |bcstSize|))

(defclass |opcode| ()
  (|byte|
   |ri|
   |_67h|
   |mm|
   |pp|
   |w|
   |l|
   |nd|
   |nf|
   |scc|
   |mod|
   |modr|
   |modrm|))

(defparameter *x64*
  (let ((cl-json:*json-identifier-name-to-lisp* #'identity))
	 (cl-json:with-decoder-simple-clos-semantics
	   (cl-json:decode-json-from-string
	    (uiop:read-file-string
             (asdf:system-relative-pathname :asmdb "jsonifiedISA.json"))))))
