;;; helm-clojuredocs.el --- search for help in clojuredocs.org

;; Author: Michal Buczko <michal.buczko@gmail.com>
;; URL: https://github.com/mbuczko/helm-clojuredocs
;; Package-Requires: ((edn "1.1.2") (helm "1.5.7"))
;; Version: 0.2
;; Keywords: helm, clojure

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
(require 'edn)
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

(defface helm-clojuredocs-package
  '((default (:foreground "green"))) "Face used to describe package")

(defface helm-clojuredocs-type
  '((default (:foreground "grey50"))) "Face used to describe type")

(defun helm-net--url-retrieve-sync (request parser)
  (with-current-buffer (url-retrieve-synchronously request)
    (funcall parser)))

(defun helm-clojuredocs--parse-suggestion (suggestion)
  (cons
   (format "%s %s %s"
           (propertize (gethash ':ns suggestion) 'face 'helm-clojuredocs-package)
           (gethash ':name suggestion)
           (propertize (concat
                        "<" (gethash ':type suggestion) ">") 'face 'helm-clojuredocs-type))
   (gethash :href suggestion)))

(defun helm-clojuredocs--parse-buffer ()
  (goto-char (point-min))
  (when (re-search-forward "\\(({.+})\\)" nil t)
    (cl-loop for i in (edn-read (match-string 0))
             collect (helm-clojuredocs--parse-suggestion i) into result
             finally return result)))

(defun helm-clojuredocs-fetch (pattern request-prefix)
  "Fetch Clojuredocs suggestions and return them as a list."
  (let ((request (concat helm-clojuredocs-suggest-url
                         (url-hexify-string (or (and request-prefix
                                                     (concat request-prefix " " pattern))
                                                pattern)))))
    (puthash pattern (helm-net--url-retrieve-sync
                      request #'helm-clojuredocs--parse-buffer) helm-clojuredocs-cache)))

(defun helm-clojuredocs-set-candidates (&optional request-prefix)
  "Set candidates with result and number of clojuredocs results found."
  (let ((suggestions (or (gethash helm-pattern helm-clojuredocs-cache)
                         (or (sleep-for 0.1)
                             (helm-clojuredocs-fetch helm-pattern request-prefix)))))
    (if (member helm-pattern suggestions)
        suggestions
      (append
       suggestions
       (list (cons (format "Search for '%s' on clojuredocs.org" helm-input)
                   (concat "/search?q=" helm-input)))))))

(defvar helm-clojuredocs-cache (make-hash-table :test 'equal))
(defvar helm-source-clojuredocs
  (helm-build-sync-source "clojuredocs.org suggest"
    :candidates #'helm-clojuredocs-set-candidates
    :init (lambda () (clrhash helm-clojuredocs-cache))
    :action '(("Go to clojuredocs.org" . (lambda (candidate)
                                           (browse-url (concat "http://clojuredocs.org" candidate)))))
    :volatile t
    :requires-pattern 3))


(defun helm-clojuredocs-invoke (&optional init-value)
  (setq debug-on-error t)
  (helm :sources 'helm-source-clojuredocs
        :buffer "*helm-clojuredocs*"
        :prompt "Doc for: "
        :input init-value)
  (setq debug-on-error nil))

;;;###autoload
(defun helm-clojuredocs ()
  "Preconfigured `helm' for searching in clojuredocs.org"
  (interactive)
  (helm-clojuredocs-invoke))

;;;###autoload
(defun helm-clojuredocs-at-point ()
  "Preconfigured `helm' for searching in clojuredocs.org with symbol at point"
  (interactive)
  (helm-clojuredocs-invoke (thing-at-point 'symbol)))

(provide 'helm-clojuredocs)

;; Local Variables:
;; coding: utf-8
;; End:

;;; helm-clojuredocs.el ends here
