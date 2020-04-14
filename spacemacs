;
; - * -mode:emacs - lisp - * - ;
; This file is loaded by Spacemacs at startup.;
; It must be stored in your home directory.

(defun dotspacemacs/layers ()
  "Configuration Layers declaration.
You should not put any user code in this function besides modifying the variable
values."
  (setq-default
   ;; Base distribution to use. This is a layer contained in the directory
   ;; `+distribution'. For now available distributions are `spacemacs-base'
   ;; or `spacemacs'. (default 'spacemacs)
   dotspacemacs-distribution 'spacemacs
   ;; List of additional paths where to look for configuration layers.
   ;; Paths must have a trailing slash (i.e. `~/.mycontribs/')
   dotspacemacs-configuration-layer-path '()
   ;; List of configuration layers to load. If it is the symbol `all' instead
   ;; of a list then all discovered layers will be installed.
   dotspacemacs-configuration-layers
   '(systemd
   elm
     csv
     rust
     ruby
     sql
     nginx
     yaml
     python
     elixir
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
     syntax-checking
     version-control
     ;; react
     scala
     java
     csharp
     c-c++
     semantic
     cscope
     php
     ocaml
     reason
     javascript
     multiple-cursors
     (typescript :variables
                 typescript-fmt-tool 'typescript-formatter)                                       ;
     ;; flow-type
     ;; (drpandemic-javascript :variables drpandemic-javascript-enable-flycheck-flow nil flow-type-enable-eldoc-type-info nil)
     ;; drpandemic-symbols
     ;; drpandemic-javascript
     (c-c++ :variables c-c++-default-mode-for-headers 'c++-mode)
     (c-c++ :variables c-c++-enable-clang-support t)
     ;; (colors :variables colors-enable-nyan-cat-progress-bar t)
     )
   ;; List of additional packages that will be installed without (spacemacs/toggle-indent-guide-globally-on)(spacemacs/toggle-indent-guide-globally-on)being
   ;; wrapped in a layer. If you need some configuration for these
   ;; packages then consider to create a layer, you can also put the
   ;; configuration in `dotspacemacs/config'.
   dotspacemacs-additional-packages
   '(
     ;; rjsx-mode
     ;; company-flow
     vue-mode
     ;; eglot
     gdscript-mode
     )
   ;; A list of packages and/or extensions that will not be install and loaded.
   dotspacemacs-excluded-packages
   '(
     smartparens
     emmet-mode
     )
   ;; If non-nil spacemacs will delete any orphan packages, i.e. packages that
   ;; are declared in a layer which is not a member of
   ;; the list `dotspacemacs-configuration-layers'. (default t)
   dotspacemacs-delete-orphan-packages t))

(defun dotspacemacs/config ()
  (setq-default
   flycheck-scalastyle-jar "~/bin/scalastyle_2.11-0.6.0.jar"
   )
  )

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
   dotspacemacs-themes '(seoul256
                         spacemacs-dark
                         misterioso
                         oldlace
                         spacemacs-light
                         monokai
                         )
   dotspacemacs-colorize-cursor-according-to-state t
   dotspacemacs-default-font '("Hasklig"
                               :size 30
                               :weight normal
                               :width normal
                               :powerline-scale 1.1)
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
   dotspacemacs-line-numbers 'relative
   dotspacemacs-elpa-timeout 5
   rust-format-on-save t
   ))

(defun dotspacemacs/user-init ()
  "Initialization function for user code.
It is called immediately after `dotspacemacs/init'.  You are free to put any
user code."
  )

