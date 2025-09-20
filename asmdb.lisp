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
  (|aliasOf|
   |alt|
   |arch|
   |bcstSize|
   |broadcast|
   |category|
   |commutative|
   |consecutiveLead|
   |control|
   |elementSize|
   |encodingPreference|
   |encoding|
   |er|
   |ext|
   |fields|
   |fpuStack|
   |fpuTop|
   |groupIndex|
   |groupPattern|
   |imm|
   |implicit|
   |io|
   |kmask|
   |k|
   |name|
   |opcodeString|
   |opcodeValue|
   |opcode|
   |operands|
   |operations|
   |prefixes|
   |prefix|
   |privilege|
   |rel|
   |sae|
   |specialRegs|
   |tupleType|
   |volatile|
   |vsibReg|
   |vsibSize|
   |zmask|))


(defclass |operand| ()
  (|type| ;; the type of operand - "reg", "reg/mem", "rel", "mem", or "mem/reg"
   |data| ;; the operand's data (possibly procesed) (see below for table)
   |flags| ;;  this is an int, that is an enum value. See the flags table below
   |reg| ;; register descriptor if appropriate. See below for reg table
   |mem| ;; memory descriptor if appropriate. See below for mem table
   |imm| ;; Size of immediate operand, if appropriate. 0 4 8 16 32 or 64
   |rel| ;; Size of relative displacement, if appropriate. 0 8 16 or 32
   |restrict| ;; operand is restricted (specific reg or value). Doesnt seem to be used in x86
   |read| ;; true if operand is a read op from reg/mem
   |write| ;; true if operand is a write op to reg/mem
   |regType| ;; register operand's type
   |regIndexRel| ;; 0 or 1. 1 means the register index is relative to the previous register operand index
   |memSize| ;; memory operand's size, if appropriate (-1 if not relevent). See below for values in json
   |immSign| ;; Required sign of immediate - "any", "signed", or "unsigned"
   |immValue| ;; this is rare. Its 1 if it's an immediate AND only for specific instructions (shift/rotate
   |rwxIndex| ;; read/write (RWX) index
   |rwxWidth| ;; read/write (RWX) width
   |groupPattern| ;; group pattern in case this operand was created from a group. e.g. "rv" "ry" "xy" "xyz"
   |memSegment| ;; segment specified with register that is used to perform a memory IO. "ds" or "es"
   |memOff| ;; T if this is a memory operand and uses an absolute offset
   |memFar| ;; T if memory is a far pointer (includes segment in first two bytes)
   |vsibReg| ;; AVX VSIB register type. "xmm" "ymm" or "zmm"
   |vsibSize| ;; AVX VSIB register type. 32, 64, or -1 (-1 means not applicable here)
   |bcstSize| ;; AVX-512 broadcast size. 16, 32, 64, or -1 (-1 means not applicable here)
   ))


;;;; flags table
;;
;; Optional
;; Implicit
;; Commutative
;; ZExt
;; ReadAccess
;; WriteAccess

;;;; RegType Table
;;
;; "r8"
;; "r16"
;; "r32"
;; "r64"
;; "sreg"
;; "creg"
;; "dreg"
;; "r8hi"
;; "bnd"
;; "st"
;; "mm"
;; "xmm"
;; "ymm"
;; "zmm"
;; "k"
;; "tmm"

;;;; x86 data values
;; "1"
;; "ah"
;; "al"
;; "ax"
;; "bnd"
;; "bnd/mem"
;; "cl"
;; "creg"
;; "cs"
;; "cx"
;; "dfv"
;; "dreg"
;; "ds"
;; "dx"
;; "eax"
;; "ebx"
;; "ecx"
;; "edx"
;; "es"
;; "fs"
;; "gs"
;; "imm16"
;; "imm32"
;; "imm4"
;; "imm64"
;; "imm8"
;; "imms32"
;; "imms8"
;; "immu16"
;; "immu32"
;; "k"
;; "k+1"
;; "k/m16"
;; "k/m32"
;; "k/m64"
;; "k/m8"
;; "m128"
;; "m16"
;; "m16_16"
;; "m16_32"
;; "m16_64"
;; "m16int"
;; "m256"
;; "m32"
;; "m32/r32"
;; "m32fp"
;; "m32int"
;; "m384"
;; "m512"
;; "m64"
;; "m64/r64"
;; "m64fp"
;; "m64int"
;; "m8"
;; "m80bcd"
;; "m80dec"
;; "m80fp"
;; "mem"
;; "mib"
;; "mm"
;; "mm/m32"
;; "mm/m64"
;; "moff16"
;; "moff32"
;; "moff64"
;; "moff8"
;; "r16"
;; "r16/m16"
;; "r32"
;; "r32/m16"
;; "r32/m32"
;; "r32/m8"
;; "r64"
;; "r64/m16"
;; "r64/m64"
;; "r8"
;; "r8/m8"
;; "rax"
;; "rbx"
;; "rcx"
;; "rdx"
;; "rel16"
;; "rel32"
;; "rel8"
;; "sreg"
;; "ss"
;; "st(0)"
;; "st(i)"
;; "tmem"
;; "tmm"
;; "tmm+1"
;; "vm32x"
;; "vm32y"
;; "vm32z"
;; "vm64x"
;; "vm64y"
;; "vm64z"
;; "xmm"
;; "xmm/m128"
;; "xmm/m16"
;; "xmm/m32"
;; "xmm/m64"
;; "xmm/m8"
;; "xmm0"
;; "ymm"
;; "ymm/m256"
;; "zmm"
;; "zmm/m512"

;;;; Reg Table
;;
;; "al"
;; "ax"
;; "eax"
;; "rax"
;; "r8"
;; "r16"
;; "r32"
;; "r64"
;; "edx"
;; "rdx"
;; "dx"
;; "cx"
;; "ecx"
;; "rcx"
;; "sreg"
;; "creg"
;; "dreg"
;; "ds"
;; "es"
;; "ss"
;; "fs"
;; "gs"
;; "cs"
;; "cl"
;; "ebx"
;; "rbx"
;; "ah"
;; "bnd"
;; "st(0)"
;; "st(i)"
;; "mm"
;; "xmm"
;; "xmm0"
;; "ymm"
;; "zmm"
;; "k"
;; "tmm"

;;;; Mem Table
;;
;; "m8"
;; "m16"
;; "m32"
;; "m64"
;; "m16_16"
;; "m16_32"
;; "m16_64"
;; "mem"
;; "moff8"
;; "moff16"
;; "moff32"
;; "moff64"
;; "m512"
;; "m128"
;; "mib"
;; "m32fp"
;; "m64fp"
;; "m80dec"
;; "m80bcd"
;; "m16int"
;; "m32int"
;; "m64int"
;; "m80fp"
;; "m384"
;; "m256"
;; "vm32x"
;; "vm32y"
;; "vm32z"
;; "vm64x"
;; "vm64y"
;; "vm64z"
;; "tmem"

;;;; MemSizes Table
;;
;; -1  - I think this means it's not a mem-operand
;; 0
;; 8
;; 16
;; 32
;; 48
;; 64
;; 80
;; 128
;; 256
;; 384
;; 512

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
   |scc|   ;; ===== MISSING ===== Not sure why. Original json suggests it should be there, but isa export doesnt have it - I bodged it in the json file, but we need to fix the js
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
