;;; org-alert.el --- Notify org deadlines via notify-send

;; Copyright (C) 2015 Stephen Pegoraro

;; Author: Stephen Pegoraro <spegoraro@tutive.com>
;; Version: 0.1.0
;; Package-Requires: ((s "1.10.0") (dash "2.11.0") (alert "1.2"))
;; Keywords: org, org-mode, notify, notifications, calendar
;; URL: https://github.com/groksteve/org-alert

;; This program is free software: you can redistribute it and/or modify
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

;; This package provides functions to display system notifications for
;; any org-mode deadlines that are due in your agenda. To perform a
;; one-shot check call (org-alert-deadlines). To enable repeated
;; checking call (org-alert-enable) and to disable call
;; (org-alert-disable). You can set the checking interval by changing
;; the org-alert-interval variable to the number of seconds you'd
;; like.


;;; Code:

(require 's)
(require 'dash)
(require 'alert)
(require 'org-agenda)

(defvar org-alert-interval 300
  "Interval in seconds to recheck and display deadlines.")

(defvar org-alert-notification-title "Org Agenda"
  "Title to be sent with notify-send.")

(defvar org-alert-headline-regexp "\\(Sched.+:.+\\|Deadline:.+\\)"
  "Regexp for headlines to search in agenda buffer.")

(defvar org-alert-notify-cutoff 10
  "Number of minutes before a deadline to send a notification")

(defun org-alert--strip-prefix (headline)
  "Remove the scheduled/deadline prefix from HEADLINE."
  (replace-regexp-in-string ".*:\s+" "" headline))


(defun org-alert--unique-headlines (regexp agenda)
  "Return unique headlines from the results of REGEXP in AGENDA."
  (let ((lst (delete-dups
	      (mapcar #'car
		      (s-match-strings-all
		       org-alert-headline-regexp agenda)))))
  (cl-loop for i = 0 then (1+ i)
	   for elt in lst
	   unless (cl-oddp i) collect elt)))

(defun org-alert--get-headlines ()
  "Return the current org agenda as text only."
  (with-temp-buffer
    (let ((org-agenda-sticky nil)
	  (org-agenda-buffer-tmp-name (buffer-name)))
      (ignore-errors (org-agenda-list 1))
      (org-alert--unique-headlines org-alert-headline-regexp
				   (buffer-substring-no-properties (point-min) (point-max))))))


(defun org-alert--headline-complete? (headline)
  "Return whether HEADLINE has been completed."
  (--any? (s-starts-with? it headline) org-done-keywords-for-agenda))


(defun org-alert--filter-active (deadlines)
  "Remove any completed headings from the provided DEADLINES."
  (cl-remove-if-not
   #'(lambda (str) (string-match "TODO" str)) deadlines))


(defun org-alert--string-match (regexp str &optional num)
  "Return NUMth match in STR matching REGEXP"
  (or num (setq num 1))
  (string-match regexp str)
  (match-string num str))


(defun org-alert--parse-entries (deadlines)
  "Extract the time and task name of entries in DEADLINES,
returning the result as a list of (TIME TASK)"
  (mapcar #'(lambda (dl)
	      (list (org-alert--string-match "\\([0-9]+:[0-9]+\\)" dl)
		    (org-alert--string-match "Scheduled: +TODO +\\(.*\\)" dl)))
	  deadlines))


(defun to-minute (hour minute)
  "Convert HOUR and MINUTE to minutes"
  (+ (* 60 hour) minute))


(defun check-time (time &optional now)
  "Check that TIME is less than current time"
  (let* ((time (mapcar #'string-to-number (split-string time ":")))
	 (now (or now (decode-time (current-time))))
	 (now (to-minute (decoded-time-hour now) (decoded-time-minute now)))
	 (then (to-minute (car time) (cadr time))))
    (<= (- then now) org-alert-notify-cutoff)))


(defun org-alert-check ()
  "Check for active, due deadlines and initiate notifications."
  (interactive)
  ;; avoid interrupting current command.
  (unless (minibufferp)
    (save-window-excursion
      (save-excursion
        (save-restriction
	  (let ((active (org-alert--filter-active
			 (org-alert--get-headlines))))
	    (dolist (dl (org-alert--parse-entries active))
	      (when (and dl (check-time (car dl)))
		(alert
		 (concat (car dl) ": "
			 (cadr dl)) :title org-alert-notification-title)))))))
    (when (get-buffer org-agenda-buffer-name)
      (ignore-errors
    	(with-current-buffer org-agenda-buffer-name
    	  (org-agenda-redo t))))))


(defun org-alert-enable ()
  "Enable the notification timer.  Cancels existing timer if running."
  (interactive)
  (org-alert-disable)
  (run-at-time 0 org-alert-interval 'org-alert-check))


(defun org-alert-disable ()
  "Cancel the running notification timer."
  (interactive)
  (dolist (timer timer-list)
    (if (eq (elt timer 5) 'org-alert-check)
	(cancel-timer timer))))


(provide 'org-alert)
;;; org-alert.el ends here

;; tests
(ert-deftest test-check-time ()
  (should (equal (check-time "10:06" '(0 55 9 24 8 2021 2 t -18000)) nil))
  (should (equal (check-time "10:04" '(0 55 9 24 8 2021 2 t -18000)) t)))
