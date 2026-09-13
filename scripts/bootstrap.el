;;; bootstrap.el --- bootstrap.el -*- lexical-binding: t; -*-

(require 'package)
(require 'seq)
(require 'subr-x)

(defun elisp-ci--parse-list (str)
  "Parse space, comma, or newline-delimited STR into a list of strings."
  (when (and str (not (string-empty-p (string-trim str))))
    (split-string str "[ \t\n,]+" t)))

(defun elisp-ci--configure-archives ()
  "Configure `package-archives` and `package-unsigned-archives` from environment."
  (let* ((archive-names (or (elisp-ci--parse-list (getenv "INPUT_ARCHIVES"))
                            '("gnu" "nongnu" "melpa" "elpaish")))
         (unsigned-names (or (elisp-ci--parse-list (getenv "INPUT_UNSIGNED_ARCHIVES"))
                             '("elpaish")))
         (standard-map '(("gnu" . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")
                         ("melpa" . "https://melpa.org/packages/")
                         ("elpaish" . "https://tychoish.github.io/elpaish/snapshot/"))))
    (setq package-archives
          (delq nil
                (mapcar (lambda (name)
                          (if (assoc name standard-map)
                              (cons name (cdr (assoc name standard-map)))
                            (message "Warning: unknown standard archive '%s'" name)
                            nil))
                        archive-names)))
    (setq package-unsigned-archives unsigned-names)
    (message "Configured package-archives: %S" package-archives)
    (message "Configured package-unsigned-archives: %S" package-unsigned-archives)))

(defun elisp-ci--setup-load-paths ()
  "Add directories in INPUT_LOAD_PATHS to `load-path`."
  (let ((paths (or (elisp-ci--parse-list (getenv "INPUT_LOAD_PATHS"))
                   '("."))))
    (dolist (p paths)
      (let ((exp (expand-file-name p)))
        (when (file-directory-p exp)
          (add-to-list 'load-path exp)
          (message "Added to load-path: %s" exp))))))

(defun elisp-ci--install-dependencies ()
  "Install required dependencies from INPUT_DEPENDENCIES."
  (package-initialize)
  (let* ((dep-strs (elisp-ci--parse-list (getenv "INPUT_DEPENDENCIES")))
         (dep-syms (mapcar #'intern dep-strs)))
    (when dep-syms
      (unless package-archive-contents
        (message "Refreshing package archive contents...")
        (package-refresh-contents))
      (dolist (dep dep-syms)
        (unless (package-installed-p dep)
          (message "Installing dependency: %s" dep)
          (package-install dep))))))

;; Execute initialization
(elisp-ci--configure-archives)
(elisp-ci--setup-load-paths)
(elisp-ci--install-dependencies)

(defun elisp-ci--find-test-files (&optional pattern-override)
  "Find test files matching pattern in INPUT_TEST_FILES or PATTERN-OVERRIDE."
  (let* ((pattern-input (or pattern-override (getenv "INPUT_TEST_FILES") "test/test-*.el"))
         (patterns (elisp-ci--parse-list pattern-input))
         (matched nil))
    (dolist (pat patterns)
      (let ((files (file-expand-wildcards pat t)))
        (setq matched (append matched files))))
    (delete-dups matched)))

(provide 'bootstrap)
;;; bootstrap.el ends here
