;;; py-project-root helpers

(defvar py-project-root 'not-initialized
  "The root of the project the current buffer is in.")
(make-variable-buffer-local 'py-project-root)

(defun py-project-find-root ()
  "Find an appropriate project root for the current buffer.

If no root directory is found, nil is returned."
  (directory-file-name
   (locate-dominating-file buffer-file-name "dev.nix")))

(defun py-project-root ()
  "Return the root of the current buffer's project.

You can set the variable `py-project-root' in, for example,
.dir-locals.el to configure this."
  (when (eq py-project-root 'not-initialized)
    ;; Set it to nil so when the user runs C-g on the project root
    ;; prompt, it's set to "no project root".
    (setq py-project-root nil)
    (setq py-project-root
          ;; (or
          (py-project-find-root)
          ;; (read-directory-name "Project root: "
          ;;                      default-directory))
          )
    ;; (when (and (not (file-directory-p py-project-root))
    ;;            (y-or-n-p "Directory does not exist, create? "))
    ;;   (make-directory py-project-root t))
    )
  py-project-root)


;;; ipython

(defun use-ipython-locally ()
  "Use ipython in the local buffer if it is available"
  (when (executable-find "ipython")
    (set (make-local-variable 'python-shell-interpreter)
         (file-name-nondirectory "ipython"))
    (set (make-local-variable 'python-shell-interpreter-args)
         "")
    (set (make-local-variable 'python-shell-prompt-regexp)
         "In \\[[0-9]+\\]: ")
    (set (make-local-variable 'python-shell-prompt-output-regexp)
         "Out\\[[0-9]+\\]: ")
    (set (make-local-variable 'python-shell-completion-setup-code)
         "from IPython.core.completerlib import module_completion")
    (set (make-local-variable 'python-shell-completion-module-string-code)
         "';'.join(module_completion('''%s'''))\n")
    (set (make-local-variable 'python-shell-completion-string-code)
         "';'.join(get_ipython().Completer.all_completions('''%s'''))\n")))


;;; flymake stuff

(defvar py-codechecker "flake8"
  "codechecker for flymake in python-mode")

(defun jho/flymake-pycodecheck-find-checker ()
  "Check for a project local python-codechecker. Else assume it is in PATH."
  (let ((checker (expand-file-name (concat "bin/" py-codechecker)
                                   (py-project-root))))
    (if (file-executable-p checker)
        checker
      (when (executable-find py-codechecker)
        py-codechecker))))

(defun dss/flymake-pycodecheck-init ()
  (let* ((temp-file (flymake-init-create-temp-buffer-copy
                     'flymake-create-temp-inplace))
         (local-file (file-relative-name
                      temp-file
                      (file-name-directory buffer-file-name))))
    (list (jho/flymake-pycodecheck-find-checker)
          (list local-file))))

(defun dss/pylint-msgid-at-point ()
  (interactive)
  (let (msgid
        (line-no (line-number-at-pos)))
    (dolist (elem flymake-err-info msgid)
      (if (eq (car elem) line-no)
            (let ((err (car (second elem))))
              (setq msgid (second (split-string (flymake-ler-text err)))))))))

(defun dss/pylint-silence (msgid)
  "Add a special pylint comment to silence a particular warning."
  (interactive (list (read-from-minibuffer "msgid: " (dss/pylint-msgid-at-point))))
  (save-excursion
    (comment-dwim nil)
    (if (looking-at "pylint:")
        (progn (end-of-line)
               (insert ","))
        (insert "pylint: disable-msg="))
    (insert msgid)))

