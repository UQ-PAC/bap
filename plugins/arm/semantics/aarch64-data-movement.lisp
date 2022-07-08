(declare (context (target arm armv8-a+le)))

(in-package aarch64)

;;; LOADS, MOVES, STORES

;; LD...

;; LDR (register) 

(defmacro LDR*ro* (rt base index signed s scale setf mem-load)
  "(LDR*ro* rt base index signed s scale setf mem-load) loads a register from memory at the address calculated from a base register and optionally shifted and extended offset value. NOTE: does not HaveMTE2Ext(), SetTagCheckedInstruction(), CheckSPAlignment()"
  (let ((shift (* s scale))
        (off (if (= signed 1)
          (cast-signed 64 (lshift index shift))
          (cast-unsigned 64 (lshift index shift)))))
    (setf rt (mem-load (+ base off)))))

(defmacro LDRWro* (wt base index signed s) (LDR*ro* wt base index signed s 2 setw load-hword))
(defmacro LDRXro* (xt base index signed s) (LDR*ro* xt base index signed s 3 set$ load-word))

(defun LDRWroW (wt base index signed s) (LDRWro* wt base index signed s))
(defun LDRWroX (wt base index signed s) (LDRWro* wt base index signed s))
(defun LDRXroW (xt base index signed s) (LDRXro* xt base index signed s))
(defun LDRXroX (xt base index signed s) (LDRXro* xt base index signed s))

;; LDR (immediate, unsigned offset) 

(defun LDRXui (dst reg off)
  (set$ dst (load-word (+ reg (lshift off 3)))))

(defun LDRWui (dst reg off)
  (setw dst
        (cast-unsigned (word) (load-hword (+ reg (lshift off 2))))))

;; LDRB (immediate, post-index)

(defun LDRBBpost (_ dst base simm)
  "(LDRBBpost _ dst base simm) loads a byte from the base address and stores it in the 32 bit dst register, and increments the base register by simm. NOTE: does not HaveMTE2Ext(), SetTagCheckedInstruction(), CheckSPAlignment(), ConstrainUnpredictable()"
  (setw dst (cast-unsigned 32 (load-byte base)))
  (set$ base (+ base simm)))

;; LDRB (immediate, pre-index)

(defun LDRBBpre (_ dst base simm)
  "(LDRBBpre _ dst base simm) loads a byte from the base address and an offset simm and stores it in the 32 bit dst register. NOTE: does not HaveMTE2Ext(), SetTagCheckedInstruction(), CheckSPAlignment(), ConstrainUnpredictable()"
  (setw dst (cast-unsigned 32 (load-byte (+ base simm))))
  (set$ base (+ base simm)))

;; LDRB (immediate, unsigned offset)

(defun LDRBBui (dst reg off)
  "(LDRBBui _ dst base simm) loads a byte from a preindexed base address and an unsigned offset and stores it in the 32 bit dst register. NOTE: does not HaveMTE2Ext(), SetTagCheckedInstruction(), CheckSPAlignment(), ConstrainUnpredictable()"
  (setw dst
        (cast-unsigned 32 (load-byte (+ reg off)))))

;; LDRB (register)

(defmacro LDRBBro* (dst base index signed)
  "(LDRBBro* dst base index signed) loads a byte from memory from a base address and index and stores it in a 32 bit destination register. NOTE: does not HaveMTE2Ext(), SetTagCheckedInstruction(), CheckSPAlignment()"
  (let ((off (if (= signed 1)
          (cast-signed 64 index)
          (cast-unsigned 64 index))))
    (setw dst (cast-unsigned 32 (load-byte (+ base off))))))

(defun LDRBBroW (dst base index signed _) (LDRBBro* dst base index signed))
(defun LDRBBroX (dst base index signed _) (LDRBBro* dst base index signed))

;; LDP (post-index)

(defun LDPXpost (dst r1 r2 base off)
  (let ((off (lshift off 3)))
    (set$ r1 (load-word base))
    (set$ r2 (load-word (+ base (sizeof word))))
    (set$ dst (+ dst off))))

;; LDP (signed offset)

(defmacro LDP*i (r1 r2 base imm scale datasize setf mem-load)
  "(LDP*i r1 r2 base imm scale datasize setf mem-load) loads a pair of registers r1 and r2 from the address calculated from a base register value and immediate offset. NOTE: does not HaveMTE2Ext(), SetTagCheckedInstruction(), CheckSPAlignment()"
  (let ((off (lshift (cast-signed 64 imm) scale)))
    (setf r1 (mem-load (+ base off)))
    (setf r2 (mem-load (+ base off (/ datasize 8))))))

