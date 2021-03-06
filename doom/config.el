;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq user-full-name "John Doe"
      user-mail-address "john@doe.com")

(setq doom-font (font-spec :family "Hasklig" :size 30 :weight 'semi-light)
      doom-variable-pitch-font (font-spec :family "sans" :size 13))

(setq doom-theme 'doom-material)

(setq org-directory "~/Projects/org/")

(setq display-line-numbers-type 'relative)

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

;; Localleader, major
(setq doom-localleader-key ",")

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

;; Smartparens
(remove-hook 'doom-first-buffer-hook #'smartparens-global-mode)

;; Whitespace
(global-whitespace-mode +1)
(setq whitespace-style '(face trailing))

(map! :leader :desc "Describe at point" "h d" #'lsp-describe-thing-at-point)
(map! :leader :desc "Describe error at point" "h h" #'flycheck-display-error-at-point)

;; LSP doesn't take half the screen when showing doc in the minibuffer
;; https://emacs-lsp.github.io/lsp-mode/tutorials/how-to-turn-off/
(setq lsp-signature-render-documentation nil)

;; Prevent flycheck from putting a "!" at the left of the screen on errors
(setq flycheck-indication-mode nil)
