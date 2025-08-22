;;;; asmdb.asd

(asdf:defsystem #:asmdb
  :description "Describe asmdb here"
  :author "Your Name <your.name@example.com>"
  :license  "Specify license here"
  :version "0.0.1"
  :depends-on (:cl-json :cl-ppcre)
  :serial t
  :components ((:file "package")
               (:file "asmdb")))