(defun dotspacemacs/user-config ()
  ;; c#
  (setq-default
   omnisharp-server-executable-path "/opt/omnisharp-roslyn/omnisharp"
   )
  (setq-default omnisharp--curl-executable-path "/usr/bin/curl")

  ;; ;; rust
  ;; (add-hook 'rust-mode-hook 'flycheck-disable-checker)
  (setq rust-format-on-save t)
  (setq-default lsp-ui-doc-enable nil)

  ;; whitespace
  (setq whitespace-style '(face trailing tabs))
  ;; (custom-set-faces
  ;;  '(whitespace-tab ((t (:background "red")))))
  (global-whitespace-mode)
  ;; Indentation
  (setq-default js-indent-level 4)
  (setq-default typescript-indent-level 4)
  (setq-default standard-indent 4)
  (setq-default rust-indent-offset 4)
  (setq-default
   ;; js2-mode
   js2-basic-offset 4
   ;; web-mode
   css-indent-offset 4
   web-mode-markup-indent-offset 4
   web-mode-css-indent-offset 4
   web-mode-code-indent-offset 4
   web-mode-attr-indent-offset 4)
  (add-hook 'js2-mode-hook (lambda ()
                             (setq js2-basic-offset 4)
                             (setq js2-mode-show-parse-errors nil)
                             (setq js2-mode-show-strict-warnings nil)
                             ))
  ;; Default to react
  ;; (add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))

  ;; typescript
  (custom-set-variables
   '(flycheck-typescript-tslint-executable "~/.nvm/versions/node/v9.5.0/bin/tslint"))

  ;; Tern autocomplete
  (push '(company-tern) company-backends-web-mode)

  ;; Indent guide
  (spacemacs/toggle-highlight-indentation-current-column-on)

  ;; Show line width
  (spacemacs/toggle-fill-column-indicator-on)

  ;; Powerline
  (fancy-battery-mode)
  (spacemacs/toggle-mode-line-minor-modes-off)
  (setq powerline-default-separator 'nil)
  (spaceline-compile)

  ;; Flycheck
  (flycheck-pos-tip-mode)
  (flycheck-display-error-at-point)
  (setq flycheck-check-syntax-automatically '(save mode-enabled))

  ;; Elixir
  (setq flycheck-elixir-credo-strict t)

  ;; auto-complete
  (global-company-mode)
  (setq company-minimum-prefix-length 1)
  (let ((map company-active-map))
    ;; use TAB to auto-complete instead of RET
    ;;    (define-key map [escape] 'company-abort)
    (define-key map [return] 'nil)
    (define-key map (kbd "RET") 'nil)
    (define-key map [tab] 'company-complete)
    (define-key map (kbd "TAB") 'company-complete-selection)
    (define-key map (kbd "<tab>") 'company-complete-selection))

  (global-set-key (kbd "C-SPC") 'company-complete)

  ;; evil save
  (evil-ex-define-cmd "W" 'save-buffer)

  ;; misc
  (add-hook 'hack-local-variables-hook (lambda () (setq truncate-lines t)))

  ;; navigation
  (spacemacs/set-leader-keys "SPC" 'avy-goto-char-timer)

  ;; java
  (setq eclim-eclipse-dirs "/usr/lib/eclipse/"
        eclim-executable "/usr/lib/eclipse/eclim")

  ;; scala
  (setq-default flycheck-scalastylerc "~/.config/scalastyle_config.xml")

  ;; parens
  (remove-hook 'prog-mode-hook #'smartparens-mode)
  (turn-off-smartparens-mode)

  ;; whitespace
  (setq-default show-trailing-whitespace t)

  ;; max column display
  (setq-default fill-column 120)

  ;; c++
  (add-hook 'before-save-hook 'clang-format-hook)
  (defun clang-format-hook ()
    (case major-mode
      ((c++-mode) (clang-format-buffer))))

  (add-hook 'c++-mode-hook 'clang-checker-hook)
  (defun clang-checker-hook ()
    (flycheck-select-checker 'c/c++-clang))

  (setq-default dotspacemacs-configuration-layers
                '((c-c++ :variables c-c++-enable-clang-support t)))

  ;; Ligature
  ;; (drpandemic-symbols/init)

  ;; Fix auto paste
  (add-hook 'spacemacs-buffer-mode-hook (lambda ()
    (set (make-local-variable 'mouse-1-click-follows-link) nil)))

  ;; Newline at end of file
  (setq require-final-newline t)
  (setq mode-require-final-newline t)

  (setq dotspacemacs-distinguish-gui-tab t)

  ;; dumb-jump by default
  (setq-default spacemacs-default-jump-handlers '(dumb-jump-go evil-goto-definition))
  (spacemacs/set-leader-keys "jg" #'dumb-jump-go)
  (setq dumb-jump-max-find-time 10)

  ;; golden ratio
  (golden-ratio-mode)
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
    ("--verbose" "--gpg-sign=DrPandemic <bipbip500@gmail.com>")))
 '(package-selected-packages
   (quote
    (winum unfill toml-mode rvm ruby-tools ruby-test-mode rubocop rspec-mode robe rbenv rake racer shut-up minitest fuzzy flycheck-rust seq flycheck-credo chruby cargo rust-mode bundler inf-ruby dash stickyfunc-enhance srefactor sql-indent pdf-tools tablist omnisharp helm-cscope xcscope disaster csharp-mode company-c-headers cmake-mode clang-format evil-easymotion helm-purpose window-purpose imenu-list vmd-mode nginx-mode yaml-mode magit-gh-pulls github-search github-clone github-browse-file gist gh marshal logito pcache ht yapfify pyvenv pytest pyenv-mode py-isort pip-requirements live-py-mode hy-mode helm-pydoc cython-mode company-anaconda anaconda-mode pythonic powerline pug-mode spinner ob-elixir org markdown-mode json-snatcher json-reformat multiple-cursors js2-mode hydra parent-mode hide-comnt projectile request haml-mode gitignore-mode fringe-helper git-gutter+ git-gutter pos-tip flycheck flx magit magit-popup git-commit with-editor smartparens iedit anzu evil goto-chg undo-tree highlight sbt-mode scala-mode diminish web-completion-data dash-functional tern s bind-map bind-key yasnippet packed company elixir-mode pkg-info epl helm avy helm-core async auto-complete popup package-build company-emacs-eclim racket-mode faceup eclim skewer-mode simple-httpd dumb-jump f smooth-scrolling ruby-end page-break-lines leuven-theme buffer-move bracketed-paste xterm-color ws-butler window-numbering which-key web-mode web-beautify volatile-highlights vi-tilde-fringe uuidgen use-package toc-org tagedit spacemacs-theme spaceline solarized-theme smeargle slim-mode shell-pop scss-mode sass-mode restart-emacs rainbow-mode rainbow-identifiers rainbow-delimiters quelpa popwin persp-mode pcre2el paradox orgit org-plus-contrib org-bullets open-junk-file noflet neotree mwim multi-term move-text mmm-mode markdown-toc magit-gitflow macrostep lorem-ipsum livid-mode linum-relative link-hint less-css-mode json-mode js2-refactor js-doc jade-mode info+ indent-guide ido-vertical-mode hungry-delete hl-todo highlight-parentheses highlight-numbers highlight-indentation help-fns+ helm-themes helm-swoop helm-projectile helm-mode-manager helm-make helm-gitignore helm-flx helm-descbinds helm-css-scss helm-company helm-c-yasnippet helm-ag google-translate golden-ratio gitconfig-mode gitattributes-mode git-timemachine git-messenger git-link git-gutter-fringe git-gutter-fringe+ gh-md flycheck-pos-tip flycheck-mix flx-ido fill-column-indicator fancy-battery eyebrowse expand-region exec-path-from-shell evil-visualstar evil-visual-mark-mode evil-unimpaired evil-tutor evil-surround evil-search-highlight-persist evil-numbers evil-nerd-commenter evil-mc evil-matchit evil-magit evil-lisp-state evil-indent-plus evil-iedit-state evil-exchange evil-escape evil-ediff evil-args evil-anzu eval-sexp-fu eshell-z eshell-prompt-extras esh-help ensime emmet-mode elisp-slime-nav diff-hl define-word company-web company-tern company-statistics company-quickhelp column-enforce-mode color-identifiers-mode coffee-mode clean-aindent-mode auto-yasnippet auto-highlight-symbol auto-compile alchemist aggressive-indent adaptive-wrap ace-window ace-link ace-jump-helm-line ac-ispell))))
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
 '(flycheck-typescript-tslint-executable "~/.nvm/versions/node/v9.5.0/bin/tslint")
 '(magit-commit-arguments
   (quote
    ("--verbose" "--gpg-sign=DrPandemic <bipbip500@gmail.com>")))
 '(package-selected-packages
   (quote
    (systemd winum unfill toml-mode rvm ruby-tools ruby-test-mode rubocop rspec-mode robe rbenv rake racer shut-up minitest fuzzy flycheck-rust seq flycheck-credo chruby cargo rust-mode bundler inf-ruby dash stickyfunc-enhance srefactor sql-indent pdf-tools tablist omnisharp helm-cscope xcscope disaster csharp-mode company-c-headers cmake-mode clang-format evil-easymotion helm-purpose window-purpose imenu-list vmd-mode nginx-mode yaml-mode magit-gh-pulls github-search github-clone github-browse-file gist gh marshal logito pcache ht yapfify pyvenv pytest pyenv-mode py-isort pip-requirements live-py-mode hy-mode helm-pydoc cython-mode company-anaconda anaconda-mode pythonic powerline pug-mode spinner ob-elixir org markdown-mode json-snatcher json-reformat multiple-cursors js2-mode hydra parent-mode hide-comnt projectile request haml-mode gitignore-mode fringe-helper git-gutter+ git-gutter pos-tip flycheck flx magit magit-popup git-commit with-editor smartparens iedit anzu evil goto-chg undo-tree highlight sbt-mode scala-mode diminish web-completion-data dash-functional tern s bind-map bind-key yasnippet packed company elixir-mode pkg-info epl helm avy helm-core async auto-complete popup package-build company-emacs-eclim racket-mode faceup eclim skewer-mode simple-httpd dumb-jump f smooth-scrolling ruby-end page-break-lines leuven-theme buffer-move bracketed-paste xterm-color ws-butler window-numbering which-key web-mode web-beautify volatile-highlights vi-tilde-fringe uuidgen use-package toc-org tagedit spacemacs-theme spaceline solarized-theme smeargle slim-mode shell-pop scss-mode sass-mode restart-emacs rainbow-mode rainbow-identifiers rainbow-delimiters quelpa popwin persp-mode pcre2el paradox orgit org-plus-contrib org-bullets open-junk-file noflet neotree mwim multi-term move-text mmm-mode markdown-toc magit-gitflow macrostep lorem-ipsum livid-mode linum-relative link-hint less-css-mode json-mode js2-refactor js-doc jade-mode info+ indent-guide ido-vertical-mode hungry-delete hl-todo highlight-parentheses highlight-numbers highlight-indentation help-fns+ helm-themes helm-swoop helm-projectile helm-mode-manager helm-make helm-gitignore helm-flx helm-descbinds helm-css-scss helm-company helm-c-yasnippet helm-ag google-translate golden-ratio gitconfig-mode gitattributes-mode git-timemachine git-messenger git-link git-gutter-fringe git-gutter-fringe+ gh-md flycheck-pos-tip flycheck-mix flx-ido fill-column-indicator fancy-battery eyebrowse expand-region exec-path-from-shell evil-visualstar evil-visual-mark-mode evil-unimpaired evil-tutor evil-surround evil-search-highlight-persist evil-numbers evil-nerd-commenter evil-mc evil-matchit evil-magit evil-lisp-state evil-indent-plus evil-iedit-state evil-exchange evil-escape evil-ediff evil-args evil-anzu eval-sexp-fu eshell-z eshell-prompt-extras esh-help ensime emmet-mode elisp-slime-nav diff-hl define-word company-web company-tern company-statistics company-quickhelp column-enforce-mode color-identifiers-mode coffee-mode clean-aindent-mode auto-yasnippet auto-highlight-symbol auto-compile alchemist aggressive-indent adaptive-wrap ace-window ace-link ace-jump-helm-line ac-ispell))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(company-tooltip-common ((t (:inherit company-tooltip :weight bold :underline nil))))
 '(company-tooltip-common-selection ((t (:inherit company-tooltip-selection :weight bold :underline nil))))
 '(whitespace-tab ((t (:background "red")))))
)
