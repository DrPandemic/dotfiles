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
    rjsx-mode
    eldoc
    company
    flycheck
    (flow-minor-mode :location (recipe :fetcher github :repo "jdelStrother/flow-minor-mode"))
    (company-flow :toggle (configuration-layer/package-usedp 'company))
    (flycheck-flow :toggle (configuration-layer/package-usedp 'flycheck))
    ))

(defun drpandemic-javascript/init-rjsx-mode ()
  (use-package rjsx-mode
    :defer t
    :init
    (progn
      (add-to-list 'auto-mode-alist '("\\.js\\'" . rjsx-mode))

      (setq
       js2-mode-show-strict-warnings nil
       js2-mode-show-parse-errors nil
       js-indent-level 2
       js2-basic-offset 2
       js2-strict-trailing-comma-warning nil
       js2-strict-missing-semi-warning nil)

      (advice-add #'js-jsx-indent-line
                  :after
                  #'drpandemic-javascript/js-jsx-indent-line-align-closing-bracket)
      )
    :config
    (modify-syntax-entry ?_ "w" js2-mode-syntax-table)))

(defun drpandemic-javascript/init-flow-minor-mode ()
  (use-package flow-minor-mode)
  (spacemacs/declare-prefix-for-mode 'flow-minor-mode "mf" "flow" "flow type checker commands")
  (spacemacs/set-leader-keys-for-minor-mode 'flow-minor-mode
    "fd" 'flow-minor-jump-to-definition
    "fc" 'flow-minor-status
    "ft" 'flow-minor-type-at-pos
    ))

(defun drpandemic-javascript/init-company-flow ()
  (use-package company-flow
    :defer t
    :config
    (progn
      (push 'rjsx-mode company-flow-modes))))

(defun drpandemic-javascript/init-flycheck-flow()
  (with-eval-after-load 'flycheck
    (use-package flycheck-flow
      :config
      (progn
        ;; Don't run flow if there's no @flow pragma
        (custom-set-variables '(flycheck-javascript-flow-args (quote ("--respect-pragma"))))
        ;; Run flow in rjsx-mode files
        (flycheck-add-mode 'javascript-flow 'rjsx-mode)
        ;; After running js-flow, run js-eslint
        (flycheck-add-next-checker 'javascript-flow 'javascript-eslint)
        ))))

;; (defun drpandemic-javascript/post-init-eldoc()
;;   (with-eval-after-load 'eldoc-mode
;;     (message "6")
;;     (push 'flow-type/enable-eldoc react-mode-hook)))

(defun drpandemic-javascript/post-init-company ()
  (message "8")
  (add-to-list 'company-backends 'company-flow)
  (push 'company-flow company-backends)
  (message "8")
  )

(defun drpandemic-javascript/post-init-company-flow ()
  (use-package company-flow
    :defer t
    :config
    (progn
      (push 'rjsx-mode company-flow-modes))))

(defun drpandemic-javascript/post-init-flycheck ()
  (push 'javascript-jshint flycheck-disabled-checkers)
  (push 'json-jsonlint flycheck-disabled-checkers)
  (add-hook 'js2-mode-hook #'drpandemic-javascript/use-eslint-from-node-modules)
  )

(defun drpandemic-javascript/post-init-rjsx-mode ()
  (with-eval-after-load 'add-node-modules-path
    (add-hook 'js2-mode-hook 'add-node-modules-path)
    )
  (with-eval-after-load 'flycheck
    (add-hook 'js2-mode-hook 'flow-minor-enable-automatically)
    ))

;;; packages.el ends here
