;;; test-action-scripts.el --- Tests for action scripts -*- lexical-binding: t; -*-

(require 'ert)
(require 'bootstrap (expand-file-name "../scripts/bootstrap.el" (file-name-directory (or load-file-name buffer-file-name))))

(ert-deftest action-scripts/parse-list ()
  "Test string parsing helper."
  (should (equal (elisp-ci--parse-list "foo bar,baz\nqux") '("foo" "bar" "baz" "qux")))
  (should (null (elisp-ci--parse-list "")))
  (should (null (elisp-ci--parse-list nil))))

(provide 'test-action-scripts)
;;; test-action-scripts.el ends here
