;;; packages.el --- drpandemic-javascript layer packages file for Spacemacs.
;;
;; Copyright (c) 2012-2017 Sylvain Benner & Contributors
;;
;; Author:  <parasithe@aerius>
;; URL: https://github.com/syl20bnr/spacemacs
;;
;; This file is not part of GNU Emacs.
;;
;;; License: GPLv3

;; Initial layer from https://github.com/aaronjensen/spacemacs.d/tree/master/layers/%2Baj/aj-javascript
;; and https://github.com/jdelStrother/spacemacs/tree/flow-type-minor/layers/%2Blang/flow-type
;; This is a react and flow type layer

(defconst drpandemic-javascript-packages
  '(
    web-mode
    eldoc
    flycheck
    (flow-minor-mode :location (recipe :fetcher github :repo "an-sh/flow-minor-mode"))
    (company-flow :toggle (configuration-layer/package-usedp 'company))
    (flycheck-flow :toggle (configuration-layer/package-usedp 'flycheck))
    ))

(defun drpandemic-javascript/post-init-web-mode ()
  (use-package react-mode
    :defer t
    :init
    (progn
      (add-to-list 'auto-mode-alist '("\\.js\\'" . react-mode))

      (remove-hook 'react-mode-hook 'tern-mode)
      (remove-hook 'react-mode-hook 'emmet-mode)

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

      (advice-add #'js-jsx-indent-line
                  :after
                  #'drpandemic-javascript/js-jsx-indent-line-align-closing-bracket)
      )
    :config
    (modify-syntax-entry ?_ "w" js2-mode-syntax-table)))

(defun drpandemic-javascript/init-flow-minor-mode ()
  (use-package flow-minor-mode)
  (spacemacs/declare-prefix-for-mode 'react-mode "mf" "flow" "flow type checker commands")
  (spacemacs/set-leader-keys-for-minor-mode 'react-mode
    "fd" 'flow-minor-jump-to-definition
    "fc" 'flow-minor-status
    "ft" 'flow-minor-type-at-pos
    ))

(defun drpandemic-javascript/init-company-flow ()
  (use-package company-flow
    :defer t
    :config
    (progn
      (push 'react-mode company-flow-modes))))

(defun drpandemic-javascript/init-flycheck-flow()
  (with-eval-after-load 'flycheck
    (when drpandemic-javascript-enable-flycheck-flow
      (use-package flycheck-flow
        :config
        (progn
          ;; Don't run flow if there's no @flow pragma
          (custom-set-variables '(flycheck-javascript-flow-args (quote ("--respect-pragma"))))
          ;; Run flow in react-mode files
          (flycheck-add-mode 'javascript-flow 'react-mode)
          ;; After running js-flow, run js-eslint
          (flycheck-add-next-checker 'javascript-flow 'javascript-eslint)
          )))))

(defun drpandemic-javascript/post-init-eldoc()
  (add-hook 'react-mode-hook #'drpandemic-javascript/enable-eldoc))

(defun drpandemic-javascript/post-init-company-flow ()
  (with-eval-after-load 'company
    (spacemacs|add-company-backends
      :backends company-flow
      :modes
      react-mode)
    (add-hook 'react-mode-hook #'drpandemic-javascript/use-flow-from-node-modules)
    ))

(defun drpandemic-javascript/post-init-flycheck ()
  (push 'javascript-jshint flycheck-disabled-checkers)
  (push 'json-jsonlint flycheck-disabled-checkers)
  (add-hook 'react-mode-hook #'drpandemic-javascript/use-eslint-from-node-modules)
  (spacemacs/enable-flycheck 'react-mode))

(defun drpandemic-javascript/post-init-react-mode ()
  (with-eval-after-load 'flycheck
    (add-hook 'react-mode-hook 'flow-minor-enable-automatically)
    )
  )

;;; packages.el ends here
