;;; test-fixture-pkg.el --- Tests for fixture package -*- lexical-binding: t; -*-

(require 'ert)
(require 'fixture-pkg)

(ert-deftest fixture-pkg/greet ()
  "Test greeting function."
  (should (equal (fixture-pkg-greet "World") "Hello, World!")))

(ert-deftest fixture-pkg/add ()
  "Test add function."
  (should (= (fixture-pkg-add 20 22) 42)))

(provide 'test-fixture-pkg)
;;; test-fixture-pkg.el ends here
