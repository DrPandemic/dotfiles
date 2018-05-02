;
; - * -mode:emacs - lisp - * - ;
; This file is loaded by Spacemacs at startup.;
; It must be stored in your home directory.

(defun dotspacemacs/layers ()
  "Configuration Layers declaration.
You should not put any user code in this function besides modifying the variable
values."
  (setq-default
   dotspacemacs-distribution 'spacemacs
   dotspacemacs-configuration-layer-path '()
   dotspacemacs-configuration-layers
   '(csv
     rust
     '((ruby :variables ruby-enable-enh-ruby-mode t ruby-version-manager 'chruby))
     ruby-on-rails
     sql
     nginx
     yaml
     html
     auto-completion
     better-defaults
     emacs-lisp
     git
     github
     markdown
     (markdown :variables markdown-live-preview-engine 'vmd)
     ;; org
     (shell :variables
            shell-default-height 30
            shell-default-position 'bottom
            shell-default-term-shell "/bin/bash"
            )
     ;; spell-checking
     '((syntax-checking :variables syntax-checking-enable-tooltips nil))
     version-control
     react
     (typescript :variables
                 typescript-fmt-tool 'typescript-formatter)
     scala
     semantic
     cscope
     ;; (drpandemic-javascript :variables drpandemic-javascript-enable-flycheck-flow nil flow-type-enable-eldoc-type-info nil)
     ;; drpandemic-symbols
     )
   dotspacemacs-additional-packages
   '(
     ;; rjsx-mode
     ;  (simon-shopify//configure-ruby)
     ; company-flow
     graphql-mode
     )
   dotspacemacs-excluded-packages
   '(
     smartparens
     emmet-mode
     )
   dotspacemacs-delete-orphan-packages t))

(defun dotspacemacs/config () "")

(defun dotspacemacs/init ()
  "Initialization function.
This function is called at the very startup of Spacemacs initialization
before layers configuration.
You should not put any user code in there besides modifying the variable
values."
  (setq-default
   dotspacemacs-editing-style 'vim
   dotspacemacs-verbose-loading nil
   dotspacemacs-startup-banner 'official
   dotspacemacs-startup-lists '(recents projects)
   dotspacemacs-themes '(spacemacs-dark
                         misterioso
                         oldlace
                         seoul256
                         spacemacs-light
                         monokai
                         )
   dotspacemacs-colorize-cursor-according-to-state t
   dotspacemacs-default-font '("Source Code Pro"
                               :size 15
                               :weight normal
                               :width normal
                               :powerline-scale 1.1)
   dotspacemacs-line-numbers 'relative
   dotspacemacs-leader-key "SPC"
   dotspacemacs-emacs-leader-key "M-m"
   dotspacemacs-major-logmode-leader-key ","
   dotspacemacs-major-mode-emacs-leader-key "C-M-m"
   dotspacemacs-command-key ":"
   dotspacemacs-remap-Y-to-y$ t
   dotspacemacs-auto-save-file-location 'cache
   dotspacemacs-use-ido nil
   dotspacemacs-helm-resize nil
   dotspacemacs-helm-no-header nil
   dotspacemacs-helm-position 'bottom
   dotspacemacs-enable-paste-micro-state nil
   dotspacemacs-which-key-delay 0.4
   dotspacemacs-which-key-position 'bottom
   dotspacemacs-loading-progress-bar t
   dotspacemacs-fullscreen-at-startup nil
   dotspacemacs-fullscreen-use-non-native nil
   dotspacemacs-maximized-at-startup nil
   dotspacemacs-active-transparency 90
   dotspacemacs-inactive-transparency 90
   dotspacemacs-mode-line-unicode-symbols t
   dotspacemacs-smooth-scrolling t
   dotspacemacs-smartparens-strict-mode nil
   dotspacemacs-highlight-delimiters 'all
   dotspacemacs-persistent-server nil
   dotspacemacs-search-tools '("rg" "ag" "pt" "ack" "grep")
   dotspacemacs-default-package-repository nil
   ))