(defun LDPXi (r1 r2 base imm) (LDP*i r1 r2 base imm 3 64 set$ load-word))
(defun LDPWi (w1 w2 base imm) (LDP*i w1 w2 base imm 2 32 setw load-hword))

;; LDRH (register)

(defmacro LDRHHro* (wt base index signed s)
  "(LDRHHro* wt base index signed s) loads 2 bytes from the address calculated from a base register address and offset. NOTE: does not HaveMTE2Ext(), SetTagCheckedInstruction(), CheckSPAlignment()"
  (let ((off (if (= signed 1)
          (cast-signed 64 (lshift index s))
          (cast-unsigned 64 (lshift index s)))))
    (setw wt (load-dbyte (+ base off)))))

(defun LDRHHroX (wt xn xm extend s) (LDRHHro* wt xn xm extend s))
(defun LDRHHroW (wt xn wm extend s) (LDRHHro* wt xn wm extend s))

;; LDRH (immediate, unsigned offset)

(defun LDRHHui (wt xn pimm)
  "(LDRHHui wt xn pimm) loads 2 bytes from the address calculated from a base register and unsigned immediate offset. NOTE: does not HaveMTE2Ext(), SetTagCheckedInstruction(), CheckSPAlignment()"
  (let ((off (lshift (cast-unsigned 64 pimm) 1)))
    (setw wt (load-dbyte (+ xn off)))))

;; LDRSW (immediate, unsigned offset)

(defun LDRSWui (dst base off)
  (set$ dst (cast-signed
             (word)
             (load-hword (+ base (lshift off 2))))))

;; LRDSW (register)

(defmacro LDRSWro* (xt base index signed s)
  "(LDRSWro* xt base index signed s) loads 32 bits from memory from a base address and offset and stores it in the destination register xt. NOTE: does not HaveMTE2Ext(), SetTagCheckedInstruction(), CheckSPAlignment()"
  (let ((shift (* s 2))
        (off (if (= signed 1)
          (cast-signed 64 (lshift index shift))
          (cast-unsigned 64 (lshift index shift)))))
    (set$ xt (load-hword (+ base off)))))

(defun LDRSWroX (xt base xm signed s) (LDRSWro* xt base xm signed s))
(defun LDRSWroW (xt base wm signed s) (LDRSWro* xt base wm signed s))

;; LDURB
  
(defun LDURBBi (wt base simm)
  "(LDURBBi wt base simm) loads a byte from the address calculated from a base register and signed immediate offset and stores it in the 32 bit destination register. NOTE: does not HaveMTE2Ext(), SetTagCheckedInstruction(), CheckSPAlignment()"
  (setw wt (load-byte (+ base simm))))

;; LDUR

(defmacro LDUR*i (rt base simm setf mem-load)
  "(LDUR*i rt base simm setf mem-load) loads a register from the address calculated from a base register and signed immediate offset. NOTE: does not HaveMTE2Ext(), SetTagCheckedInstruction(), CheckSPAlignment()"
  (setf rt (mem-load (+ base (cast-signed 64 simm)))))

(defun LDURWi (wt base simm) (LDUR*i wt base simm setw load-hword))
(defun LDURXi (xt base simm) (LDUR*i xt base simm set$ load-word))

;; MOV...

(defmacro MOVZ*i (set dst imm off)
  (set dst (lshift imm off)))

(defun MOVZWi (dst imm off) (MOVZ*i setw dst imm off))
(defun MOVZXi (dst imm off) (MOVZ*i set$ dst imm off))

(defmacro MOVN*i (set dst imm off)
  (set dst (lnot (lshift imm off))))

(defun MOVNWi (dst imm off) (MOVN*i setw dst imm off))
(defun MOVNXi (dst imm off) (MOVN*i set$ dst imm off))

(defmacro MOVK*i (dst reg imm off)
  (let ((mask (lnot (lshift (- (lshift 1 16) 1) off))))
    (set$ dst (logor (logand reg mask) (lshift imm off)))))

(defun MOVKWi (dst reg imm off) (MOVK*i dst reg imm off))
(defun MOVKXi (dst reg imm off) (MOVK*i dst reg imm off))

;; ST...

; STRB
(defun STRBBui (src reg off)
  (store-byte (+ reg off) src))

