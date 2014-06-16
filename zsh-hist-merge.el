;;; zsh-hist-merge.el --- merging multiple zsh files      -*- lexical-binding: t; -*-

;; Copyright (C) 2014 KAWABATA, Taichi

;; Author: KAWABATA, Taichi <kawabata.taichi@lab.ntt.co.jp>
;; Keywords: tools

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This code merges two zsh_history files (`zsh-histomerge-target-1'
;; `zsh-histomerge-target-2') and output to specified file
;; (`zsh-hist-merge-dest'), and remove (older) duplicate commands,
;; assuming that "setopt extended_history" is set.

;;; Code:

(require 'zsh-history)

(defgroup zsh-hist-merge nil
  "ZSH History merge."
  :prefix "zsh-hist-"
  :group 'shell)

(defcustom zsh-hist-merge-target-1
  "~/.zsh_history"
  "ZSH history merge target 1."
  :type 'file
  :group 'zsh-hist-merge)

(defcustom zsh-hist-merge-target-2
  "~/.zsh_history_orig"
  "ZSH history merge target 2."
  :type 'file
  :group 'zsh-hist-merge)

(defcustom zsh-hist-merge-dest
  "~/.zsh_history_dest"
  "ZSH history merge destination."
  :type 'file
  :group 'zsh-hist-merge)

(defvar zsh-hist-merge-newline "⏎")

(defun zsh-hist-merge-encode-newline ()
  "Encode zsh_history newline."
  (interactive)
  (goto-char (point-min))
  (while (re-search-forward "\\\\\n" nil t)
    (replace-match (concat "\\\\" zsh-hist-merge-newline))))

(defun zsh-hist-merge-decode-newline ()
  "Encode zsh_history newline."
  (interactive)
  (goto-char (point-min))
  (while (re-search-forward
          (concat "\\\\" zsh-hist-merge-newline) nil t)
    (replace-match "\\\\\n")))

(defun zsh-hist-merge-files ()
  "Merge two history files."
  (interactive)
  (let ((coding-system-for-read 'zsh-history)
        (coding-system-for-write 'zsh-history)
        (table (make-hash-table :test 'equal)))
    (with-temp-file zsh-hist-merge-dest
      (insert-file-contents zsh-hist-merge-target-1)
      (insert-file-contents zsh-hist-merge-target-2)
      (zsh-hist-merge-encode-newline)
      (sort-lines nil (point-min) (point-max))
      (goto-char (point-max))
      (while (re-search-backward "^: [0-9]+:[0-9];\\(.+\\)\n" nil t)
        (let ((match (match-string 1)))
          (if (gethash match table)
              (replace-match "")
            (puthash match t table))))
      (zsh-hist-merge-decode-newline))))

(provide 'zsh-hist-merge)

;;; zsh-hist-merge.el ends here
