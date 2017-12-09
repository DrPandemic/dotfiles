;; https://gist.github.com/kwf/dea7bc51101083acb95c875140e2a96d#file-pretty-pragmata-el-L167
;; http://emacsredux.com/blog/2014/08/25/a-peek-at-emacs-24-dot-4-prettify-symbols-mode/
(defun drpandemic-symbols/setup-symbols ()
  (setq prettify-symbols-alist
    (append prettify-symbols-alist
      '(("!!" . ?)
        ("lambda" . ?λ)
        ("!="  . ?≠)
        ("!==" . ?≢)
        ("<-"   . ?←)
        ("->"   . ?→)
        ("=>"   . ?⇒)
        ("<=>"  . ?⟺)
        ("<==>" . ?⟺)
        ("==>"  . ?⟹)
        ("<=="  . ?⟸)
        ("|->"  . ?⟼)
        ("<-|"  . ?⟻)
        ("|=>"  . ?⟾)
        ("<=|" . ?⟽)
        ))))

(defun refresh-pretty ()
  (prettify-symbols-mode -1)
  (prettify-symbols-mode +1))

(defun drpandemic-symbols/init ()
  (mapc (lambda (hook)
          (add-hook hook (lambda () (drpandemic-symbols/setup-symbols) (refresh-pretty))))
        '(text-mode-hook
          prog-mode-hook))
  )