(defun dotspacemacs/user-init ()
  "Initialization function for user code.
It is called immediately after `dotspacemacs/init'.  You are free to put any
user code."
  )

(defun copy-file-name-to-clipboard ()
  "Copy the current buffer file name to the clipboard."
  (interactive)
  (let ((filename (if (equal major-mode 'dired-mode)
                      default-directory
                    (buffer-file-name))))
    (when filename
      (kill-new filename)
      (message "Copied buffer file name '%s' to the clipboard." filename))))

(defconst simon-shopify//default-ruby-version "2.4.4")

(defun simon-shopify//file-name-in-project-root (file-name)
  (concat (file-name-as-directory (projectile-project-root)) file-name))

(defun simon-shopify//read-ruby-version ()
  (lexical-let ((ruby-version-file-path (simon-shopify//file-name-in-project-root ".ruby-version")))
    (cond
     ((file-exists-p ruby-version-file-path)
      (with-temp-buffer
        (insert-file-contents (simon-shopify//ruby-version-file-path))
        (buffer-string)))
     (t simon-shopify//default-ruby-version))))

(defun simon-shopify//use-local-rubocop ()
  (lexical-let ((rubocop-path (simon-shopify//file-name-in-project-root "bin/rubocop")))
    (when (file-executable-p rubocop-path)
      (setq flycheck-ruby-rubocop-executable rubocop-path))))

(defun simon-shopify//enter-chruby ()
  (lexical-let ((ruby-version (simon-shopify//read-ruby-version)))
    (chruby ruby-version)
    ruby-version))

(defun simon-shopify//ruby-mode-hook ()
  (simon-shopify//use-local-rubocop)
  ;; (lexical-let* ((delimiter-face-foreground (face-foreground 'enh-ruby-string-delimiter-face)))
  ;;   (set-face-foreground 'enh-ruby-regexp-delimiter-face delimiter-face-foreground)
  ;;   (set-face-foreground 'enh-ruby-heredoc-delimiter-face delimiter-face-foreground))
  (lexical-let* ((ruby-version (simon-shopify//enter-chruby))
                 (ruby-version-directory (concat "/opt/rubies/" ruby-version))
                 (ruby-program (concat (file-name-as-directory ruby-version-directory) "bin/ruby")))
    (when (file-executable-p ruby-program)
      (setq enh-ruby-program ruby-program
            flycheck-ruby-executable ruby-program))))

(defun simon-shopify//configure-ruby ()
  (setq enh-ruby-add-encoding-comment-on-save nil)
  (chruby simon-shopify//default-ruby-version)
  (add-hook 'enh-ruby-mode-hook 'simon-shopify//ruby-mode-hook t)
  (add-hook 'ruby-mode-hook 'simon-shopify//ruby-mode-hook t)
  (remove-hook 'enh-ruby-mode-hook 'rubocop-mode)
  (remove-hook 'ruby-mode-hook 'rubocop-mode))

(defun simon-shopify//rb-config (key)
  (lexical-let ((command (concat "ruby -e 'print(RbConfig::CONFIG[%(" key ")])'")))
    (shell-command-to-string command)))

(defun dotspacemacs/user-config ()
  (simon-shopify//configure-ruby)

  ;; faster projectile
  (setq projectile-enable-caching t)
  (setq shell-file-name "/bin/sh")

  ;; line wrap
  (add-hook 'hack-local-variables-hook (lambda ()
                                         (setq truncate-lines t)))

  ;; Indentation
  (setq-default rust-indent-offset 2)
  (setq-default
   ;; js2-mode
   js2-basic-offset 2
   ;; web-mode
   css-indent-offset 2
   web-mode-markup-indent-offset 2
   web-mode-css-indent-offset 2
   web-mode-code-indent-offset 2
   web-mode-attr-indent-offset 2)
  (add-hook 'js2-mode-hook (lambda ()
                             (setq js2-basic-offset 2)
                             (setq js2-mode-show-parse-errors nil)
                             (setq js2-mode-show-strict-warnings nil)
                             ))
  ;; Default extensions
  (add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))
  (add-to-list 'auto-mode-alist '("\\.tsx\\'" . typescript-mode))

  ;; Flycheck
  (global-flycheck-mode)

  ;; Typescript
  (with-eval-after-load 'tide
    (flycheck-add-mode 'typescript-tide 'typescript-tsx-mode))

  ;; Tern autocomplete
  (push '(company-tern) company-backends-web-mode)

  ;; Indent guide
  (spacemacs/toggle-highlight-indentation-current-column-on)

  ;; Show line width
  (spacemacs/toggle-fill-column-indicator-on)
  ;; max column display
  (setq-default fill-column 120)

  ;; Powerline
  ;; (fancy-battery-mode)
  (spacemacs/toggle-mode-line-major-mode-off)
  (spacemacs/toggle-mode-line-minor-modes-off)
  (setq powerline-default-separator 'nil)
  (spaceline-compile)

  ;; Flycheck
  ;; (flycheck-pos-tip-mode)
  ;; (flycheck-display-error-at-point)
  (setq flycheck-check-syntax-automatically '(save mode-enabled))

  ;; Elixir
  (setq flycheck-elixir-credo-strict t)

  ;; auto-complete
  (global-company-mode)
  (setq company-minimum-prefix-length 1)
  (setq company-idle-delay 1)
  (let ((map company-active-map))
    ;; use TAB to auto-complete instead of RET
    ;;    (define-key map [escape] 'company-abort)
    (define-key map [return] 'nil)
    (define-key map (kbd "RET") 'nil)
    (define-key map [tab] 'company-complete)
    (define-key map (kbd "TAB") 'company-complete-selection)
    (define-key map (kbd "<tab>") 'company-complete-selection))
  ;; autocomplete keybinding
  (define-key evil-insert-state-map (kbd "C-SPC") 'company-complete)


  ;; evil save
  (evil-ex-define-cmd "W" 'save-buffer)

  ;; misc
  (add-hook 'hack-local-variables-hook (lambda () (setq truncate-lines t)))

  ;; navigation
  (spacemacs/set-leader-keys "SPC" 'avy-goto-char-timer)

  ;; parens
  (remove-hook 'prog-mode-hook #'smartparens-mode)
  (turn-off-smartparens-mode)

  ;; Ligature
  ;; (drpandemic-symbols/init)

  ;; Newline at end of file
  (setq require-final-newline t)
  (setq mode-require-final-newline t)

  ;; org-mode
  (setq org-log-done 'time)

  ;; show trailing whitspaces
  (setq whitespace-style '(face trailing tabs))
  (custom-set-faces
   '(whitespace-tab ((t (:background "red")))))
  (global-whitespace-mode)
  )

;; Do not write anything past this comment. This is where Emacs will
;; auto-generate custom variable definitions.
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(magit-commit-arguments
   (quote
    ("--verbose")))
 '(package-selected-packages
   (quote
    (php-extras php-mode winum unfill toml-mode rvm ruby-tools ruby-test-mode rubocop rspec-mode robe rbenv rake racer shut-up minitest fuzzy flycheck-rust seq flycheck-credo chruby cargo rust-mode bundler inf-ruby dash stickyfunc-enhance srefactor sql-indent pdf-tools tablist omnisharp helm-cscope xcscope disaster csharp-mode company-c-headers cmake-mode clang-format evil-easymotion helm-purpose window-purpose imenu-list vmd-mode nginx-mode yaml-mode magit-gh-pulls github-search github-clone github-browse-file gist gh marshal logito pcache ht yapfify pyvenv pytest pyenv-mode py-isort pip-requirements live-py-mode hy-mode helm-pydoc cython-mode company-anaconda anaconda-mode pythonic powerline pug-mode spinner ob-elixir org markdown-mode json-snatcher json-reformat multiple-cursors js2-mode hydra parent-mode hide-comnt projectile request haml-mode gitignore-mode fringe-helper git-gutter+ git-gutter pos-tip flycheck flx magit magit-popup git-commit with-editor smartparens iedit anzu evil goto-chg undo-tree highlight sbt-mode scala-mode diminish web-completion-data dash-functional tern s bind-map bind-key yasnippet packed company elixir-mode pkg-info epl helm avy helm-core async auto-complete popup package-build company-emacs-eclim racket-mode faceup eclim skewer-mode simple-httpd dumb-jump f smooth-scrolling ruby-end page-break-lines leuven-theme buffer-move bracketed-paste xterm-color ws-butler window-numbering which-key web-mode web-beautify volatile-highlights vi-tilde-fringe uuidgen use-package toc-org tagedit spacemacs-theme spaceline solarized-theme smeargle slim-mode shell-pop scss-mode sass-mode restart-emacs rainbow-mode rainbow-identifiers rainbow-delimiters quelpa popwin persp-mode pcre2el paradox orgit org-plus-contrib org-bullets open-junk-file noflet neotree mwim multi-term move-text mmm-mode markdown-toc magit-gitflow macrostep lorem-ipsum livid-mode linum-relative link-hint less-css-mode json-mode js2-refactor js-doc jade-mode info+ indent-guide ido-vertical-mode hungry-delete hl-todo highlight-parentheses highlight-numbers highlight-indentation help-fns+ helm-themes helm-swoop helm-projectile helm-mode-manager helm-make helm-gitignore helm-flx helm-descbinds helm-css-scss helm-company helm-c-yasnippet helm-ag google-translate golden-ratio gitconfig-mode gitattributes-mode git-timemachine git-messenger git-link git-gutter-fringe git-gutter-fringe+ gh-md flycheck-pos-tip flycheck-mix flx-ido fill-column-indicator fancy-battery eyebrowse expand-region exec-path-from-shell evil-visualstar evil-visual-mark-mode evil-unimpaired evil-tutor evil-surround evil-search-highlight-persist evil-numbers evil-nerd-commenter evil-mc evil-matchit evil-magit evil-lisp-state evil-indent-plus evil-iedit-state evil-exchange evil-escape evil-ediff evil-args evil-anzu eval-sexp-fu eshell-z eshell-prompt-extras esh-help ensime emmet-mode elisp-slime-nav diff-hl define-word company-web company-tern company-statistics company-quickhelp column-enforce-mode color-identifiers-mode coffee-mode clean-aindent-mode auto-yasnippet auto-highlight-symbol auto-compile alchemist aggressive-indent adaptive-wrap ace-window ace-link ace-jump-helm-line ac-ispell))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(company-tooltip-common ((t (:inherit company-tooltip :weight bold :underline nil))))
 '(company-tooltip-common-selection ((t (:inherit company-tooltip-selection :weight bold :underline nil)))))
(defun dotspacemacs/emacs-custom-settings ()
  "Emacs custom settings.
This is an auto-generated function, do not modify its content directly, use
Emacs customize menu instead.
This function is called at the very end of Spacemacs initialization."
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(magit-commit-arguments (quote ("--verbose")))
 '(package-selected-packages
   (quote
    (rjsx-mode magithub ghub+ apiwrap magit-svn json-navigator hierarchy gitignore-templates evil-goggles dotenv-mode php-extras php-mode winum unfill toml-mode rvm ruby-tools ruby-test-mode rubocop rspec-mode robe rbenv rake racer shut-up minitest fuzzy flycheck-rust seq flycheck-credo chruby cargo rust-mode bundler inf-ruby dash stickyfunc-enhance srefactor sql-indent pdf-tools tablist omnisharp helm-cscope xcscope disaster csharp-mode company-c-headers cmake-mode clang-format evil-easymotion helm-purpose window-purpose imenu-list vmd-mode nginx-mode yaml-mode magit-gh-pulls github-search github-clone github-browse-file gist gh marshal logito pcache ht yapfify pyvenv pytest pyenv-mode py-isort pip-requirements live-py-mode hy-mode helm-pydoc cython-mode company-anaconda anaconda-mode pythonic powerline pug-mode spinner ob-elixir org markdown-mode json-snatcher json-reformat multiple-cursors js2-mode hydra parent-mode hide-comnt projectile request haml-mode gitignore-mode fringe-helper git-gutter+ git-gutter pos-tip flycheck flx magit magit-popup git-commit with-editor smartparens iedit anzu evil goto-chg undo-tree highlight sbt-mode scala-mode diminish web-completion-data dash-functional tern s bind-map bind-key yasnippet packed company elixir-mode pkg-info epl helm avy helm-core async auto-complete popup package-build company-emacs-eclim racket-mode faceup eclim skewer-mode simple-httpd dumb-jump f smooth-scrolling ruby-end page-break-lines leuven-theme buffer-move bracketed-paste xterm-color ws-butler window-numbering which-key web-mode web-beautify volatile-highlights vi-tilde-fringe uuidgen use-package toc-org tagedit spacemacs-theme spaceline solarized-theme smeargle slim-mode shell-pop scss-mode sass-mode restart-emacs rainbow-mode rainbow-identifiers rainbow-delimiters quelpa popwin persp-mode pcre2el paradox orgit org-plus-contrib org-bullets open-junk-file noflet neotree mwim multi-term move-text mmm-mode markdown-toc magit-gitflow macrostep lorem-ipsum livid-mode linum-relative link-hint less-css-mode json-mode js2-refactor js-doc jade-mode info+ indent-guide ido-vertical-mode hungry-delete hl-todo highlight-parentheses highlight-numbers highlight-indentation help-fns+ helm-themes helm-swoop helm-projectile helm-mode-manager helm-make helm-gitignore helm-flx helm-descbinds helm-css-scss helm-company helm-c-yasnippet helm-ag google-translate golden-ratio gitconfig-mode gitattributes-mode git-timemachine git-messenger git-link git-gutter-fringe git-gutter-fringe+ gh-md flycheck-pos-tip flycheck-mix flx-ido fill-column-indicator fancy-battery eyebrowse expand-region exec-path-from-shell evil-visualstar evil-visual-mark-mode evil-unimpaired evil-tutor evil-surround evil-search-highlight-persist evil-numbers evil-nerd-commenter evil-mc evil-matchit evil-magit evil-lisp-state evil-indent-plus evil-iedit-state evil-exchange evil-escape evil-ediff evil-args evil-anzu eval-sexp-fu eshell-z eshell-prompt-extras esh-help ensime emmet-mode elisp-slime-nav diff-hl define-word company-web company-tern company-statistics company-quickhelp column-enforce-mode color-identifiers-mode coffee-mode clean-aindent-mode auto-yasnippet auto-highlight-symbol auto-compile alchemist aggressive-indent adaptive-wrap ace-window ace-link ace-jump-helm-line ac-ispell))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(company-tooltip-common ((t (:inherit company-tooltip :weight bold :underline nil))))
 '(company-tooltip-common-selection ((t (:inherit company-tooltip-selection :weight bold :underline nil)))))
)
