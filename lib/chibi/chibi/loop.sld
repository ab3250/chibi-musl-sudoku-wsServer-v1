
(define-library (chibi loop)
  (export loop for in-list in-lists in-port in-file up-from down-from
          listing listing-reverse appending appending-reverse
          summing multiplying in-string in-string-reverse in-substrings
          in-vector in-vector-reverse)
  (import (chibi))
  (include "loop/loop.scm"))
