;;;; asmdb.lisp

;; todo[baggers]
;; - scc is always empty, that's wrong

(in-package #:asmdb)

(defclass |io| ()
  (|AC|
   |AF|
   |C0|
   |C1|
   |C2|
   |C3|
   |CF|
   |DF|
   |IF|
   |MSR|
   |MXCSR|
   |OF|
   |PF|
   |SD|
   |SF|
   |TF|
   |XCR|
   |ZF|))

(defclass |ext| ()
  (|3DNOW|
   |3DNOW2|
   |ADX|
   |AESKLE|
   |AESNI|
   |AMX_AVX512|
   |AMX_BF16|
   |AMX_COMPLEX|
   |AMX_FP16|
   |AMX_FP8|
   |AMX_INT8|
   |AMX_MOVRS|
   |AMX_TF32|
   |AMX_TILE|
   |AMX_TRANSPOSE|
   |APX_F|
   |AVX|
   |AVX10_2|
   |AVX2|
   |AVX512_BF16|
   |AVX512_BITALG|
   |AVX512_BW|
   |AVX512_CD|
   |AVX512_DQ|
   |AVX512_F|
   |AVX512_FP16|
   |AVX512_IFMA|
   |AVX512_VBMI|
   |AVX512_VBMI2|
   |AVX512_VL|
   |AVX512_VNNI|
   |AVX512_VP2INTERSECT|
   |AVX512_VPOPCNTDQ|
   |AVX_IFMA|
   |AVX_NE_CONVERT|
   |AVX_VNNI|
   |AVX_VNNI_INT16|
   |AVX_VNNI_INT8|
   |BMI|
   |BMI2|
   |CET_IBT|
   |CET_SS|
   |CLDEMOTE|
   |CLFLUSH|
   |CLFLUSHOPT|
   |CLWB|
   |CLZERO|
   |CMOV|
   |CMPCCXADD|
   |CMPXCHG16B|
   |CMPXCHG8B|
   |ENQCMD|
   |F16C|
   |FMA|
   |FMA4|
   |FPU|
   |FSGSBASE|
   |FXSR|
   |GEODE|
   |GFNI|
   |HRESET|
   |I486|
   |INVLPGB|
   |KL|
   |LAHFSAHF|
   |LWP|
   |LZCNT|
   |MCOMMIT|
   |MMX|
   |MMX2|
   |MONITOR|
   |MONITORX|
   |MOVBE|
   |MOVDIR64B|
   |MOVDIRI|
   |MOVRS|
   |MPX|
   |MSR|
   |MSRLIST|
   |MSR_IMM|
   |OSPKE|
   |PCLMULQDQ|
   |PCONFIG|
   |POPCNT|
   |PREFETCHI|
   |PREFETCHW|
   |PREFETCHWT1|
   |PTWRITE|
   |RAO_INT|
   |RDPID|
   |RDPRU|
   |RDRAND|
   |RDSEED|
   |RDTSC|
   |RDTSCP|
   |RMPQUERY|
   |RTM|
   |SEAM|
   |SERIALIZE|
   |SEV_ES|
   |SEV_SNP|
   |SHA|
   |SHA512|
   |SKINIT|
   |SM3|
   |SM4|
   |SMAP|
   |SMX|
   |SSE|
   |SSE2|
   |SSE3|
   |SSE4A|
   |SSE4_1|
   |SSE4_2|
   |SSSE3|
   |SVM|
   |TBM|
   |TSE|
   |TSXLDTRK|
   |UINTR|
   |USER_MSR|
   |VAES|
   |VMX|
   |VPCLMULQDQ|
   |WAITPKG|
   |WBNOINVD|
   |WRMSRNS|
   |XOP|
   |XSAVE|
   |XSAVEC|
   |XSAVEOPT|
   |XSAVES|))

(defclass |alias| ()
  (|primaryName|
   |aliasNames|
   |format|))

(defclass |category| ()
  (|AMX|
   |AVX|
   |AVX10_2|
   |AVX512|
   |CRYPTO_HASH|
   |FPU|
   |GP|
   |GP_EXT|
   |GP_IN_OUT|
   |MASK|
   |MMX|
   |SIMD|
   |SSE|
   |STATE|
   |SYSTEM|
   |VIRTUALIZATION|))

(defclass |prefixes| ()
  (|bnd|
   |ilock|
   |lock|
   |repIgnore|
   |repne|
   |rep|
   |xacqrel|
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
  (|byte|  ;; opcode byte (a single value specified in hex
   |ri|    ;; Indicates if the opcode is combined with a register, "XX+r" or "XX+i"
   |_67h|  ;; Indicates if the opcode uses the 67h prefix
   |mm|    ;; opcode MM[MMM] part (map) - see below for my guess at mm values' meanings
   |pp|    ;; opcode PP part - "66", "66F2", "66F3", "9B", "F2", "F3", or "NP"
   |w|     ;; opcode W field - "W0", "W1", or "WIG" (WIG means 'W ignored')
   |l|     ;; EVEX.LL - "128", "256", "512", "LIG", "xy", or "xyz"
   |nd|    ;; EVEX.ND (APX new destionation) - 0 or T
   |nf|    ;; EVEX.NF (no flags. I think APX, avoids writing to flags, nice) - 0 or T
   |scc|   ;; ===== MISSING ===== Not sure why. Original json suggests it should be there, but isa export doesnt have it
   |mod|   ;; contraints on modrm.mod - "!(11)", "11", or "xx"
   |modr|  ;; "0", "1", "2", "3", "4", "5", "6", "7", or "r"
   |modm|  ;;  "b" or unbound
   |modrm| ;;  "", "0", "2", "3", "4", or "b"
   ))

;;;; |mod| guessed info
;;
;; "!(11)" modrm.mod constrained to anything except 11
;; "11"    modrm.mod constrained to 11
;; "xx"    modrm.mod unconstrained

;;;; |mm| guessed info
;;
;;"0F" - legacy 2 byte opcodes
;;"0F01"
;;"0F38" - legacy 3 byte opcodes
;;"0F3A" - legacy 3 byte opcodes
;;
;;"D8" -
;;"D9"  |
;;"DA"  |
;;"DB"  |- probably fp related
;;"DC"  |
;;"DD"  |
;;"DE"  |
;;"DF" -
;;
;;"MAP4" -
;;"MAP5"  |
;;"MAP6"  |
;;"MAP7"  |- avx, xop, apx
;;"MAP8"  |
;;"MAP9"  |
;;"MAPA" -

;;;; |pp| guessed info
;;
;; "66" - operand size prefix |
;; "F2" - repeat ne prefix    |<-- true but also could be simd prefix
;; "F3" - repeat prefix       |
;; "66F2" - combinations?
;; "66F3" - combinations?
;; "9B" - ?
;; "NP" - no prefix

(defparameter *x64*
  (let ((cl-json:*json-identifier-name-to-lisp* #'identity))
	 (cl-json:with-decoder-simple-clos-semantics
	   (cl-json:decode-json-from-string
	    (uiop:read-file-string
             (asdf:system-relative-pathname :asmdb "jsonifiedISA.json"))))))



;; (maphash (lambda (k v)
;; 	   (loop for x across v
;; 		 for i from 0
;; 		 do (let* ((op (slot-value x '|opcode|))
;; 			   (field '|pp|)
;; 			   (it (when (slot-boundp op field)
;; 				 (slot-value op field))))
;; 		      (when (and it (not (equal it "")))
;; 			(format t "~%~s[~s]: ~s" k i it)))))
;; 	 (gethash '|_instructionMap| *x64*))


;; (let ((horse (make-hash-table :test #'equal)))
;;   (maphash (lambda (k v)
;; 	     k
;; 	     (loop for x across v
;; 		   for i from 0
;; 		   do (let* ((op (slot-value x '|opcode|))
;; 			     (field '|pp|)
;; 			     (it (when (slot-boundp op field)
;; 				   (slot-value op field))))
;; 		        (when (and it (not (equal it "")))
;;                           (setf (gethash it horse) 1)))))
;; 	   (gethash '|_instructionMap| *x64*))
;;   (maphash (lambda (k v) v (print k)) horse))
