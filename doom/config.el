;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq user-full-name "John Doe"
      user-mail-address "john@doe.com")

(setq doom-font (font-spec :family "Hasklig" :size 30 :weight 'semi-light)
      doom-variable-pitch-font (font-spec :family "sans" :size 13))

(setq doom-theme 'doom-material)

(setq org-directory "~/Projects/org/")

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
(setq better-jumper-context 'buffer)
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
