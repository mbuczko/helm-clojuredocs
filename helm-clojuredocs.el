;;; helm-clojuredocs.el --- helm search in clojuredocs.org -*- lexical-binding: t -*-

;; Copyright (C) 2016 Michal Buczko <michal.buczko@gmail.com>

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

;;; Code:

(require 'url)
(require 'browse-url)
(require 'helm)

(defgroup helm-clojuredocs nil
  "Net related applications and libraries for Helm."
  :group 'helm)

(defcustom helm-clojuredocs-suggest-url
  "http://clojuredocs.org/ac-search?query="
  "Url used for looking up Clojuredocs suggestions."
  :type 'string
  :group 'helm-clojuredocs)

(defface face-package
  '((default (:foreground "green"))) "Face used to describe package")

(defface face-type
  '((default (:foreground "grey50"))) "Face used to describe type")

(defun helm-net--url-retrieve-sync (request parser)
  (with-current-buffer (url-retrieve-synchronously request)
    (funcall parser)))

(defun helm-clojuredocs--parse-suggestion (suggestion)
  (cons
   (format "%s %s %s"
           (propertize (gethash ':ns suggestion) 'face 'face-package)
           (gethash ':name suggestion)
           (propertize (concat
                        "<" (gethash ':type suggestion) ">") 'face 'face-type))
   (gethash :href suggestion)))

(defun helm-clojuredocs--parse-buffer ()
  (goto-char (point-min))
  (when (re-search-forward "\\(({.+})\\)" nil t)
    (cl-loop for i in (edn-read (match-string 0))
             collect (helm-clojuredocs--parse-suggestion i) into result
             finally return result)))

(defun helm-clojuredocs-fetch (input)
  "Fetch Clojuredocs suggestions and return them as a list."
  (require 'edn)
  (let ((request (concat helm-clojuredocs-suggest-url
                         (url-hexify-string input))))
    (helm-net--url-retrieve-sync
     request #'helm-clojuredocs--parse-buffer)))

(defun helm-clojuredocs-set-candidates (&optional request-prefix)
  "Set candidates with result and number of clojuredocs results found."
  (let ((suggestions (helm-clojuredocs-fetch
                      (or (and request-prefix
                               (concat request-prefix
                                       " " helm-pattern))
                          helm-pattern))))
    (if (member helm-pattern suggestions)
        suggestions
      (append
       suggestions
       (list (cons (format "Search for '%s' on clojuredocs.org" helm-input)
                   (concat "/search?q=" helm-input)))))))

(defvar helm-source-clojuredocs
  (helm-build-sync-source "clojuredocs.org suggest"
    :candidates #'helm-clojuredocs-set-candidates
    :action '(("Go to clojuredocs.org" . (lambda (candidate)
                                           (browse-url (concat "http://clojuredocs.org" candidate)))))
    :volatile t
    :requires-pattern 3))

;;;###autoload
(defun helm-clojuredocs ()
  "Preconfigured `helm' for searching in clojuredocs.org"
  (interactive)
  (setq debug-on-error t)
  (helm-other-buffer 'helm-source-clojuredocs "*helm clojuredocs*"))

(provide 'helm-clojuredocs)

;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:

;;; helm-clojuredocs.el ends here
