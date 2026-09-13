;;; run-lint.el --- Standardized linter & byte-compilation harness -*- lexical-binding: t; -*-

(require 'bytecomp)
(require 'seq)
(require 'subr-x)

;; Load bootstrap logic
(let ((bootstrap-file (expand-file-name "bootstrap.el" (file-name-directory (or load-file-name buffer-file-name)))))
  (when (file-exists-p bootstrap-file)
    (load-file bootstrap-file)))

(defun elisp-ci--find-target-files ()
  "Find elisp target files to lint from INPUT_TARGET_FILES."
  (let* ((pattern-input (or (getenv "INPUT_TARGET_FILES") "*.el"))
         (patterns (elisp-ci--parse-list pattern-input))
         (matched nil))
    (dolist (pat patterns)
      (let ((files (file-expand-wildcards pat t)))
        (setq matched (append matched files))))
    (delete-dups matched)))

(defun elisp-ci--run-lint ()
  "Run byte compilation and checkdoc on target files."
  (let ((files (elisp-ci--find-target-files))
        (error-count 0)
        (should-byte-compile (not (string-equal (getenv "INPUT_BYTE_COMPILE") "false")))
        (should-checkdoc (not (string-equal (getenv "INPUT_CHECKDOC") "false"))))
    (unless files
      (message "No files found matching INPUT_TARGET_FILES")
      (kill-emacs 0))
    (message "Target files for linting: %S" files)

    (when should-byte-compile
      (setq byte-compile-error-on-warn t)
      (dolist (f files)
        (message "==> Byte-compiling %s..." f)
        (unless (byte-compile-file (expand-file-name f))
          (message "ERROR: Byte compilation failed for %s" f)
          (cl-incf error-count))))

    (when should-checkdoc
      (require 'checkdoc)
      (dolist (f files)
        (message "==> Checking docstrings in %s..." f)
        (with-temp-buffer
          (insert-file-contents f)
          (emacs-lisp-mode)
          (condition-case err
              (checkdoc-current-buffer t)
            (error
             (message "Checkdoc warning/error in %s: %S" f err))))))

    (if (> error-count 0)
        (progn
          (message "Linting failed with %d errors" error-count)
          (kill-emacs 1))
      (message "Linting completed successfully")
      (kill-emacs 0))))

(elisp-ci--run-lint)

;;; run-lint.el ends here