; STR (register)
(defun str-reg (scale rt rn rm signed shift)
  "stores rt to (rn + rm << (shift * scale)) with signed or unsigned extension 
  of rm, where rt is a register of size (8 << scale). Note that rm can be an X 
  or W register and it chooses the appropriate extend mode implicitly. rn must 
  be an X register."
  (assert (< signed 2))
  (assert-msg (= (word-width rt) (lshift 8 scale))
      "(aarch64-data-movement.lisp:str-reg) scale must match size of rt") 
  (store-word (+ rn 
     (if (= signed 1) 
       (signed-extend   (word-width rm) (lshift rm (* shift scale)))
       (unsigned-extend (word-width rm) (lshift rm (* shift scale))))) 
      rt))

; rm is an X register
(defun STRWroX  (rt rn rm option shift)
 (str-reg 2 rt rn rm option shift))

(defun STRXroX (rt rn rm option shift)
 (str-reg 3 rt rn rm option shift))

(defun STRBroX  (rt rn rm option shift)
 (str-reg 0 rt rn rm option shift))

(defun STRHroX  (rt rn rm option shift)
 (str-reg 1 (cast-low 16 rt) rn rm option shift))

(defun STRSroX  (rt rn rm option shift)
 (str-reg 2 rt rn rm option shift))

(defun STRDroX (rt rn rm option shift)
  (str-reg 3 rt rn rm option shift))

(defun STRQroX (rt rn rm option shift)
  (str-reg 4 rt rn rm option shift))

; rm is a W register
(defun STRWroW  (rt rn rm option shift)
 (str-reg 2 rt rn rm option shift))

(defun STRXroW (rt rn rm option shift)
 (str-reg 3 rt rn rm option shift))

(defun STRBroW  (rt rn rm option shift)
 (str-reg 0 rt rn rm option shift))

(defun STRHroW  (rt rn rm option shift)
 (str-reg 1 (cast-low 16 rt) rn rm option shift))

(defun STRSroW  (rt rn rm option shift)
 (str-reg 2 rt rn rm option shift))

(defun STRDroW (rt rn rm option shift)
  (str-reg 3 rt rn rm option shift))

(defun STRQroW (rt rn rm option shift)
  (str-reg 4 rt rn rm option shift))

; STRHHroX
(defun STRHHroX (rt rn rm option shift)
  (str-reg 1 (cast-low 16 rt) rn rm option shift))

; STR (immediate) (base registers):
(defun str-post (xreg src off)
  "stores all of src to xreg, and post-indexes reg (reg += off)."
  (store-word xreg src)
  (set$ xreg (+ xreg off)))

(defun STRWpost (_ rt rn simm)
  (str-post rn rt simm))

(defun STRXpost (_ rt rn simm)
  (str-post rn rt simm))

; STR (SIMD registers)
(defun STRQpost (_ rt rn simm)
  (str-post rn rt simm))

(defun STRDpost (_ rt rn simm)
  (str-post rn rt simm))

(defun STRSpost (_ rt rn simm)
  (str-post rn (cast-low 32 rt) simm))

(defun STRHpost (_ rt rn simm)
  (str-post rn (cast-low 16 rt) simm))

(defun STRBpost (_ rt rn simm)
  (str-post rn (cast-low 8 rt) simm))

(defun str-pre (xreg src off)
  "stores all of src to xreg, and pre-indexes reg (reg += off)."
  (store-word (+ xreg off) src)
  (set$ xreg (+ xreg off)))

(defun STRWpre (_ rt rn simm)
  (str-pre rn rt simm))

(defun STRXpre (_ rt rn simm)
  (str-pre rn rt simm))

; STR (SIMD registers)
(defun STRQpre (_ rt rn simm)
  (str-pre rn rt simm))

(defun STRDpre (_ rt rn simm)
  (str-pre rn rt simm))

(defun STRSpre (_ rt rn simm)
  (str-pre rn (cast-low 32 rt) simm))

(defun STRHpre (_ rt rn simm)
  (str-pre rn (cast-low 16 rt) simm))

(defun STRBpre (_ rt rn simm)
  (str-pre rn (cast-low 8 rt) simm))

(defun STR*ui (scale src reg off) 
  "Stores a register of size (8 << scale) to the memory address 
  (reg + (off << scale))."
  (assert-msg (= (word-width src) (lshift 8 scale))
      "(aarch64-data-movement.lisp:STR*ui) scale must match size of register") 
  (store-word (+ reg (lshift off scale)) 
    (cast-unsigned (lshift 8 scale) src)))

(defun STRQui (src reg off)
  (STR*ui 4 src reg off))

(defun STRDui (src reg off)
  (STR*ui 3 src reg off))

