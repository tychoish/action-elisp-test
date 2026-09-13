;;; bootstrap.el --- Bootstrap package.el, keyrings, and dependencies -*- lexical-binding: t; -*-

(require 'package)
(require 'seq)
(require 'subr-x)
(require 'url)

(defun elisp-ci--parse-list (input)
  "Parse INPUT into a list of cleaned string tokens.
INPUT can be:
- A list or sequence of strings, symbols, or sub-elements.
- A string in YAML structure format (bullets `- item` or `* item`, `[a, b]`).
- A string with newline, comma, tab, or space delimiters.
- Nil (returns nil)."
  (cond
   ((null input) nil)
   ((and (sequencep input) (not (stringp input)))
    (let ((results nil))
      (seq-doseq (elem input)
        (dolist (item (elisp-ci--parse-list elem))
          (push item results)))
      (nreverse (delete-dups results))))
   ((stringp input)
    (let* ((cleaned (string-trim input)))
      (if (string-empty-p cleaned)
          nil
        (let* ((unbracketed (if (and (string-prefix-p "[" cleaned)
                                     (string-suffix-p "]" cleaned))
                                (substring cleaned 1 -1)
                              cleaned))
               (raw-lines (split-string unbracketed "[\n\r]+" t))
               (results nil))
          (dolist (line raw-lines)
            (let* ((line-no-comment (replace-regexp-in-string "#.*$" "" line))
                   (item (string-trim line-no-comment)))
              ;; Strip leading YAML bullet: '- ' or '* '
              (when (string-match "\\`[-*]\\s-+\\(.*\\)\\'" item)
                (setq item (string-trim (match-string 1 item))))
              ;; Strip single leading dash without space e.g. "-item"
              (when (and (string-prefix-p "-" item) (> (length item) 1) (not (string-prefix-p "--" item)))
                (setq item (string-trim (substring item 1))))
              ;; Split comma, space, or tab separated tokens on this line
              (dolist (tok (split-string item "[, \t]+" t))
                (let ((sub (string-trim tok)))
                  ;; Strip surrounding single or double quotes from individual token
                  (when (or (and (string-prefix-p "\"" sub) (string-suffix-p "\"" sub) (> (length sub) 1))
                            (and (string-prefix-p "'" sub) (string-suffix-p "'" sub) (> (length sub) 1)))
                    (setq sub (substring sub 1 -1)))
                  (unless (string-empty-p sub)
                    (push sub results))))))
          (nreverse (delete-dups results))))))
   ((symbolp input)
    (list (symbol-name input)))
   (t
    (list (format "%s" input)))))

(defun elisp-ci--import-elpaish-keyring ()
  "Fetch and import ELPAish GPG public keyring for archive verification."
  (condition-case err
      (let* ((keyring-url (or (getenv "INPUT_KEYRING_URL")
                              "https://tychoish.github.io/elpaish/elpaish-keyring.gpg"))
             (temp-file (make-temp-file "elpaish-keyring" nil ".gpg")))
        (message "Fetching ELPAish GPG keyring from %s..." keyring-url)
        (url-copy-file keyring-url temp-file t)
        (when (fboundp 'package-import-keyring)
          (package-import-keyring temp-file)
          (message "Successfully imported ELPAish GPG keyring into package.el GnuPG dir."))
        (delete-file temp-file))
    (error
     (message "Note: Could not import ELPAish GPG keyring (%s); using fallback unsigned archive entry."
              (error-message-string err)))))

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
    (when (member "elpaish" archive-names)
      (elisp-ci--import-elpaish-keyring))
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

(defun elisp-ci--install-dependencies (&optional extra-deps)
  "Install required dependencies from INPUT_DEPENDENCIES and EXTRA-DEPS."
  (package-initialize)
  (let* ((env-deps (elisp-ci--parse-list (getenv "INPUT_DEPENDENCIES")))
         (all-dep-strs (append env-deps (elisp-ci--parse-list extra-deps)))
         (dep-syms (delete-dups (mapcar #'intern all-dep-strs))))
    (when dep-syms
      (unless package-archive-contents
        (message "Refreshing package archive contents...")
        (package-refresh-contents))
      (dolist (dep dep-syms)
        (unless (package-installed-p dep)
          (message "Installing dependency: %s" dep)
          (package-install dep))))))

(defun elisp-ci--find-test-files (&optional pattern-override)
  "Find test files matching pattern in INPUT_TEST_FILES or PATTERN-OVERRIDE."
  (let* ((pattern-input (or pattern-override (getenv "INPUT_TEST_FILES") "test/test-*.el"))
         (patterns (elisp-ci--parse-list pattern-input))
         (matched nil))
    (dolist (pat patterns)
      (let ((files (file-expand-wildcards pat t)))
        (setq matched (append matched files))))
    (delete-dups matched)))

;; Execute standard bootstrapping
(elisp-ci--configure-archives)
(elisp-ci--setup-load-paths)
(elisp-ci--install-dependencies)

(provide 'bootstrap)
;;; bootstrap.el ends here
