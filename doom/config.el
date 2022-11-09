;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq user-full-name "John Doe"
      user-mail-address "john@doe.com")

(setq doom-font (font-spec :family "Hasklig" :size 15 :weight 'semi-light)
      doom-variable-pitch-font (font-spec :family "sans" :size 13))

(setq doom-theme 'doom-horizon)

(setq org-directory "~/Projects/org/")

(setq display-line-numbers-type 'relative)

;; company
(after! company
  (setq company-idle-delay 0.5
        company-minimum-prefix-length 2
        company-show-numbers t)
  (add-hook 'evil-normal-state-entry-hook #'company-abort)

  (define-key company-active-map (kbd "TAB") 'company-complete)
  (define-key company-active-map (kbd "<tab>") 'company-complete)
  (define-key company-active-map (kbd "RET") nil)
  (define-key company-active-map (kbd "<return>") nil)
  )

;; spelling
(set-company-backend! '(text-mode
                        markdown-mode)
  '(:seperate company-ispell
              company-files
              company-yasnippet))
;; /company

;; history
(setq-default history-length 1000)
(setq-default better-jumper-max-length 1000)
(setq-default prescient-history-length 1000)


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
(map! :leader :desc "Format" "c =" #'lsp-format-region)

;; LSP doesn't take half the screen when showing doc in the minibuffer
;; https://emacs-lsp.github.io/lsp-mode/tutorials/how-to-turn-off/
(setq lsp-signature-render-documentation nil)

;; Disable lsp logs
;;(setq lsp-log-io nil)

;; Ignoring jsons
(with-eval-after-load 'lsp-mode
  (add-to-list 'lsp-file-watch-ignored-directories "[/\\\\]data\\'"))

;; Prevent flycheck from putting a "!" at the left of the screen on errors
(setq flycheck-indication-mode nil)

;; Dart
(setq dart-format-on-save t)

;; C#
;; (setq lsp-csharp-server-path "/usr/bin/omnisharp")

;; Godot
(setq gdscript-indent-offset 2)

;; Gleam
(use-package! gleam-mode
  :mode "\\.gleam$")

;; Default indent
(doom/set-indent-width 2)

;; Godot
(defun godot-run ()
  "Run the current Godot project"
  (interactive)
  (async-shell-command (concat "godot-mono --path " (projectile-project-root)))
  )
(defun godot-build ()
  "Build the current Godot project"
  (interactive)
  (shell-command (concat "msbuild " (projectile-project-root)))
  )

(defun godot-build-run ()
  "Build and then run the current Godot project"
  (interactive)
  (godot-build)
  (godot-run)
  )

;; Deno
(add-hook 'typescript-mode-hook 'deno-fmt-mode)
(add-hook 'js2-mode-hook 'deno-fmt-mode)
