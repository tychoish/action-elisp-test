;;; test-action-scripts.el --- Tests for action scripts -*- lexical-binding: t; -*-

(require 'ert)
(require 'bootstrap)

(ert-deftest action-scripts/parse-list-plain ()
  "Test plain space and comma separated lists."
  (should (equal (elisp-ci--parse-list "foo bar,baz qux") '("foo" "bar" "baz" "qux")))
  (should (null (elisp-ci--parse-list "")))
  (should (null (elisp-ci--parse-list nil))))

(ert-deftest action-scripts/parse-list-yaml-bullets ()
  "Test multiline YAML lists with bullet syntax (- and *)."
  (let ((yaml-input "- compat\n- transient\n- llama")
        (indented-yaml "  - compat\n  - transient\n  - llama")
        (star-input "* compat\n* transient\n* llama")
        (commented-yaml "- compat # elpa pkg\n- transient # needed"))
    (should (equal (elisp-ci--parse-list yaml-input) '("compat" "transient" "llama")))
    (should (equal (elisp-ci--parse-list indented-yaml) '("compat" "transient" "llama")))
    (should (equal (elisp-ci--parse-list star-input) '("compat" "transient" "llama")))
    (should (equal (elisp-ci--parse-list commented-yaml) '("compat" "transient")))))

(ert-deftest action-scripts/parse-list-yaml-array-and-quotes ()
  "Test YAML/JSON bracket arrays and quoted items."
  (let ((bracket-input "[\"compat\", \"transient\"]")
        (unquoted-bracket "[compat, transient]")
        (quoted-yaml "- 'compat'\n- \"transient\""))
    (should (equal (elisp-ci--parse-list bracket-input) '("compat" "transient")))
    (should (equal (elisp-ci--parse-list unquoted-bracket) '("compat" "transient")))
    (should (equal (elisp-ci--parse-list quoted-yaml) '("compat" "transient")))))

(ert-deftest action-scripts/parse-list-elisp-lists-and-structures ()
  "Test Elisp lists of strings, symbols, and sequences."
  (should (equal (elisp-ci--parse-list '("compat" "transient")) '("compat" "transient")))
  (should (equal (elisp-ci--parse-list '("compat transient" "llama")) '("compat" "transient" "llama")))
  (should (equal (elisp-ci--parse-list '(compat transient)) '("compat" "transient")))
  (should (equal (elisp-ci--parse-list '["compat" "transient"]) '("compat" "transient")))
  (should (equal (elisp-ci--parse-list '("- compat" "- transient")) '("compat" "transient"))))

(ert-deftest action-scripts/discover-package-requires ()
  "Test automatic discovery of dependencies from Package-Requires header."
  (let ((deps (elisp-ci--discover-package-requires)))
    ;; In this repository, fixture-pkg.el or others might have headers
    (message "Discovered root deps: %S" deps)
    (should (listp deps))))

(ert-deftest action-scripts/get-dependencies-env-override ()
  "Test overriding dependencies via ELISP_CI_DEPENDENCIES environment variable."
  (let ((process-environment (cons "ELISP_CI_DEPENDENCIES=transient llama" process-environment)))
    (should (equal (elisp-ci--get-dependencies) '("transient" "llama")))))

(provide 'test-action-scripts)
;;; test-action-scripts.el ends here