(defun STRSui (src reg off)
  (STR*ui 2 src reg off))

(defun STRHui (src reg off)
  (STR*ui 1 src reg off))

(defun STRBui (src reg off)
  (STR*ui 0 src reg off))

(defun STRXui (src reg off)
  (STR*ui 3 src reg off))

(defun STRWui (src reg off)
  (STR*ui 2 src reg off))

; STRH (base reg), signed offset variant
(defun STRHHui (rt rn off)
  (store-word (+ rn (lshift off 1)) (cast-low 16 rt)))

; STRB 
(defun STRBBpost (_ rt base simm)
  (store-byte base rt)
  (set$ base (+ base simm)))

(defun STRBBpre (_ rt base simm)
  (store-byte (+ base simm) rt)
  (set$ base (+ base simm)))

(defun STRBBroW (rt rn rm option shift)
  (let ((off
    (if (= option 1)
        (signed-extend 32 rm)         ; SXTW
      (unsigned-extend 32 rm))))      ; UXTW
    (store-byte (+ rn off) rt)))

(defun STRBBroX (rt rn rm option shift)
  (let ((off 
    (if (= option 1)
        (signed-extend 64 rm)         ; SXTX
      (unsigned-extend 64 rm))))      ; LSL
    (store-byte (+ rn off) rt)))


; STP

(defun store-pair (scale indexing t1 t2 dst imm) 
  "store the pair t1,t2 of size (8 << scale) at the register dst plus an offset, 
  using the specified indexing."
  (assert-msg (and (= (word-width t1) (lshift 8 scale)) 
      (= (word-width t2) (lshift 8 scale)))
      "(aarch64-data-movement.lisp) scale must match size of register ") 
  (let ((off (lshift (cast-signed 64 imm) scale)) (datasize (lshift 8 scale))
      (addr (case indexing
              'post dst
              'pre  (+ dst off)
              'offset (+ dst off)
              (assert-msg (= 1 0) 
      "(aarch64-data-movement.lisp) invalid indexing scheme.")))
            )
    (store-word addr t1)
    (store-word (+ addr (/ datasize 8)) t2)
    (case indexing
       'post (set$ dst (+ addr off))
       'pre  (set$ dst addr)
       'offset )
    ))

; post-indexed
(defun STPWpost (_ t1 t2 dst off)
  (store-pair 2 'post t1 t2 dst off))

(defun STPXpost (_ t1 t2 dst off)
    (store-pair 3 'post t1 t2 dst off))

(defun STPSpost (_ t1 t2 dst off)
  (store-pair 2 'post t1 t2 dst off))

(defun STPDpost (_ t1 t2 dst off)
  (store-pair 3 'post t1 t2 dst off))

(defun STPQpost (_ t1 t2 dst off)
  (store-pair 4 'post t1 t2 dst off))

; pre-indexed
(defun STPXpre (_ t1 t2 dst off)
    (store-pair 3 'pre t1 t2 dst off))

(defun STPWpre (_ t1 t2 dst off)
  (store-pair 2 'pre t1 t2 dst off))

(defun STPSpre (_ t1 t2 dst off)
  (store-pair 2 'pre t1 t2 dst off))

(defun STPDpre (_ t1 t2 dst off)
  (store-pair 3 'pre t1 t2 dst off))

(defun STPQpre (_ t1 t2 dst off)
  (store-pair 4 'pre t1 t2 dst off))

; signed-offset
(defun STPWi (rt rt2 base imm) 
  (store-pair 2 'offset rt rt2 base imm))

(defun STPXi (rt rt2 base imm)
  (store-pair 3 'offset rt rt2 base imm))

(defun STPSi (rt rt2 base imm) 
  (store-pair 2 'offset rt rt2 base imm))

(defun STPDi (rt rt2 base imm) 
  (store-pair 3 'offset rt rt2 base imm))

(defun STPQi (rt rt2 base imm) 
  (store-pair 4 'offset rt rt2 base imm))


; addr + offset indexed STUR
(defmacro STUR*i (src base off size)
  "Takes `size` bits from src and stores at base + off"
  (store-word (+ base off) (cast-low size src)))

(defun STURXi  (src base off) (STUR*i src base off 64))

(defun STURWi  (src base off) (STUR*i src base off 32))

(defun STURHHi  (src base off) (STUR*i src base off 16))

(defun STURBBi (src base off) (STUR*i src base off 8))

(defun STURDi (rn rt imm) (STUR*i rn rt imm 64))

(defun STURQi (rn rt imm) (STUR*i rn rt imm 128)) 

