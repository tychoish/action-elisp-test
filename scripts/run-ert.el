;;; run-ert.el --- Standardized ERT test runner harness -*- lexical-binding: t; -*-

(require 'ert)
(require 'seq)
(require 'subr-x)

;; Load bootstrap logic
(let ((bootstrap-file (expand-file-name "bootstrap.el" (file-name-directory (or load-file-name buffer-file-name)))))
  (when (file-exists-p bootstrap-file)
    (load-file bootstrap-file)))

(defun elisp-ci--find-test-files ()
  "Find test files matching pattern in INPUT_TEST_FILES."
  (let* ((pattern-input (or (getenv "INPUT_TEST_FILES") "test/test-*.el"))
         (patterns (elisp-ci--parse-list pattern-input))
         (matched nil))
    (dolist (pat patterns)
      (let ((files (file-expand-wildcards pat t)))
        (setq matched (append matched files))))
    (delete-dups matched)))

(defun elisp-ci--run-tests ()
  "Load test files and execute ERT test suite."
  (let ((test-files (elisp-ci--find-test-files))
        (runner (or (getenv "INPUT_RUNNER") "ert")))
    (unless test-files
      (message "No test files found matching INPUT_TEST_FILES")
      (kill-emacs 1))
    (message "Discovered test files: %S" test-files)
    (dolist (tf test-files)
      (message "Loading test file: %s" tf)
      (load-file (expand-file-name tf)))

    (if (string-equal runner "elpaish")
        (progn
          (unless (package-installed-p 'elpaish)
            (package-install 'elpaish))
          (require 'elpaish-check)
          (elpaish-test-package-batch))
      ;; Standard ERT batch runner
      (ert-run-tests-batch-and-exit))))

(elisp-ci--run-tests)

;;; run-ert.el ends here
