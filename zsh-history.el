;;; zsh-history.el --- Zsh history file encoder/decoder.  -*- lexical-binding: t; -*-

;; Filename: zsh-history.el
;; Description: Zsh history file encoder/decoder.
;; Author: KAWABATA, Taichi <kawabata.taichi_at_gmail.com>
;; Created: 2010-01-01
;; Version: 1.140313
;; Keywords: i18n
;; Human-Keywords: Zsh
;; URL: https://github.com/kawabata/emacs-zsh-history

;;; Commentary:

;; This is a tiny tool to encode/decode Z-shell history file.
;;
;; In zsh history file, some functional bytes are escaped with meta
;; character. As of it, non-ascii texts in history file are sometimes
;; undecipherable.
;;
;; According to `init.c' of zsh, followings are meta characters.
;;
;; - 0x00, 0x83(Meta), 0x84(Pound)-0x9d(Nularg), 0xa0(Marker)
;;
;; For these bytes, 0x83(Meta) is preceded and target byte is `xor'ed
;; with 0x20.
;;
;; This file provides encoder and decoder for these bytes, so that
;; UTF-8 string in history file can be handled in Emacs.

;;; Code:

(defvar zsh-history-coding-system 'utf-8
  "Base coding system of zsh history file.")

(define-ccl-program zsh-history-decoder
  '(1 ((loop
        (read-if (r0 == #x83)
                 ((read r0) (r0 ^= #x20)))
        ;; write binary bytes, so you need to decode them later.
        (write r0)
        (repeat))))
  "decode .zsh_history file.")

(define-ccl-program zsh-history-encoder
  '(2 ((loop
        ;; it reads raw bytes, so you need to encode characters beforehand.
        (read r0)
        (r1 = (r0 < #x9e))
        (r2 = (r0 == #xa0))
        (if (((r0 > #x82) & r1) | r2)
            ((write #x83) (write (r0 ^ #x20)))
          (write r0))
        (repeat))))
  "encode .zsh_history file.")

(defun zsh-history-post-read (len)
  "Decode region as speicified coding system from current point to LEN.
This is intended to be used with CCL program."
  (save-excursion
    (save-restriction
      (narrow-to-region (point) (+ (point) len))
      (encode-coding-region (point-min) (point-max) 'latin-1)
      (decode-coding-region (point-min) (point-max) zsh-history-coding-system)
      (- (point-max) (point-min)))))

(defun zsh-history-pre-write (_ignore _ignore2)
  "Zsh-history pre write.  _IGNORE ad _IGNORE2 are ignored."
  (encode-coding-region (point-min) (point-max) zsh-history-coding-system)
  (decode-coding-region (point-min) (point-max) 'latin-1))

(define-coding-system 'zsh-history "ZSH history"
  :coding-type 'ccl
  :charset-list '(unicode)
  :mnemonic ?Z :ascii-compatible-p t
  :eol-type 'unix
  :ccl-decoder 'zsh-history-decoder
  :post-read-conversion 'zsh-history-post-read
  :ccl-encoder 'zsh-history-encoder
  :pre-write-conversion 'zsh-history-pre-write)

;; declare to use this encoder/decoder for zsh_history file.
(modify-coding-system-alist 'file "zsh_history" 'zsh-history)

(provide 'zsh-history)

;;; zsh-history.el ends here

;; Local Variables:
;; time-stamp-pattern: "10/Version:\\\\?[ \t]+1.%02y%02m%02d\\\\?\n"
;; End:
