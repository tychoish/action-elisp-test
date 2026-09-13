;;; run-coverage.el --- run-coverage.el -*- lexical-binding: t; -*-

(require 'ert)
(require 'seq)
(require 'subr-x)
(require 'bootstrap nil t)

(defvar under-cover-report-format)
(defvar under-cover-report-file)
(declare-function under-cover "under-cover")

;; Load bootstrap logic
(let ((bootstrap-file (expand-file-name "bootstrap.el" (file-name-directory (or load-file-name buffer-file-name)))))
  (when (file-exists-p bootstrap-file)
    (load-file bootstrap-file)))

(defun elisp-ci--setup-and-run-coverage ()
  "Setup under-cover, load test files, and output coverage report."
  (let* ((output-file (or (getenv "INPUT_OUTPUT_FILE") "coverage.json"))
         (source-pat (or (getenv "INPUT_SOURCE_FILES") "*.el"))
         (format-opt (or (getenv "INPUT_REPORT_FORMAT") "simplecov"))
         (test-files (elisp-ci--find-test-files)))

    ;; Install under-cover if not available
    (unless (package-installed-p 'under-cover)
      (message "Installing under-cover...")
      (package-install 'under-cover))

    (require 'under-cover)
    (setq under-cover-report-format (intern format-opt))
    (setq under-cover-report-file (expand-file-name output-file))

    ;; Instrument source files
    (let ((source-files (file-expand-wildcards source-pat t)))
      (message "Instrumenting source files for coverage: %S" source-files)
      (dolist (sf source-files)
        (under-cover sf)))

    ;; Load test files and execute ERT suite
    (message "Loading test files: %S" test-files)
    (dolist (tf test-files)
      (load-file (expand-file-name tf)))

    (message "Running ERT tests with coverage tracking...")
    (ert-run-tests-batch-and-exit)))

(elisp-ci--setup-and-run-coverage)

;;; run-coverage.el ends here
