
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Cursors

;;> Returns true iff \var{iset} is empty.

(define (iset-empty? iset)
  (and (iset? iset)
       (cond ((iset-bits iset) => zero?) (else #f))
       (let ((l (iset-left iset))) (or (not l) (iset-empty? l)))
       (let ((r (iset-right iset))) (or (not r) (iset-empty? r)))))

(define-record-type Iset-Cursor
  (make-iset-cursor node pos stack)
  iset-cursor?
  (node iset-cursor-node iset-cursor-node-set!)
  (pos iset-cursor-pos iset-cursor-pos-set!)
  (stack iset-cursor-stack iset-cursor-stack-set!))

(define (%iset-cursor iset . o)
  (iset-cursor-advance
   (make-iset-cursor iset
                     (or (iset-bits iset) (iset-start iset))
                     (if (pair? o) (car o) '()))))

;;> Create a new iset cursor pointing to the first element of iset,
;;> with an optional stack argument.

(define (iset-cursor iset . o)
  (let ((stack (if (pair? o) (car o) '())))
    (if (iset-left iset)
        (iset-cursor (iset-left iset) (cons iset stack))
        (%iset-cursor iset stack))))

;; Continue to the next node in the search stack.
(define (iset-cursor-pop cur)
  (let ((node (iset-cursor-node cur))
        (stack (iset-cursor-stack cur)))
    (cond
     ((iset-right node)
      (iset-cursor (iset-right node) stack))
     ((pair? stack)
      (%iset-cursor (car stack) (cdr stack)))
     (else
      cur))))

;; Advance to the next node+pos that can be referenced if at the end
;; of this node's range.
(define (iset-cursor-advance cur)
  (let ((node (iset-cursor-node cur))
        (pos (iset-cursor-pos cur)))
    (cond
     ((if (iset-bits node) (zero? pos) (> pos (iset-end node)))
      (iset-cursor-pop cur))
     (else cur))))

;;> Return a new iset cursor pointing to the next element of
;;> \var{iset} after \var{cur}.  If \var{cur} is already at
;;> \scheme{end-of-iset?}, the resulting cursor is as well.

(define (iset-cursor-next iset cur)
  (iset-cursor-advance
   (let ((node (iset-cursor-node cur))
         (pos (iset-cursor-pos cur))
         (stack (iset-cursor-stack cur)))
     (let ((pos (if (iset-bits node) (bitwise-and pos (- pos 1)) (+ pos 1))))
       (make-iset-cursor node pos stack)))))

;;> Return the element of iset \var{iset} at cursor \var{cur}.  If the
;;> cursor is at \scheme{end-of-iset?}, raises an error.

(define (iset-ref iset cur)
  (let ((node (iset-cursor-node cur))
        (pos (iset-cursor-pos cur)))
    (cond
     ((iset-bits node)
      (if (zero? pos)
          (error "cursor reference past end of iset")
          (+ (iset-start node)
             (integer-length (- pos (bitwise-and pos (- pos 1))))
             -1)))
     (else
      (if (> pos (iset-end node))
          (error "cursor reference past end of iset")
          pos)))))

;;> Returns true iff \var{cur} is at the end of iset, such that
;;> \scheme{iset-ref} is no longer valid.

(define (end-of-iset? cur)
  (let ((node (iset-cursor-node cur)))
    (and (if (iset-bits node)
             (zero? (iset-cursor-pos cur))
             (> (iset-cursor-pos cur) (iset-end node)))
         (not (iset-right node))
         (null? (iset-cursor-stack cur)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Rank/Select operations, acting directly on isets without an
;; optimized data structure.

(define (iset-node-size iset)
  (if (iset-bits iset)
      (bit-count (iset-bits iset))
      (+ 1 (- (iset-end iset) (iset-start iset)))))

;; Number of bits set in i below index n.
(define (bit-rank i n)
  (bit-count (bitwise-and i (- (arithmetic-shift 1 n) 1))))

;;> Returns the rank (i.e. index within the iset) of the given
;;> element, a number in [0, size).  This can be used to compress an
;;> integer set to a minimal consecutive set of integets.  Can also be
;;> thought of as the number of elements in iset smaller than element.
(define (iset-rank iset element)
  (let lp ((iset iset) (count 0))
    (cond
     ((< element (iset-start iset))
      (if (iset-left iset)
          (lp (iset-left iset) count)
          (error "integer not in iset" iset element)))
     ((> element (iset-end iset))
      (if (iset-right iset)
          (lp (iset-right iset)
              (+ count
                 (cond ((iset-left iset) => iset-size) (else 0))
                 (iset-node-size iset)))
          (error "integer not in iset" iset element)))
     ((iset-bits iset)
      (+ count
         (cond ((iset-left iset) => iset-size) (else 0))
         (bit-rank (iset-bits iset)
                   (- element (iset-start iset)))))
     (else
      (+ count
         (cond ((iset-left iset) => iset-size) (else 0))
         (integer-length (- element (iset-start iset))))))))

(define (nth-set-bit i n)
  ;; TODO: optimize
  (if (zero? n)
      (first-set-bit i)
      (nth-set-bit (bitwise-and i (- i 1)) (- n 1))))

;;> Selects the index-th element of iset starting at 0.  The inverse
;;> operation of \scheme{iset-rank}.
(define (iset-select iset index)
  (let lp ((iset iset) (index index) (stack '()))
    (if (and iset (iset-left iset))
        (lp (iset-left iset) index (cons iset stack))
        (let ((iset (if iset iset (car stack)))
              (stack (if iset stack (cdr stack))))
          (let ((node-size (iset-node-size iset)))
            (cond
             ((and (< index node-size) (iset-bits iset))
              (+ (iset-start iset)
                 (nth-set-bit (iset-bits iset) index)))
             ((< index node-size)
              (+ (iset-start iset) index))
             ((iset-right iset)
              (lp (iset-right iset) (- index node-size) stack))
             ((pair? stack)
              (lp #f  (- index node-size) stack))
             (else
              (error "iset index out of range" iset index))))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Equality

(define (iset2= is1 is2)
  (let lp ((cur1 (iset-cursor is1))
           (cur2 (iset-cursor is2)))
    (cond ((end-of-iset? cur1) (end-of-iset? cur2))
          ((end-of-iset? cur2) #f)
          ((= (iset-ref is1 cur1) (iset-ref is2 cur2))
           (lp (iset-cursor-next is1 cur1) (iset-cursor-next is2 cur2)))
          (else
           #f))))

(define (iset2<= is1 is2)
  (let lp ((cur1 (iset-cursor is1))
           (cur2 (iset-cursor is2)))
    (cond ((end-of-iset? cur1))
          ((end-of-iset? cur2) #f)
          (else
           (let ((i1 (iset-ref is1 cur1))
                 (i2 (iset-ref is1 cur2)))
             (cond ((> i1 i2)
                    (lp cur1 (iset-cursor-next is2 cur2)))
                   ((= i1 i2)
                    (lp (iset-cursor-next is1 cur1)
                        (iset-cursor-next is2 cur2)))
                   (else
                    ;; (< i1 i2) - i1 won't occur in is2
                    #f)))))))

;;> Returns true iff all arguments contain the same elements.  Always
;;> returns true if there are less than two arguments.

(define (iset= . o)
  (or (null? o)
      (let lp ((a (car o)) (ls (cdr o)))
        (or (null? ls) (and (iset2= a (car ls)) (lp (car ls) (cdr ls)))))))

;;> Returns true iff the arguments are monotonically increasing, that
;;> is each argument contains every element of all preceding
;;> arguments.  Always returns true if there are less than two
;;> arguments.

(define (iset<= . o)
  (or (null? o)
      (let lp ((a (car o)) (ls (cdr o)))
        (or (null? ls) (and (iset2<= a (car ls)) (lp (car ls) (cdr ls)))))))

;;> Returns true iff the arguments are monotonically decreasing, that
;;> is each argument contains every element of all succeeding
;;> arguments.  Always returns true if there are less than two
;;> arguments.

(define (iset>= . o)
  (apply iset<= (reverse o)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Folding

(define (iset-fold-node kons knil iset)
  (let lp ((is iset) (acc knil))
    (let* ((left (iset-left is))
           (acc (kons is (if left (lp left acc) acc)))
           (right (iset-right is)))
      (if right (lp right acc) acc))))

;;> The fundamental iset iterator.  Applies \var{kons} to every
;;> element of \var{iset} along with an accumulator, starting with
;;> \var{knil}.  Returns \var{knil} if \var{iset} is empty.

(define (iset-fold kons knil iset)
  (iset-fold-node
   (lambda (is acc)
     (let ((start (iset-start is))
           (end (iset-end is))
           (bits (iset-bits is)))
       (if bits
           (let ((limit (+ 1 (- end start))))
             (do ((n1 bits n2)
                  (n2 (bitwise-and bits (- bits 1)) (bitwise-and n2 (- n2 1)))
                  (acc acc (kons (+ start (integer-length (- n1 n2)) -1) acc)))
                 ((zero? n1) acc)))
           (do ((i start (+ i 1))
                (acc acc (kons i acc)))
               ((> i end) acc)))))
   knil
   iset))

(define (iset-for-each-node proc iset)
  (iset-fold-node (lambda (node acc) (proc node)) #f iset))

;;> Runs \var{proc} on every element of iset, discarding the results.

(define (iset-for-each proc iset)
  (iset-fold (lambda (i acc) (proc i)) #f iset))

;;> Returns a list of every integer in \var{iset} in sorted
;;> (increasing) order.

(define (iset->list iset)
  (reverse (iset-fold cons '() iset)))

;;> Returns the number of elements in \var{iset}.

(define (iset-size iset)
  (iset-fold-node
   (lambda (is acc) (+ acc (iset-node-size is)))
   0
   iset))
