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
   '(
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
     react
     scala
     java
     csharp
     c-c++
     semantic
     cscope
     php
     ocaml
     reason
     ;; flow-type
     (drpandemic-javascript :variables drpandemic-javascript-enable-flycheck-flow nil flow-type-enable-eldoc-type-info nil)
     drpandemic-symbols
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
  (setq-default
   omnisharp-server-executable-path "/opt/omnisharp-roslyn/OmniSharp.exe"
   )
  )

(defun dotspacemacs/init ()
  "Initialization function.
This function is called at the very startup of Spacemacs initialization
before layers configuration.
You should not put any user code in there besides modifying the variable
values."
  ;; This setq-default sexp is an exhaustive list of all the supported
  ;; spacemacs settings.
  (setq-default
   ;; One of `vim', `emacs' or `hybrid'. Evil is always enabled but if the
   ;; variable is `emacs' then the `holy-mode' is enabled at startup. `hybrid'
   ;; uses emacs key bindings for vim's insert mode, but otherwise leaves evil
   ;; unchanged. (default 'vim)
   dotspacemacs-editing-style 'vim
   ;; If non nil output loading progress in `*Messages*' buffer. (default nil)
   dotspacemacs-verbose-loading nil
   ;; Specify the startup banner. Default value is `offlanguage withicial', it displays
   ;; the official spacemacs logo. An integer value is the index of text
   ;; banner, `random' choosCloudes a random text banner in `core/banners'
   ;; directory. A string value must be a path to an image format supported
   ;; by your Emacs build.
   ;; If the value is nil then no banner is displayed. (default 'official)
   dotspacemacs-startup-banner 'official
   ;; List of items to show in the startup buffer. If nil it is disabled.
   ;; Possible values are: `recents' `bookmarks' `projects'.
   ;; (default '(recents projects))
   dotspacemacs-startup-lists '(recents projects)
   ;; List of themes, the first of the list is loaded when spacemacs starts.
   ;; Press <SPC> T n to cycle to the next theme in the list (works great
   ;; with 2 themes variants, one dark and one light)
   dotspacemacs-themes '(spacemacs-dark
                         misterioso
                         oldlace
                         seoul256
                         spacemacs-light
                         monokai
                         )
   ;; If non nil the cursor color matches the state color.
   dotspacemacs-colorize-cursor-according-to-state t
   ;; Default font. `powerline-scale' allows to quickly tweak the mode-line
   ;; size to make separators look notconfiguconfigurationration too crappy.
   dotspacemacs-default-font '("Hasklig"
                               :size 15
                               :weight normal
                               :width normal
                               :powerline-scale 1.1)
   ;; The leader key
   dotspacemacs-leader-key "SPC"
   ;; The leader key accessible in `emacs state' and `insert state'
   ;; (default "M-m")
   dotspacemacs-emacs-leader-key "M-m"
   ;; Major mode leader key is a shortcut key which is the equivalent of
   ;; pressing `<leader> m`. Set it to `nil` to disable it. (default ",")
   dotspacemacs-major-logmode-leader-key ","
   ;; Major mode leader key accessible in `emacs state' and `insert state'.
   ;; (default "C-M-m)
   dotspacemacs-major-mode-emacs-leader-key "C-M-m"
   ;; The command key used for Evil commands (ex-commands) and
   ;; Emacs commands (M-x).
   ;; By default the command key is `:' so ex-commands are executed like in Vim
   ;; with `:' and Emacs commands are executed with `<leader> :'.
   dotspacemacs-command-key ":"
   ;; If non nil `Y' is remapped to `y$'. (default t)
   dotspacemacs-remap-Y-to-y$ t
   ;; Location where to auto-save files. Possible values are `original' to
   ;; auto-save the file in-place, `cache' to auto-save the file to another
   ;; file stored in the cache directory and `nil' to disable auto-saving.
   ;; (default 'cache)
   dotspacemacs-auto-save-file-location 'cache
   ;; If non nil then `ido' replaces `helm' for some commands. For now only
   ;; `find-files' (SPC f f), `find-spacemacs-file' (SPC f e s), and
   ;; `find-contrib-file' (SPC f e c) are replaced. (default nil)
   dotspacemacs-use-ido nil
   ;; If non nil, `helm' will try to miminimize the space it uses. (default nil)
   dotspacemacs-helm-resize nil
   ;; if non nil, the helm header is hidden when there is only one source.
   ;; (default nil)
   dotspacemacs-helm-no-header nil
   ;; define the position to display `helm', options are `bottom', `top',
   ;; `left', or `right'. (default 'bottom)
   dotspacemacs-helm-position 'bottom
   ;; If non nil the paste micro-state is enabled. When enabled pressing `p`
   ;; several times cycle between the kill ring content. (default nil)
   dotspacemacs-enable-paste-micro-state nil
   ;; Which-key delay in seconds. The which-key buffer is the popup listing
   ;; the commands bound to the current keystroke sequence. (default 0.4)
   dotspacemacs-which-key-delay 0.4
   ;; Which-key frame position. Possible values are `right', `bottom' and
   ;; `right-then-bottom'. right-then-bottom tries to display the frame to the
   ;; right; if there is insufficient space it displays it at the bottom.
   ;; (default 'bottom)
   dotspacemacs-which-key-position 'bottom
   ;; If non nil a progress bar is displayed when spacemacs is loading. This
   ;; may increase the boot time on some systems and emacs builds, set it to
   ;; nil to boost the loading time. (default t)
   dotspacemacs-loading-progress-bar t
   ;; If non nil the frame is fullscreen when Emacs starts up. (default nil)
   ;; (Emacs 24.4+ only)
   dotspacemacs-fullscreen-at-startup nil
   ;; If non nil `spacemacs/toggle-fullscreen' will not use native fullscreen.
   ;; Use to disable fullscreen animations in OSX. (default nil)
   dotspacemacs-fullscreen-use-non-native nil
   ;; If non nil the frame is maximized when Emacs starts up.
   ;; Takes effect only if `dotspacemacs-fullscreen-at-startup' is nil.
   ;; (default nil) (Emacs 24.4+ only)
   dotspacemacs-maximized-at-startup nil
   ;; A value from the range (0..100), in increasing opacity, which describes
   ;; the transparency level of a frame when it's active or selected.
   ;; Transparency can be toggled through `toggle-transparency'. (default 90)
   dotspacemacs-active-transparency 90
   ;; A value from the range (0..100), in increasing opacity, which describes
   ;; the transparency level of a frame when it's inactive or deselected.
   ;; Transparency can be toggled through `toggle-transparency'. (default 90)
   dotspacemacs-inactive-transparency 90
   ;; If non nil unicode symbols are displayed in the mode line. (default t)
   dotspacemacs-mode-line-unicode-symbols t
   ;; If non nil smooth scrolling (native-scrolling) is enabled. Smooth
   ;; scrolling overrides the default behavior of Emacs which recenters the
   ;; point when it reaches the top or bottom of the screen. (default t)
   dotspacemacs-smooth-scrolling t
   ;; If non-nil smartparens-strict-mode will be enabled in programming modes.
   ;; (default nil)
   dotspacemacs-smartparens-strict-mode nil
   ;; Select a scope to highlight delimiters. Possible values are `any',
   ;; `current', `all' or `nil'. Default is `all' (highlight any scope and
   ;; emphasis the current one). (default 'all)
   dotspacemacs-highlight-delimiters 'all
   ;; If non nil advises quit functions to keep server open when quitting.
   ;; (default nil)
   dotspacemacs-persistent-server nil
   ;; List of search tool executable names. Spacemacs uses the first installed
   ;; tool of the list. Supported tools are `ag', `pt', `ack' and `grep'.
   ;; (default '("ag" "pt" "ack" "grep"))
   dotspacemacs-search-tools '("rg" "ag" "pt" "ack" "grep")
   ;; The default package repository used if no explicit repository has been
   ;; specified with an installed package.
   ;; Not used for now. (default nil)
   dotspacemacs-default-package-repository nil
   ))

(defun dotspacemacs/user-init ()
  "Initialization function for user code.
It is called immediately after `dotspacemacs/init'.  You are free to put any
user code."
  )

(defun dotspacemacs/user-config ()
  ;; Indentation
  (setq-default js-indent-level 2)
  (setq-default standard-indent 2)
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
  ;; Default to react
  (add-to-list 'auto-mode-alist '("\\.js\\'" . react-mode))

  ;; Tern autocomplete
  ;; (push '(company-tern) company-backends-web-mode)

  ;; Make linums relative by default
  (linum-relative-global-mode)

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

  ;; max column display
  (setq-default fill-column 80)

  ;; c++
  (add-hook 'before-save-hook 'clang-format-hook)
  (defun clang-format-hook ()
    (case major-mode
      ((c++-mode) (clang-format-buffer))))

  (add-hook 'c++-mode-hook 'clang-checker-hook)
  (defun clang-checker-hook ()
    (flycheck-select-checker 'c/c++-clang))

  ;; Ligature
  (drpandemic-symbols/init)

  ;; Fix auto paste
  (add-hook 'spacemacs-buffer-mode-hook (lambda ()
    (set (make-local-variable 'mouse-1-click-follows-link) nil)))

  ;; Newline at end of file
  (setq require-final-newline t)
  (setq mode-require-final-newline t)

  ;; org-mode
  (setq org-log-done 'time)
  (org-agenda-log-mode)

  ;; reason
  ;; (add-hook 'reason-mode-hook (lambda ()
  ;;   (add-hook 'before-save-hook 'refmt-before-save)))
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
 '(magit-commit-arguments
   (quote
    ("--verbose" "--gpg-sign=DrPandemic <bipbip500@gmail.com>")))
 '(package-selected-packages
   (quote
    (utop tuareg caml symon string-inflection seoul256-theme ruby-refactor realgud test-simple loc-changes load-relative phpunit phpcbf php-extras php-auto-yasnippets password-generator oldlace-theme ocp-indent monokai-theme merlin meghanada impatient-mode htmlize gradle-mode flycheck-flow flow-minor-mode evil-lion editorconfig drupal-mode company-php ac-php-core php-mode company-flow cmake-ide levenshtein browse-at-remote winum unfill toml-mode rvm ruby-tools ruby-test-mode rubocop rspec-mode robe rbenv rake racer shut-up minitest fuzzy flycheck-rust seq flycheck-credo chruby cargo rust-mode bundler inf-ruby dash stickyfunc-enhance srefactor sql-indent pdf-tools tablist omnisharp helm-cscope xcscope disaster csharp-mode company-c-headers cmake-mode clang-format evil-easymotion helm-purpose window-purpose imenu-list vmd-mode nginx-mode yaml-mode magit-gh-pulls github-search github-clone github-browse-file gist gh marshal logito pcache ht yapfify pyvenv pytest pyenv-mode py-isort pip-requirements live-py-mode hy-mode helm-pydoc cython-mode company-anaconda anaconda-mode pythonic powerline pug-mode spinner ob-elixir org markdown-mode json-snatcher json-reformat multiple-cursors js2-mode hydra parent-mode hide-comnt projectile request haml-mode gitignore-mode fringe-helper git-gutter+ git-gutter pos-tip flycheck flx magit magit-popup git-commit with-editor smartparens iedit anzu evil goto-chg undo-tree highlight sbt-mode scala-mode diminish web-completion-data dash-functional tern s bind-map bind-key yasnippet packed company elixir-mode pkg-info epl helm avy helm-core async auto-complete popup package-build company-emacs-eclim racket-mode faceup eclim skewer-mode simple-httpd dumb-jump f smooth-scrolling ruby-end page-break-lines leuven-theme buffer-move bracketed-paste xterm-color ws-butler window-numbering which-key web-mode web-beautify volatile-highlights vi-tilde-fringe uuidgen use-package toc-org tagedit spacemacs-theme spaceline solarized-theme smeargle slim-mode shell-pop scss-mode sass-mode restart-emacs rainbow-mode rainbow-identifiers rainbow-delimiters quelpa popwin persp-mode pcre2el paradox orgit org-plus-contrib org-bullets open-junk-file noflet neotree mwim multi-term move-text mmm-mode markdown-toc magit-gitflow macrostep lorem-ipsum livid-mode linum-relative link-hint less-css-mode json-mode js2-refactor js-doc jade-mode info+ indent-guide ido-vertical-mode hungry-delete hl-todo highlight-parentheses highlight-numbers highlight-indentation help-fns+ helm-themes helm-swoop helm-projectile helm-mode-manager helm-make helm-gitignore helm-flx helm-descbinds helm-css-scss helm-company helm-c-yasnippet helm-ag google-translate golden-ratio gitconfig-mode gitattributes-mode git-timemachine git-messenger git-link git-gutter-fringe git-gutter-fringe+ gh-md flycheck-pos-tip flycheck-mix flx-ido fill-column-indicator fancy-battery eyebrowse expand-region exec-path-from-shell evil-visualstar evil-visual-mark-mode evil-unimpaired evil-tutor evil-surround evil-search-highlight-persist evil-numbers evil-nerd-commenter evil-mc evil-matchit evil-magit evil-lisp-state evil-indent-plus evil-iedit-state evil-exchange evil-escape evil-ediff evil-args evil-anzu eval-sexp-fu eshell-z eshell-prompt-extras esh-help ensime emmet-mode elisp-slime-nav diff-hl define-word company-web company-tern company-statistics company-quickhelp column-enforce-mode color-identifiers-mode coffee-mode clean-aindent-mode auto-yasnippet auto-highlight-symbol auto-compile alchemist aggressive-indent adaptive-wrap ace-window ace-link ace-jump-helm-line ac-ispell))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(company-tooltip-common ((t (:inherit company-tooltip :weight bold :underline nil))))
 '(company-tooltip-common-selection ((t (:inherit company-tooltip-selection :weight bold :underline nil)))))
)
