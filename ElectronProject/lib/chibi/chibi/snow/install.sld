(define-library (chibi snow install)
  (import (scheme base))
  (export snow-module-directory snow-binary-module-directory)
  (begin
   (define snow-module-directory "/usr/local/share/snow")
   (define snow-binary-module-directory "/usr/local/lib/snow")))
