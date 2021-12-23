;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq user-full-name "John Doe"
      user-mail-address "john@doe.com")

;; (setq doom-font (font-spec :family "Hasklig" :size 20 :weight 'semi-light))
(setq doom-font (font-spec :family "Hasklig" :size 24 :weight 'semi-light))

(setq doom-theme 'doom-nord)

(setq org-directory "~/Projects/notes/agenda")

(setq display-line-numbers-type 'relative)


;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; company
(after! company
  (setq company-idle-delay 0.5
        company-minimum-prefix-length 2)
  (setq company-show-numbers t)
(add-hook 'evil-normal-state-entry-hook #'company-abort))

;; history
(setq-default history-length 1000)
(setq-default better-jumper-max-length 1000)
(setq-default prescient-history-length 1000)

;; spelling
(set-company-backend! '(text-mode
                        markdown-mode)
  '(:seperate company-ispell
              company-files
              company-yasnippet))

;; spacemacs keybindings
(map! :leader :desc "Search in project" "/" #'+default/search-project)
(map! :leader :desc "Split" "w /" #'evil-window-vsplit)
;; (setq better-jumper-context 'buffer)
(map! :leader :desc "Choose window" "w W" #'ace-window)
;; Golden ratio
(use-package! golden-ratio
  :after-call pre-command-hook
  :config
  (golden-ratio-mode +1)
  ;; Using this hook for resizing windows is less precise than
  ;; `doom-switch-window-hook'.
  (remove-hook 'window-configuration-change-hook #'golden-ratio)
  (add-hook 'doom-switch-window-hook #'golden-ratio))

;; Fill Column
(add-hook 'prog-mode-hook
          (lambda ()
            (display-fill-column-indicator-mode)
            (set-fill-column 120)
            ))
(add-hook 'org-mode-hook #'display-fill-column-indicator-mode)
(display-time)

;; shadowenv
(add-hook 'ruby-mode-hook 'shadowenv-global-mode)

;; Modeline
(setq doom-modeline-buffer-file-name-style 'file-name)

;; Faster projectile
(setq projectile-indexing-method 'alien)
(setq projectile-generic-command "git ls-files -zco --exclude-standard")
(setq projectile-enable-caching t)

;; Smartparens
(remove-hook 'doom-first-buffer-hook #'smartparens-global-mode)

(defun copy-file-name-to-clipboard ()
  "Copy the current buffer file name to the clipboard."
  (interactive)
  (let ((filename (if (equal major-mode 'dired-mode)
                      default-directory
                    (buffer-file-name))))
    (when filename
      (kill-new filename)
      (message "Copied buffer file name '%s' to the clipboard." filename))))

;; Comments
(setq-hook! 'ruby-mode-hook
    comment-line-break-function nil)

;; Whitespace
(global-whitespace-mode +1)
(setq whitespace-style '(face trailing))

;; ;; Company
;; (after! 'company-mode
;;   (let ((map company-active-map))
;;     (define-key map [return] 'nil)
;;     (define-key map (kbd "RET") 'nil)
;;     (define-key map [tab] 'company-complete)
;;     (define-key map (kbd "TAB") 'company-complete-selection)
;;     (define-key map (kbd "<tab>") 'company-complete-selection)))

;; Magit
;; (remove-hook 'magit-status-sections-hook #'magit-insert-tags-header)
;; (remove-hook 'magit-status-sections-hook #'magit-insert-status-header)
;; (remove-hook 'magit-status-sections-hook #'magit-insert-unpushed-to-pushremote)
;; (remove-hook 'magit-status-sections-hook #'magit-insert-unpushed-to-upstream-or-recent)
;; (remove-hook 'magit-status-sections-hook #'magit-insert-unpulled-from-pushremote)
;; (remove-hook 'magit-status-sections-hook #'magit-insert-unpulled-from-upstream)

;; Tramp
(setq tramp-default-method "ssh")
