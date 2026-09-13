;;; fixture-pkg.el --- Sample fixture package -*- lexical-binding: t; -*-

;; Author: sam kleinman <sam@tychoish.com>
;; Maintainer: sam kleinman <sam@tychoish.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "29.1"))

;;; Commentary:
;; Test fixture package for elisp-ci.

;;; Code:

(defun fixture-pkg-greet (name)
  "Return greeting for NAME."
  (format "Hello, %s!" name))

(defun fixture-pkg-add (a b)
  "Return sum of A and B."
  (+ a b))

(provide 'fixture-pkg)
;;; fixture-pkg.el ends here
